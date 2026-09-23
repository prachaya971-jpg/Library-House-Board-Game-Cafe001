import 'package:flutter/material.dart';

class CustomerBottomBar extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTapIndex;

  const CustomerBottomBar({
    super.key,
    required this.currentIndex,
    required this.onTapIndex,
  });

  @override
  Widget build(BuildContext context) {
    const primaryColor = Color(0xFFE5A93C);

    return Container(
      height: 65,
      decoration: const BoxDecoration(
        color: primaryColor,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
        
          _buildNavItem(
            icon: Icons.home_rounded,
            isSelected: currentIndex == 0,
            onTap: () => onTapIndex(0),
          ),
          _buildNavItem(
            icon: Icons.casino_outlined,
            isSelected: currentIndex == 1,
            onTap: () => onTapIndex(1),
          ),
          _buildNavItem(
            icon: Icons.lightbulb_outline_rounded,
            isSelected: currentIndex == 2,
            onTap: () => onTapIndex(2),
          ),
        ],
      ),
    );
  }

  Widget _buildNavItem({
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: SizedBox(
        width: 80,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 32,
              color: Colors.black87,
            ),
            const SizedBox(height: 4),
            Container(
              width: 5,
              height: 5,
              decoration: BoxDecoration(
                color: isSelected ? Colors.black87 : Colors.transparent,
                shape: BoxShape.circle,
              ),
            ),
          ],
        ),
      ),
    );
  }
}