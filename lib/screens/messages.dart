import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../avatar.dart';
import '../models.dart';
import '../state.dart';
import '../theme.dart';

Conversation _convoFor(String id, KazumiState state) {
  final creator = demoCreators.where((c) => c.id == id).toList();
  if (creator.isNotEmpty) return Conversation(id: id, name: creator.first.name, style: creator.first.style);
  if (id == 'req_1') return Conversation(id: id, name: 'PixelFan99', style: const AvatarStyle(hairStyle: 'Short Bob', hairColor: Color(0xFFFFD166), eyeColor: Color(0xFFB45309), outfit: 'Gaming Tee', accessory: 'None'), isRequest: true);
  return Conversation(id: id, name: id, style: const AvatarStyle());
}

class MessagesScreen extends StatefulWidget {
  const MessagesScreen({super.key});
  @override
  State<MessagesScreen> createState() => _MessagesScreenState();
}

class _MessagesScreenState extends State<MessagesScreen> {
  String _tab = 'All';
  String _query = '';
  @override
  Widget build(BuildContext context) {
    final state = context.watch<KazumiState>();
    // Blocked conversations are hidden/filtered — they cannot bypass via requests.
    final all = state.chats.keys.where((id) => !state.blocked.contains(id)).map((id) => _convoFor(id, state)).toList();
    List<Conversation> shown;
    if (_tab == 'Requests') {
      shown = all.where((c) => c.isRequest).toList();
    } else if (_tab == 'Unread') {
      shown = all.where((c) {
        final msgs = state.chats[c.id] ?? [];
        return msgs.isNotEmpty && msgs.last.sender != 'You' && !c.isRequest;
      }).toList();
    } else {
      shown = all.where((c) => !c.isRequest).toList();
    }
    if (_query.isNotEmpty) {
      shown = shown.where((c) => c.name.toLowerCase().contains(_query.toLowerCase())).toList();
    }
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const PixelText('MESSAGES', size: 24, color: KazumiColors.pinkDeep),
              const SizedBox(height: 10),
              TextField(
                decoration: const InputDecoration(prefixIcon: Icon(Icons.search), hintText: 'Search conversations…', border: OutlineInputBorder(), filled: true, fillColor: Colors.white),
                onChanged: (v) => setState(() => _query = v),
              ),
              const SizedBox(height: 10),
              Row(
                children: ['All', 'Unread', 'Requests'].map((t) {
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: PixelChip(label: t, selected: _tab == t, onTap: () => setState(() => _tab = t)),
                  );
                }).toList(),
              ),
            ],
          ),
        ),
        Expanded(
          child: shown.isEmpty
              ? const Center(child: Text('No conversations here yet.'))
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: shown.length,
                  itemBuilder: (context, i) {
                    final convo = shown[i];
                    final msgs = state.chats[convo.id] ?? [];
                    final last = msgs.isEmpty ? 'No messages yet' : msgs.last.text;
                    final unread = msgs.isNotEmpty && msgs.last.sender != 'You';
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: PixelCard(
                        onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => ChatDetailScreen(conversation: convo))),
                        child: Row(
                          children: [
                            AnimatedAvatar(style: convo.style, size: 52, animate: false),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Expanded(child: Text(convo.name, style: const TextStyle(fontWeight: FontWeight.w800))),
                                      if (unread) Container(width: 10, height: 10, decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle)),
                                    ],
                                  ),
                                  Text(last, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: KazumiColors.inkSoft)),
                                  if (convo.isRequest) const Text('Message request', style: TextStyle(fontSize: 12, color: KazumiColors.pinkDeep, fontWeight: FontWeight.w700)),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }
}

class ChatDetailScreen extends StatefulWidget {
  final Conversation conversation;
  const ChatDetailScreen({super.key, required this.conversation});
  @override
  State<ChatDetailScreen> createState() => _ChatDetailScreenState();
}

class _ChatDetailScreenState extends State<ChatDetailScreen> {
  final _ctrl = TextEditingController();
  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<KazumiState>();
    final convo = widget.conversation;
    final msgs = state.chats[convo.id] ?? [];
    final blocked = state.blocked.contains(convo.id);
    final muted = state.muted.contains(convo.id);
    return Scaffold(
      appBar: AppBar(
        title: Text(convo.name),
        actions: [
          PopupMenuButton<String>(
            onSelected: (v) async {
              if (v == 'block') {
                await state.blockUser(convo.id);
                if (context.mounted) {
                  Navigator.of(context).pop();
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('${convo.name} blocked — their conversations and requests are now hidden.')));
                }
              } else if (v == 'mute') {
                await state.muteUser(convo.id);
                if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(muted ? '${convo.name} unmuted.' : '${convo.name} muted.')));
              } else if (v == 'report') {
                if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Report recorded locally. There is no server review in v1.')));
              }
            },
            itemBuilder: (_) => [
              PopupMenuItem(value: 'mute', child: Text(muted ? 'Unmute' : 'Mute')),
              const PopupMenuItem(value: 'block', child: Text('Block')),
              const PopupMenuItem(value: 'report', child: Text('Report')),
            ],
          ),
        ],
      ),
      body: PixelBackground(
        child: Column(
          children: [
            if (convo.isRequest)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                color: KazumiColors.gold.withValues(alpha: 0.4),
                child: const Text('This is a message request. Replying accepts it into your main inbox. Blocked users cannot reach you via requests.', style: TextStyle(fontSize: 13)),
              ),
            if (blocked) const Padding(padding: EdgeInsets.all(16), child: Text('This conversation is blocked and hidden from your inbox.')),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: msgs.length,
                itemBuilder: (context, i) {
                  final m = msgs[i];
                  final mine = m.sender == 'You';
                  return TweenAnimationBuilder<double>(
                    key: ValueKey(m.id),
                    tween: Tween<double>(begin: 0, end: 1),
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeOutCubic,
                    builder: (context, v, child) => Opacity(opacity: v, child: Transform.translate(offset: Offset(0, (1 - v) * 10), child: child)),
                    child: Align(
                      alignment: mine ? Alignment.centerRight : Alignment.centerLeft,
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(color: mine ? KazumiColors.lavender : Colors.white, borderRadius: BorderRadius.circular(14), border: Border.all(color: KazumiColors.lavender)),
                        child: Text(m.text),
                      ),
                    ),
                  );
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _ctrl,
                      decoration: const InputDecoration(hintText: 'Message…', border: OutlineInputBorder()),
                      onSubmitted: (_) => _send(state),
                    ),
                  ),
                  const SizedBox(width: 8),
                  FilledButton(onPressed: () => _send(state), child: const Text('Send')),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _send(KazumiState state) {
    final t = _ctrl.text;
    if (t.trim().isEmpty) return;
    state.sendMessage(widget.conversation.id, t);
    _ctrl.clear();
  }
}
