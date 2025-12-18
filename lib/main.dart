import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import 'package:flutter5/utils/date_formatter.dart';
import 'package:flutter/foundation.dart';
import 'dart:async';
import 'dart:io';

bool get isTestEnvironment {
  return Platform.environment.containsKey('FLUTTER_TEST');
}

void main() {
  FlutterError.onError = (FlutterErrorDetails details) {
    if (kDebugMode) {
      FlutterError.presentError(details);
    } else {
      debugPrint('Flutter Error: ${details.exception}');
      debugPrint('Stack trace: ${details.stack}');
    }
  };

  runZonedGuarded(() {
    runApp(const NotesApp());
  }, (Object error, StackTrace stackTrace) {
    debugPrint('Async Error: $error');
    debugPrint('Async Stack: $stackTrace');
  });
}

class NotesApp extends StatelessWidget {
  const NotesApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Заметки',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: const NotesListScreen(),
      debugShowCheckedModeBanner: false,
      builder: isTestEnvironment ? null : (BuildContext context, Widget? widget) {
        ErrorWidget.builder = (FlutterErrorDetails errorDetails) {
          return Material(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 64, color: Colors.red),
                  const SizedBox(height: 16),
                  const Text('Что-то пошло не так'),
                  const SizedBox(height: 8),
                  Text(
                    'Ошибка: ${errorDetails.exception}',
                    style: const TextStyle(fontSize: 12),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          );
        };
        return widget!;
      },
    );
  }
}

class Note {
  final String id;
  final String title;
  final String content;
  final DateTime createdAt;
  final DateTime updatedAt;

