import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class SettingsScreen extends StatelessWidget {
  final Function(ThemeMode) onThemeChanged;
  const SettingsScreen({super.key, required this.onThemeChanged});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildSectionTitle('Appearance'),
        ListTile(
          title: const Text('Light Mode'),
          leading: const Icon(Icons.light_mode),
          onTap: () => onThemeChanged(ThemeMode.light),
        ),
        ListTile(
          title: const Text('Dark Mode'),
          leading: const Icon(Icons.dark_mode),
          onTap: () => onThemeChanged(ThemeMode.dark),
        ),
        ListTile(
          title: const Text('System Default'),
          leading: const Icon(Icons.settings_display),
          onTap: () => onThemeChanged(ThemeMode.system),
        ),
        const Divider(),
        _buildSectionTitle('About'),
        const ListTile(
          title: Text('Version'),
          subtitle: Text('2.0.0 (Pro)'),
          leading: Icon(Icons.info_outline),
        ),
        const ListTile(
          title: Text('Developer'),
          subtitle: Text('Ultimate Flutter Dev'),
          leading: Icon(Icons.code),
        ),
      ],
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16),
      child: Text(
        title,
        style: GoogleFonts.poppins(
          fontWeight: FontWeight.bold,
          color: Colors.deepPurple,
        ),
      ),
    );
  }
}
