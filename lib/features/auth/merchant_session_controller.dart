import 'dart:async';
import 'package:get/get.dart';
import '../access/access_repository.dart';
import 'auth_repository.dart';

class MerchantSessionController extends GetxController {
  MerchantSessionController(this.auth, this.access);
  final MerchantAuthRepository auth;
  final MerchantAccessRepository access;
  MerchantIdentity? identity;
  bool starting = true, signingIn = false, signingOut = false;
  bool sendingCode = false, verifyingCode = false, codeSent = false;
  bool loadingShops = false, loadingAnchor = false;
  String? error, accessError, phoneNotice;
  String requestedPhone = '';
  int resendSeconds = 0;
  List<MerchantShop> shops = const [];
  MerchantShop? selectedShop;
  ApprovedAnchor? anchor;
  StreamSubscription<MerchantIdentity?>? _authSubscription;
  StreamSubscription<ShopAccessSnapshot>? _shopSubscription;
  StreamSubscription<ApprovedAnchor?>? _anchorSubscription;
  Timer? _resendTimer, _requestTimer;
  int _sessionVersion = 0, _phoneVersion = 0, _selectionVersion = 0;

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
    _selectionVersion++;
    _anchorSubscription?.cancel();
    _anchorSubscription = null;
    _shopSubscription?.cancel();
    _shopSubscription = null;
    shops = const [];
    selectedShop = null;
    anchor = null;
    loadingShops = false;
    loadingAnchor = false;
    accessError = null;
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
      if (next?.hasVerifiedPhone == true) _connectShops();
    }
    update();
  }

  Future<void> signIn() async {
    if (signingIn) return;
    signingIn = true;
    error = null;
    update();
    try {
      await auth.signInWithGoogle();
    } catch (e) {
      if (!isClosed) error = message(e);
    } finally {
      if (!isClosed) {
        signingIn = false;
        update();
      }
    }
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

  Future<void> _connectShops() async {
    final user = identity;
    if (user == null || !user.hasVerifiedPhone) return;
    final version = _sessionVersion;
    loadingShops = true;
    accessError = null;
    update();
    try {
      await access.ensureProfile(user);
      if (isClosed || version != _sessionVersion) return;
      _shopSubscription = access
          .watchShops(user.uid)
          .listen(
            (snapshot) {
              if (isClosed || version != _sessionVersion) return;
              loadingShops = false;
              if (!snapshot.serverConfirmed) {
                shops = const [];
                selectedShop = null;
                anchor = null;
                _selectionVersion++;
                accessError =
                    'Connect to the internet to confirm your shop access.';
              } else {
                accessError = null;
                shops = List.unmodifiable(snapshot.shops);
                final previous = selectedShop;
                final available = shops.where((s) => s.approved).toList();
                final matches = available
                    .where(
                      (s) =>
                          s.id == previous?.id &&
                          s.anchorId == previous?.anchorId,
                    )
                    .toList();
                if (matches.isEmpty) {
                  selectedShop = null;
                  anchor = null;
                  _selectionVersion++;
                  if (available.isNotEmpty) selectShop(available.first);
                } else {
                  selectedShop = matches.first;
                }
              }
              update();
            },
            onError: (Object e) {
              if (isClosed || version != _sessionVersion) return;
              shops = const [];
              selectedShop = null;
              anchor = null;
              _selectionVersion++;
              loadingShops = false;
              accessError = message(e);
              update();
            },
          );
    } catch (e) {
      if (!isClosed && version == _sessionVersion) {
        loadingShops = false;
        accessError = message(e);
        update();
      }
    }
  }

  Future<void> refreshAccess() async {
    if (loadingShops) return;
    _clearAccess();
    update();
    try {
      await auth.refreshIdentity();
      await _connectShops();
    } catch (e) {
      if (!isClosed) {
        accessError = message(e);
        update();
      }
    }
  }

  Future<void> selectShop(MerchantShop shop) async {
    final uid = identity?.uid;
    if (uid == null || !shops.any((s) => s.id == shop.id && s.approved)) return;
    final version = ++_selectionVersion;
    final session = _sessionVersion;
    selectedShop = shop;
    anchor = null;
    loadingAnchor = true;
    accessError = null;
    update();
    _anchorSubscription?.cancel();
    final firstResult = Completer<void>();
    bool current() =>
        !isClosed && version == _selectionVersion && session == _sessionVersion;
    void failed(Object e) {
      if (!current()) return;
      anchor = null;
      loadingAnchor = false;
      accessError = message(e);
      update();
      if (!firstResult.isCompleted) firstResult.complete();
    }

    try {
      _anchorSubscription = access
          .watchApprovedAnchor(uid: uid, shop: shop)
          .listen((value) {
            if (!current()) return;
            anchor = value;
            loadingAnchor = false;
            accessError = value == null
                ? 'Connect to the internet to confirm your anchor access.'
                : null;
            update();
            if (!firstResult.isCompleted) firstResult.complete();
          }, onError: failed);
      await firstResult.future.timeout(const Duration(seconds: 20));
    } catch (e) {
      failed(e);
    }
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
