import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../avatar.dart';
import '../models.dart';
import '../state.dart';
import '../theme.dart';
import 'rooms.dart';
import 'studio.dart';

/// Demo viewer numbers are labelled as demo everywhere — never real.
int demoViewers(String id) {
  switch (id) {
    case 'mikachan':
      return 1240;
    case 'sakura':
      return 860;
    case 'kiko':
      return 540;
    default:
      return 320;
  }
}

class LiveDiscoveryScreen extends StatefulWidget {
  const LiveDiscoveryScreen({super.key});
  @override
  State<LiveDiscoveryScreen> createState() => _LiveDiscoveryScreenState();
}

class _LiveDiscoveryScreenState extends State<LiveDiscoveryScreen> {
  String _cat = 'All';
  @override
  Widget build(BuildContext context) {
    final live = demoCreators.where((c) => c.isLive).toList();
    final filtered = _cat == 'All' ? live : live.where((c) => c.category == _cat).toList();
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const PixelText('LIVE NOW', size: 24, color: KazumiColors.pinkDeep),
        const SizedBox(height: 4),
        const DemoLabel('Viewer counts below are demo data, not real viewers.'),
        const SizedBox(height: 12),
        FilledButton.icon(
          onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const StudioScreen())),
          icon: const Icon(Icons.videocam_outlined),
          label: const Text('Go LIVE'),
        ),
        const SizedBox(height: 14),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: ['All', 'Just Chatting', 'Music', 'Gaming', 'Art'].map((c) {
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: PixelChip(label: c, selected: _cat == c, onTap: () => setState(() => _cat = c)),
              );
            }).toList(),
          ),
        ),
        const SizedBox(height: 14),
        if (filtered.isEmpty) const PixelCard(child: Text('Nobody is live in this category right now. Try another category or Go LIVE yourself!')),
        ...filtered.map((c) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: PixelCard(
                onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => WatchScreen(creator: c))),
                child: Row(
                  children: [
                    AnimatedAvatar(style: c.style, portraitAsset: c.portrait, size: 72, pendant: c.id == 'mikachan', animate: false),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(children: [
                            Text(c.name, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
                            const SizedBox(width: 6),
                            Container(padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2), decoration: BoxDecoration(color: Colors.red, borderRadius: BorderRadius.circular(6)), child: const Text('LIVE', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w800))),
                          ]),
                          Text(c.room == 'Gaming' ? 'Gaming LIVE · ${c.category}' : 'My Room LIVE · ${c.category}', style: const TextStyle(color: KazumiColors.inkSoft)),
                          Text('Demo viewers: ~${demoViewers(c.id)} (demo data)', style: const TextStyle(fontSize: 12, color: KazumiColors.inkSoft)),
                        ],
                      ),
                    ),
                    const Icon(Icons.chevron_right),
                  ],
                ),
              ),
            )),
      ],
    );
  }
}

class WatchScreen extends StatefulWidget {
  final Creator creator;
  const WatchScreen({super.key, required this.creator});
  @override
  State<WatchScreen> createState() => _WatchScreenState();
}

