import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:googleapis/gmail/v1.dart' as gmail;
import 'package:myapp/services/google_auth_service.dart';

class GmailNoteEditorScreen extends StatefulWidget {
  final String folder;
  final gmail.Message message;

  const GmailNoteEditorScreen({
    super.key,
    required this.message,
    required this.folder,
  });

  @override
  State<GmailNoteEditorScreen> createState() => _GmailNoteEditorScreenState();
}

class _GmailNoteEditorScreenState extends State<GmailNoteEditorScreen> {
  final GoogleService _authService = GoogleService();

  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _bodyController = TextEditingController();
  final FocusNode _titleFocusNode = FocusNode();
  final FocusNode _bodyFocusNode = FocusNode();

  bool _isEdited = false;
  DateTime _lastEdited = DateTime.now();

  // For undo/redo functionality
  List<String> _titleHistory = [];
  List<String> _bodyHistory = [];
  int _currentHistoryIndex = -1;
  bool _isUndoRedoInProgress = false;

  @override
  void initState() {
    super.initState();
    _initializeContent();
    _titleFocusNode.addListener(_onTitleFocusChange);

    // Initialize history
    _titleHistory.add(_titleController.text);
    _bodyHistory.add(_bodyController.text);
    _currentHistoryIndex = 0;
  }

  void _initializeContent() {
    final subject = _extractHeader('Subject');
    final rawBody = widget.message.snippet ?? '';

    _titleController.text = subject.isNotEmpty ? subject : 'Untitled Note';
    _bodyController.text = rawBody;

    _titleController.addListener(_onTextChanged);
    _bodyController.addListener(_onTextChanged);
  }

  void _onTitleFocusChange() {
    if (!_titleFocusNode.hasFocus && _titleController.text.isEmpty) {
      setState(() {
        _titleController.text = 'Untitled Note';
      });
    }
  }

  void _onTextChanged() {
    if (_isUndoRedoInProgress) return;

    if (!_isEdited) {
      setState(() {
        _isEdited = true;
        _lastEdited = DateTime.now();
      });
    }

    // Add to history if this is a new change (not undo/redo)
    if (_currentHistoryIndex == _titleHistory.length - 1) {
      _titleHistory.add(_titleController.text);
      _bodyHistory.add(_bodyController.text);
      _currentHistoryIndex++;

      // Limit history size (keep last 50 changes)
      if (_titleHistory.length > 50) {
        _titleHistory.removeAt(0);
        _bodyHistory.removeAt(0);
        _currentHistoryIndex--;
      }
    }
  }

  void _undo() {
    if (_currentHistoryIndex > 0) {
      _isUndoRedoInProgress = true;
      setState(() {
        _currentHistoryIndex--;
        _titleController.text = _titleHistory[_currentHistoryIndex];
        _bodyController.text = _bodyHistory[_currentHistoryIndex];
        _isEdited = true;
        _lastEdited = DateTime.now();
      });
      _isUndoRedoInProgress = false;
    }
  }

  void _redo() {
    if (_currentHistoryIndex < _titleHistory.length - 1) {
      _isUndoRedoInProgress = true;
      setState(() {
        _currentHistoryIndex++;
        _titleController.text = _titleHistory[_currentHistoryIndex];
        _bodyController.text = _bodyHistory[_currentHistoryIndex];
        _isEdited = true;
        _lastEdited = DateTime.now();
      });
      _isUndoRedoInProgress = false;
    }
  }

