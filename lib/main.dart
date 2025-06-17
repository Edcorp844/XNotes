import 'package:flutter/cupertino.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:myapp/models/note_model.dart';
import 'package:myapp/repositories/note_repo.dart';
import 'package:myapp/screens/mainscreen.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final appDocumentDir = await getApplicationDocumentsDirectory();
  await Hive.initFlutter(appDocumentDir.path);

  Hive.registerAdapter(NoteAdapter());
  await Hive.openBox<Note>('notes');

  runApp(
    Provider<NoteRepository>(
      create: (_) => NoteRepository(Hive.box<Note>('notes')),
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return CupertinoApp(
      debugShowCheckedModeBanner: false,
      title: 'XNotes',
      theme: CupertinoThemeData(
        brightness: Brightness.dark,
        textTheme: CupertinoTextThemeData(
          navTitleTextStyle: TextStyle(
            inherit: false,
            fontFamily: 'SanFrancisco',
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
          textStyle: TextStyle(
            inherit: false,
            fontFamily: 'SanFrancisco',
            fontSize: 16,
          ),
        ),
        barBackgroundColor: CupertinoColors.systemBackground,
        scaffoldBackgroundColor: CupertinoColors.systemBackground,
      ),
      home: const MainScreen(),
    );
  }
}
