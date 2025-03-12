import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'login_screen.dart';

class SettingsScreen extends StatefulWidget {
  final bool isDarkMode;
  final Function(bool) onToggleDarkMode;

  const SettingsScreen({
    Key? key,
    required this.isDarkMode,
    required this.onToggleDarkMode,
  }) : super(key: key);

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _notifEnabled = true;
  bool _showDailyTotal = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: ListView(
        children: [
          SwitchListTile(
            title: const Text('Dark Mode'),
            value: widget.isDarkMode,
            onChanged: (value) {
              widget.onToggleDarkMode(value);
            },
            secondary: const Icon(Icons.brightness_6),
          ),
          SwitchListTile(
            title: const Text('Enable Notifications'),
            value: _notifEnabled,
            onChanged: (value) {
              setState(() {
                _notifEnabled = value;
              });
            },
            secondary: const Icon(Icons.notifications),
          ),
          SwitchListTile(
            title: const Text("Show Daily Total Expenses"),
            value: _showDailyTotal,
            onChanged: (value) {
              setState(() {
                _showDailyTotal = value;
              });
            },
            secondary: const Icon(Icons.calendar_today),
          ),
          const Divider(),
          ListTile(
            title: const Text('App Version'),
            subtitle: const Text('1.0.0'),
            leading: const Icon(Icons.info_outline),
          ),
          ListTile(
  leading: const Icon(Icons.logout),
  title: const Text('Logout'),
  onTap: () async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('username');
    if (!mounted) return;
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => const LoginScreen()),
      (route) => false,
    );
  },
),

        ],
      ),
    );
  }
}
