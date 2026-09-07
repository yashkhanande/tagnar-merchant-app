import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../auth_repository.dart';

class FirebaseMerchantAuthRepository implements MerchantAuthRepository {
  FirebaseMerchantAuthRepository({
    required FirebaseAuth auth,
    GoogleSignIn? google,
  }) : _auth = auth,
       _google = google ?? GoogleSignIn.instance;
  final FirebaseAuth _auth;
  final GoogleSignIn _google;
  Future<void>? _googleInitialization;
  String? _verificationId, _phone, _uid;
  int? _resendToken;
  int _generation = 0;
  bool _linking = false;

  @override
  Stream<MerchantIdentity?> get identities =>
      _auth.idTokenChanges().asyncMap((user) async {
        if (user == null) return null;
        final token = await user.getIdTokenResult();
        if (_auth.currentUser?.uid != user.uid) return null;
        return MerchantIdentity(
          uid: user.uid,
          name: user.displayName ?? 'Merchant',
          email: user.email ?? '',
          verifiedPhone: token.claims?['phone_number'] as String?,
        );
      });

  @override
  Future<void> signInWithGoogle() async {
    cancelPhoneVerification();
    try {
      await (_googleInitialization ??= _google.initialize());
      final account = await _google.authenticate();
      final idToken = account.authentication.idToken;
      if (idToken == null) {
        throw const AuthFailure(
          'Google did not return a sign-in token. Please try again.',
        );
      }
      await _auth.signInWithCredential(
        GoogleAuthProvider.credential(idToken: idToken),
      );
    } on GoogleSignInException catch (e) {
      if (e.code == GoogleSignInExceptionCode.canceled) {
        throw const AuthFailure('Google sign-in was cancelled.');
      }
      throw const AuthFailure(
        'Google sign-in could not finish. Check your connection and the Android Firebase setup.',
      );
    } on FirebaseAuthException catch (e) {
      throw AuthFailure(authMessage(e.code));
    }
  }

  bool _current(int generation, String uid) =>
      generation == _generation && _auth.currentUser?.uid == uid;

  @override
  Future<void> sendPhoneCode(
    String phone, {
    required void Function(PhoneEvent) onEvent,
    bool resend = false,
  }) async {
    final user = _auth.currentUser;
    if (user == null) throw const AuthFailure('Sign in with Google first.');
    if (!RegExp(r'^\+[1-9]\d{7,14}$').hasMatch(phone)) {
      throw const AuthFailure(
        'Enter +, country code and phone number, without spaces.',
      );
    }
    final resendToken = resend && _phone == phone && _uid == user.uid
        ? _resendToken
        : null;
    cancelPhoneVerification();
    _phone = phone;
    _uid = user.uid;
    final generation = _generation;
    void emit(PhoneEvent event) {
      if (_current(generation, user.uid)) onEvent(event);
    }

    try {
      await _auth.verifyPhoneNumber(
        phoneNumber: phone,
        forceResendingToken: resendToken,
        timeout: const Duration(seconds: 60),
        verificationCompleted: (credential) async {
          if (!_current(generation, user.uid) || _linking) return;
          try {
            await _link(credential, generation, user.uid);
            emit(const PhoneEvent(PhoneEventKind.verified));
          } catch (e) {
            emit(PhoneEvent(PhoneEventKind.failed, message: failureMessage(e)));
          }
        },
        verificationFailed: (error) => emit(
          PhoneEvent(
            PhoneEventKind.failed,
            message: authMessage(error.code, details: error.message),
          ),
        ),
        codeSent: (verificationId, resendToken) {
          if (!_current(generation, user.uid)) return;
          _verificationId = verificationId;
          _resendToken = resendToken;
          emit(const PhoneEvent(PhoneEventKind.codeSent));
        },
        codeAutoRetrievalTimeout: (verificationId) {
          if (!_current(generation, user.uid)) return;
          _verificationId = verificationId;
          emit(const PhoneEvent(PhoneEventKind.autoRetrievalTimedOut));
        },
      );
    } on FirebaseAuthException catch (e) {
      throw AuthFailure(authMessage(e.code));
    }
  }

