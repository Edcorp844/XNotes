import 'dart:convert';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart'
    show Theme, ThemeData, Material; // just for Quill
import 'package:flutter_quill/flutter_quill.dart';
import 'package:myapp/models/note_model.dart';
import 'package:myapp/repositories/note_repo.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';

class CupertinoNoteEditor extends StatefulWidget {
  final Note? existingNote;

  const CupertinoNoteEditor({super.key, this.existingNote});

  @override
  CupertinoNoteEditorState createState() => CupertinoNoteEditorState();
}

class CupertinoNoteEditorState extends State<CupertinoNoteEditor> {
  late final QuillController _controller;
  late final TextEditingController _titleController;
  late final FocusNode _titleFocusNode;
  late final FocusNode _editorFocusNode;
  bool _isEdited = false;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController();
    _titleFocusNode = FocusNode();
    _editorFocusNode = FocusNode();

    try {
      final initialContent = widget.existingNote?.content;
      _controller = QuillController(
        document:
            initialContent != null && initialContent.isNotEmpty
                ? _parseDocument(initialContent)
                : Document(),
        selection: const TextSelection.collapsed(offset: 0),
      );
    } catch (e) {
      _controller = QuillController(
        document: Document(),
        selection: const TextSelection.collapsed(offset: 0),
      );
      debugPrint('Error initializing document: $e');
    }

    if (widget.existingNote != null) {
      _titleController.text = widget.existingNote!.title;
    }

    _titleController.addListener(_checkForChanges);
    _controller.document.changes.listen((_) => _checkForChanges());
  }

  Document _parseDocument(String content) {
    try {
      return Document.fromJson(jsonDecode(content));
    } catch (_) {
      return Document()..insert(0, content);
    }
  }

  void _checkForChanges() {
    final hasTitleChanges = widget.existingNote?.title != _titleController.text;
    final hasContentChanges =
        widget.existingNote?.content !=
        jsonEncode(_controller.document.toDelta().toJson());

    setState(() {
      _isEdited = hasTitleChanges || hasContentChanges;
    });
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = CupertinoTheme.of(context).textTheme;

    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        middle: CupertinoTextField(
          controller: _titleController,
          focusNode: _titleFocusNode,
          placeholder: 'Title',
          style: textTheme.navTitleTextStyle.copyWith(
            inherit: true,
            fontFamily: 'SanFrancisco',
          ),
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: null,
        ),
        trailing: CupertinoButton(
          padding: EdgeInsets.zero,
          onPressed: _isEdited ? _saveNote : null,
          child: Text(
            'Done',
            style: textTheme.textStyle.copyWith(
              inherit: true,
              color:
                  _isEdited
                      ? CupertinoColors.activeBlue
                      : CupertinoColors.inactiveGray,
            ),
          ),
        ),
      ),
      child: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: CupertinoScrollbar(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      Theme(
                        // 👈 Wrap to satisfy Quill's style dependencies
                        data: ThemeData(), // empty/default is fine
                        child: Material(
                          color: CupertinoColors.systemBackground.resolveFrom(
                            context,
                          ),
                          child: QuillEditor(
                            controller: _controller,
                            focusNode: _editorFocusNode,
                            scrollController: ScrollController(),
                            config: QuillEditorConfig(
                              scrollable: false,
                              autoFocus: true,
                              placeholder: 'Start typing...',
                              expands: false,
                              padding: EdgeInsets.zero,
                            ),
                          ),
                        ),
                      ),
                      Container(
                        height: 44,
                        decoration: BoxDecoration(
                          border: Border(
                            bottom: BorderSide(
                              color: CupertinoColors.separator,
                              width: 0.5,
                            ),
                          ),
                        ),
                        child: SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: [
                              _buildToolbarButton(
                                CupertinoIcons.bold,
                                () =>
                                    _controller.formatSelection(Attribute.bold),
                              ),
                              _buildToolbarButton(
                                CupertinoIcons.italic,
                                () => _controller.formatSelection(
                                  Attribute.italic,
                                ),
                              ),
                              _buildToolbarButton(
                                CupertinoIcons.underline,
                                () => _controller.formatSelection(
                                  Attribute.underline,
                                ),
                              ),
                              _buildToolbarButton(
                                CupertinoIcons.list_bullet,
                                () => _controller.formatSelection(Attribute.ul),
                              ),
                              _buildToolbarButton(
                                CupertinoIcons.list_number,
                                () => _controller.formatSelection(Attribute.ol),
                              ),
                              _buildToolbarButton(
                                CupertinoIcons.textformat_size,
                                () => _controller.formatSelection(Attribute.h1),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildToolbarButton(IconData icon, VoidCallback onPressed) {
    return CupertinoButton(
      minSize: 44,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Icon(icon, size: 22),
      onPressed: onPressed,
    );
  }

  Future<void> _saveNote() async {
    if (!_isEdited) return;

    final noteRepository = Provider.of<NoteRepository>(context, listen: false);
    final now = DateTime.now();

    final note = Note(
      id: widget.existingNote?.id ?? Uuid().v4(),
      title: _titleController.text,
      content: jsonEncode(_controller.document.toDelta().toJson()),
      createdAt: widget.existingNote?.createdAt ?? now,
      updatedAt: now,
    );

    try {
      await noteRepository.saveNote(note);
      if (mounted) Navigator.of(context).pop();
    } catch (_) {
      if (mounted) {
        showCupertinoDialog(
          context: context,
          builder:
              (context) => CupertinoAlertDialog(
                title: const Text('Error'),
                content: const Text('Failed to save note'),
                actions: [
                  CupertinoDialogAction(
                    child: const Text('OK'),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
        );
      }
    }
  }

  @override
  void dispose() {
    _titleController.removeListener(_checkForChanges);
    _titleController.dispose();
    _titleFocusNode.dispose();
    _editorFocusNode.dispose();
    _controller.dispose();
    super.dispose();
  }
}
