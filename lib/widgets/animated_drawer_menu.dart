import 'package:flutter/material.dart';
import '../screens/settings_page.dart';
import '../screens/about_page.dart';

/// Animated Drawer Menu Widget for AppBar
class AnimatedDrawerMenu extends StatefulWidget {
  @override
  State<AnimatedDrawerMenu> createState() => _AnimatedDrawerMenuState();
}

class _AnimatedDrawerMenuState extends State<AnimatedDrawerMenu>
    with SingleTickerProviderStateMixin {
  bool _menuOpen = false;
  late AnimationController _controller;
  late Animation<double> _opacityAnim;
  late Animation<Offset> _offsetAnim1;
  late Animation<Offset> _offsetAnim2;
  late Animation<Offset> _offsetAnim3;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
    );
    _opacityAnim = CurvedAnimation(parent: _controller, curve: Curves.easeOut);
    _offsetAnim1 = Tween<Offset>(begin: const Offset(0, -0.3), end: Offset.zero)
        .animate(
          CurvedAnimation(
            parent: _controller,
            curve: const Interval(0.0, 0.5, curve: Curves.easeOut),
          ),
        );
    _offsetAnim2 = Tween<Offset>(begin: const Offset(0, -0.3), end: Offset.zero)
        .animate(
          CurvedAnimation(
            parent: _controller,
            curve: const Interval(0.2, 0.7, curve: Curves.easeOut),
          ),
        );
    _offsetAnim3 = Tween<Offset>(begin: const Offset(0, -0.3), end: Offset.zero)
        .animate(
          CurvedAnimation(
            parent: _controller,
            curve: const Interval(0.4, 1.0, curve: Curves.easeOut),
          ),
        );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _toggleMenu() {
    setState(() {
      _menuOpen = !_menuOpen;
      if (_menuOpen) {
        _controller.forward();
      } else {
        _controller.reverse();
      }
    });
  }

  void _onMenuItemTap(String value) {
    _toggleMenu();
    switch (value) {
      case 'settings':
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const SettingsPage()),
        );
        break;
      case 'about':
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const AboutPage()),
        );
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final menuColor = const Color(0xFFE8E8E8); // Match card color
    return Stack(
      clipBehavior: Clip.none,
      children: [
        IconButton(
          icon: const Icon(Icons.menu, color: Colors.black54),
          onPressed: _toggleMenu,
        ),
        Positioned(
          left: 0,
          top: kToolbarHeight,
          child: AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              return _menuOpen || _controller.value > 0.01
                  ? Material(
                      color: Colors.transparent,
                      child: FadeTransition(
                        opacity: _opacityAnim,
                        child: Container(
                          width: 160,
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          decoration: BoxDecoration(
                            color: menuColor,
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black12,
                                blurRadius: 12,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              SlideTransition(
                                position: _offsetAnim1,
                                child: _AnimatedMenuItem(
                                  icon: Icons.settings,
                                  text: 'تنظیمات',
                                  onTap: () => _onMenuItemTap('settings'),
                                ),
                              ),
                              SlideTransition(
                                position: _offsetAnim2,
                                child: _AnimatedMenuItem(
                                  icon: Icons.info_outline,
                                  text: 'درباره ما',
                                  onTap: () => _onMenuItemTap('about'),
                                ),
                              ),
                              SlideTransition(
                                position: _offsetAnim3,
                                child: _AnimatedMenuItem(
                                  icon: Icons.close,
                                  text: 'بستن',
                                  onTap: _toggleMenu,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    )
                  : const SizedBox.shrink();
            },
          ),
        ),
      ],
    );
  }
}

class _AnimatedMenuItem extends StatelessWidget {
  final IconData icon;
  final String text;
  final VoidCallback onTap;
  const _AnimatedMenuItem({
    required this.icon,
    required this.text,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: Row(
          children: [
            Icon(icon, color: Colors.black54, size: 22),
            const SizedBox(width: 12),
            Text(
              text,
              style: const TextStyle(
                color: Colors.black87,
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