class _WatchScreenState extends State<WatchScreen> {
  bool _loading = true;
  bool _showChat = true;
  final _chatCtrl = TextEditingController();
  double _tilt = 0.15;

  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(milliseconds: 600), () {
      if (mounted) setState(() => _loading = false);
    });
  }

  @override
  void dispose() {
    _chatCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<KazumiState>();
    final c = widget.creator;
    final following = state.isFollowing(c.id);
    final messages = (state.liveChats[c.id] ?? []).where((m) => !m.hidden).toList();
    return Scaffold(
      appBar: AppBar(
        title: Text('${c.name} — ${c.room} LIVE'),
        actions: [
          IconButton(
            icon: const Icon(Icons.flag_outlined),
            tooltip: 'Report stream',
            onPressed: () => _report(context),
          ),
        ],
      ),
      body: PixelBackground(
        child: _loading
            ? const Center(child: Column(mainAxisSize: MainAxisSize.min, children: [CircularProgressIndicator(), SizedBox(height: 12), Text('Loading stream…')]))
            : !c.isLive
                ? _OfflineView(creator: c)
                : ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      SizedBox(
                        height: 300,
                        child: c.room == 'Gaming'
                            ? GamingStage(style: c.style, avatarSize: 92)
                            : PixelBedroom(style: c.style, avatarSize: 180, tilt: _tilt, pendant: c.id == 'mikachan'),
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          AnimatedAvatar(style: c.style, portraitAsset: c.portrait, size: 52, pendant: c.id == 'mikachan', animate: false),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(c.name, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 17)),
                                Text('${c.handle} · ${c.followers} followers', style: const TextStyle(color: KazumiColors.inkSoft)),
                                Text('Demo viewers: ~${demoViewers(c.id)} (demo data, not real)', style: const TextStyle(fontSize: 12, color: KazumiColors.inkSoft)),
                              ],
                            ),
                          ),
                          AnimatedSwitcher(
                            duration: const Duration(milliseconds: 350),
                            switchInCurve: Curves.easeOutCubic,
                            switchOutCurve: Curves.easeInCubic,
                            transitionBuilder: (child, anim) => FadeTransition(opacity: anim, child: ScaleTransition(scale: anim, child: child)),
                            child: following
                                ? OutlinedButton(key: const ValueKey('following'), onPressed: () => state.toggleFollow(c.id), child: const Text('Following ✓'))
                                : FilledButton(key: const ValueKey('follow'), onPressed: () => state.toggleFollow(c.id), child: const Text('Follow')),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(c.bio, style: const TextStyle(color: KazumiColors.inkSoft)),
                      const SizedBox(height: 10),
                      // Smooth head-tilt control: glides, never snaps.
                      Row(
                        children: [
                          const Text('Head tilt', style: TextStyle(fontWeight: FontWeight.w700)),
                          Expanded(
                            child: Slider(
                              value: _tilt,
                              min: -1,
                              max: 1,
                              onChanged: (v) => setState(() => _tilt = v),
                            ),
                          ),
                          IconButton(
                            icon: Icon(_showChat ? Icons.chat_bubble_outline : Icons.chat_bubble),
                            tooltip: 'Toggle chat',
                            onPressed: () => setState(() => _showChat = !_showChat),
                          ),
                        ],
                      ),
                      Row(
                        children: ['❤️', '⭐', '🔥', '🎉'].map((e) {
                          return Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: AnimatedScale(
                              scale: 1,
                              duration: const Duration(milliseconds: 300),
                              curve: Curves.easeOutBack,
                              child: OutlinedButton(
                                onPressed: () => state.addReaction(c.id, e),
                                child: Text(e, style: const TextStyle(fontSize: 18)),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 4),
                      Text('Reactions sent: ${state.liveReactions[c.id] ?? 0}'),
                      const SizedBox(height: 12),
                      if (_showChat) ...[
                        const PixelText('Live chat', size: 17),
                        const Text('Demo chat lines are labelled demo data. Your messages are saved locally.', style: TextStyle(fontSize: 12, color: KazumiColors.inkSoft)),
                        const SizedBox(height: 8),
                        ...messages.map((m) {
                          final mine = m.sender == 'You';
                          return TweenAnimationBuilder<double>(
                            key: ValueKey(m.id),
                            tween: Tween<double>(begin: 0, end: 1),
                            duration: const Duration(milliseconds: 300),
                            curve: Curves.easeOutCubic,
                            builder: (context, v, child) {
                              return Opacity(
                                opacity: v,
                                child: Transform.translate(offset: Offset(0, (1 - v) * 10), child: child),
                              );
                            },
                            child: Align(
                              alignment: mine ? Alignment.centerRight : Alignment.centerLeft,
                              child: Container(
                                margin: const EdgeInsets.only(bottom: 8),
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                decoration: BoxDecoration(
                                  color: mine ? KazumiColors.lavender : Colors.white,
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(color: KazumiColors.lavender),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text(m.sender, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 12)),
                                        if (!mine) ...[
                                          const SizedBox(width: 6),
                                          InkWell(
                                            onTap: () => state.hideLiveMessage(c.id, m.id),
                                            child: const Text('Hide (creator tools)', style: TextStyle(fontSize: 11, color: KazumiColors.pinkDeep, decoration: TextDecoration.underline)),
                                          ),
                                        ],
                                      ],
                                    ),
                                    Text(m.text),
                                  ],
                                ),
                              ),
                            ),
                          );
                        }),
                        Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: _chatCtrl,
                                decoration: const InputDecoration(hintText: 'Say something nice…', border: OutlineInputBorder()),
                                onSubmitted: (_) => _send(state),
                              ),
                            ),
                            const SizedBox(width: 8),
                            FilledButton(onPressed: () => _send(state), child: const Text('Send')),
                          ],
                        ),
                      ],
                    ],
                  ),
      ),
    );
  }

  void _send(KazumiState state) {
    final t = _chatCtrl.text;
    if (t.trim().isEmpty) return;
    state.sendLiveChat(widget.creator.id, t);
    _chatCtrl.clear();
  }

  void _report(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Report stream'),
        content: const Text('Reports are stored locally in v1 — there is no server review yet. The stream will also be hidden from your feed for this session if you confirm.'),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('Cancel')),
          FilledButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Report recorded locally. Thank you.')));
            },
            child: const Text('Report'),
          ),
        ],
      ),
    );
  }
}

class _OfflineView extends StatelessWidget {
  final Creator creator;
  const _OfflineView({required this.creator});
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedAvatar(style: creator.style, portraitAsset: creator.portrait, size: 130, animate: false),
            const SizedBox(height: 12),
            const PixelText('Currently offline', size: 20),
            Text('${creator.name} is not live right now.', style: const TextStyle(color: KazumiColors.inkSoft)),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Browse live creators'),
            ),
          ],
        ),
      ),
    );
  }
}
