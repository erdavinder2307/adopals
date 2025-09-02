import 'package:flutter/material.dart';

class ModernBottomNavigation extends StatefulWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;
  final String? currentUserRole;
  final bool isLoggedIn;
  final int? cartCount;
  final String? userImage;
  final VoidCallback? onThemeTap;
  final VoidCallback? onProfileTap;

  const ModernBottomNavigation({
    Key? key,
    required this.currentIndex,
    required this.onTap,
    this.currentUserRole,
    this.isLoggedIn = false,
    this.cartCount,
    this.userImage,
    this.onThemeTap,
    this.onProfileTap,
  }) : super(key: key);

  @override
  State<ModernBottomNavigation> createState() => _ModernBottomNavigationState();
}

class _ModernBottomNavigationState extends State<ModernBottomNavigation>
    with TickerProviderStateMixin {
  late List<AnimationController> _controllers;
  late List<Animation<double>> _animations;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
  }

  void _initializeAnimations() {
    final itemCount = _getNavigationItems().length;
    _controllers = List.generate(
      itemCount,
      (index) => AnimationController(
        duration: const Duration(milliseconds: 200),
        vsync: this,
      ),
    );
    _animations = _controllers.map((controller) {
      return Tween<double>(begin: 1.0, end: 1.2).animate(
        CurvedAnimation(parent: controller, curve: Curves.elasticOut),
      );
    }).toList();

    // Animate the current item
    if (widget.currentIndex < _controllers.length) {
      _controllers[widget.currentIndex].forward();
    }
  }

  @override
  void didUpdateWidget(ModernBottomNavigation oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.currentIndex != widget.currentIndex) {
      _updateAnimations();
    }
  }

  void _updateAnimations() {
    for (int i = 0; i < _controllers.length; i++) {
      if (i == widget.currentIndex) {
        _controllers[i].forward();
      } else {
        _controllers[i].reverse();
      }
    }
  }

  @override
  void dispose() {
    for (var controller in _controllers) {
      controller.dispose();
    }
    super.dispose();
  }

  List<BottomNavItem> _getNavigationItems() {
    final items = <BottomNavItem>[
      const BottomNavItem(
        icon: Icons.home_outlined,
        activeIcon: Icons.home,
        label: 'Home',
      ),
    ];

    if (widget.isLoggedIn) {
      items.add(
        const BottomNavItem(
          icon: Icons.palette_outlined,
          activeIcon: Icons.palette,
          label: 'Theme',
        ),
      );

      // Add cart for buyers
      if (widget.currentUserRole == 'buyer') {
        items.add(
          BottomNavItem(
            icon: Icons.pets_outlined,
            activeIcon: Icons.pets,
            label: 'Cart',
            badge: widget.cartCount,
          ),
        );
      }

      items.add(
        const BottomNavItem(
          icon: Icons.account_circle_outlined,
          activeIcon: Icons.account_circle,
          label: 'Profile',
          isProfile: true,
        ),
      );
    } else {
      // For non-logged-in users, add login option
      items.add(
        const BottomNavItem(
          icon: Icons.login_outlined,
          activeIcon: Icons.login,
          label: 'Sign In',
        ),
      );
    }

    return items;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final items = _getNavigationItems();

    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        child: Container(
          height: 72,
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: items.asMap().entries.map((entry) {
              final index = entry.key;
              final item = entry.value;
              final isSelected = index == widget.currentIndex;

              return AnimatedBuilder(
                animation: _animations[index],
                builder: (context, child) {
                  return Transform.scale(
                    scale: _animations[index].value,
                    child: _buildNavItem(
                      item: item,
                      isSelected: isSelected,
                      colorScheme: colorScheme,
                      onTap: () {
                        widget.onTap(index);
                        _handleItemTap(index, item);
                      },
                    ),
                  );
                },
              );
            }).toList(),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem({
    required BottomNavItem item,
    required bool isSelected,
    required ColorScheme colorScheme,
    required VoidCallback onTap,
  }) {
    final iconColor = isSelected ? colorScheme.primary : colorScheme.onSurfaceVariant;
    final backgroundColor = isSelected 
        ? colorScheme.primaryContainer.withOpacity(0.3)
        : Colors.transparent;

    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          height: 56,
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Stack(
            children: [
              Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Icon or profile image
                    if (item.isProfile && widget.userImage != null && widget.userImage!.isNotEmpty)
                      CircleAvatar(
                        radius: 12,
                        backgroundImage: NetworkImage(widget.userImage!),
                        onBackgroundImageError: (exception, stackTrace) {
                          // Fallback handled by child
                        },
                        child: const SizedBox.shrink(),
                      )
                    else
                      Icon(
                        isSelected ? item.activeIcon : item.icon,
                        color: iconColor,
                        size: 24,
                      ),
                    
                    const SizedBox(height: 2),
                    
                    // Label
                    Text(
                      item.label,
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                        color: iconColor,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              
              // Badge
              if (item.badge != null && item.badge! > 0)
                Positioned(
                  right: 8,
                  top: 4,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: colorScheme.error,
                      borderRadius: BorderRadius.circular(10),
                      boxShadow: [
                        BoxShadow(
                          color: colorScheme.error.withOpacity(0.3),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                    child: Text(
                      item.badge! > 99 ? '99+' : item.badge.toString(),
                      style: TextStyle(
                        color: colorScheme.onError,
                        fontSize: 8,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  void _handleItemTap(int index, BottomNavItem item) {
    // Handle special cases
    if (widget.isLoggedIn) {
      if (index == 1) {
        // Theme button
        widget.onThemeTap?.call();
        return;
      } else if (item.isProfile) {
        // Profile button
        widget.onProfileTap?.call();
        return;
      }
    }
    
    // For other items, the parent widget handles navigation
  }
}

class BottomNavItem {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  final int? badge;
  final bool isProfile;

  const BottomNavItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
    this.badge,
    this.isProfile = false,
  });
}
