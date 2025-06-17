import 'package:flutter/cupertino.dart';

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
          CupertinoSliverNavigationBar(largeTitle: Text('Folders')),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(0.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CupertinoListSection.insetGrouped(
                    header: Text('Google'),
                    children: [
                      FolderTile(folderName: 'Notes'),
                      FolderTile(folderName: 'Stored'),
                      FolderTile(folderName: 'Learn'),
                      FolderTile(folderName: 'Guitar'),
                    ],
                  ),
                ],
              ),
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
          Icon(CupertinoIcons.folder),
          SizedBox(width: 8),
          Text(folderName),
        ],
      ),
      trailing: Icon(CupertinoIcons.right_chevron),
    );
  }
}
