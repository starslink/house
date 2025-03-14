import 'package:flutter/material.dart';

import '../screens/profile_screen.dart';
import '../screens/property_screen.dart';
import '../screens/rent_screen.dart';
import '../screens/tenant_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;

  final List<Widget> _screens = [
    const PropertyScreen(),
    const TenantScreen(),
    const RentScreen(),
    const ProfileScreen(),
  ];

  final List<String> _titles = ['房屋管理', '租客管理', '租金管理', '个人设置'];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_selectedIndex],
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: BottomNavigationBar(
          currentIndex: _selectedIndex,
          onTap: (index) {
            setState(() {
              _selectedIndex = index;
            });
          },
          type: BottomNavigationBarType.fixed,
          items: [
            BottomNavigationBarItem(
              icon: const Icon(Icons.apartment_outlined),
              activeIcon: const Icon(Icons.apartment),
              label: _titles[0],
            ),
            BottomNavigationBarItem(
              icon: const Icon(Icons.people_outline),
              activeIcon: const Icon(Icons.people),
              label: _titles[1],
            ),
            BottomNavigationBarItem(
              icon: const Icon(Icons.payments_outlined),
              activeIcon: const Icon(Icons.payments),
              label: _titles[2],
            ),
            BottomNavigationBarItem(
              icon: const Icon(Icons.person_outline),
              activeIcon: const Icon(Icons.person),
              label: _titles[3],
            ),
          ],
        ),
      ),
    );
  }
}
