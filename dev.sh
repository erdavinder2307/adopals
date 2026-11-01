#!/usr/bin/env bash
# ============================================================
# Adoplas Mobile – dev launcher
# Run from: adopals/
# ============================================================
set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

GREEN="\033[0;32m"; YELLOW="\033[1;33m"; RED="\033[0;31m"
CYAN="\033[0;36m"; BOLD="\033[1m"; NC="\033[0m"
info()  { echo -e "${GREEN}[mobile]${NC} $*"; }
warn()  { echo -e "${YELLOW}[mobile]${NC} $*"; }
error() { echo -e "${RED}[mobile]${NC} $*"; exit 1; }
ask()   { echo -e "${CYAN}[mobile]${NC} $*"; }

# ── Check Flutter ─────────────────────────────────────────────
command -v flutter &>/dev/null || error "flutter not found."
info "Flutter: $(flutter --version 2>/dev/null | head -1)"

# ── Get packages ──────────────────────────────────────────────
info "Getting Flutter packages …"
flutter pub get

echo ""
echo -e "${BOLD}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${BOLD}  Available Devices, Simulators & Emulators${NC}"
echo -e "${BOLD}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"

declare -a DEVICE_UDID=()
declare -a DEVICE_NAME=()
declare -a DEVICE_TYPE=()
declare -a DEVICE_STATE=()

# ── Physical devices (connected via USB or wireless) ──────────
info "Scanning for connected devices …"
while IFS='|' read -r phys_id phys_name phys_plat; do
  [ -z "$phys_id" ] && continue
  DEVICE_UDID+=("$phys_id")
  DEVICE_NAME+=("$phys_name  [$phys_plat]")
  DEVICE_TYPE+=("physical")
  DEVICE_STATE+=("Connected")
done < <(flutter devices --machine 2>/dev/null | python3 -c "
import sys, json
try:
    devs = json.load(sys.stdin)
    skip = {'web-javascript', 'darwin', 'darwin-arm64', 'linux-x64', 'windows-x64'}
    for d in devs:
        plat = d.get('targetPlatform', '')
        if not d.get('isEmulator', False) and plat not in skip:
            print(d['id'] + '|' + d['name'] + '|' + plat)
except:
    pass
" 2>/dev/null || true)

# ── iOS simulators ────────────────────────────────────────────
if command -v xcrun &>/dev/null; then
  while IFS='|' read -r udid name state; do
    DEVICE_UDID+=("$udid")
    DEVICE_NAME+=("$name")
    DEVICE_TYPE+=("ios")
    DEVICE_STATE+=("$state")
  done < <(xcrun simctl list devices available --json 2>/dev/null | python3 -c "
import sys, json
d = json.load(sys.stdin)
seen = set()
for devs in d['devices'].values():
    for v in devs:
        if not v.get('isAvailable'): continue
        if 'iPhone' not in v['name'] and 'iPad' not in v['name']: continue
        if v['udid'] in seen: continue
        seen.add(v['udid'])
        print(v['udid'] + '|' + v['name'] + '|' + v.get('state','Shutdown'))
" 2>/dev/null || true)
fi

# ── Android AVDs ──────────────────────────────────────────────
if command -v emulator &>/dev/null; then
  while IFS= read -r avd; do
    [ -z "$avd" ] && continue
    RUNNING=$(adb devices 2>/dev/null | grep -c "emulator" || true)
    STATE=$( [ "$RUNNING" -gt 0 ] && echo "Running" || echo "Shutdown" )
    DEVICE_UDID+=("avd:$avd")
    DEVICE_NAME+=("$avd  (Android AVD)")
    DEVICE_TYPE+=("android")
    DEVICE_STATE+=("$STATE")
  done < <(emulator -list-avds 2>/dev/null || true)
fi

# ── Display table ─────────────────────────────────────────────
BOOTED_IDX=-1
for i in "${!DEVICE_NAME[@]}"; do
  state="${DEVICE_STATE[$i]}"
  case "$state" in
    Connected)        tag="${GREEN}● connected${NC}" ;;
    Booted|Running)   tag="${GREEN}● running${NC}" ;;
    *)                tag="${YELLOW}○ stopped${NC}" ;;
  esac
  if [ "$state" = "Connected" ] || [ "$state" = "Booted" ] || [ "$state" = "Running" ]; then
    [ "$BOOTED_IDX" -eq -1 ] && BOOTED_IDX=$i
  fi
  printf "  %2d)  %-42s  %b\n" "$((i+1))" "${DEVICE_NAME[$i]}" "$tag"
