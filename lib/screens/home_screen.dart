import 'package:flutter/material.dart';

import '../screens/profile_screen.dart';
import '../screens/property_screen.dart';
import '../screens/rent_screen.dart';
import '../screens/tenant_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        type: BottomNavigationBarType.fixed,
        selectedItemColor: Colors.black,
        unselectedItemColor: Colors.grey,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.apartment), label: '房屋管理'),
          BottomNavigationBarItem(icon: Icon(Icons.people), label: '租客管理'),
          BottomNavigationBarItem(icon: Icon(Icons.payments), label: '租金管理'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: '个人设置'),
        ],
      ),
    );
  }
}
