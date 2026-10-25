import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../avatar.dart';
import '../models.dart';
import '../state.dart';
import '../theme.dart';
import 'live.dart';
import 'profile.dart';
import 'shell.dart';
import 'studio.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String _query = '';
  @override
  Widget build(BuildContext context) {
    final state = context.watch<KazumiState>();
    final q = _query.toLowerCase();
    final recommended = demoCreators.where((c) => q.isEmpty || c.name.toLowerCase().contains(q) || c.category.toLowerCase().contains(q)).toList();
    final followed = demoCreators.where((c) => state.isFollowing(c.id)).toList();
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Row(
          children: [
            const Expanded(child: PixelText('KAZUMI', size: 26, color: KazumiColors.pinkDeep)),
            FilledButton.icon(
              onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const StudioScreen())),
              icon: const Icon(Icons.videocam_outlined, size: 18),
              label: const Text('Go LIVE'),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text('Welcome back, ${state.userName}! Cozy streams, pixel rooms, starlight chats.', style: const TextStyle(color: KazumiColors.inkSoft)),
        const SizedBox(height: 12),
        TextField(
          decoration: const InputDecoration(prefixIcon: Icon(Icons.search), hintText: 'Search creators, categories…', border: OutlineInputBorder(), filled: true, fillColor: Colors.white),
          onChanged: (v) => setState(() => _query = v),
        ),
        const SizedBox(height: 16),
        const StoreShortcut(),
        const SizedBox(height: 20),
        const PixelText('Recommended creators', size: 18),
        const SizedBox(height: 10),
        SizedBox(
          height: 270,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: recommended.length,
            separatorBuilder: (_, _) => const SizedBox(width: 12),
            itemBuilder: (context, i) {
              final c = recommended[i];
              return SizedBox(
                width: 160,
                child: PixelCard(
                  onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => CreatorProfileScreen(creator: c))),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      AnimatedAvatar(style: c.style, size: 72, pendant: c.id == 'mikachan', animate: false),
                      const SizedBox(height: 6),
                      Text(c.name, style: const TextStyle(fontWeight: FontWeight.w800), overflow: TextOverflow.ellipsis),
                      Text(c.category, style: const TextStyle(fontSize: 12, color: KazumiColors.inkSoft)),
                      if (c.isLive)
                        Container(
                          margin: const EdgeInsets.only(top: 4),
                          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                          decoration: BoxDecoration(color: Colors.red, borderRadius: BorderRadius.circular(6)),
                          child: const Text('LIVE', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w800)),
                        ),
                      const SizedBox(height: 6),
                      SizedBox(
                        width: double.infinity,
                        child: AnimatedSwitcher(
                          duration: const Duration(milliseconds: 300),
                          transitionBuilder: (child, anim) => FadeTransition(opacity: anim, child: child),
                          child: state.isFollowing(c.id)
                              ? OutlinedButton(key: const ValueKey('f'), onPressed: () => state.toggleFollow(c.id), child: const Text('Following ✓'))
                              : FilledButton(key: const ValueKey('u'), onPressed: () => state.toggleFollow(c.id), child: const Text('Follow')),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 20),
        const PixelText('Followed creators', size: 18),
        const SizedBox(height: 10),
        if (followed.isEmpty)
          const PixelCard(child: Text('You are not following anyone yet. Tap Follow on a creator above and they will appear here.'))
        else
          ...followed.map((c) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: PixelCard(
                  onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => CreatorProfileScreen(creator: c))),
                  child: Row(
                    children: [
                      AnimatedAvatar(style: c.style, size: 56, animate: false),
                      const SizedBox(width: 12),
                      Expanded(child: Text(c.name, style: const TextStyle(fontWeight: FontWeight.w800))),
                      if (c.isLive)
                        TextButton(
                          onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => WatchScreen(creator: c))),
                          child: const Text('Watch LIVE'),
                        )
                      else
                        const Text('Offline', style: TextStyle(color: KazumiColors.inkSoft)),
                    ],
                  ),
                ),
              )),
        const SizedBox(height: 20),
        const PixelText('Live right now', size: 18),
        const SizedBox(height: 10),
        ...demoCreators.where((c) => c.isLive).map((c) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: PixelCard(
                onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => WatchScreen(creator: c))),
                child: Row(
                  children: [
                    AnimatedAvatar(style: c.style, size: 56, pendant: c.id == 'mikachan', animate: false),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('${c.name} — ${c.room} LIVE', style: const TextStyle(fontWeight: FontWeight.w800)),
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
