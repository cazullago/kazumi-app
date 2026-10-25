import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../avatar.dart';
import '../models.dart';
import '../state.dart';
import '../theme.dart';
import 'live.dart';
import 'profile.dart';

class DiscoverScreen extends StatefulWidget {
  const DiscoverScreen({super.key});
  @override
  State<DiscoverScreen> createState() => _DiscoverScreenState();
}

class _DiscoverScreenState extends State<DiscoverScreen> {
  String _query = '';
  String _cat = 'All';
  @override
  Widget build(BuildContext context) {
    final state = context.watch<KazumiState>();
    final q = _query.toLowerCase();
    final creators = demoCreators.where((c) {
      final matchesQ = q.isEmpty || c.name.toLowerCase().contains(q) || c.bio.toLowerCase().contains(q);
      final matchesC = _cat == 'All' || c.category == _cat;
      return matchesQ && matchesC;
    }).toList();
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const PixelText('DISCOVER', size: 24, color: KazumiColors.pinkDeep),
        const SizedBox(height: 10),
        TextField(
          decoration: const InputDecoration(prefixIcon: Icon(Icons.search), hintText: 'Search creators…', border: OutlineInputBorder(), filled: true, fillColor: Colors.white),
          onChanged: (v) => setState(() => _query = v),
        ),
        const SizedBox(height: 12),
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
        const PixelText('Creators', size: 18),
        const SizedBox(height: 10),
        ...creators.map((c) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: PixelCard(
                onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => CreatorProfileScreen(creator: c))),
                child: Row(
                  children: [
                    AnimatedAvatar(style: c.style, portraitAsset: c.portrait, size: 64, pendant: c.id == 'mikachan', animate: false),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(c.name, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
                          Text(c.bio, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(color: KazumiColors.inkSoft, fontSize: 13)),
                          Text('${c.followers} followers · ${c.category}${c.isLive ? ' · LIVE' : ''}', style: const TextStyle(fontSize: 12, color: KazumiColors.inkSoft)),
                        ],
                      ),
                    ),
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 300),
                      transitionBuilder: (child, anim) => FadeTransition(opacity: anim, child: child),
                      child: state.isFollowing(c.id)
                          ? OutlinedButton(key: const ValueKey('f'), onPressed: () => state.toggleFollow(c.id), child: const Text('Following ✓'))
                          : FilledButton(key: const ValueKey('u'), onPressed: () => state.toggleFollow(c.id), child: const Text('Follow')),
                    ),
                  ],
                ),
              ),
            )),
        const SizedBox(height: 16),
        const PixelText('Rooms to explore', size: 18),
        const SizedBox(height: 10),
        ...creators.map((c) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: PixelCard(
                onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => c.isLive ? WatchScreen(creator: c) : CreatorProfileScreen(creator: c))),
                child: Row(
                  children: [
                    Text(c.room == 'Gaming' ? '🎮' : '🛏️', style: const TextStyle(fontSize: 26)),
                    const SizedBox(width: 10),
                    Expanded(child: Text("${c.name}'s ${c.room} room — ${c.category}", style: const TextStyle(fontWeight: FontWeight.w700))),
                    const Icon(Icons.chevron_right),
                  ],
                ),
              ),
            )),
      ],
    );
  }
}
