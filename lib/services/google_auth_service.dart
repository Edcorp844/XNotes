import 'package:google_sign_in/google_sign_in.dart';
import 'package:http/http.dart' as http;
import 'package:googleapis/gmail/v1.dart' as gmail;

/// A wrapper class for authenticating users and interacting with Gmail.
class GoogleAuthService {
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: [
      gmail.GmailApi.gmailReadonlyScope,
      // Add write scopes here if needed, e.g. gmail.GmailApi.gmailModifyScope
      gmail.GmailApi.gmailModifyScope,
    ],
  );

  GoogleSignInAccount? _currentUser;
  gmail.GmailApi? _gmailApi;

  /// Attempts to sign in the user with Google.
  Future<bool> signIn() async {
    try {
      _currentUser = await _googleSignIn.signIn();
      if (_currentUser == null) return false;

      final authHeaders = await _currentUser!.authHeaders;
      final client = _GoogleAuthClient(authHeaders);

      _gmailApi = gmail.GmailApi(client);
      return true;
    } catch (e) {
      print('Google Sign-In failed: $e');
      return false;
    }
  }

  /// Signs out the current user from Google.
  Future<void> signOut() async {
    await _googleSignIn.signOut();
    _currentUser = null;
    _gmailApi = null;
  }

  /// Returns the signed-in user's display name, or null if not signed in.
  String? get displayName => _currentUser?.displayName;

  /// Returns true if a user is currently signed in.
  bool get isSignedIn => _currentUser != null;

  /// Fetches the list of notes (emails) under the "Notes" label.
  Future<List<gmail.Message>> fetchAppleNotes() async {
    if (_gmailApi == null) {
      throw Exception('Gmail API is not initialized. Call signIn() first.');
    }

    final labels = await _gmailApi!.users.labels.list('me');
    final notesLabel = labels.labels?.firstWhere(
      (label) => label.name?.toLowerCase() == 'notes',
      orElse: () => throw Exception('Notes label not found in Gmail.'),
    );

    final messageList = await _gmailApi!.users.messages.list(
      'me',
      labelIds: [notesLabel!.id!],
    );

    final messages = <gmail.Message>[];

    for (final msg in messageList.messages ?? []) {
      final fullMessage = await _gmailApi!.users.messages.get('me', msg.id!);
      messages.add(fullMessage);
    }

    return messages;
  }
}

/// A simple HTTP client that adds Google auth headers to each request.
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
