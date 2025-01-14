import 'package:flutter/material.dart';

class BottomNavBar extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTabSelected;

  const BottomNavBar(
      {Key? key, required this.currentIndex, required this.onTabSelected})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return BottomNavigationBar(
      currentIndex: currentIndex,
      onTap: onTabSelected,
      backgroundColor: Colors.black,
      selectedItemColor:
          Color.fromARGB(255, 0, 150, 255), // Lighter blue for selected
      unselectedItemColor: Colors.white,
      selectedLabelStyle: TextStyle(fontWeight: FontWeight.bold),
      unselectedLabelStyle: TextStyle(fontWeight: FontWeight.normal),
      type: BottomNavigationBarType.fixed,
      items: [
        _buildCustomItem(Icons.home, 'Home', 0),
        _buildCustomItem(Icons.local_police, 'Emergency', 1),
        _buildCustomItem(Icons.history, 'History', 2),
        _buildCustomItem(Icons.account_circle, 'Profile', 3),
      ],
    );
  }

  BottomNavigationBarItem _buildCustomItem(
      IconData icon, String label, int index) {
    return BottomNavigationBarItem(
      icon: InkWell(
        onTap: () => onTabSelected(index),
        child: AnimatedContainer(
          duration: Duration(milliseconds: 300),
          curve: Curves.easeInOut,
          child: Icon(
            icon,
            size: currentIndex == index ? 35 : 28, // Enlarged icon on tap
            color: currentIndex == index
                ? Color.fromARGB(255, 0, 150, 255) // Lighter blue color
                : Colors.white,
          ),
        ),
      ),
      label: label,
    );
  }
}
