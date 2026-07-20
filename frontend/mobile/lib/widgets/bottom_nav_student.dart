import 'package:flutter/material.dart';
import '../theme/app_text_styles.dart';

class BottomNavStudent extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTap;
  final bool hasApprovedRequest;

  const BottomNavStudent({
    super.key,
    required this.currentIndex,
    required this.onTap,
    this.hasApprovedRequest = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        border: Border(top: BorderSide(color: Theme.of(context).dividerColor, width: 1)),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 6,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: BottomNavigationBar(
        currentIndex: currentIndex,
        onTap: onTap,
        backgroundColor: Colors.transparent,
        elevation: 0,
        type: BottomNavigationBarType.fixed,
        selectedItemColor: Theme.of(context).colorScheme.onSurface,
        unselectedItemColor: Colors.grey,
        selectedLabelStyle: AppTextStyles.bodySecondary.copyWith(fontWeight: FontWeight.bold),
        unselectedLabelStyle: AppTextStyles.bodySecondary,
        items: [
          const BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            activeIcon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Stack(
              clipBehavior: Clip.none,
              children: [
                Icon(Icons.qr_code, color: hasApprovedRequest ? null : Colors.grey.withOpacity(0.5)),
                if (!hasApprovedRequest)
                  const Positioned(
                    right: -4,
                    bottom: -4,
                    child: Icon(Icons.lock, size: 12, color: Colors.grey),
                  ),
              ],
            ),
            label: 'QR Pass',
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.history_outlined),
            activeIcon: Icon(Icons.history),
            label: 'History',
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            activeIcon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}
