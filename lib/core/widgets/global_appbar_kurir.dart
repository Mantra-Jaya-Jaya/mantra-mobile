import 'package:flutter/material.dart';

class GlobalAppBarKurir extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final bool showBackButton;
  final PreferredSizeWidget? bottom;
  final VoidCallback? onBackPressed;

  const GlobalAppBarKurir({
    super.key,
    required this.title,
    this.showBackButton = false,
    this.bottom,
    this.onBackPressed,
  });

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: const Color(0xFFAD510D), 
      elevation: 0,
      automaticallyImplyLeading: false, 
      titleSpacing: showBackButton ? 0 : 28,

      leading: showBackButton
          ? IconButton(
              padding: EdgeInsets.only(left: 18),
              icon: const Icon(Icons.arrow_back_ios, color: Colors.white, size: 24),
              onPressed: onBackPressed ?? () => Navigator.pop(context),
            )
          : null,

      title: Text(
        title,
        style: const TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
      centerTitle: false,
      bottom: bottom, 
    );
  }

  @override
  Size get preferredSize {
    return Size.fromHeight(56.0 + (bottom?.preferredSize.height ?? 0.0));
  }
}
