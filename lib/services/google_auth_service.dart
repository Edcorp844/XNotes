import 'package:google_sign_in/google_sign_in.dart';
import 'package:http/http.dart' as http;
import 'package:googleapis/gmail/v1.dart' as gmail;
import 'dart:convert';

class GoogleService {
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: [
      gmail.GmailApi.gmailReadonlyScope,
      gmail.GmailApi.gmailModifyScope,
    ],
  );

  GoogleSignInAccount? _currentUser;
  gmail.GmailApi? _gmailApi;
  String? _userEmail;

  /// Sign in and initialize Gmail API
  Future<bool> signIn() async {
    try {
      _currentUser ??= await _googleSignIn.signInSilently();
      _currentUser ??= await _googleSignIn.signIn();

      if (_currentUser == null) return false;

      final authHeaders = await _currentUser!.authHeaders;
      final client = _GoogleAuthClient(authHeaders);

      _gmailApi = gmail.GmailApi(client);
      _userEmail = _currentUser!.email;

      return true;
    } catch (e) {
      print('Google Sign-In failed: $e');
      return false;
    }
  }

  Future<void> signOut() async {
    await _googleSignIn.signOut();
    _currentUser = null;
    _gmailApi = null;
    _userEmail = null;
  }

  String? get displayName => _currentUser?.displayName;
  bool get isSignedIn => _currentUser != null;

  /// Fetches notes from Gmail labeled "Notes"
  Future<List<gmail.Message>> fetchAppleNotes() async {
    if (_gmailApi == null) throw Exception('Not authenticated');

    final notesLabel = await _getNotesLabel();
    final messageList = await _gmailApi!.users.messages.list(
      'me',
      labelIds: [notesLabel.id!],
    );

    return await Future.wait(
      (messageList.messages ?? []).map(
        (msg) => _gmailApi!.users.messages.get('me', msg.id!),
      ),
    );
  }

  /// Saves or updates a note
  Future<gmail.Message> saveNote({
    String? messageId,
    required String subject,
    required String content,
  }) async {
    if (_gmailApi == null) throw Exception('Not authenticated');
    if (_userEmail == null || _userEmail!.isEmpty) {
      throw Exception('User email not available');
    }

    final raw = _buildNoteMessage(
      to: _userEmail!,
      subject: subject,
      body: content,
    );

    final gmail.Message message = gmail.Message(raw: raw);

    final sent = await _gmailApi!.users.messages.send(
      message,
      'me',
    );

    if (messageId == null) {
      await _addNoteLabel(sent.id!);
    }

    return await _gmailApi!.users.messages.get('me', sent.id!);
  }

  /// Retrieves or creates the "Notes" label
  Future<gmail.Label> _getNotesLabel() async {
    final labels = await _gmailApi!.users.labels.list('me');
    final existing = labels.labels?.firstWhere(
      (label) => label.name?.toLowerCase() == 'notes',
      orElse: () => gmail.Label(),
    );

    if (existing?.id != null) return existing!;

    return await _gmailApi!.users.labels.create(
      gmail.Label(name: 'Notes', labelListVisibility: 'labelShow'),
      'me',
    );
  }

  /// Adds "Notes" label to a message
  Future<void> _addNoteLabel(String messageId) async {
    final notesLabel = await _getNotesLabel();
    await _gmailApi!.users.messages.modify(
      gmail.ModifyMessageRequest(addLabelIds: [notesLabel.id!]),
      'me',
      messageId,
    );
  }

  /// Composes a base64-encoded raw RFC 2822 email message
  String _buildNoteMessage({
    required String to,
    required String subject,
    required String body,
  }) {
    final lines = [
      'From: $to',
      'To: $to',
      'Subject: $subject',
      'Content-Type: text/plain; charset="utf-8"',
      '',
      body,
    ];

    final rawText = lines.join('\n');
    final bytes = utf8.encode(rawText);
    return base64Url.encode(bytes);
  }
}

/// Authenticated HTTP client for Gmail API
class _GoogleAuthClient extends http.BaseClient {
  final Map<String, String> _headers;
  final http.Client _client = http.Client();

  _GoogleAuthClient(this._headers);

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) {
    request.headers.addAll(_headers);
    return _client.send(request);
  }
}
