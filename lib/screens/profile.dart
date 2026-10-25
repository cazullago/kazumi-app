import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../avatar.dart';
import '../models.dart';
import '../state.dart';
import '../theme.dart';
import 'live.dart';
import 'messages.dart';
import 'settings.dart';
import 'store.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});
  @override
  Widget build(BuildContext context) {
    final state = context.watch<KazumiState>();
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Row(
          children: [
            const Expanded(child: PixelText('PROFILE', size: 24, color: KazumiColors.pinkDeep)),
            IconButton(
              icon: const Icon(Icons.settings_outlined),
              tooltip: 'Privacy & Safety',
              onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const SettingsScreen())),
            ),
          ],
        ),
        const SizedBox(height: 10),
        // Avatar is DISPLAY ONLY here. Appearance changes are Store-only.
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 400),
          switchInCurve: Curves.easeOutCubic,
          switchOutCurve: Curves.easeInCubic,
          transitionBuilder: (child, anim) => FadeTransition(opacity: anim, child: ScaleTransition(scale: Tween<double>(begin: 0.96, end: 1).animate(anim), child: child)),
          child: PixelCard(
            key: ValueKey(state.equippedSignature),
            child: Column(
              children: [
                AnimatedAvatar(style: state.userStyle, size: 170, tilt: 0.15),
                const SizedBox(height: 8),
                Text(state.userName, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 20)),
                Text(state.userBio, textAlign: TextAlign.center, style: const TextStyle(color: KazumiColors.inkSoft)),
                const SizedBox(height: 6),
                const DemoLabel(aiNotConnectedLabel),
                const SizedBox(height: 4),
                Text(
                  state.aiApproved ? 'Placeholder avatar approved — awaiting real AI generation.' : 'Placeholder avatar — not an AI likeness.',
                  style: const TextStyle(fontSize: 12, color: KazumiColors.inkSoft),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _Stat(label: 'Following', value: '${state.following.length}'),
            _Stat(label: 'Posts', value: '${state.userPosts.length}'),
            _Stat(label: 'Stars', value: '${state.stars}'),
          ],
        ),
        const SizedBox(height: 12),
        FilledButton(
          onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const StoreScreen())),
          child: const Text('Open Store — change your look here (Store-only)'),
        ),
        const SizedBox(height: 8),
        OutlinedButton(
          onPressed: () async {
            final nameCtrl = TextEditingController(text: state.userName);
            final bioCtrl = TextEditingController(text: state.userBio);
            final ok = await showDialog<bool>(
              context: context,
              builder: (ctx) => AlertDialog(
                title: const Text('Edit profile text'),
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Display name')),
                    TextField(controller: bioCtrl, decoration: const InputDecoration(labelText: 'Bio')),
                    const SizedBox(height: 8),
                    const Text('Name and bio only — avatar appearance can only change in the Store.', style: TextStyle(fontSize: 12, color: KazumiColors.inkSoft)),
                  ],
                ),
                actions: [
                  TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('Cancel')),
                  FilledButton(onPressed: () => Navigator.of(ctx).pop(true), child: const Text('Save')),
                ],
              ),
            );
            if (ok == true) {
              await state.updateProfileText(name: nameCtrl.text, bio: bioCtrl.text);
            }
          },
          child: const Text('Edit name & bio (not appearance)'),
        ),
        const SizedBox(height: 20),
        const PixelText('Your posts', size: 18),
        const SizedBox(height: 10),
        if (state.userPosts.isEmpty)
          const PixelCard(child: Text('No posts yet. Create one from the community feed — see Discover for creator posts, or post from your profile below.'))
        else
          ...state.userPosts.map((p) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: PixelCard(child: Text(p.text)),
              )),
        const SizedBox(height: 12),
        const PixelText('Create a post', size: 18),
        const SizedBox(height: 8),
        _CreatePostBox(),
      ],
    );
  }
}

class _Stat extends StatelessWidget {
  final String label;
  final String value;
  const _Stat({required this.label, required this.value});
  @override
  Widget build(BuildContext context) {
    return Column(children: [Text(value, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18)), Text(label, style: const TextStyle(color: KazumiColors.inkSoft))]);
  }
}

class _CreatePostBox extends StatefulWidget {
  @override
  State<_CreatePostBox> createState() => _CreatePostBoxState();
}

class _CreatePostBoxState extends State<_CreatePostBox> {
  final _ctrl = TextEditingController();
  String _kind = 'text';
  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = context.read<KazumiState>();
    return PixelCard(
      child: Column(
        children: [
          TextField(controller: _ctrl, maxLines: 3, decoration: const InputDecoration(hintText: 'Share something cozy…', border: OutlineInputBorder())),
          const SizedBox(height: 8),
          Row(
            children: ['text', 'room', 'photo'].map((k) {
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: PixelChip(label: k == 'text' ? 'Text' : k == 'room' ? 'Room' : 'Photo placeholder', selected: _kind == k, onTap: () => setState(() => _kind = k)),
              );
            }).toList(),
          ),
          const SizedBox(height: 8),
          if (_kind == 'photo') const Text('Photo posts use a placeholder frame in v1 — your photo stays on device until sharing connects.', style: TextStyle(fontSize: 12, color: KazumiColors.inkSoft)),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: () {
                state.addPost(_ctrl.text, _kind);
                _ctrl.clear();
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Post published locally.')));
              },
              child: const Text('Post'),
            ),
          ),
        ],
      ),
    );
  }
}

