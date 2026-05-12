import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'note_list_screen.dart';
import 'settings_screen.dart';

class MainNavigationScreen extends StatefulWidget {
  final Function(ThemeMode) onThemeChanged;
  const MainNavigationScreen({super.key, required this.onThemeChanged});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _selectedIndex = 0;
  final GlobalKey<NoteListScreenState> _notesKey = GlobalKey();
  final GlobalKey<NoteListScreenState> _archiveKey = GlobalKey();

  final List<String> _titles = ['Notes', 'Archive', 'Settings'];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          _titles[_selectedIndex],
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      drawer: Drawer(
        child: Column(
          children: [
            DrawerHeader(
              decoration: const BoxDecoration(color: Colors.deepPurple),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.note_alt, size: 48, color: Colors.white),
                    const SizedBox(height: 8),
                    Text(
                      'Notes App Pro',
                      style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            _buildDrawerItem(0, Icons.notes, 'Notes'),
            _buildDrawerItem(1, Icons.archive_outlined, 'Archive'),
            const Divider(),
            _buildDrawerItem(2, Icons.settings_outlined, 'Settings'),
          ],
        ),
      ),
      body: IndexedStack(
        index: _selectedIndex,
        children: [
          NoteListScreen(key: _notesKey, isArchive: false),
          NoteListScreen(key: _archiveKey, isArchive: true),
          SettingsScreen(onThemeChanged: widget.onThemeChanged),
        ],
      ),
    );
  }

  Widget _buildDrawerItem(int index, IconData icon, String title) {
    return ListTile(
      selected: _selectedIndex == index,
      leading: Icon(icon),
      title: Text(title, style: GoogleFonts.poppins()),
      onTap: () {
        setState(() => _selectedIndex = index);
        
        // Refresh data when switching to Notes or Archive
        if (index == 0) {
          _notesKey.currentState?.refreshNotes();
        } else if (index == 1) {
          _archiveKey.currentState?.refreshNotes();
        }

        Navigator.pop(context);
      },
    );
  }
}
