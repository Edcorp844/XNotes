import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:myapp/models/note_model.dart';
import 'package:myapp/screens/note_editor_screen.dart';

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
            onPressed: () {
              createNewNote(context);
            },
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
