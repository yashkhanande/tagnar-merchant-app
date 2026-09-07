import 'models.dart';

/// Later adapters must authorize merchant scope on the server.
/// There is deliberately no API to set a payment's status.
abstract interface class MerchantRepository {
  Future<MerchantSnapshot> load({DemoScenario scenario = DemoScenario.normal});
  Future<void> respondToOffer(String offerId, OfferDecision decision);
  Future<void> sendMessage(String conversationId, String text);
  Future<void> markConversationRead(String conversationId);
  Future<void> requestPhoneCode(String phone);
  Future<void> confirmPhone(String phone, String code);
}

class MerchantException implements Exception {
  const MerchantException(this.message);
  final String message;
  @override
  String toString() => message;
}
