import 'package:flutter/cupertino.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:myapp/models/note_model.dart';
import 'package:myapp/screens/gmail_notes_screen.dart';
import 'package:myapp/screens/local_notes_screen.dart';

class MainScreen extends StatelessWidget {
  const MainScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      child: CustomScrollView(
        slivers: [
          CupertinoSliverNavigationBar.search(
            largeTitle: const Text('Folders'),
            searchField: const CupertinoSearchTextField(),
            trailing: CupertinoButton(
              onPressed: () {},
              padding: EdgeInsets.zero,
              child: const Text('Edit'),
            ),
          ),
          SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                /// 🌿 Local Notes Section
                CupertinoListSection.insetGrouped(
                  header: const Text('On This Device'),
                  children: [
                    ValueListenableBuilder<Box<Note>>(
                      valueListenable: Hive.box<Note>('notes').listenable(),
                      builder: (context, box, _) {
                        return FolderTile(
                          icon: CupertinoIcons.folder_fill,
                          folderName: 'Notes',
                          noteCount: box.length,
                          onTap: () {
                            Navigator.push(
                              context,
                              CupertinoPageRoute(
                                builder: (_) => const LocalNotesScreen(),
                              ),
                            );
                          },
                        );
                      },
                    ),
                  ],
                ),

                /// 📩 Gmail Notes Section
                CupertinoListSection.insetGrouped(
                  header: const Text('Gmail Notes'),
                  children: [
                    FolderTile(
                      icon: CupertinoIcons.folder,
                      folderName: 'Notes',
                      noteCount:
                          null, // Optional: you can fetch Gmail note count
                      onTap: () {
                        Navigator.push(
                          context,
                          CupertinoPageRoute(
                            builder: (_) => const GmailNotesScreen(),
                          ),
                        );
                      },
                    ),
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
  final IconData icon;
  final String folderName;
  final int? noteCount;
  final VoidCallback onTap;

  const FolderTile({
    super.key,
    required this.icon,
    required this.folderName,
    this.noteCount,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final textTheme = CupertinoTheme.of(context).textTheme;

    return CupertinoListTile(
      title: Row(
        children: [
          Icon(icon, size: 20),
          const SizedBox(width: 8),
          Text(folderName, style: textTheme.textStyle),
        ],
      ),
      additionalInfo:
          noteCount != null
              ? Text(
                '$noteCount',
                style: textTheme.textStyle.copyWith(
                  color: CupertinoColors.secondaryLabel,
                ),
              )
              : null,
      trailing: const Icon(CupertinoIcons.right_chevron),
      onTap: onTap,
    );
  }
}
