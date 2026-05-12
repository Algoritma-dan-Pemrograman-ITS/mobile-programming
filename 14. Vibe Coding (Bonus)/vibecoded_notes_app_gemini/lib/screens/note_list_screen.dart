import 'package:flutter/material.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lottie/lottie.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../helpers/database_helper.dart';
import '../models/note.dart';
import '../widgets/note_card.dart';
import 'note_detail_screen.dart';

class NoteListScreen extends StatefulWidget {
  final bool isArchive;
  const NoteListScreen({super.key, required this.isArchive});

  @override
  State<NoteListScreen> createState() => NoteListScreenState();
}

class NoteListScreenState extends State<NoteListScreen> {
  late List<Note> allNotes;
  List<Note> displayedNotes = [];
  bool isLoading = false;
  bool isGridView = true;
  String searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadPreferences();
    refreshNotes();
  }

  Future<void> _loadPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      isGridView = prefs.getBool('isGridView') ?? true;
    });
  }

  Future<void> _toggleView() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      isGridView = !isGridView;
      prefs.setBool('isGridView', isGridView);
    });
  }

  Future refreshNotes() async {
    setState(() => isLoading = true);
    allNotes = await DatabaseHelper.instance.readAllNotes(includeArchived: widget.isArchive);
    _filterNotes(searchQuery);
    setState(() => isLoading = false);
  }

  void _filterNotes(String query) {
    setState(() {
      searchQuery = query;
      displayedNotes = allNotes
          .where((note) =>
              note.title.toLowerCase().contains(query.toLowerCase()) ||
              note.content.toLowerCase().contains(query.toLowerCase()))
          .toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent, // Use parent background
      body: Column(
        children: [
          _buildSearchBar(),
          Expanded(
            child: isLoading
                ? const Center(child: CircularProgressIndicator())
                : displayedNotes.isEmpty
                    ? _buildEmptyState()
                    : _buildNotesContainer(),
          ),
        ],
      ),
      floatingActionButton: widget.isArchive
          ? null
          : FloatingActionButton(
              backgroundColor: Colors.deepPurple,
              onPressed: () async {
                await Navigator.of(context).push(
                  MaterialPageRoute(builder: (context) => const NoteDetailScreen()),
                );
                refreshNotes();
              },
              child: const Icon(Icons.add, color: Colors.white),
            ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: Theme.of(context).brightness == Brightness.dark
                    ? Colors.white10
                    : Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withAlpha(20),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: TextField(
                controller: _searchController,
                onChanged: _filterNotes,
                decoration: const InputDecoration(
                  hintText: 'Search...',
                  border: InputBorder.none,
                  icon: Icon(Icons.search, size: 20),
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            icon: Icon(isGridView ? Icons.view_list : Icons.grid_view),
            onPressed: _toggleView,
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Lottie.network(
            'https://assets9.lottiefiles.com/packages/lf20_m6cuL6.json',
            width: 150,
            height: 150,
            errorBuilder: (context, error, stackTrace) => const Icon(Icons.note_alt, size: 64, color: Colors.grey),
          ),
          const SizedBox(height: 16),
          Text(
            widget.isArchive ? "No archived notes." : "Your list is empty.",
            style: GoogleFonts.poppins(color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Widget _buildNotesContainer() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12.0),
      child: isGridView
          ? MasonryGridView.count(
              crossAxisCount: 2,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              itemCount: displayedNotes.length,
              itemBuilder: (context, index) => _buildNoteCard(displayedNotes[index]),
            )
          : ListView.separated(
              itemCount: displayedNotes.length,
              separatorBuilder: (context, index) => const SizedBox(height: 12),
              itemBuilder: (context, index) => _buildNoteCard(displayedNotes[index]),
            ),
    );
  }

  Widget _buildNoteCard(Note note) {
    return NoteCard(
      note: note,
      onTap: () async {
        await Navigator.of(context).push(
          MaterialPageRoute(builder: (context) => NoteDetailScreen(note: note)),
        );
        refreshNotes();
      },
      onDelete: () async {
        await DatabaseHelper.instance.delete(note.id!);
        refreshNotes();
      },
      onTogglePin: () async {
        final updatedNote = note.copyWith(isPinned: !note.isPinned);
        await DatabaseHelper.instance.update(updatedNote);
        refreshNotes();
      },
      onArchive: () async {
        final updatedNote = note.copyWith(isArchived: !note.isArchived, isPinned: false);
        await DatabaseHelper.instance.update(updatedNote);
        refreshNotes();
      },
    );
  }
}
