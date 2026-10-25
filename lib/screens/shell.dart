import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../state.dart';
import '../theme.dart';
import 'discover.dart';
import 'home.dart';
import 'live.dart';
import 'messages.dart';
import 'profile.dart';
import 'store.dart';
import 'studio.dart';

/// Bottom navigation: Home, Discover, LIVE (prominent raised centre),
/// Messages, Profile — plus a clear Go LIVE button on Home and LIVE tabs.
class ShellScreen extends StatefulWidget {
  const ShellScreen({super.key});
  @override
  State<ShellScreen> createState() => _ShellScreenState();
}

class _ShellScreenState extends State<ShellScreen> {
  int _tab = 0;

  List<Widget> get _pages => const [
        HomeScreen(),
        DiscoverScreen(),
        LiveDiscoveryScreen(),
        MessagesScreen(),
        ProfileScreen(),
      ];

  void _go(int i) => setState(() => _tab = i);

  @override
  Widget build(BuildContext context) {
    final state = context.watch<KazumiState>();
    final unread = state.chats.values.any((msgs) => msgs.isNotEmpty && msgs.last.sender != 'You');
    return Scaffold(
      body: PixelBackground(
        child: SafeArea(
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 350),
            switchInCurve: Curves.easeInOutCubic,
            switchOutCurve: Curves.easeInCubic,
            transitionBuilder: (child, anim) => FadeTransition(
              opacity: anim,
              child: SlideTransition(
                position: Tween<Offset>(begin: const Offset(0.04, 0), end: Offset.zero).animate(anim),
                child: child,
              ),
            ),
            child: KeyedSubtree(key: ValueKey(_tab), child: _pages[_tab]),
          ),
        ),
      ),
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          border: Border(top: BorderSide(color: KazumiColors.lavender, width: 2)),
        ),
        padding: const EdgeInsets.only(bottom: 8, top: 4),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _NavItem(icon: Icons.home_outlined, label: 'Home', active: _tab == 0, onTap: () => _go(0)),
            _NavItem(icon: Icons.explore_outlined, label: 'Discover', active: _tab == 1, onTap: () => _go(1)),
            _LiveButton(onTap: () => _go(2)),
            _NavItem(icon: Icons.chat_bubble_outline, label: 'Messages', active: _tab == 3, badge: unread, onTap: () => _go(3)),
            _NavItem(icon: Icons.person_outline, label: 'Profile', active: _tab == 4, onTap: () => _go(4)),
          ],
        ),
      ),
      floatingActionButton: _tab == 0
          ? FloatingActionButton.extended(
              onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const StudioScreen())),
              backgroundColor: KazumiColors.pinkDeep,
              icon: const Icon(Icons.videocam, color: Colors.white),
              label: const Text('Go LIVE', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800)),
            )
          : null,
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool active;
  final bool badge;
  final VoidCallback onTap;
  const _NavItem({required this.icon, required this.label, required this.active, this.badge = false, required this.onTap});
  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                Icon(icon, color: active ? KazumiColors.pinkDeep : KazumiColors.inkSoft, size: 24),
                if (badge) Positioned(right: -4, top: -2, child: Container(width: 10, height: 10, decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle))),
              ],
            ),
            Text(label, style: TextStyle(fontSize: 11, fontWeight: active ? FontWeight.w800 : FontWeight.w500, color: active ? KazumiColors.pinkDeep : KazumiColors.inkSoft)),
          ],
        ),
      ),
    );
  }
}

class _LiveButton extends StatefulWidget {
  final VoidCallback onTap;
  const _LiveButton({required this.onTap});
  @override
  State<_LiveButton> createState() => _LiveButtonState();
}

class _LiveButtonState extends State<_LiveButton> {
  double _scale = 1;
  @override
  Widget build(BuildContext context) {
    return Transform.translate(
      offset: const Offset(0, -14),
      child: GestureDetector(
        onTapDown: (_) => setState(() => _scale = 0.92),
        onTapUp: (_) => setState(() => _scale = 1),
        onTapCancel: () => setState(() => _scale = 1),
        onTap: widget.onTap,
        child: AnimatedScale(
          scale: _scale,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOutCubic,
          child: Container(
            width: 62,
            height: 62,
            decoration: BoxDecoration(
              color: KazumiColors.pinkDeep,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 3),
              boxShadow: const [BoxShadow(color: Color(0x33000000), blurRadius: 8, offset: Offset(0, 3))],
            ),
            child: const Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.videocam, color: Colors.white, size: 22),
                Text('LIVE', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w900)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Shared store shortcut used by Home/Profile.
class StoreShortcut extends StatelessWidget {
  const StoreShortcut({super.key});
  @override
  Widget build(BuildContext context) {
    final state = context.watch<KazumiState>();
    return PixelCard(
      onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const StoreScreen())),
      child: Row(
        children: [
          const Text('⭐', style: TextStyle(fontSize: 26)),
          const SizedBox(width: 10),
          Expanded(child: Text('${state.stars} Stars — visit the Store to change your look (Store-only)', style: const TextStyle(fontWeight: FontWeight.w700))),
          const Icon(Icons.chevron_right),
        ],
      ),
    );
  }
}
