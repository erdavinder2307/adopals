import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:adopals/screens/buyer_profile_screen.dart'; // Import the BuyerProfileScreen

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

class _CommonAppBarState extends State<CommonAppBar> {
  Color _parseColor(dynamic colorValue) {
    if (colorValue is int) {
      return Color(colorValue);
    }
    if (colorValue is String && colorValue.startsWith('#')) {
      return Color(int.parse(colorValue.replaceFirst('#', '0xff')));
    }
    // Fallback to purple if not a valid hex string
    return Colors.purple;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AppBar(
      backgroundColor: theme.appBarTheme.backgroundColor ?? theme.primaryColor,
      elevation: 2,
      leading: widget.currentUserRole == 'admin'
          ? IconButton(
              icon: Icon(Icons.home), //Image.asset('assets/images/home@0.1x.png', width: 30, height: 30),
              onPressed: widget.onLogoTap,
            )
          : null,
      title: GestureDetector(
        onTap: widget.onLogoTap,
        child: Row(
          children: [
            Image.asset('assets/images/logo-v10.png', width: 40, height: 40),
            // const SizedBox(width: 8),
            // Text('AdoPals', style: TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
      ),
      actions: [
        // if (widget.currentUserRole == 'seller')
        //   Row(children: [
        //     const Icon(Icons.storefront),
        //     const SizedBox(width: 4),
        //     const Text('Seller'),
        //     const SizedBox(width: 16),
        //   ]),
        // if (widget.currentUserRole == 'buyer')
        //   Row(children: [
        //     const Icon(Icons.shopping_cart),
        //     const SizedBox(width: 4),
        //     const Text('Buyer'),
        //     const SizedBox(width: 16),
        //   ]),
        if (widget.notificationCount != null && widget.currentUserRole != 'admin')
          Stack(
            children: [
              IconButton(
                icon: const Icon(Icons.notifications),
                onPressed: widget.onNotificationTap,
              ),
              if ((widget.notificationCount ?? 0) > 0)
                Positioned(
                  right: 8,
                  top: 8,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: Colors.red,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      widget.notificationCount.toString(),
                      style: const TextStyle(color: Colors.white, fontSize: 10),
                    ),
                  ),
                ),
            ],
          ),
        IconButton(
          icon: Icon(widget.isDarkTheme ? Icons.light_mode : Icons.dark_mode),
          onPressed: widget.onThemeTap,
        ),
        if (widget.themes != null && widget.onThemeChange != null)
          PopupMenuButton<String>(
            icon: const Icon(Icons.palette),
            onSelected: widget.onThemeChange,
            itemBuilder: (context) => widget.themes!
                .map((theme) => PopupMenuItem<String>(
                      value: theme['value'],
                      child: Row(
                        children: [
                          Container(
                            width: 20,
                            height: 20,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: LinearGradient(
                                colors: [
                                  Color(theme['primaryColor']),
                                  Color(theme['accentColor']),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(theme['viewValue'] ?? ''),
                        ],
                      ),
                    ))
                .toList(),
          ),
        PopupMenuButton<String>(
          icon: Icon(Icons.more_vert),
          onSelected: (value) {
            switch (value) {
              case 'profile':
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const BuyerProfileScreen(),
                  ),
                );
                break;
              case 'orders':
                // TODO: Implement orders navigation
                break;
              case 'registerSeller':
                widget.onRegisterSeller?.call();
                break;
              case 'switchRole':
                widget.onSwitchRole?.call();
                break;
              case 'logout':
                widget.onLogout?.call();
                break;
            }
          },
          itemBuilder: (context) => [
            const PopupMenuItem<String>(value: 'profile', child: Text('Profile')),
            const PopupMenuItem<String>(value: 'orders', child: Text('My Orders')),
            if (widget.currentUserRole == 'buyer' && !widget.isSeller)
              const PopupMenuItem<String>(value: 'registerSeller', child: Text('Register as seller')),
            if (widget.currentUserRole == 'buyer' && widget.isSeller)
              const PopupMenuItem<String>(value: 'switchRole', child: Text('Switch to seller')),
            if (widget.currentUserRole == 'seller')
              const PopupMenuItem<String>(value: 'switchRole', child: Text('Switch to buyer')),
            const PopupMenuItem<String>(value: 'logout', child: Text('Logout')),
          ],
        ),
        if (widget.currentUserRole == 'buyer')
          Stack(
            children: [
              IconButton(
                icon: const Icon(Icons.shopping_cart),
                onPressed: widget.onCartTap,
              ),
              if ((widget.cartCount ?? 0) > 0)
                Positioned(
                  right: 8,
                  top: 8,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: Colors.red,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      widget.cartCount.toString(),
                      style: const TextStyle(color: Colors.white, fontSize: 10),
                    ),
                  ),
                ),
            ],
          ),
      ],
    );
  }
}
