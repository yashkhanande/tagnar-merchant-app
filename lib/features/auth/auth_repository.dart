class MerchantIdentity {
  const MerchantIdentity({
    required this.uid,
    required this.name,
    required this.email,
    this.photoUrl = '',
    this.verifiedPhone,
  });
  final String uid, name, email, photoUrl;

  /// Comes from a Firebase-issued ID token, never a profile document or input.
  final String? verifiedPhone;
  bool get hasVerifiedPhone =>
      verifiedPhone != null && verifiedPhone!.isNotEmpty;
}

enum PhoneEventKind { codeSent, autoRetrievalTimedOut, verified, failed }

class PhoneEvent {
  const PhoneEvent(this.kind, {this.message});
  final PhoneEventKind kind;
  final String? message;
}

abstract interface class MerchantAuthRepository {
  Stream<MerchantIdentity?> get identities;
  Future<void> sendPhoneCode(
    String phone, {
    required void Function(PhoneEvent) onEvent,
    bool resend = false,
  });
  Future<void> confirmPhoneCode(String code);
  void cancelPhoneVerification();
  Future<void> refreshIdentity();
  Future<void> signOut();
}

class AuthFailure implements Exception {
  const AuthFailure(this.message);
  final String message;
  @override
  String toString() => message;
}
