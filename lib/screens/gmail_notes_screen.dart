import 'dart:convert';
import 'package:flutter/cupertino.dart';
import 'package:googleapis/gmail/v1.dart' as gmail;
import 'package:myapp/screens/gmail_notes_editing%20screen.dart';
import 'package:myapp/services/google_auth_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class GmailNotesScreen extends StatefulWidget {
  const GmailNotesScreen({super.key});

  @override
  State<GmailNotesScreen> createState() => _GmailNotesScreenState();
}

class _GmailNotesScreenState extends State<GmailNotesScreen> {
  final GoogleAuthService _authService = GoogleAuthService();

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
      if (!signedIn) {
        throw Exception('User not signed in');
      }

      final messages = await _authService.fetchAppleNotes();

      setState(() {
        _messages = messages;
        _isLoading = false;
      });

      // Cache the notes
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
          _isLoading
              ? const SliverFillRemaining(
                child: Center(child: CupertinoActivityIndicator()),
              )
              : _error != null
              ? SliverFillRemaining(child: Center(child: Text(_error!)))
              : _messages.isEmpty
              ? const SliverFillRemaining(
                child: Center(child: Text('No notes found.')),
              )
              : SliverList(
                delegate: SliverChildBuilderDelegate((context, index) {
                  final msg = _messages[index];
                  final subject = _getSubject(msg);
                  final snippet = msg.snippet ?? '';

                  return CupertinoListTile(
                    title: Text(subject),
                    subtitle: Text(
                      snippet,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: CupertinoTheme.of(context).textTheme.textStyle
                          .copyWith(color: CupertinoColors.secondaryLabel),
                    ),
                    onTap: () {
                      Navigator.of(context).push(
                        CupertinoPageRoute(
                          builder:
                              (context) => GmailNoteEditorScreen(message: msg),
                        ),
                      );
                    },
                  );
                }, childCount: _messages.length),
              ),
        ],
      ),
    );
  }
}