/// Another creator's profile: Follow + Message, tabs for posts/clips/rooms/achievements.
class CreatorProfileScreen extends StatefulWidget {
  final Creator creator;
  const CreatorProfileScreen({super.key, required this.creator});
  @override
  State<CreatorProfileScreen> createState() => _CreatorProfileScreenState();
}

class _CreatorProfileScreenState extends State<CreatorProfileScreen> with SingleTickerProviderStateMixin {
  late final TabController _tabs;
  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<KazumiState>();
    final c = widget.creator;
    final following = state.isFollowing(c.id);
    return Scaffold(
      appBar: AppBar(
        title: Text(c.name),
        actions: [
          PopupMenuButton<String>(
            onSelected: (v) async {
              if (v == 'block') {
                await state.blockUser(c.id);
                if (context.mounted) {
                  Navigator.of(context).pop();
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('${c.name} blocked.')));
                }
              } else if (v == 'report') {
                if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Report recorded locally. There is no server review in v1.')));
              }
            },
            itemBuilder: (_) => const [PopupMenuItem(value: 'block', child: Text('Block')), PopupMenuItem(value: 'report', child: Text('Report'))],
          ),
        ],
      ),
      body: PixelBackground(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            PixelCard(
              child: Column(
                children: [
                  AnimatedAvatar(style: c.style, portraitAsset: c.portrait, size: 150, tilt: 0.15, pendant: c.id == 'mikachan'),
                  const SizedBox(height: 8),
                  Text(c.name, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 20)),
                  Text(c.handle, style: const TextStyle(color: KazumiColors.inkSoft)),
                  Text(c.bio, textAlign: TextAlign.center, style: const TextStyle(color: KazumiColors.inkSoft)),
                  const SizedBox(height: 6),
                  Text('${c.followers} followers · ${c.category}${c.isLive ? ' · LIVE now' : ' · Offline'}'),
                  if (c.isLive) Text('Demo viewers: ~${demoViewers(c.id)} (demo data)', style: const TextStyle(fontSize: 12, color: KazumiColors.inkSoft)),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: AnimatedSwitcher(
                          duration: const Duration(milliseconds: 300),
                          transitionBuilder: (child, anim) => FadeTransition(opacity: anim, child: child),
                          child: following
                              ? OutlinedButton(key: const ValueKey('f'), onPressed: () => state.toggleFollow(c.id), child: const Text('Following ✓'))
                              : FilledButton(key: const ValueKey('u'), onPressed: () => state.toggleFollow(c.id), child: const Text('Follow')),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => ChatDetailScreen(conversation: Conversation(id: c.id, name: c.name, style: c.style)))),
                          child: const Text('Message'),
                        ),
                      ),
                    ],
                  ),
                  if (c.isLive) ...[
                    const SizedBox(height: 8),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton(onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => WatchScreen(creator: c))), child: const Text('Watch LIVE')),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 12),
            TabBar(
              controller: _tabs,
              labelColor: KazumiColors.pinkDeep,
              tabs: const [Tab(text: 'Posts'), Tab(text: 'Clips'), Tab(text: 'Rooms'), Tab(text: 'Stars')],
            ),
            SizedBox(
              height: 300,
              child: TabBarView(
                controller: _tabs,
                children: [
                  ListView(
                    children: [
                      PixelCard(child: Text('“${c.bio}” — latest update from ${c.name}.')),
                      const SizedBox(height: 10),
                      const PixelCard(child: Text('Cozy stream highlights and room tours land here.')),
                    ],
                  ),
                  ListView(
                    children: [
                      PixelCard(
                        onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => c.isLive ? WatchScreen(creator: c) : CreatorProfileScreen(creator: c))),
                        child: Text('▶ ${c.name} — lofi room tour clip (opens their stream/profile)'),
                      ),
                      const SizedBox(height: 10),
                      const PixelCard(child: Text('▶ Chill beats session — clip (demo listing)')),
                    ],
                  ),
                  ListView(
                    children: [
                      PixelCard(
                        onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => c.isLive ? WatchScreen(creator: c) : CreatorProfileScreen(creator: c))),
                        child: Text("🏠 ${c.name}'s ${c.room} room — tap to visit"),
                      ),
                    ],
                  ),
                  ListView(
                    children: [
                      PixelCard(child: Text('⭐ First Stream — unlocked (demo achievement)')),
                      SizedBox(height: 10),
                      PixelCard(child: Text('🔒 100-Star Room — locked (demo achievement)')),
                      SizedBox(height: 10),
                      PixelCard(child: Text('🔒 Cozy Host — locked (demo achievement)')),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
