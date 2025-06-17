import 'package:hive/hive.dart';
import 'package:myapp/models/note_model.dart';

class NoteRepository {
  final Box<Note> _notesBox;

  NoteRepository(this._notesBox);

  List<Note> getAllNotes() => _notesBox.values.toList();

  Note? getNote(String id) => _notesBox.get(id);

  Future<void> saveNote(Note note) async {
    await _notesBox.put(note.id, note);
  }

  Future<void> deleteNote(String id) async {
    await _notesBox.delete(id);
  }
}
