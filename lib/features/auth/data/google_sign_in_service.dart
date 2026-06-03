import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

const googleClientId = String.fromEnvironment('GOOGLE_CLIENT_ID');

final googleSignInServiceProvider = Provider<GoogleSignInService>((ref) {
  return GoogleSignInService(GoogleSignIn.instance);
});

class GoogleSignInService {
  GoogleSignInService(this._googleSignIn);

  final GoogleSignIn _googleSignIn;
  Future<void>? _initialization;

  Stream<GoogleSignInAuthenticationEvent> get authenticationEvents =>
      _googleSignIn.authenticationEvents;

  bool get supportsAuthenticate => _googleSignIn.supportsAuthenticate();

  bool get isConfigured => googleClientId.isNotEmpty;

  Future<void> ensureInitialized() {
    return _initialization ??= _googleSignIn.initialize(
      clientId: googleClientId.isEmpty ? null : googleClientId,
      serverClientId: googleClientId.isEmpty ? null : googleClientId,
    );
  }

  Future<void> authenticate() async {
    await ensureInitialized();
    await _googleSignIn.authenticate();
  }

  Future<void> signOut() async {
    await ensureInitialized();
    await _googleSignIn.signOut();
  }
}
