enum RequestKind { brand, product }

enum RequestStatus { pending, approved, declined }

enum OfferDecision { accepted, declined }

enum RecordStatus { received, pending, failed, refunded }

enum ChatRole { brand, master, user }

enum DemoScenario { normal, empty, error }

extension DisplayLabel on Enum {
  String get label => '${name[0].toUpperCase()}${name.substring(1)}';
}

class AnchorProfile {
  const AnchorProfile({
    this.merchantId = 'merchant-demo-001',
    this.name = 'Aarav Shah',
    this.anchorName = 'Building',
    this.anchorId = 'ANCHOR-PN-0142',
    this.location = 'Baner, Pune, Maharashtra',
    this.phone = '+919876543210',
    this.phoneConfirmed = false,
  });
  final String merchantId, name, anchorName, anchorId, location, phone;
  final bool phoneConfirmed;
}

class MerchantRequest {
  const MerchantRequest({
    required this.id,
    required this.brand,
    required this.title,
    required this.kind,
    required this.status,
    required this.date,
    required this.category,
    required this.description,
  });
  final String id, brand, title, category, description;
  final RequestKind kind;
  final RequestStatus status;
  final DateTime date;
}

class MerchantOffer {
  const MerchantOffer({
    required this.id,
    required this.brand,
    required this.title,
    required this.description,
    required this.rewardRupees,
    required this.expiresAt,
    this.decision,
  });
  final String id, brand, title, description;
  final int rewardRupees;
  final DateTime expiresAt;
  final OfferDecision? decision;
  bool isActive(DateTime now) =>
      decision == OfferDecision.accepted && expiresAt.isAfter(now);
  bool canRespond(DateTime now) => decision == null && expiresAt.isAfter(now);
  MerchantOffer withDecision(OfferDecision value) => MerchantOffer(
    id: id,
    brand: brand,
    title: title,
    description: description,
    rewardRupees: rewardRupees,
    expiresAt: expiresAt,
    decision: value,
  );
}

class PaymentRecord {
  const PaymentRecord({
    required this.id,
    required this.from,
    required this.description,
    required this.amountPaise,
    required this.date,
    required this.status,
    this.method = 'Bank transfer · •• 2048',
  });
  final String id, from, description, method;
  final int amountPaise;
  final DateTime date;
  final RecordStatus status;
}

class InteractionDay {
  const InteractionDay(
    this.date,
    this.views,
    this.productTaps,
    this.offerOpens,
  );
  final DateTime date;
  final int views, productTaps, offerOpens;
}

class ChatMessage {
  const ChatMessage({
    required this.id,
    required this.text,
    required this.sentAt,
    required this.fromMerchant,
  });
  final String id, text;
  final DateTime sentAt;
  final bool fromMerchant;
  Map<String, Object> toJson() => {
    'id': id,
    'text': text,
    'sentAt': sentAt.toIso8601String(),
    'fromMerchant': fromMerchant,
  };
  factory ChatMessage.fromJson(Map<String, dynamic> json) => ChatMessage(
    id: json['id'] as String,
    text: json['text'] as String,
    sentAt: DateTime.parse(json['sentAt'] as String),
    fromMerchant: json['fromMerchant'] as bool,
  );
}

class Conversation {
  Conversation({
    required this.id,
    required this.name,
    required this.role,
    required List<ChatMessage> messages,
    required this.unread,
  }) : messages = List.unmodifiable(messages);
  final String id, name;
  final ChatRole role;
  final int unread;
  final List<ChatMessage> messages;
  Conversation copy({List<ChatMessage>? messages, int? unread}) => Conversation(
    id: id,
    name: name,
    role: role,
    messages: messages ?? this.messages,
    unread: unread ?? this.unread,
  );
}

class MerchantSnapshot {
  MerchantSnapshot({
    required this.profile,
    required List<MerchantRequest> requests,
    required List<MerchantOffer> offers,
    required List<PaymentRecord> payments,
    required List<InteractionDay> interactions,
    required List<Conversation> conversations,
  }) : requests = List.unmodifiable(requests),
       offers = List.unmodifiable(offers),
       payments = List.unmodifiable(payments),
       interactions = List.unmodifiable(interactions),
       conversations = List.unmodifiable(conversations);
  final AnchorProfile profile;
  final List<MerchantRequest> requests;
  final List<MerchantOffer> offers;
  final List<PaymentRecord> payments;
  final List<InteractionDay> interactions;
  final List<Conversation> conversations;
}
