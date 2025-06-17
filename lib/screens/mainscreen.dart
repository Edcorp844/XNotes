import 'dart:convert';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_quill/quill_delta.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:myapp/models/note_model.dart';
import 'package:myapp/repositories/note_repo.dart';
import 'package:myapp/screens/note_editor_screen.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      child: CustomScrollView(
        slivers: [
          const CupertinoSliverNavigationBar(largeTitle: Text('Folders')),
          SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Local Notes Folder (from Hive)
                CupertinoListSection.insetGrouped(
                  header: const Text('Local Storage'),
                  children: [
                    CupertinoListTile(
                      title: const Row(
                        children: [
                          Icon(CupertinoIcons.folder_fill),
                          SizedBox(width: 8),
                          Text('Notes'),
                        ],
                      ),
                      additionalInfo: ValueListenableBuilder<Box<Note>>(
                        valueListenable: Hive.box<Note>('notes').listenable(),
                        builder: (context, box, _) {
                          final noteCount = box.length;
                          return Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: Text(
                              '$noteCount',
                              style: CupertinoTheme.of(
                                context,
                              ).textTheme.textStyle.copyWith(
                                color: CupertinoColors.secondaryLabel,
                              ),
                            ),
                          );
                        },
                      ),
                      trailing: const Icon(CupertinoIcons.right_chevron),
                      onTap: () {
                        // Navigate to local notes screen
                        Navigator.push(
                          context,
                          CupertinoPageRoute(
                            builder: (context) => LocalNotesScreen(),
                          ),
                        );
                      },
                    ),

                    // Show note count from Hive
                  ],
                ),

                // Google Folders Section
                CupertinoListSection.insetGrouped(
                  header: const Text('Google Sync'),
                  children: const [
                    FolderTile(folderName: 'Stored'),
                    FolderTile(folderName: 'Learn'),
                    FolderTile(folderName: 'Guitar'),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class FolderTile extends StatelessWidget {
  final String folderName;
  const FolderTile({super.key, required this.folderName});

  @override
  Widget build(BuildContext context) {
    return CupertinoListTile(
      title: Row(
        children: [
          const Icon(CupertinoIcons.folder),
          const SizedBox(width: 8),
          Text(folderName),
        ],
      ),
      trailing: const Icon(CupertinoIcons.right_chevron),
      onTap: () {
        // Handle folder tap
      },
    );
  }
}

class LocalNotesScreen extends StatelessWidget {
  const LocalNotesScreen({super.key});

  void createNewNote(BuildContext context) {
    Navigator.push(
      context,
      CupertinoPageRoute(builder: (context) => CupertinoNoteEditor()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      slivers: [
        CupertinoSliverNavigationBar.search(
          searchField: CupertinoSearchTextField(),
          largeTitle: Text('Notes'),
          previousPageTitle: 'Folders',
          trailing: IconButton(
            onPressed: () {},
            icon: Icon(CupertinoIcons.ellipsis_circle),
          ),
        ),
        SliverToBoxAdapter(
          child: SizedBox(
            height: MediaQuery.of(context).size.height,
            child: ValueListenableBuilder<Box<Note>>(
              valueListenable: Hive.box<Note>('notes').listenable(),
              builder: (context, box, _) {
                final notes = box.values.toList();
                if (notes.isEmpty) {
                  return const Center(child: Text('No notes found'));
                }
                return CupertinoListSection.insetGrouped(
                  children: List.generate(notes.length, (index) {
                    final note = notes[index];

                    return CupertinoListTile(
                      title: Text(
                        note.title.isNotEmpty ? note.title : 'Untitled Note',
                        style: CupertinoTheme.of(context).textTheme.textStyle,
                      ),
                      subtitle: Text(
                        note.content.length > 30
                            ? note.content.substring(0, 30) + '...'
                            : note.content,
                        style: CupertinoTheme.of(context).textTheme.textStyle
                            .copyWith(color: CupertinoColors.secondaryLabel),
                      ),
                      trailing: const Icon(CupertinoIcons.chevron_right),
                      onTap: () {
                        Navigator.push(
                          context,
                          CupertinoPageRoute(
                            builder:
                                (context) =>
                                    CupertinoNoteEditor(existingNote: note),
                          ),
                        );
                      },
                    );
                  }),
                );
              },
            ),
          ),
        ),
      ],
    );
  }
}
