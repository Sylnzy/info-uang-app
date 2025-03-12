import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:first_project/main_screen.dart' as screens;

import 'login_screen.dart';
import 'main.dart';

class AuthWrapper extends StatelessWidget {
  final bool isDarkMode;
  final Function(bool) onToggleTheme;

  const AuthWrapper({
    Key? key,
    required this.isDarkMode,
    required this.onToggleTheme,
  }) : super(key: key);

  Future<bool> _isLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    final username = prefs.getString('username');
    return username != null && username.isNotEmpty;
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
      future: _isLoggedIn(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        if (snapshot.hasData && snapshot.data == true) {
          return MainScreen(
            isDarkMode: isDarkMode,
            onToggleTheme: onToggleTheme,
          );
        } else {
          return const LoginScreen();
        }
      },
    );
  }
}