  Future<void> _link(
    PhoneAuthCredential credential,
    int generation,
    String uid,
  ) async {
    if (!_current(generation, uid)) {
      throw const AuthFailure(
        'Your sign-in session changed. Request a new code.',
      );
    }
    if (_linking) {
      throw const AuthFailure('Phone verification is already finishing.');
    }
    _linking = true;
    try {
      // Linking preserves the Google UID and never switches to a phone account.
      await _auth.currentUser!.linkWithCredential(credential);
      if (!_current(generation, uid)) return;
      await refreshIdentity();
      _verificationId = null;
    } on FirebaseAuthException catch (e) {
      throw AuthFailure(authMessage(e.code));
    } finally {
      _linking = false;
    }
  }

  @override
  Future<void> confirmPhoneCode(String code) async {
    if (!RegExp(r'^\d{6}$').hasMatch(code)) {
      throw const AuthFailure('Enter the 6-digit code from your SMS.');
    }
    final verificationId = _verificationId;
    final uid = _uid;
    if (verificationId == null || uid == null) {
      throw const AuthFailure('Request a new SMS code first.');
    }
    await _link(
      PhoneAuthProvider.credential(
        verificationId: verificationId,
        smsCode: code,
      ),
      _generation,
      uid,
    );
  }

  @override
  void cancelPhoneVerification() {
    _generation++;
    _verificationId = null;
    _phone = null;
    _uid = null;
    _resendToken = null;
  }

  @override
  Future<void> refreshIdentity() async {
    final user = _auth.currentUser;
    if (user == null) return;
    try {
      await user.reload();
      if (_auth.currentUser?.uid == user.uid) {
        await _auth.currentUser!.getIdToken(true);
      }
    } on FirebaseAuthException catch (e) {
      throw AuthFailure(authMessage(e.code));
    }
  }

  @override
  Future<void> signOut() async {
    cancelPhoneVerification();
    // Always end Firebase access even if Google's local session cleanup fails.
    await _auth.signOut();
    if (_googleInitialization != null) {
      try {
        await _google.signOut();
      } catch (_) {
        /* Firebase session is closed. */
      }
    }
  }
}

String failureMessage(Object error) => error is AuthFailure
    ? error.message
    : 'Could not finish verification. Please try again.';
String authMessage(String code, {String? details}) {
  final normalizedDetails = details?.toLowerCase() ?? '';
  if (normalizedDetails.contains('region enabled') ||
      normalizedDetails.contains('region is not allowed') ||
      normalizedDetails.contains('sms unable to be sent until this region')) {
    return 'SMS delivery is disabled for this phone region in Firebase. Ask the administrator to enable the region under Authentication settings.';
  }
  return switch (code) {
    'invalid-phone-number' =>
      'Enter a valid phone number with its country code.',
    'invalid-verification-code' ||
    'invalid-credential' => 'The SMS code is incorrect. Please try again.',
    'session-expired' || 'invalid-verification-id' =>
      'This SMS session expired. Request a new code.',
    'credential-already-in-use' =>
      'This phone belongs to another account. Sign in to that account or contact support. Your Google account has not been switched.',
    'provider-already-linked' =>
      'A phone is already linked. Refresh your session or sign in again.',
    'requires-recent-login' =>
      'Please sign out and sign in again before verifying your phone.',
    'too-many-requests' => 'Too many attempts. Wait before trying again.',
    'quota-exceeded' =>
      'The SMS service has reached its limit. Please try later.',
    'operation-not-allowed' =>
      'Phone sign-in is not enabled for this Firebase project. Contact the project administrator.',
    'app-not-authorized' ||
    'invalid-app-credential' ||
    'missing-client-identifier' =>
      'App verification failed. The administrator must check Android fingerprints and Firebase setup.',
    'network-request-failed' => 'Check your internet connection and try again.',
    'user-disabled' || 'user-token-expired' =>
      'This account cannot continue. Sign in again or contact support.',
    _ =>
      'Authentication could not finish. Please try again or contact support.',
  };
}
