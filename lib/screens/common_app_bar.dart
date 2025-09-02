import 'package:flutter/material.dart';
import 'buyer_profile_screen.dart';

class CommonAppBar extends StatefulWidget implements PreferredSizeWidget {
  final String? currentUserRole;
  final int? cartCount;
  final int? notificationCount;
  final String? userName;
  final String? userImage;
  final VoidCallback? onCartTap;
  final VoidCallback? onProfileTap;
  final VoidCallback? onThemeTap;
  final VoidCallback? onNotificationTap;
  final VoidCallback? onLogoTap;
  final VoidCallback? onLogout;
  final VoidCallback? onSwitchRole;
  final VoidCallback? onRegisterSeller;
  final bool isSeller;
  final bool isDarkTheme;
  final List<Map<String, dynamic>>? themes;
  final ValueChanged<String>? onThemeChange;

  const CommonAppBar({
    Key? key,
    this.currentUserRole,
    this.cartCount,
    this.notificationCount,
    this.userName,
    this.userImage,
    this.onCartTap,
    this.onProfileTap,
    this.onThemeTap,
    this.onNotificationTap,
    this.onLogoTap,
    this.onLogout,
    this.onSwitchRole,
    this.onRegisterSeller,
    this.isSeller = false,
    this.isDarkTheme = false,
    this.themes,
    this.onThemeChange,
  }) : super(key: key);

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  State<CommonAppBar> createState() => _CommonAppBarState();
}

class _CommonAppBarState extends State<CommonAppBar> with TickerProviderStateMixin {
  late AnimationController _notificationController;
  late Animation<double> _notificationAnimation;

  @override
  void initState() {
    super.initState();
    _notificationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _notificationAnimation = Tween<double>(begin: 1.0, end: 1.2).animate(
      CurvedAnimation(parent: _notificationController, curve: Curves.elasticOut),
    );
  }

  @override
  void dispose() {
    _notificationController.dispose();
    super.dispose();
  }

