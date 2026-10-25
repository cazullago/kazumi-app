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
        const PixelText('Recommended for you', size: 18),
        const SizedBox(height: 10),
        SizedBox(
          height: 330,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: recommended.length,
            separatorBuilder: (_, _) => const SizedBox(width: 12),
            itemBuilder: (context, i) {
              final c = recommended[i];
              final following = state.isFollowing(c.id);
              return SizedBox(
                width: 212,
                child: InkWell(
                  onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => CreatorProfileScreen(creator: c))),
                  borderRadius: BorderRadius.circular(18),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: KazumiColors.lavender, width: 2),
                      boxShadow: const [BoxShadow(color: Color(0x22000000), blurRadius: 0, offset: Offset(3, 3))],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Artwork fills the card — no empty white space.
                        Expanded(
                          child: ClipRRect(
                            borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                            child: Stack(
                              fit: StackFit.expand,
                              children: [
                                Image.asset(
                                  c.portrait,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stack) => Container(color: KazumiColors.lavender),
                                ),
                                Positioned(
                                  left: 8,
                                  top: 8,
                                  child: Row(
                                    children: [
                                      if (c.isLive)
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                          decoration: BoxDecoration(color: Colors.red, borderRadius: BorderRadius.circular(6)),
                                          child: const Text('LIVE', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w900)),
                                        ),
                                      const SizedBox(width: 6),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                        decoration: BoxDecoration(color: Colors.black54, borderRadius: BorderRadius.circular(6)),
                                        child: Text(c.category, style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w700)),
                                      ),
                                    ],
                                  ),
                                ),
                                Positioned(
                                  left: 0,
                                  right: 0,
                                  bottom: 0,
                                  child: Container(
                                    padding: const EdgeInsets.fromLTRB(10, 18, 10, 8),
                                    decoration: const BoxDecoration(
                                      gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Colors.transparent, Colors.black54]),
                                    ),
                                    child: Text(
                                      c.name,
                                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 17, shadows: [Shadow(color: Colors.black54, blurRadius: 4)]),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('${c.category} · ${c.followers} followers', style: const TextStyle(fontSize: 12, color: KazumiColors.inkSoft)),
                              Text('Demo viewers: ~${demoViewers(c.id)} (demo data)', style: const TextStyle(fontSize: 11, color: KazumiColors.inkSoft)),
                              const SizedBox(height: 8),
                              SizedBox(
                                width: double.infinity,
                                child: AnimatedSwitcher(
                                  duration: const Duration(milliseconds: 300),
                                  transitionBuilder: (child, anim) => FadeTransition(opacity: anim, child: child),
                                  child: following
                                      ? OutlinedButton(key: const ValueKey('f'), onPressed: () => state.toggleFollow(c.id), child: const Text('Following ✓'))
                                      : FilledButton(key: const ValueKey('u'), onPressed: () => state.toggleFollow(c.id), child: const Text('Follow')),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
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
          SizedBox(
            height: 118,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: followed.length,
              separatorBuilder: (_, _) => const SizedBox(width: 14),
              itemBuilder: (context, i) {
                final c = followed[i];
                return InkWell(
                  onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => CreatorProfileScreen(creator: c))),
                  child: SizedBox(
                    width: 76,
                    child: Column(
                      children: [
                        Stack(
                          children: [
                            ClipOval(child: Image.asset(c.portrait, width: 72, height: 72, fit: BoxFit.cover, errorBuilder: (context, error, stack) => Container(width: 72, height: 72, color: KazumiColors.lavender))),
                            if (c.isLive)
                              Positioned(
                                right: 0,
                                bottom: 0,
                                child: Container(padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1), decoration: BoxDecoration(color: Colors.red, borderRadius: BorderRadius.circular(6)), child: const Text('LIVE', style: TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.w900))),
                              ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(c.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13)),
                        Text(c.category, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 11, color: KazumiColors.inkSoft)),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        const SizedBox(height: 20),
        const PixelText('Live right now', size: 18),
        const SizedBox(height: 10),
        ...demoCreators.where((c) => c.isLive).map((c) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: PixelCard(
                onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => WatchScreen(creator: c))),
                child: Row(
                  children: [
                    portraitThumb(c.portrait, 64, 64, radius: 32),
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
