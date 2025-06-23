import 'dart:convert';
import 'package:flutter/cupertino.dart';
import 'package:googleapis/gmail/v1.dart' as gmail;
import 'package:myapp/screens/gmail_notes_editing%20screen.dart';
import 'package:myapp/services/google_auth_service.dart';
import 'package:myapp/widgets/notes_tile.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';

class GmailNotesScreen extends StatefulWidget {
  const GmailNotesScreen({super.key});

  @override
  State<GmailNotesScreen> createState() => _GmailNotesScreenState();
}

class _GmailNotesScreenState extends State<GmailNotesScreen> {
  final GoogleService _authService = GoogleService();

  List<gmail.Message> _messages = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadCachedNotes();
    _fetchLatestNotes();
  }

  Future<void> _loadCachedNotes() async {
    final prefs = await SharedPreferences.getInstance();
    final cachedJson = prefs.getString('cached_gmail_notes');

    if (cachedJson != null) {
      final cachedList = jsonDecode(cachedJson) as List<dynamic>;
      final messages =
          cachedList.map((json) => gmail.Message.fromJson(json)).toList();

      setState(() {
        _messages = messages;
        _isLoading = false;
      });
    }
  }

  Future<void> _fetchLatestNotes() async {
    try {
      final signedIn = _authService.isSignedIn || await _authService.signIn();
      if (!signedIn) throw Exception('User not signed in');

      final messages = await _authService.fetchAppleNotes();

      setState(() {
        _messages = messages;
        _isLoading = false;
      });

      final prefs = await SharedPreferences.getInstance();
      final encoded = jsonEncode(messages.map((m) => m.toJson()).toList());
      await prefs.setString('cached_gmail_notes', encoded);
    } catch (e) {
      if (_messages.isEmpty) {
        setState(() {
          _error = 'Failed to load notes: $e';
          _isLoading = false;
        });
      }
    }
  }

  String _getSubject(gmail.Message message) {
    final headers = message.payload?.headers ?? [];
    final subjectHeader = headers.firstWhere(
      (h) => h.name?.toLowerCase() == 'subject',
      orElse: () => gmail.MessagePartHeader(name: '', value: ''),
    );
    return subjectHeader.value ?? 'Untitled Note';
  }

  DateTime? _getInternalDate(gmail.Message msg) {
    final millis = int.tryParse(msg.internalDate ?? '');
    if (millis == null) return null;
    return DateTime.fromMillisecondsSinceEpoch(millis);
  }

  String _formatTime(DateTime date) {
    return DateFormat('h:mm a').format(date);
  }

  Map<String, List<gmail.Message>> _groupByDate(List<gmail.Message> messages) {
    final now = DateTime.now();
    final grouped = <String, List<gmail.Message>>{};

    for (final msg in messages) {
      final date = _getInternalDate(msg);
      if (date == null) continue;

      String groupLabel;

      final diff = now.difference(date);
      final isSameDay =
          now.year == date.year &&
          now.month == date.month &&
          now.day == date.day;

      if (isSameDay) {
        groupLabel = 'Today';
      } else if (diff.inDays == 1) {
        groupLabel = 'Yesterday';
      } else if (diff.inDays <= 7) {
        groupLabel = DateFormat('EEEE').format(date); // e.g. "Monday"
      } else if (diff.inDays <= 30) {
        groupLabel = 'Last 30 Days';
      } else {
        groupLabel = DateFormat('MMMM yyyy').format(date); // e.g. "May 2023"
      }

      grouped.putIfAbsent(groupLabel, () => []).add(msg);
    }

    return grouped;
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      child: CustomScrollView(
        slivers: [
          CupertinoSliverNavigationBar.search(
            largeTitle: const Text('Gmail Notes'),
            previousPageTitle: 'Folders',
            searchField: const CupertinoSearchTextField(
              placeholder: 'Search notes',
            ),
          ),
          if (_isLoading)
            const SliverFillRemaining(
              child: Center(child: CupertinoActivityIndicator()),
            )
          else if (_error != null)
            SliverFillRemaining(child: Center(child: Text(_error!)))
          else if (_messages.isEmpty)
            const SliverFillRemaining(
              child: Center(child: Text('No notes found.')),
            )
          else
            ..._buildGroupedSections(_groupByDate(_messages)),
        ],
      ),
    );
  }

  List<Widget> _buildGroupedSections(Map<String, List<gmail.Message>> grouped) {
    final sections = <Widget>[];

    // Sort groups by most recent first
    final sortedKeys =
        grouped.keys.toList()..sort((a, b) {
          final aDate = _getSortDate(grouped[a]!.first);
          final bDate = _getSortDate(grouped[b]!.first);
          return bDate.compareTo(aDate);
        });

    for (final label in sortedKeys) {
      final messages = grouped[label]!;
      sections.add(
        SliverToBoxAdapter(
          child: CupertinoListSection.insetGrouped(
            header: Text(label),
            children:
                messages.map((msg) {
                  final subject = _getSubject(msg);
                  final snippet = msg.snippet ?? '';
                  final date = _getInternalDate(msg);
                  final time = date != null ? _formatTime(date) : '';

                  return NoteTile(
                    title: subject,
                    snippet: snippet,
                    folder: 'Notes',
                    time: time,
                    onTap: () {
                      Navigator.of(context).push(
                        CupertinoPageRoute(
                          builder:
                              (context) => GmailNoteEditorScreen(
                                message: msg,
                                folder: 'Notes',
                              ),
                        ),
                      );
                    },
                  );
                }).toList(),
          ),
        ),
      );
    }

    return sections;
  }

  DateTime _getSortDate(gmail.Message msg) =>
      _getInternalDate(msg) ?? DateTime(2000);
}
