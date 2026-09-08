import '../models.dart';

MerchantSnapshot demoFixtures(DateTime now) {
  DateTime ago(int days, [int hour = 11]) =>
      DateTime(now.year, now.month, now.day - days, hour);
  return MerchantSnapshot(
    profile: const AnchorProfile(),
    requests: [
      MerchantRequest(
        id: 'REQ-1042',
        brand: 'Earth & Grain',
        title: 'Organic pantry collection',
        kind: RequestKind.product,
        status: RequestStatus.pending,
        date: ago(0),
        category: 'Food & beverages',
        description:
            'Proposal to feature six organic pantry products at your anchor. Includes a product display and a two-week discovery campaign.',
      ),
      MerchantRequest(
        id: 'REQ-1041',
        brand: 'Daily Brew',
        title: 'Meet your neighbourhood coffee',
        kind: RequestKind.brand,
        status: RequestStatus.pending,
        date: ago(1),
        category: 'Food & beverages',
        description:
            'A brand discovery placement for local coffee lovers. Requested display period: 14 days. Brand artwork will be supplied.',
      ),
      MerchantRequest(
        id: 'REQ-1038',
        brand: 'Leaf Home',
        title: 'Refill essentials',
        kind: RequestKind.product,
        status: RequestStatus.approved,
        date: ago(3),
        category: 'Home & living',
        description:
            'Three refillable cleaning products for the household essentials display. Demo approval was recorded before this session.',
      ),
      MerchantRequest(
        id: 'REQ-1035',
        brand: 'Stride',
        title: 'Weekend essentials campaign',
        kind: RequestKind.brand,
        status: RequestStatus.declined,
        date: ago(8),
        category: 'Lifestyle',
        description:
            'A weekend brand placement proposal. Demo decline reason: category does not match the current anchor.',
      ),
      MerchantRequest(
        id: 'REQ-1032',
        brand: 'Sunfield',
        title: 'Cold-pressed juices',
        kind: RequestKind.product,
        status: RequestStatus.pending,
        date: ago(12),
        category: 'Food & beverages',
        description:
            'Feature four seasonal juices for seven days. Stock and placement terms are to be agreed with the brand.',
      ),
    ],
    offers: [
      MerchantOffer(
        id: 'OFF-208',
        brand: 'Daily Brew',
        title: 'A little coffee. More discovery.',
        description:
            'Feature Daily Brew at your anchor for 7 days. The sample placement reward is ₹2,400. Accepting only updates this local demo; it does not create a payment.',
        rewardRupees: 2400,
        expiresAt: ago(-7),
      ),
      MerchantOffer(
        id: 'OFF-201',
        brand: 'Leaf Home',
        title: 'Everyday essentials, thoughtfully made',
        description: 'A 14-day home essentials placement at Corner Market.',
        rewardRupees: 1800,
        expiresAt: ago(-14),
        decision: OfferDecision.accepted,
      ),
    ],
    payments: [
      PaymentRecord(
        id: 'TXN-2026-0186',
        from: 'Leaf Home',
        description: 'September placement · installment 1',
        amountPaise: 850000,
        date: ago(0, 10),
        status: RecordStatus.received,
      ),
      PaymentRecord(
        id: 'TXN-2026-0185',
        from: 'Earth & Grain',
        description: 'Product discovery campaign',
        amountPaise: 620000,
        date: ago(2, 14),
        status: RecordStatus.received,
      ),
      PaymentRecord(
        id: 'TXN-2026-0184',
        from: 'Daily Brew',
        description: 'Previous campaign settlement',
        amountPaise: 240000,
        date: ago(4, 16),
        status: RecordStatus.pending,
      ),
      PaymentRecord(
        id: 'TXN-2026-0183',
        from: 'Sunfield',
        description: 'Seasonal display placement',
        amountPaise: 375000,
        date: ago(6),
        status: RecordStatus.received,
      ),
      PaymentRecord(
        id: 'TXN-2026-0179',
        from: 'Stride',
        description: 'Bank transfer unsuccessful',
        amountPaise: 160000,
        date: ago(10),
        status: RecordStatus.failed,
      ),
      PaymentRecord(
        id: 'TXN-2026-0174',
        from: 'Leaf Home',
        description: 'August discovery campaign',
        amountPaise: 980000,
        date: ago(19),
        status: RecordStatus.received,
      ),
      PaymentRecord(
        id: 'TXN-2026-0162',
        from: 'Sunfield',
        description: 'Cancelled placement refund',
        amountPaise: 125000,
        date: ago(35),
        status: RecordStatus.refunded,
      ),
    ],
    interactions: List.generate(
      45,
      (i) => InteractionDay(
        ago(i, 0),
        42 + (i * 17 % 93),
        12 + (i * 7 % 31),
        4 + (i * 3 % 16),
      ),
    ),
    conversations: [
      Conversation(
        id: 'chat-brand',
        name: 'Daily Brew',
        role: ChatRole.brand,
        unread: 2,
        messages: [
          ChatMessage(
            id: 'b1',
            text:
                'Hi Aarav! We would love to feature our coffee at Corner Market.',
            sentAt: ago(1, 10),
            fromMerchant: false,
          ),
          ChatMessage(
            id: 'b2',
            text: 'Please share the placement details.',
            sentAt: ago(1, 11),
            fromMerchant: true,
          ),
          ChatMessage(
            id: 'b3',
            text: 'The proposal is ready. You can review it in your offers.',
            sentAt: ago(0, 9),
            fromMerchant: false,
          ),
        ],
      ),
      Conversation(
        id: 'chat-master',
        name: 'Priya · Pune Master',
        role: ChatRole.master,
        unread: 1,
        messages: [
          ChatMessage(
            id: 'm1',
            text:
                'Your merchant anchor is linked. Let me know if you need help with the display.',
            sentAt: ago(0, 8),
            fromMerchant: false,
          ),
        ],
      ),
      Conversation(
        id: 'chat-user',
        name: 'Riya Mehta',
        role: ChatRole.user,
        unread: 0,
        messages: [
          ChatMessage(
            id: 'u1',
            text: 'Are the refill essentials available at your anchor?',
            sentAt: ago(2, 12),
            fromMerchant: false,
          ),
          ChatMessage(
            id: 'u2',
            text: 'Yes, you can find them near the entrance.',
            sentAt: ago(2, 13),
            fromMerchant: true,
          ),
        ],
      ),
    ],
  );
}