  Note({
    required this.id,
    required this.title,
    required this.content,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Note.create({required String title, required String content}) {
    final now = DateTime.now();
    return Note(
      id: const Uuid().v4(),
      title: title,
      content: content,
      createdAt: now,
      updatedAt: now,
    );
  }

  Note copyWith({
    String? title,
    String? content,
  }) {
    return Note(
      id: id,
      title: title ?? this.title,
      content: content ?? this.content,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'content': content,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory Note.fromMap(Map<String, dynamic> map) {
    return Note(
      id: map['id'] ?? '',
      title: map['title'] ?? '',
      content: map['content'] ?? '',
      createdAt: DateTime.parse(map['createdAt']),
      updatedAt: DateTime.parse(map['updatedAt']),
    );
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is Note &&
            runtimeType == other.runtimeType &&
            id == other.id &&
            title == other.title &&
            content == other.content;
  }

  @override
  int get hashCode {
    return Object.hash(id, title, content);
  }
}

class NotesListScreen extends StatefulWidget {
  const NotesListScreen({super.key});

  @override
  NotesListScreenState createState() => NotesListScreenState();
}

class NotesListScreenState extends State<NotesListScreen> {
  List<Note> notes = [
    Note.create(
      title: 'Первая заметка',
      content: 'Это пример первой заметки в приложении',
    ),
    Note.create(
      title: 'Список покупок',
      content: 'Молоко, хлеб, яйца, фрукты',
    ),
    Note.create(
      title: 'Идеи для проекта',
      content: 'Разработать мобильное приложение на Flutter',
    ),
  ];

  List<Note> filteredNotes = [];
  TextEditingController searchController = TextEditingController();
  int _currentPage = 0;
  final int _notesPerPage = 10;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    filteredNotes = List.from(notes);
    searchController.addListener(_onSearchChanged);
    
    // Пагинация при скролле
    _scrollController.addListener(() {
      if (_scrollController.position.pixels ==
          _scrollController.position.maxScrollExtent) {
        _loadMoreNotes();
      }
    });
  }

  @override
  void dispose() {
    searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    _filterNotes(searchController.text);
  }

  void _filterNotes(String query) {
    setState(() {
      _currentPage = 0;
      if (query.isEmpty) {
        filteredNotes = List.from(notes);
      } else {
        filteredNotes = notes
            .where((note) =>
                note.title.toLowerCase().contains(query.toLowerCase()) ||
                note.content.toLowerCase().contains(query.toLowerCase()))
            .toList();
      }
    });
  }

  List<Note> get _paginatedNotes {
    final start = _currentPage * _notesPerPage;
    final end = (start + _notesPerPage < filteredNotes.length)
        ? start + _notesPerPage
        : filteredNotes.length;
    return filteredNotes.sublist(0, end);
  }

  void _loadMoreNotes() {
    if ((_currentPage + 1) * _notesPerPage < filteredNotes.length) {
      setState(() {
        _currentPage++;
      });
    }
  }

  void _addNote(Note newNote) {
    setState(() {
      notes.insert(0, newNote);
      _filterNotes(searchController.text);
    });
  }

  void _updateNote(Note updatedNote) {
    setState(() {
      final index = notes.indexWhere((note) => note.id == updatedNote.id);
      if (index != -1) {
        notes[index] = updatedNote;
        _filterNotes(searchController.text);
      }
    });
  }

  void _deleteNote(String noteId) {
    setState(() {
      notes.removeWhere((note) => note.id == noteId);
      _filterNotes(searchController.text);
    });
  }

  void _showDeleteConfirmation(Note note) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Удалить заметку?'),
          content: Text('Заметка "${note.title}" будет удалена безвозвратно.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Отмена'),
            ),
            TextButton(
              onPressed: () {
                _deleteNote(note.id);
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Заметка "${note.title}" удалена'),
                    backgroundColor: Colors.red,
                    duration: const Duration(seconds: 2),
                  ),
                );
              },
              child: const Text(
                'Удалить',
                style: TextStyle(color: Colors.red),
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final displayNotes = _paginatedNotes;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Мои заметки'),
        backgroundColor: Colors.blue,
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {
              showSearch(
                context: context,
                delegate: NotesSearchDelegate(notes, _filterNotes),
              );
            },
          ),
        ],
      ),
      body: filteredNotes.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.note_add,
                    size: 64,
                    color: Colors.grey[400],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    searchController.text.isNotEmpty
                        ? 'Ничего не найдено'
                        : 'Нет заметок',
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.grey[600],
                    ),
                  ),
                  if (searchController.text.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 16),
                      child: TextButton(
                        onPressed: () {
                          searchController.clear();
                          _filterNotes('');
                        },
                        child: const Text('Очистить поиск'),
                      ),
                    ),
                ],
              ),
            )
          : Column(
              children: [
                Expanded(
                  child: ListView.builder(
                    controller: _scrollController,
                    itemCount: displayNotes.length + 1, 
                    itemExtent: 100, 
                    cacheExtent: 500, 
                                      
                    itemBuilder: (context, index) {
                      if (index == displayNotes.length) {
                        return _buildLoadMoreIndicator();
                      }
                      final note = displayNotes[index];
                      return Dismissible(
                        key: ValueKey('dismissible_${note.id}'),
                        background: Container(
                          color: Colors.red,
                          alignment: Alignment.centerRight,
                          padding: const EdgeInsets.only(right: 20),
                          child: const Icon(
                            Icons.delete,
                            color: Colors.white,
                            size: 30,
                          ),
                        ),
                        direction: DismissDirection.endToStart,
                        confirmDismiss: (direction) async {
                          _showDeleteConfirmation(note);
                          return false;
                        },
                        child: Card(
                          key: ValueKey('card_${note.id}'),
                          margin:
                              const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          elevation: 2,
                          child: ListTile(
                            key: ValueKey('tile_${note.id}'),
                            leading: Container(
                              width: 50,
                              height: 50,
                              decoration: BoxDecoration(
                                color: Colors.blue.shade50,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Icon(
                                Icons.note,
                                color: Colors.blue,
                              ),
                            ),
                            title: Text(
                              note.title,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  note.content,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(fontSize: 14),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Изменено: ${DateFormatter.formatCached(note.updatedAt)}',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey,
                                  ),
                                ),
                              ],
                            ),
                            trailing: IconButton(
                              icon: const Icon(
                                Icons.delete,
                                color: Colors.red,
                              ),
                              onPressed: () => _showDeleteConfirmation(note),
                            ),
                            onTap: () async {
                              final updatedNote = await Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => NoteEditScreen(
                                    existingNote: note,
                                  ),
                                ),
                              );
                              if (updatedNote != null) {
                                _updateNote(updatedNote);
                              }
                            },
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final newNote = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const NoteEditScreen(),
            ),
          );
          if (newNote != null) {
            _addNote(newNote);
          }
        },
        child: const Icon(Icons.add),
        backgroundColor: Colors.blue,
      ),
    );
  }

  Widget _buildLoadMoreIndicator() {
    if (_paginatedNotes.length < filteredNotes.length) {
      return Padding(
        padding: const EdgeInsets.all(16.0),
        child: Center(
          child: ElevatedButton(
            onPressed: _loadMoreNotes,
            child: const Text('Загрузить еще заметки'),
          ),
        ),
      );
    } else {
      return const SizedBox.shrink();
    }
  }
}

