import 'dart:convert';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart' hide Text;
import 'package:googleapis/gmail/v1.dart' as gmail;

class GmailNoteEditorScreen extends StatefulWidget {
  final gmail.Message message;

  const GmailNoteEditorScreen({super.key, required this.message});

  @override
  State<GmailNoteEditorScreen> createState() => _GmailNoteEditorScreenState();
}

class _GmailNoteEditorScreenState extends State<GmailNoteEditorScreen> {
  late final QuillController _controller;
  late final TextEditingController _titleController;
  late final ScrollController _scrollController;
  late final FocusNode _focusNode;

  @override
  void initState() {
    super.initState();

    final subject = _extractHeader('Subject');

    // Safely extract body text or default to empty string
    final rawBody = widget.message.snippet ?? '';

    final document = _createDocumentFromBody(rawBody);

    _titleController = TextEditingController(text: subject);

    _controller = QuillController(
      document: document,
      selection: const TextSelection.collapsed(offset: 0),
    );

    _scrollController = ScrollController();
    _focusNode = FocusNode();
  }

  Document _createDocumentFromBody(String body) {
    try {
      final decoded = jsonDecode(body);
      return Document.fromJson(decoded);
    } catch (_) {
      return Document()..insert(0, body);
    }
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

  @override
  void dispose() {
    _titleController.dispose();
    _controller.dispose();
    _scrollController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = CupertinoTheme.of(context);

    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        previousPageTitle: 'Gmail Notes',
        middle: CupertinoTextField(
          controller: _titleController,
          placeholder: 'Title',
          style: theme.textTheme.navTitleTextStyle.copyWith(
            fontWeight: FontWeight.w600,
          ),
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
        ),
        trailing: CupertinoButton(
          padding: EdgeInsets.zero,
          child: const Text('Done'),
          onPressed: () {
            // TODO: Add save logic here if needed
            Navigator.of(context).pop();
          },
        ),
      ),
      child: SafeArea(
        child: Column(
          children: [
            _buildToolbar(),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Theme(
                  data: ThemeData(),
                  child: QuillEditor(
                    controller: _controller,
                    scrollController: _scrollController,
                    focusNode: _focusNode,
                    config: const QuillEditorConfig(
                      autoFocus: false,
                      expands: false,
                      padding: EdgeInsets.zero,
                      scrollable: true,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildToolbar() {
    return Container(
      height: 44,
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: CupertinoColors.separator)),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            _toolbarButton(CupertinoIcons.bold, Attribute.bold),
            _toolbarButton(CupertinoIcons.italic, Attribute.italic),
            _toolbarButton(CupertinoIcons.underline, Attribute.underline),
            _toolbarButton(CupertinoIcons.textformat_size, Attribute.h1),
            _toolbarButton(CupertinoIcons.list_bullet, Attribute.ul),
            _toolbarButton(CupertinoIcons.list_number, Attribute.ol),
          ],
        ),
      ),
    );
  }

  Widget _toolbarButton(IconData icon, Attribute attribute) {
    return CupertinoButton(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Icon(icon, size: 22),
      onPressed: () => _controller.formatSelection(attribute),
    );
  }
}
