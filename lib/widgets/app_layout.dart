import 'package:flutter/material.dart';
import '../theme/app_constants.dart';
import 'bottom_nav.dart';
import 'desktop_sidebar.dart';

/// Responsive app shell: bottom nav on mobile, sidebar on desktop.
class AppLayout extends StatelessWidget {
  const AppLayout({
    super.key,
    required this.child,
    required this.currentPath,
    required this.onNavigate,
    this.hideNav = false,
  });

  final Widget child;
  final String currentPath;
  final void Function(String path) onNavigate;
  final bool hideNav;

  @override
  Widget build(BuildContext context) {
    if (hideNav) {
      return child;
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth >= AppConstants.desktopBreakpoint) {
          // Desktop layout with sidebar
          return Row(
            children: [
              DesktopSidebar(
                currentPath: currentPath,
                onNavigate: onNavigate,
              ),
              Expanded(child: child),
            ],
          );
        }

        // Mobile layout with bottom nav
        return Column(
          children: [
            Expanded(child: child),
            BottomNav(
              currentPath: currentPath,
              onNavigate: onNavigate,
            ),
          ],
        );
      },
    );
  }
}
