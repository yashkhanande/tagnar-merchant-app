import 'dart:async';
import 'package:get/get.dart';
import '../access/access_repository.dart';
import 'auth_repository.dart';
import '../../models/onboarding_details.dart';

class MerchantSessionController extends GetxController {
  MerchantSessionController(this.auth, this.access);
  final MerchantAuthRepository auth;
  final MerchantAccessRepository access;
  MerchantIdentity? identity;
  bool starting = true, signingOut = false;
  bool sendingCode = false, verifyingCode = false, codeSent = false;
  bool loadingAnchors = false;
  bool loadingProfile = false, savingOnboarding = false;
  bool profileLoaded = false;
  bool onboardingCompleted = false;
  String? error, accessError, phoneNotice;
  OnboardingDetails onboardingDetails = const OnboardingDetails();
  String requestedPhone = '';
  int resendSeconds = 0;
  List<MerchantAnchor> anchors = const [];
  MerchantAnchor? selectedAnchor;
  StreamSubscription<MerchantIdentity?>? _authSubscription;
  StreamSubscription<AnchorAccessSnapshot>? _anchorSubscription;
  Timer? _resendTimer, _requestTimer;
  int _sessionVersion = 0, _phoneVersion = 0;

  void start() {
    _authSubscription = auth.identities.listen(
      _identityChanged,
      onError: (Object e) {
        if (isClosed) return;
        _clearAccess();
        starting = false;
        error = message(e);
        update();
      },
    );
  }

  void _clearAccess() {
    _sessionVersion++;
    _anchorSubscription?.cancel();
    _anchorSubscription = null;
    anchors = const [];
    selectedAnchor = null;
    loadingAnchors = false;
    accessError = null;
    loadingProfile = false;
    profileLoaded = false;
    savingOnboarding = false;
    onboardingCompleted = false;
    onboardingDetails = const OnboardingDetails();
  }

  void _identityChanged(MerchantIdentity? next) {
    if (isClosed) return;
    final old = identity;
    identity = next;
    starting = false;
    if (old?.uid != next?.uid || old?.verifiedPhone != next?.verifiedPhone) {
      cancelPhone();
      _clearAccess();
      error = null;
      if (next?.hasVerifiedPhone == true) _connectProfile();
    }
    update();
  }

  Future<void> sendCode(String phone, {bool resend = false}) async {
    if (sendingCode || verifyingCode || (resend && resendSeconds > 0)) return;
    if (!RegExp(r'^\+[1-9]\d{7,14}$').hasMatch(phone)) {
      error = 'Enter +, country code and phone number, without spaces.';
      update();
      return;
    }
    final version = ++_phoneVersion;
    sendingCode = true;
    codeSent = false;
    error = null;
    phoneNotice = null;
    requestedPhone = phone;
    update();
    _requestTimer?.cancel();
    _requestTimer = Timer(const Duration(seconds: 90), () {
      if (isClosed || version != _phoneVersion || !sendingCode) return;
      sendingCode = false;
      error =
          'SMS request timed out. Check your connection and request a new code.';
      auth.cancelPhoneVerification();
      _phoneVersion++;
      update();
    });
    try {
      await auth.sendPhoneCode(
        phone,
        resend: resend,
        onEvent: (event) {
          if (isClosed || version != _phoneVersion) return;
          sendingCode = false;
          _requestTimer?.cancel();
          switch (event.kind) {
            case PhoneEventKind.codeSent:
              codeSent = true;
              phoneNotice = 'SMS sent. Enter the code below.';
              _startCooldown();
            case PhoneEventKind.autoRetrievalTimedOut:
              codeSent = true;
              phoneNotice =
                  'Automatic detection timed out. You can still enter the SMS code.';
            case PhoneEventKind.verified:
              verifyingCode = false;
              phoneNotice = 'Phone verified.';
            case PhoneEventKind.failed:
              error = event.message ?? 'SMS verification failed. Try again.';
          }
          update();
        },
      );
    } catch (e) {
      if (!isClosed && version == _phoneVersion) {
        sendingCode = false;
        _requestTimer?.cancel();
        error = message(e);
        update();
      }
    }
  }