done

echo ""

CHOSEN_IDX=-1
CHOSEN_UDID=""

# ── Already running? ──────────────────────────────────────────
if [ "$BOOTED_IDX" -ge 0 ]; then
  info "Already running: ${DEVICE_NAME[$BOOTED_IDX]}"
  ask "Use it? [Y/n]: \c"
  read -r USE_RUNNING
  USE_RUNNING="${USE_RUNNING:-y}"
  if [[ "$USE_RUNNING" =~ ^[Yy] ]]; then
    CHOSEN_IDX=$BOOTED_IDX
    CHOSEN_UDID="${DEVICE_UDID[$BOOTED_IDX]}"
  fi
fi

# ── Ask which one to start ────────────────────────────────────
if [ "$CHOSEN_IDX" -eq -1 ]; then
  ask "Enter number to start (or press Enter to let Flutter choose): \c"
  read -r CHOICE
  if [ -n "$CHOICE" ] && [[ "$CHOICE" =~ ^[0-9]+$ ]]; then
    IDX=$((CHOICE - 1))
    if [ "$IDX" -ge 0 ] && [ "$IDX" -lt "${#DEVICE_NAME[@]}" ]; then
      CHOSEN_IDX=$IDX
      CHOSEN_UDID="${DEVICE_UDID[$IDX]}"
      TYPE="${DEVICE_TYPE[$IDX]}"

      if [ "$TYPE" = "physical" ]; then
        info "Using physical device: ${DEVICE_NAME[$IDX]}"
      elif [ "$TYPE" = "ios" ]; then
        info "Starting ${DEVICE_NAME[$IDX]} …"
        xcrun simctl boot "$CHOSEN_UDID" 2>/dev/null || true
        open -a Simulator 2>/dev/null || true
        info "Waiting for simulator to boot …"
        for _ in $(seq 1 30); do
          ST=$(xcrun simctl list devices --json 2>/dev/null | python3 -c "
import sys,json
d=json.load(sys.stdin)
for devs in d['devices'].values():
  for v in devs:
    if v['udid']=='$CHOSEN_UDID': print(v.get('state','')); exit()
" 2>/dev/null || true)
          [ "$ST" = "Booted" ] && break
          sleep 2
        done
        info "Simulator ready ✓"
      else
        info "Starting ${DEVICE_NAME[$IDX]} …"
        AVD="${CHOSEN_UDID#avd:}"
        emulator -avd "$AVD" -no-snapshot-load &>/dev/null &
        info "Waiting for Android emulator to boot …"
        ADB_DEV=""
        for _ in $(seq 1 60); do
          ADB_DEV=$(adb devices 2>/dev/null | grep -E 'emulator.*device$' | head -1 | awk '{print $1}')
          if [ -n "$ADB_DEV" ]; then
            BOOT=$(adb -s "$ADB_DEV" shell getprop sys.boot_completed 2>/dev/null | tr -d '[:space:]')
            [ "$BOOT" = "1" ] && break
          fi
          sleep 2
        done
        info "Waiting for Flutter to detect emulator …"
        for _ in $(seq 1 20); do
          flutter devices 2>/dev/null | grep -q "$ADB_DEV" && break
          sleep 2
        done
        CHOSEN_UDID="$ADB_DEV"
        info "Emulator ready ✓  ($CHOSEN_UDID)"
      fi
    fi
  fi
fi

D_FLAG=""
[ "$CHOSEN_IDX" -ge 0 ] && [ -n "$CHOSEN_UDID" ] && D_FLAG="-d $CHOSEN_UDID"

echo ""
info "Launching Adoplas Mobile …"
info "Hot reload: ${BOLD}r${NC} | Restart: ${BOLD}R${NC} | Quit: ${BOLD}q${NC}"
echo ""

exec flutter run $D_FLAG