  void _showThemeBottomSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => _buildThemeBottomSheet(),
    );
  }

  void _showProfileBottomSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => _buildProfileBottomSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isAdmin = widget.currentUserRole == 'admin';
    final isBuyer = widget.currentUserRole == 'buyer';

    return AppBar(
      backgroundColor: colorScheme.surface,
      foregroundColor: colorScheme.onSurface,
      elevation: 0,
      scrolledUnderElevation: 1,
      centerTitle: false,
      leading: isAdmin 
        ? _buildAdminMenuButton(colorScheme)
        : null,
      title: _buildLogo(),
      actions: [
        // Role indicator chip
        if (widget.currentUserRole != null)
          _buildRoleChip(colorScheme),
        
        const SizedBox(width: 4), // Reduced from 8
        
        // Notification button with animation
        if (widget.notificationCount != null && !isAdmin)
          _buildNotificationButton(colorScheme),
        
        // Theme toggle button
        _buildThemeButton(colorScheme),
        
        // Profile menu button
        _buildProfileButton(colorScheme),
        
        // Cart button for buyers
        if (isBuyer)
          _buildCartButton(colorScheme),
        
        const SizedBox(width: 4), // Reduced from 8
      ],
    );
  }

  Widget _buildAdminMenuButton(ColorScheme colorScheme) {
    return Container(
      margin: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: colorScheme.primaryContainer,
        borderRadius: BorderRadius.circular(12),
      ),
      child: IconButton(
        icon: Icon(Icons.admin_panel_settings, color: colorScheme.onPrimaryContainer),
        onPressed: widget.onLogoTap,
        tooltip: 'Admin Dashboard',
      ),
    );
  }

  Widget _buildLogo() {
    return GestureDetector(
      onTap: widget.onLogoTap,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: Image.asset(
                'assets/images/logo-v10.png', 
                width: 28, // Reduced from 32
                height: 28, // Reduced from 32
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primary,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Icon(
                      Icons.pets,
                      color: Theme.of(context).colorScheme.onPrimary,
                      size: 18, // Reduced from 20
                    ),
                  );
                },
              ),
            ),
          ),
          const SizedBox(width: 6), // Reduced from 8
          Flexible( // Changed from fixed text to Flexible
            child: Text(
              'AdoPals',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                fontSize: 20, // Slightly reduced
                color: Theme.of(context).colorScheme.primary,
              ),
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRoleChip(ColorScheme colorScheme) {
    IconData roleIcon;
    String roleText;
    Color chipColor;

    switch (widget.currentUserRole) {
      case 'buyer':
        roleIcon = Icons.favorite;
        roleText = 'Pet Parent';
        chipColor = colorScheme.tertiary;
        break;
      case 'seller':
      case 'giver':
        roleIcon = Icons.storefront;
        roleText = 'Pet Giver';
        chipColor = colorScheme.secondary;
        break;
      case 'admin':
        roleIcon = Icons.admin_panel_settings;
        roleText = 'Admin';
        chipColor = colorScheme.error;
        break;
      default:
        return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: chipColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: chipColor.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(roleIcon, size: 14, color: chipColor),
          const SizedBox(width: 4),
          Text(
            roleText,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: chipColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationButton(ColorScheme colorScheme) {
    return AnimatedBuilder(
      animation: _notificationAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _notificationAnimation.value,
          child: Stack(
            children: [
              Container(
                margin: const EdgeInsets.all(2), // Reduced from 4
                decoration: BoxDecoration(
                  color: colorScheme.surfaceVariant,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: IconButton(
                  icon: Icon(
                    Icons.notifications_outlined,
                    color: colorScheme.onSurfaceVariant,
                  ),
                  onPressed: () {
                    _notificationController.forward().then((_) {
                      _notificationController.reverse();
                    });
                    widget.onNotificationTap?.call();
                  },
                  tooltip: 'Notifications',
                ),
              ),
              if ((widget.notificationCount ?? 0) > 0)
                Positioned(
                  right: 6, // Adjusted for new margin
                  top: 6,   // Adjusted for new margin
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
                    constraints: const BoxConstraints(minWidth: 18, minHeight: 18),
                    child: Text(
                      widget.notificationCount! > 99 ? '99+' : widget.notificationCount.toString(),
                      style: TextStyle(
                        color: colorScheme.onError,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildThemeButton(ColorScheme colorScheme) {
    return Container(
      margin: const EdgeInsets.all(2), // Reduced from 4
      decoration: BoxDecoration(
        color: colorScheme.surfaceVariant,
        borderRadius: BorderRadius.circular(12),
      ),
      child: IconButton(
        icon: Icon(
          widget.isDarkTheme ? Icons.light_mode : Icons.dark_mode,
          color: colorScheme.onSurfaceVariant,
        ),
        onPressed: _showThemeBottomSheet,
        tooltip: 'Theme Settings',
      ),
    );
  }

  Widget _buildProfileButton(ColorScheme colorScheme) {
    return Container(
      margin: const EdgeInsets.all(2), // Reduced from 4
      decoration: BoxDecoration(
        color: colorScheme.surfaceVariant,
        borderRadius: BorderRadius.circular(12),
      ),
      child: IconButton(
        icon: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: widget.userImage != null && widget.userImage!.isNotEmpty
              ? Image.network(
                  widget.userImage!,
                  width: 24,
                  height: 24,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Icon(
                      Icons.account_circle,
                      color: colorScheme.onSurfaceVariant,
                      size: 24,
                    );
                  },
                )
              : Icon(
                  Icons.account_circle,
                  color: colorScheme.onSurfaceVariant,
                  size: 24,
                ),
        ),
        onPressed: _showProfileBottomSheet,
        tooltip: 'Profile Menu',
      ),
    );
  }

  Widget _buildCartButton(ColorScheme colorScheme) {
    return Stack(
      children: [
        Container(
          margin: const EdgeInsets.all(2), // Reduced from 4
          decoration: BoxDecoration(
            color: colorScheme.primaryContainer,
            borderRadius: BorderRadius.circular(12),
          ),
          child: IconButton(
            icon: Icon(
              Icons.pets,
              color: colorScheme.onPrimaryContainer,
            ),
            onPressed: widget.onCartTap,
            tooltip: 'Adoption Cart',
          ),
        ),
        if ((widget.cartCount ?? 0) > 0)
          Positioned(
            right: 6, // Adjusted for new margin
            top: 6,   // Adjusted for new margin
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
              constraints: const BoxConstraints(minWidth: 18, minHeight: 18),
              child: Text(
                widget.cartCount! > 99 ? '99+' : widget.cartCount.toString(),
                style: TextStyle(
                  color: colorScheme.onError,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildThemeBottomSheet() {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle
            Container(
              margin: const EdgeInsets.only(top: 12),
              height: 4,
              width: 40,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.onSurfaceVariant.withOpacity(0.4),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Theme Settings',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  // Quick theme toggle
                  ListTile(
                    leading: Icon(
                      widget.isDarkTheme ? Icons.light_mode : Icons.dark_mode,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    title: Text(widget.isDarkTheme ? 'Switch to Light Mode' : 'Switch to Dark Mode'),
                    trailing: Switch(
                      value: widget.isDarkTheme,
                      onChanged: (value) {
                        widget.onThemeTap?.call();
                        Navigator.pop(context);
                      },
                    ),
                    onTap: () {
                      widget.onThemeTap?.call();
                      Navigator.pop(context);
                    },
                  ),
                  
                  if (widget.themes != null && widget.onThemeChange != null) ...[
                    const Divider(),
                    const SizedBox(height: 8),
                    Text(
                      'Color Themes',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 16),
                    
                    // Theme grid
                    GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 3,
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 12,
                        childAspectRatio: 1,
                      ),
                      itemCount: widget.themes!.length,
                      itemBuilder: (context, index) {
                        final theme = widget.themes![index];
                        return _buildThemeOption(theme);
                      },
                    ),
                  ],
                  
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildThemeOption(Map<String, dynamic> theme) {
    return GestureDetector(
      onTap: () {
        widget.onThemeChange?.call(theme['value']);
        Navigator.pop(context);
      },
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: Theme.of(context).colorScheme.outline.withOpacity(0.3),
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [
                    Color(int.parse(theme['primaryColor'].toString().replaceAll('#', '0xFF'))),
                    Color(int.parse(theme['accentColor'].toString().replaceAll('#', '0xFF'))),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              theme['viewValue'] ?? '',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileBottomSheet() {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle
            Container(
              margin: const EdgeInsets.only(top: 12),
              height: 4,
              width: 40,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.onSurfaceVariant.withOpacity(0.4),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  // Profile header
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 24,
                        backgroundImage: widget.userImage != null && widget.userImage!.isNotEmpty
                            ? NetworkImage(widget.userImage!)
                            : null,
                        child: widget.userImage == null || widget.userImage!.isEmpty
                            ? Icon(
                                Icons.account_circle,
                                size: 32,
                                color: Theme.of(context).colorScheme.primary,
                              )
                            : null,
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.userName ?? 'User',
                              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            if (widget.currentUserRole != null)
                              Text(
                                _getRoleDisplayName(widget.currentUserRole!),
                                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                                ),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // Menu items
                  if (widget.currentUserRole != 'admin') ...[
                    _buildProfileMenuItem(
                      icon: Icons.person_outline,
                      title: 'Profile',
                      onTap: () {
                        Navigator.pop(context);
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const BuyerProfileScreen(),
                          ),
                        );
                      },
                    ),
                    
                    _buildProfileMenuItem(
                      icon: widget.currentUserRole == 'buyer' ? Icons.pets : Icons.assignment,
                      title: widget.currentUserRole == 'buyer' ? 'My Adoptions' : 'My Requests',
                      onTap: () {
                        Navigator.pop(context);
                        // TODO: Navigate to orders/requests
                      },
                    ),
                    
                    if (widget.currentUserRole == 'buyer' && !widget.isSeller)
                      _buildProfileMenuItem(
                        icon: Icons.storefront_outlined,
                        title: 'Register as Pet Giver',
                        onTap: () {
                          Navigator.pop(context);
                          widget.onRegisterSeller?.call();
                        },
                      ),
                    
                    if (widget.currentUserRole == 'buyer' && widget.isSeller)
                      _buildProfileMenuItem(
                        icon: Icons.swap_horizontal_circle,
                        title: 'Switch to Pet Giver',
                        onTap: () {
                          Navigator.pop(context);
                          widget.onSwitchRole?.call();
                        },
                      ),
                    
                    if (widget.currentUserRole == 'seller' || widget.currentUserRole == 'giver')
                      _buildProfileMenuItem(
                        icon: Icons.swap_horizontal_circle,
                        title: 'Switch to Pet Parent',
                        onTap: () {
                          Navigator.pop(context);
                          widget.onSwitchRole?.call();
                        },
                      ),
                  ],
                  
                  const Divider(),
                  
                  _buildProfileMenuItem(
                    icon: Icons.logout,
                    title: 'Logout',
                    isDestructive: true,
                    onTap: () {
                      Navigator.pop(context);
                      _showLogoutConfirmation();
                    },
                  ),
                  
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileMenuItem({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    bool isDestructive = false,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    final textColor = isDestructive ? colorScheme.error : colorScheme.onSurface;
    final iconColor = isDestructive ? colorScheme.error : colorScheme.primary;

    return ListTile(
      leading: Icon(icon, color: iconColor),
      title: Text(
        title,
        style: TextStyle(
          color: textColor,
          fontWeight: FontWeight.w500,
        ),
      ),
      onTap: onTap,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
    );
  }

  String _getRoleDisplayName(String role) {
    switch (role) {
      case 'buyer':
        return 'Pet Parent';
      case 'seller':
      case 'giver':
        return 'Pet Giver';
      case 'admin':
        return 'Administrator';
      default:
        return role;
    }
  }

  void _showLogoutConfirmation() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(context);
              widget.onLogout?.call();
            },
            child: const Text('Logout'),
          ),
        ],
      ),
    );
  }
}
