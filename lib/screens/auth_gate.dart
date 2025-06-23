import 'package:flutter/cupertino.dart';
import 'package:myapp/services/google_auth_service.dart';
import 'package:provider/provider.dart';

class AuthGate extends StatefulWidget {
  final Widget child;

  const AuthGate({required this.child, Key? key}) : super(key: key);

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  bool _loading = true;
  bool _signedIn = false;
  String? _error;

  late final GoogleService _authService;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _authService = Provider.of<GoogleService>(context, listen: false);
    _checkSignIn();
  }

  Future<void> _checkSignIn() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      // Attempt sign-in silently first (if user already signed in)
      if (!_authService.isSignedIn) {
        _signedIn = await _authService.signIn();
      } else {
        _signedIn = true;
      }
    } catch (e) {
      _error = 'Failed to sign in: $e';
      _signedIn = false;
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const CupertinoPageScaffold(
        child: Center(child: CupertinoActivityIndicator()),
      );
    }

    if (!_signedIn) {
      return CupertinoPageScaffold(
        navigationBar: const CupertinoNavigationBar(
          middle: Text('Sign in Required'),
        ),
        child: Center(
          child: CupertinoButton.filled(
            child: const Text('Sign in with Google'),
            onPressed: () async {
              setState(() => _loading = true);
              final success = await _authService.signIn();
              setState(() {
                _signedIn = success;
                _loading = false;
              });
            },
          ),
        ),
      );
    }

    // Signed in — show your main notes app (pass any needed data)
    return widget.child;
  }
}
