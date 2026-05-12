import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../helpers/database_helper.dart';
import '../models/note.dart';

class NoteDetailScreen extends StatefulWidget {
  final Note? note;
  const NoteDetailScreen({super.key, this.note});

  @override
  State<NoteDetailScreen> createState() => _NoteDetailScreenState();
}

class _NoteDetailScreenState extends State<NoteDetailScreen> {
  final _formKey = GlobalKey<FormState>();
  late String title;
  late String content;
  late int selectedColor;
  late bool isPinned;
  late bool isArchived;

  final List<int> colors = [
    0xFFFFFFFF, 0xFFF28B82, 0xFFFBBC04, 0xFFFFF475,
    0xFFCCFF90, 0xFFA7FFEB, 0xFFCBF0F8, 0xFFAFCBFF,
    0xFFD7AEFB, 0xFFFDCFE8, 0xFFE6C9A8, 0xFFE8EAED,
  ];

  @override
  void initState() {
    super.initState();
    title = widget.note?.title ?? '';
    content = widget.note?.content ?? '';
    selectedColor = widget.note?.color ?? 0xFFFFFFFF;
    isPinned = widget.note?.isPinned ?? false;
    isArchived = widget.note?.isArchived ?? false;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(selectedColor),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          if (!isArchived)
            IconButton(
              icon: Icon(isPinned ? Icons.push_pin : Icons.push_pin_outlined, color: Colors.black),
              onPressed: () => setState(() => isPinned = !isPinned),
            ),
          IconButton(
            icon: Icon(isArchived ? Icons.unarchive : Icons.archive, color: Colors.black),
            onPressed: () => setState(() {
              isArchived = !isArchived;
              if (isArchived) isPinned = false;
            }),
          ),
          IconButton(
            icon: const Icon(Icons.check, color: Colors.black),
            onPressed: addOrUpdateNote,
          ),
        ],
      ),
      body: Hero(
        tag: 'note_${widget.note?.id}',
        child: Material(
          color: Colors.transparent,
          child: Column(
            children: [
              _buildColorPicker(),
              Expanded(
                child: Form(
                  key: _formKey,
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: ListView(
                      children: [
                        TextFormField(
                          initialValue: title,
                          style: GoogleFonts.poppins(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.black),
                          decoration: const InputDecoration(hintText: 'Title', border: InputBorder.none),
                          onChanged: (value) => setState(() => title = value),
                        ),
                        const SizedBox(height: 8),
                        TextFormField(
                          initialValue: content,
                          style: GoogleFonts.poppins(fontSize: 16, color: Colors.black87),
                          decoration: const InputDecoration(hintText: 'Start typing...', border: InputBorder.none),
                          maxLines: null,
                          onChanged: (value) => setState(() => content = value),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildColorPicker() {
    return SizedBox(
      height: 60,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: colors.length,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemBuilder: (context, index) {
          final color = colors[index];
          return GestureDetector(
            onTap: () => setState(() => selectedColor = color),
            child: Container(
              width: 36, height: 36,
              margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 12),
              decoration: BoxDecoration(
                color: Color(color),
                shape: BoxShape.circle,
                border: Border.all(color: selectedColor == color ? Colors.black : Colors.black12, width: 2.5),
              ),
            ),
          );
        },
      ),
    );
  }

  void addOrUpdateNote() async {
    if (title.trim().isEmpty && content.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Empty note not saved')));
      return;
    }

    final isUpdating = widget.note != null;
    if (isUpdating) {
      await updateNote();
    } else {
      await addNote();
    }
    if (mounted) Navigator.of(context).pop();
  }

  Future updateNote() async {
    final note = widget.note!.copyWith(
      title: title, content: content,
      timestamp: DateFormat('yyyy-MM-dd HH:mm').format(DateTime.now()),
      color: selectedColor, isPinned: isPinned, isArchived: isArchived,
    );
    await DatabaseHelper.instance.update(note);
  }

  Future addNote() async {
    final note = Note(
      title: title, content: content,
      timestamp: DateFormat('yyyy-MM-dd HH:mm').format(DateTime.now()),
      color: selectedColor, isPinned: isPinned, isArchived: isArchived,
    );
    await DatabaseHelper.instance.create(note);
  }
}
