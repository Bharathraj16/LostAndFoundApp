import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({Key? key}) : super(key: key);

  @override
  _SettingsPageState createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  bool _isDarkMode = true;

  @override
  void initState() {
    super.initState();
    _loadThemePreference();
  }

  // Load the saved theme preference
  void _loadThemePreference() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      _isDarkMode = prefs.getBool('isDarkMode') ?? false;
    });
  }

  // Save the theme preference
  void _saveThemePreference(bool value) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.setBool('isDarkMode', value);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Settings"),
        backgroundColor: Colors.blueAccent,
        elevation: 10,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Theme Selection
          Card(
            elevation: 5,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            child: ListTile(
              title: const Text("Dark Mode"),
              trailing: Switch(
                value: _isDarkMode,
                onChanged: (value) {
                  setState(() {
                    _isDarkMode = value;
                  });
                  _saveThemePreference(value);
                  // Apply the theme change (you can use a state management solution like Provider for this)
                },
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Help and Support Section
          Card(
            elevation: 5,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            child: ExpansionTile(
              title: const Text("Help & Support"),
              children: [
                ListTile(
                  title: const Text("FAQ"),
                  onTap: () {
                    // Navigate to FAQ page
                  },
                ),
                ListTile(
                  title: const Text("Contact Support"),
                  onTap: () {
                    // Navigate to contact support page
                  },
                ),
                ListTile(
                  title: const Text("Report an Issue"),
                  onTap: () {
                    // Navigate to issue reporting page
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // About the App Section
          Card(
            elevation: 5,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            child: ExpansionTile(
              title: const Text("About the App"),
              children: [
                ListTile(
                  title: const Text("Version"),
                  subtitle: const Text("1.0.0"),
                ),
                ListTile(
                  title: const Text("Developer"),
                  subtitle: const Text("BHARATHRAJ R"),
                ),
                ListTile(
                  title: const Text("Privacy Policy"),
                  onTap: () {
                    // Navigate to privacy policy page
                  },
                ),
                ListTile(
                  title: const Text("Terms of Service"),
                  onTap: () {
                    // Navigate to terms of service page
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}