class NotesSearchDelegate extends SearchDelegate {
  final List<Note> notes;
  final Function(String) onFilterChanged;

  NotesSearchDelegate(this.notes, this.onFilterChanged);

  @override
  List<Widget> buildActions(BuildContext context) {
    return [
      IconButton(
        icon: const Icon(Icons.clear),
        onPressed: () {
          query = '';
        },
      ),
    ];
  }

  @override
  Widget buildLeading(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.arrow_back),
      onPressed: () {
        close(context, null);
      },
    );
  }

  @override
  Widget buildResults(BuildContext context) {
    return _buildSearchResults();
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    return _buildSearchResults();
  }

  Widget _buildSearchResults() {
    final filteredNotes = notes
        .where((note) =>
            note.title.toLowerCase().contains(query.toLowerCase()) ||
            note.content.toLowerCase().contains(query.toLowerCase()))
        .toList();

    return ListView.builder(
      itemCount: filteredNotes.length,
      itemBuilder: (context, index) {
        final note = filteredNotes[index];
        return ListTile(
          leading: const Icon(Icons.note),
          title: Text(note.title),
          subtitle: Text(
            note.content,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          onTap: () {
            close(context, note);
          },
        );
      },
    );
  }
}

class NoteEditScreen extends StatefulWidget {
  final Note? existingNote;

  const NoteEditScreen({this.existingNote, super.key});

  @override
  NoteEditScreenState createState() => NoteEditScreenState();
}

class NoteEditScreenState extends State<NoteEditScreen> {
  late TextEditingController titleController;
  late TextEditingController contentController;

  @override
  void initState() {
    super.initState();
    titleController = TextEditingController(
      text: widget.existingNote?.title ?? '',
    );
    contentController = TextEditingController(
      text: widget.existingNote?.content ?? '',
    );
  }

  @override
  void dispose() {
    titleController.dispose();
    contentController.dispose();
    super.dispose();
  }

  void _saveNote() {
    final title = titleController.text.trim();
    final content = contentController.text.trim();

    if (title.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Введите заголовок заметки'),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    Note savedNote;
    if (widget.existingNote != null) {
      savedNote = widget.existingNote!.copyWith(
        title: title,
        content: content,
      );
    } else {
      savedNote = Note.create(title: title, content: content);
    }

    Navigator.pop(context, savedNote);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.existingNote != null ? 'Редактировать заметку' : 'Новая заметка',
        ),
        backgroundColor: Colors.blue,
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: _saveNote,
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: titleController,
              decoration: const InputDecoration(
                labelText: 'Заголовок',
                border: OutlineInputBorder(),
                hintText: 'Введите заголовок заметки',
              ),
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              maxLines: 1,
              autofocus: widget.existingNote == null,
            ),
            const SizedBox(height: 16),
            Expanded(
              child: TextField(
                controller: contentController,
                decoration: const InputDecoration(
                  labelText: 'Содержание',
                  border: OutlineInputBorder(),
                  hintText: 'Введите текст заметки...',
                  alignLabelWithHint: true,
                ),
                style: const TextStyle(fontSize: 16),
                maxLines: null,
                expands: true,
                textAlignVertical: TextAlignVertical.top,
                keyboardType: TextInputType.multiline,
              ),
            ),
            const SizedBox(height: 16),
            if (widget.existingNote != null)
              Text(
                'Создано: ${DateFormatter.formatCached(widget.existingNote!.createdAt)}',
                style: const TextStyle(
                  fontSize: 12,
                  color: Colors.grey,
                ),
              ),
          ],
        ),
      ),
    );
  }
}