import 'package:flutter/cupertino.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:myapp/models/note_model.dart';
import 'package:myapp/repositories/note_repo.dart';
import 'package:myapp/screens/auth_gate.dart';
import 'package:myapp/screens/mainscreen.dart';
import 'package:myapp/services/google_auth_service.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final appDocumentDir = await getApplicationDocumentsDirectory();
  await Hive.initFlutter(appDocumentDir.path);

  Hive.registerAdapter(NoteAdapter());
  await Hive.openBox<Note>('notes');

  runApp(
    MultiProvider(
      providers: [
        Provider(create: (_) => GoogleService()),
        ProxyProvider<GoogleService, NoteRepository>(
          update: (_, authService, __) {
            // You may want to customize NoteRepository to depend on authService if needed
            return NoteRepository(Hive.box<Note>('notes'));
          },
        ),
      ],
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
        brightness: Brightness.light,
        textTheme: CupertinoTextThemeData(
          navTitleTextStyle: TextStyle(
            fontFamily: 'SanFrancisco',
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: CupertinoDynamicColor.resolve(
              CupertinoColors.label,
              context,
            ),
          ),
          textStyle: TextStyle(
            fontFamily: 'SanFrancisco',
            fontSize: 16,
            color: CupertinoDynamicColor.resolve(
              CupertinoColors.label,
              context,
            ),
          ),
        ),
      ),
      home: const AuthGate(child: MainScreen()),
    );
  }
}