  Future<void> _saveChanges() async {
    try {
      final signedIn = _authService.isSignedIn || await _authService.signIn();
      if (!signedIn) throw Exception('User not signed in');

      _authService.saveNote(
        messageId: widget.message.id,
        subject:
            _titleController.text.isNotEmpty
                ? _titleController.text.trim()
                : 'Untitled',
        content:
            _bodyController.text.isNotEmpty ? _bodyController.text.trim() : '',
      );
    } catch (e) {
      showCupertinoDialog(
        context: context,
        builder:
            (context) => CupertinoAlertDialog(
              title: Text(
                'Error',
                style: TextStyle(
                  color: CupertinoColors.destructiveRed.resolveFrom(context),
                ),
              ),
              content: Text('Failed to save note: $e'),
              actions: [
                CupertinoDialogAction(
                  child: const Text('OK'),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
      );
    }

    setState(() {
      _isEdited = false;
    });

    // Show confirmation
  }

  String _extractHeader(String headerName) {
    final headers = widget.message.payload?.headers ?? [];
    return headers
            .firstWhere(
              (h) => h.name?.toLowerCase() == headerName.toLowerCase(),
              orElse: () => gmail.MessagePartHeader(name: '', value: ''),
            )
            .value ??
        '';
  }

  void _showActionSheet(BuildContext context) {
    showCupertinoModalPopup(
      context: context,
      builder:
          (BuildContext context) => CupertinoActionSheet(
            title: const Text('Note Actions'),
            actions: <CupertinoActionSheetAction>[
              CupertinoActionSheetAction(
                onPressed: () {
                  Navigator.pop(context);
                  // Implement delete functionality
                },
                child: const Text('Delete Note'),
              ),
              CupertinoActionSheetAction(
                onPressed: () {
                  Navigator.pop(context);
                  // Implement share functionality
                },
                child: const Text('Share Note'),
              ),
              CupertinoActionSheetAction(
                onPressed: () {
                  Navigator.pop(context);
                  // Implement export functionality
                },
                child: const Text('Export as PDF'),
              ),
            ],
            cancelButton: CupertinoActionSheetAction(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text('Cancel'),
            ),
          ),
    );
  }

  @override
  void dispose() {
    _titleController.dispose();
    _bodyController.dispose();
    _titleFocusNode.dispose();
    _bodyFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        previousPageTitle: widget.folder,
        middle: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            CupertinoButton(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              onPressed: _currentHistoryIndex > 0 ? _undo : null,
              child: Icon(
                CupertinoIcons.arrow_uturn_left_circle,
                color:
                    _currentHistoryIndex > 0
                        ? CupertinoTheme.of(context).primaryColor
                        : CupertinoColors.tertiaryLabel.resolveFrom(context),
                size: 20,
              ),
            ),
            CupertinoButton(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              onPressed:
                  _currentHistoryIndex < _titleHistory.length - 1
                      ? _redo
                      : null,
              child: Icon(
                CupertinoIcons.arrow_uturn_right_circle,
                color:
                    _currentHistoryIndex < _titleHistory.length - 1
                        ? CupertinoTheme.of(context).primaryColor
                        : CupertinoColors.tertiaryLabel.resolveFrom(context),
                size: 20,
              ),
            ),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            CupertinoButton(
              padding: EdgeInsets.zero,
              child: const Icon(CupertinoIcons.share, size: 20),
              onPressed: () {
                // Share functionality
              },
            ),
            CupertinoButton(
              padding: EdgeInsets.zero,
              child: const Icon(CupertinoIcons.ellipsis_circle, size: 20),
              onPressed: () => _showActionSheet(context),
            ),
            if (_isEdited)
              CupertinoButton(
                padding: EdgeInsets.zero,
                onPressed: _saveChanges,
                child: const Text(
                  'Done',
                  style: TextStyle(color: CupertinoColors.activeBlue),
                ),
              ),
          ],
        ),
      ),
      child: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: ListView(
                  children: [
                    const SizedBox(height: 8),
                    CupertinoTextField(
                      controller: _titleController,
                      focusNode: _titleFocusNode,
                      placeholder: 'Title',
                      style: CupertinoTheme.of(context)
                          .textTheme
                          .navLargeTitleTextStyle
                          .copyWith(fontSize: 24, fontWeight: FontWeight.bold),
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      decoration: null,
                    ),
                    CupertinoTextField(
                      controller: _bodyController,
                      focusNode: _bodyFocusNode,
                      placeholder: 'Start typing...',
                      keyboardType: TextInputType.multiline,
                      maxLines: null,
                      style: CupertinoTheme.of(
                        context,
                      ).textTheme.textStyle.copyWith(fontSize: 17, height: 1.5),
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      decoration: null,
                    ),
                    if (_isEdited)
                      Padding(
                        padding: const EdgeInsets.only(top: 16.0, bottom: 24.0),
                        child: Text(
                          'Edited ${_formatDate(_lastEdited)}',
                          style: CupertinoTheme.of(
                            context,
                          ).textTheme.textStyle.copyWith(
                            fontSize: 12,
                            color: CupertinoColors.secondaryLabel.resolveFrom(
                              context,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            // Undo/Redo toolbar that appears when editing
            if (_bodyFocusNode.hasFocus || _titleFocusNode.hasFocus)
              Container(
                color: CupertinoColors.systemGrey6.resolveFrom(context),
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  children: [
                    const Spacer(),
                    CupertinoButton(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: const Icon(
                        CupertinoIcons.keyboard_chevron_compact_down,
                        size: 20,
                      ),
                      onPressed: () {
                        _bodyFocusNode.unfocus();
                        _titleFocusNode.unfocus();
                      },
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      return 'Today';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }
}
