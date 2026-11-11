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

/// Pulsing red LIVE dot — soft scale + fade, eased, never snapping.
class _LivePulse extends StatefulWidget {
  const _LivePulse();
  @override
  State<_LivePulse> createState() => _LivePulseState();
}

class _LivePulseState extends State<_LivePulse> with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 1100))..repeat(reverse: true);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (context, _) {
        final v = 0.55 + 0.45 * _ctrl.value;
        return Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            color: Colors.red.withValues(alpha: v),
            shape: BoxShape.circle,
            boxShadow: [BoxShadow(color: Colors.red.withValues(alpha: 0.5 * v), blurRadius: 6 + 4 * _ctrl.value)],
          ),
        );
      },
    );
  }
}

class _FloatReact {
  final int id;
  final String emoji;
  final double x; // 0..1 across the right side
  _FloatReact({required this.id, required this.emoji, required this.x});
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
  LiveExpression _expression = LiveExpression.normal;
  final List<_FloatReact> _floats = [];
  int _floatId = 0;

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

  void _react(KazumiState state, String emoji) {
    state.addReaction(widget.creator.id, emoji);
    final id = _floatId++;
    setState(() => _floats.add(_FloatReact(id: id, emoji: emoji, x: ((_floatId * 37) % 10) / 10)));
    Future.delayed(const Duration(milliseconds: 1450), () {
      if (mounted) setState(() => _floats.removeWhere((f) => f.id == id));
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<KazumiState>();
    final c = widget.creator;
    final following = state.isFollowing(c.id);
    final messages = (state.liveChats[c.id] ?? []).where((m) => !m.hidden).toList();
    final recent = messages.length > 3 ? messages.sublist(messages.length - 3) : messages;
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
      body: _loading
          ? const Center(child: Column(mainAxisSize: MainAxisSize.min, children: [CircularProgressIndicator(), SizedBox(height: 12), Text('Loading stream…')]))
          : !c.isLive
              ? _OfflineView(creator: c)
              : Column(
                  children: [
                    // Full immersive stage — the room fills the screen area,
                    // chat + reactions float over it, nothing is a 300px box.
                    Expanded(
                      flex: 5,
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            c.room == 'Gaming'
                                ? GamingStage(style: c.style, portraitAsset: c.portrait, avatarSize: 92, expression: _expression)
                                : PixelBedroom(style: c.style, portraitAsset: c.portrait, tilt: _tilt, pendant: c.id == 'mikachan', expression: _expression),
                            // Top scrim + name plate + LIVE badge + demo viewers.
                            Positioned(
                              top: 0,
                              left: 0,
                              right: 0,
                              child: Container(
                                padding: const EdgeInsets.fromLTRB(14, 12, 14, 20),
                                decoration: const BoxDecoration(
                                  gradient: LinearGradient(
                                    begin: Alignment.topCenter,
                                    end: Alignment.bottomCenter,
                                    colors: [Color(0xCC000000), Color(0x00000000)],
                                  ),
                                  borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                                ),
                                child: Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                                      decoration: BoxDecoration(color: Colors.red, borderRadius: BorderRadius.circular(8)),
                                      child: const Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [ _LivePulse(), SizedBox(width: 6), Text('LIVE', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w800))],
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(c.name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 16, shadows: [Shadow(color: Colors.black54, blurRadius: 4)])),
                                          Text(
                                            '${c.handle} · Demo viewers: ~${demoViewers(c.id)} (demo data, not real)',
                                            style: const TextStyle(color: Colors.white, fontSize: 11, shadows: [Shadow(color: Colors.black54, blurRadius: 4)]),
                                          ),
                                        ],
                                      ),
                                    ),
                                    AnimatedSwitcher(
                                      duration: const Duration(milliseconds: 350),
                                      switchInCurve: Curves.easeOutCubic,
                                      switchOutCurve: Curves.easeInCubic,
                                      transitionBuilder: (child, anim) => FadeTransition(opacity: anim, child: ScaleTransition(scale: anim, child: child)),
                                      child: following
                                          ? OutlinedButton(
                                              key: const ValueKey('following'),
                                              style: OutlinedButton.styleFrom(backgroundColor: Colors.white, foregroundColor: KazumiColors.ink),
                                              onPressed: () => state.toggleFollow(c.id),
                                              child: const Text('Following ✓'),
                                            )
                                          : FilledButton(key: const ValueKey('follow'), onPressed: () => state.toggleFollow(c.id), child: const Text('Follow')),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            // Floating reactions rising over the stage.
                            ..._floats.map((f) {
                              return Positioned(
                                right: 18 + f.x * 70,
                                bottom: 148,
                                child: TweenAnimationBuilder<double>(
                                  tween: Tween<double>(begin: 0, end: 1),
                                  duration: const Duration(milliseconds: 1400),
                                  curve: Curves.easeOutCubic,
                                  builder: (context, v, child) {
                                    return Opacity(
                                      opacity: 1 - v,
                                      child: Transform.translate(offset: Offset(0, -v * 130), child: child),
                                    );
                                  },
                                  child: Text(f.emoji, style: const TextStyle(fontSize: 30)),
                                ),
                              );
                            }),
                            // Chat overlay at the bottom of the stage.
                            if (_showChat)
                              Positioned(
                                left: 0,
                                right: 0,
                                bottom: 0,
                                child: Container(
                                  padding: const EdgeInsets.fromLTRB(12, 18, 12, 10),
                                  decoration: const BoxDecoration(
                                    gradient: LinearGradient(
                                      begin: Alignment.topCenter,
                                      end: Alignment.bottomCenter,
                                      colors: [Color(0x00000000), Color(0xD9000000)],
                                    ),
                                    borderRadius: BorderRadius.vertical(bottom: Radius.circular(24)),
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Text('Live chat · demo lines', style: TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.w700)),
                                      const SizedBox(height: 4),
                                      ...recent.map((m) => Padding(
                                            padding: const EdgeInsets.only(bottom: 2),
                                            child: Text.rich(
                                              TextSpan(
                                                children: [
                                                  TextSpan(text: '${m.sender}  ', style: const TextStyle(color: Color(0xFFFFB7D5), fontWeight: FontWeight.w800, fontSize: 12)),
                                                  TextSpan(text: m.text, style: const TextStyle(color: Colors.white, fontSize: 12)),
                                                ],
                                              ),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          )),
                                      const SizedBox(height: 6),
                                      Row(
                                        children: [
                                          Expanded(
                                            child: TextField(
                                              controller: _chatCtrl,
                                              style: const TextStyle(color: Colors.white, fontSize: 13),
                                              decoration: InputDecoration(
                                                hintText: 'Say something nice…',
                                                hintStyle: const TextStyle(color: Colors.white54, fontSize: 13),
                                                filled: true,
                                                fillColor: Colors.white.withValues(alpha: 0.18),
                                                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(20), borderSide: BorderSide.none),
                                              ),
                                              onSubmitted: (_) => _send(state),
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          ...['❤️', '⭐', '🔥'].map((e) => Padding(
                                                padding: const EdgeInsets.only(right: 4),
                                                child: InkWell(
                                                  onTap: () => _react(state, e),
                                                  borderRadius: BorderRadius.circular(20),
                                                  child: Container(
                                                    padding: const EdgeInsets.all(7),
                                                    decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.2), shape: BoxShape.circle),
                                                    child: Text(e, style: const TextStyle(fontSize: 16)),
                                                  ),
                                                ),
                                              )),
                                          FilledButton(onPressed: () => _send(state), child: const Text('Send')),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                    // Controls below the stage.
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(c.bio, style: const TextStyle(color: KazumiColors.inkSoft)),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              const Text('Expression', style: TextStyle(fontWeight: FontWeight.w700)),
                              const SizedBox(width: 8),
                              ...LiveExpression.values.map((e) => Padding(
                                    padding: const EdgeInsets.only(right: 6),
                                    child: PixelChip(label: e.label, selected: _expression == e, onTap: () => setState(() => _expression = e)),
                                  )),
                            ],
                          ),
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
                                tooltip: 'Toggle chat overlay',
                                onPressed: () => setState(() => _showChat = !_showChat),
                              ),
                            ],
                          ),
                          Text('Reactions sent: ${state.liveReactions[c.id] ?? 0} · Demo stream — viewers and chat lines are demo data, not a real broadcast.', style: const TextStyle(fontSize: 12, color: KazumiColors.inkSoft)),
                        ],
                      ),
                    ),
                  ],
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
            LiveAnimeRig(style: creator.style, portraitAsset: creator.portrait, height: 300, animate: false),
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
