import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../core/formatters.dart';
import '../../core/models.dart';
import '../../pages/widgets/dashboard_card.dart';
import '../../pages/widgets/dashboard_theme.dart';
import '../../shared/widgets/merchant_widgets.dart';
import '../shell/merchant_controller.dart';

class ChatsPage extends StatefulWidget {
  const ChatsPage({super.key, required this.controller});
  final MerchantController controller;
  @override
  State<ChatsPage> createState() => _ChatsPageState();
}

class _ChatsPageState extends State<ChatsPage> {
  ChatRole? _role;
  String _query = '';
  @override
  Widget build(BuildContext context) {
    final chats =
        widget.controller.data!.conversations
            .where(
              (c) =>
                  (_role == null || c.role == _role) &&
                  c.name.toLowerCase().contains(_query.trim().toLowerCase()),
            )
            .toList()
          ..sort(
            (a, b) => (b.messages.lastOrNull?.sentAt ?? DateTime(2000))
                .compareTo(a.messages.lastOrNull?.sentAt ?? DateTime(2000)),
          );
    return FeatureList(
      children: [
        const SectionTitle(
          'Conversations',
          subtitle: 'Your brands, masters and customers.',
        ),
        const Notice('Demo chats. Messages are saved on this device only.'),
        TextField(
          onChanged: (v) => setState(() => _query = v),
          decoration: const InputDecoration(
            labelText: 'Search conversations',
            prefixIcon: Icon(Icons.search),
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 16),
        FilterChips<ChatRole?>(
          values: [null, ...ChatRole.values],
          selected: _role,
          label: (v) => v == null ? 'Everyone' : '${v.label}s',
          onChanged: (v) => setState(() => _role = v),
        ),
        if (chats.isEmpty)
          const EmptyState(
            title: 'No conversations found',
            message: 'Try another name or role.',
          ),
        ...chats.map(
          (c) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: InkWell(
              borderRadius: BorderRadius.circular(20),
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute<void>(
                  builder: (_) => ConversationPage(
                    controller: widget.controller,
                    conversationId: c.id,
                  ),
                ),
              ),
              child: DashboardCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        CircleAvatar(
                          backgroundColor: DashboardTheme.iconBackground,
                          child: Text(c.name[0]),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            c.name,
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                        ),
                        if (c.unread > 0)
                          Badge(
                            label: Text('${c.unread}'),
                            child: const Icon(Icons.mark_chat_unread_outlined),
                          ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    StatusPill(c.role.label),
                    const SizedBox(height: 10),
                    Text(
                      c.messages.lastOrNull?.text ?? 'Start the conversation',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (c.messages.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Text(
                        '${dateLabel(c.messages.last.sentAt)} · ${timeLabel(c.messages.last.sentAt)}',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class ConversationPage extends StatefulWidget {
  const ConversationPage({
    super.key,
    required this.controller,
    required this.conversationId,
  });
  final MerchantController controller;
  final String conversationId;
  @override
  State<ConversationPage> createState() => _ConversationPageState();
}

class _ConversationPageState extends State<ConversationPage> {
  final _message = TextEditingController();
  String? _error;
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _markRead());
  }

  Future<void> _markRead() async {
    final error = await widget.controller.perform(
      'read-${widget.conversationId}',
      () => widget.controller.repository.markConversationRead(
        widget.conversationId,
      ),
    );
    if (mounted) setState(() => _error = error);
  }

  @override
  void dispose() {
    _message.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final text = _message.text;
    if (text.trim().isEmpty) return;
    setState(() => _error = null);
    final error = await widget.controller.perform(
      'send-${widget.conversationId}',
      () =>
          widget.controller.repository.sendMessage(widget.conversationId, text),
    );
    if (!mounted) return;
    setState(() {
      _error = error;
      if (error == null) _message.clear();
    });
  }

  @override
  Widget build(BuildContext context) => GetBuilder<MerchantController>(
    init: widget.controller,
    global: false,
    builder: (c) {
      final chat = c.data!.conversations.firstWhere(
        (x) => x.id == widget.conversationId,
      );
      final busy = c.busy('send-${chat.id}');
      return Scaffold(
        appBar: AppBar(title: Text(chat.name)),
        body: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Notice(
                  '${chat.role.label} conversation · Local demo messages only',
                ),
              ),
              Expanded(
                child: chat.messages.isEmpty
                    ? const EmptyState(
                        title: 'No messages yet',
                        message: 'Say hello to start this demo conversation.',
                      )
                    : ListView.builder(
                        reverse: true,
                        padding: const EdgeInsets.all(16),
                        itemCount: chat.messages.length,
                        itemBuilder: (context, index) {
                          final m =
                              chat.messages[chat.messages.length - index - 1];
                          return Align(
                            alignment: m.fromMerchant
                                ? Alignment.centerRight
                                : Alignment.centerLeft,
                            child: Container(
                              constraints: BoxConstraints(
                                maxWidth: MediaQuery.sizeOf(context).width * .8,
                              ),
                              margin: const EdgeInsets.only(bottom: 12),
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: m.fromMerchant
                                    ? DashboardTheme.iconBackground
                                    : DashboardTheme.surface,
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(m.text),
                                  const SizedBox(height: 8),
                                  Text(
                                    '${dateLabel(m.sentAt)} · ${timeLabel(m.sentAt)}${m.fromMerchant ? ' · Local' : ''}',
                                    style: Theme.of(context)
                                        .textTheme
                                        .labelSmall
                                        ?.copyWith(
                                          color: DashboardTheme.secondary,
                                        ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
              ),
              if (_error != null)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Notice(_error!, error: true),
                ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _message,
                        enabled: !busy,
                        maxLength: 1000,
                        minLines: 1,
                        maxLines: 4,
                        onChanged: (_) => setState(() {}),
                        decoration: const InputDecoration(
                          labelText: 'Message',
                          hintText: 'Write a local demo message',
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton.filled(
                      tooltip: 'Send message',
                      onPressed: busy || _message.text.trim().isEmpty
                          ? null
                          : _send,
                      icon: busy
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.send),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    },
  );
}