  void _startCooldown() {
    _resendTimer?.cancel();
    resendSeconds = 60;
    _resendTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (isClosed || resendSeconds <= 1) {
        timer.cancel();
        resendSeconds = 0;
      } else {
        resendSeconds--;
      }
      if (!isClosed) update();
    });
  }

  void cancelPhone() {
    _phoneVersion++;
    auth.cancelPhoneVerification();
    _resendTimer?.cancel();
    _requestTimer?.cancel();
    requestedPhone = '';
    codeSent = false;
    sendingCode = false;
    verifyingCode = false;
    resendSeconds = 0;
    phoneNotice = null;
  }

  void changePhone() {
    cancelPhone();
    error = null;
    update();
  }

  Future<void> verifyCode(String code) async {
    if (verifyingCode || sendingCode) return;
    final version = _phoneVersion;
    verifyingCode = true;
    error = null;
    update();
    try {
      await auth.confirmPhoneCode(code);
    } catch (e) {
      if (!isClosed && version == _phoneVersion) error = message(e);
    } finally {
      if (!isClosed && version == _phoneVersion) {
        verifyingCode = false;
        update();
      }
    }
  }

  Future<void> _connectProfile() async {
    final user = identity;
    if (user == null) return;
    final version = _sessionVersion;
    loadingProfile = true;
    accessError = null;
    update();
    try {
      final profile = await access.ensureProfile(user);
      if (isClosed || version != _sessionVersion) return;
      loadingProfile = false;
      profileLoaded = true;
      onboardingCompleted = profile.onboardingCompleted;
      onboardingDetails = profile.details;
      update();
      if (!user.hasVerifiedPhone || !onboardingCompleted) return;
      await _connectAnchors(version, user);
    } catch (e) {
      if (!isClosed && version == _sessionVersion) {
        loadingProfile = false;
        loadingAnchors = false;
        accessError = message(e);
        update();
      }
    }
  }

  Future<void> _connectAnchors(int version, MerchantIdentity user) async {
    loadingAnchors = true;
    update();
    try {
      _anchorSubscription = access
          .watchAnchors(user.uid)
          .listen(
            (snapshot) {
              if (isClosed || version != _sessionVersion) return;
              loadingAnchors = false;
              if (!snapshot.serverConfirmed) {
                anchors = const [];
                selectedAnchor = null;
                accessError =
                    'Connect to the internet to confirm your anchor access.';
              } else {
                accessError = null;
                anchors = List.unmodifiable(snapshot.anchors);
                final previousId = selectedAnchor?.id;
                selectedAnchor = anchors
                    .where((anchor) => anchor.id == previousId)
                    .firstOrNull;
                selectedAnchor ??= anchors.firstOrNull;
              }
              update();
            },
            onError: (Object e) {
              if (isClosed || version != _sessionVersion) return;
              anchors = const [];
              selectedAnchor = null;
              loadingAnchors = false;
              accessError = message(e);
              update();
            },
          );
    } catch (e) {
      if (!isClosed && version == _sessionVersion) {
        loadingAnchors = false;
        accessError = message(e);
        update();
      }
    }
  }

  Future<bool> completeOnboarding(OnboardingDetails details) async {
    final uid = identity?.uid;
    if (uid == null || identity?.hasVerifiedPhone != true || savingOnboarding) {
      return false;
    }
    final version = _sessionVersion;
    savingOnboarding = true;
    accessError = null;
    update();
    try {
      await access.saveOnboarding(uid, details);
      if (isClosed || version != _sessionVersion) return false;
      onboardingDetails = details;
      onboardingCompleted = true;
      savingOnboarding = false;
      update();
      await _connectAnchors(version, identity!);
      return true;
    } catch (e) {
      if (!isClosed && version == _sessionVersion) {
        savingOnboarding = false;
        accessError = message(e);
        update();
      }
      return false;
    }
  }

  Future<void> refreshAccess() async {
    if (loadingAnchors) return;
    _clearAccess();
    update();
    try {
      await auth.refreshIdentity();
      await _connectProfile();
    } catch (e) {
      if (!isClosed) {
        accessError = message(e);
        update();
      }
    }
  }

  void selectAnchor(MerchantAnchor anchor) {
    if (!anchors.any((candidate) => candidate.id == anchor.id)) return;
    selectedAnchor = anchor;
    accessError = null;
    update();
  }

  Future<void> signOut() async {
    if (signingOut || verifyingCode) return;
    signingOut = true;
    cancelPhone();
    _clearAccess();
    update();
    try {
      await auth.signOut();
    } catch (e) {
      if (!isClosed) error = message(e);
    } finally {
      if (!isClosed) {
        signingOut = false;
        update();
      }
    }
  }

  static String message(Object e) => e is AuthFailure
      ? e.message
      : e is AccessFailure
      ? e.message
      : 'Could not connect securely. Check your connection and try again.';
  @override
  void onClose() {
    cancelPhone();
    _clearAccess();
    _authSubscription?.cancel();
    super.onClose();
  }
}
