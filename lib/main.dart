import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';
import '../providers/property_provider.dart';
import '../providers/rent_provider.dart';
import '../providers/tenant_provider.dart';
import '../screens/home_screen.dart';
import '../screens/login_screen.dart';
import '../services/auth_service.dart';

import 'package:intl/date_symbol_data_local.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await AuthService.initialize();
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => PropertyProvider()),
        ChangeNotifierProvider(create: (_) => TenantProvider()),
        ChangeNotifierProvider(create: (_) => RentProvider()),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '房屋管理系统',
      theme: ThemeData(
        primaryColor: Colors.black,
        scaffoldBackgroundColor: Colors.white,
        colorScheme: const ColorScheme.light(
          primary: Colors.black,
          secondary: Colors.grey,
          surface: Colors.white,
          background: Colors.white,
          error: Colors.red,
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.white,
          foregroundColor: Colors.black,
          elevation: 0,
          centerTitle: true,
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.black,
            foregroundColor: Colors.white,
            minimumSize: const Size(double.infinity, 50),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            foregroundColor: Colors.black,
            side: const BorderSide(color: Colors.black),
            minimumSize: const Size(double.infinity, 50),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
        textButtonTheme: TextButtonThemeData(
          style: TextButton.styleFrom(foregroundColor: Colors.black),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.grey[100],
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: Colors.black),
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 16,
          ),
        ),
        cardTheme: CardTheme(
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(color: Colors.grey[200]!),
          ),
          color: Colors.white,
        ),
        dividerTheme: DividerThemeData(color: Colors.grey[200], thickness: 1),
      ),
      // 设置默认语言为中文
      home: Consumer<AuthProvider>(
        builder: (context, authProvider, _) {
          return authProvider.isAuthenticated
              ? const HomeScreen()
              : const LoginScreen();
        },
      ),
    );
  }
}

class AppLogo extends StatelessWidget {
  final double size;

  const AppLogo({super.key, this.size = 120});

  @override
  Widget build(BuildContext context) {
    final double buildingWidth = size * 0.58;
    final double buildingHeight = size * 0.67;
    final double roofWidth = size * 0.75;
    final double roofHeight = size * 0.21;
    final double windowSize = size * 0.125;

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(size * 0.17),
        border: Border.all(color: Colors.black, width: 2),
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Building outline
          Container(
            width: buildingWidth,
            height: buildingHeight,
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(color: Colors.black, width: 2),
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          // Roof
          Positioned(
            top: size * 0.125,
            child: Container(
              width: roofWidth,
              height: roofHeight,
              decoration: const BoxDecoration(
                color: Colors.black,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(4),
                  topRight: Radius.circular(4),
                ),
              ),
            ),
          ),
          // Windows
          Positioned(
            top: size * 0.42,
            left: size * 0.29,
            child: Container(
              width: windowSize,
              height: windowSize,
              color: Colors.black,
            ),
          ),
          Positioned(
            top: size * 0.42,
            right: size * 0.29,
            child: Container(
              width: windowSize,
              height: windowSize,
              color: Colors.black,
            ),
          ),
          Positioned(
            top: size * 0.625,
            left: size * 0.29,
            child: Container(
              width: windowSize,
              height: windowSize,
              color: Colors.black,
            ),
          ),
          Positioned(
            top: size * 0.625,
            right: size * 0.29,
            child: Container(
              width: windowSize,
              height: windowSize,
              color: Colors.black,
            ),
          ),
        ],
      ),
    );
  }
}
