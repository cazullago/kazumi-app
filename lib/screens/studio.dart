import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import '../avatar.dart';
import '../mic.dart';
import '../state.dart';
import '../theme.dart';
import 'rooms.dart';
import 'store.dart';

/// LIVE Studio: choose room, title/category, privacy, preview, mic test,
/// avatar position/size, Start/End Live.
///
/// Honesty: this is a LOCAL PREVIEW ONLY — not a real broadcast.
/// Live transport (LiveKit/WebRTC) is not connected in v1. Camera/mic are
/// only requested after an explicit user action, with permission prompts.
class StudioScreen extends StatefulWidget {
  const StudioScreen({super.key});
  @override
  State<StudioScreen> createState() => _StudioScreenState();
}

class _StudioScreenState extends State<StudioScreen> {
  String _room = 'My Room';
  String _category = 'Just Chatting';
  String _privacy = 'Public';
  double _avatarSize = 88;
  double _overlayX = 1;
  double _tilt = 0.15;
  bool _live = false;
  bool _cameraGranted = false;
  final _titleCtrl = TextEditingController(text: 'Cozy pixel-lofi night');
  late final MicLevel _mic;

  @override
  void initState() {
    super.initState();
    _mic = MicLevel();
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _mic.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<KazumiState>();
    return Scaffold(
      appBar: AppBar(title: const Text('LIVE Studio')),
      body: PixelBackground(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: KazumiColors.gold.withValues(alpha: 0.5), borderRadius: BorderRadius.circular(12)),
              child: const Text(
                'LOCAL PREVIEW ONLY — not a real broadcast. Live transport (LiveKit/WebRTC) is not connected in v1. What you see here is your avatar preview, not a stream anyone else can watch.',
                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
              ),
            ),
            const SizedBox(height: 14),
            // Preview stage cross-fades between rooms, never snaps.
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 400),
              switchInCurve: Curves.easeOutCubic,
              switchOutCurve: Curves.easeInCubic,
              transitionBuilder: (child, anim) => FadeTransition(opacity: anim, child: ScaleTransition(scale: Tween<double>(begin: 0.97, end: 1).animate(anim), child: child)),
              child: SizedBox(
                key: ValueKey(_room),
                height: 300,
                child: _room == 'Gaming'
                    ? GamingStage(style: state.userStyle, avatarSize: _avatarSize, overlayX: _overlayX, mouthLevel: _mic.level)
                    : PixelBedroom(style: state.userStyle, avatarSize: 180, tilt: _tilt, mouthLevel: _mic.level),
              ),
            ),
            const SizedBox(height: 8),
            if (_live)
              const DemoLabel('PREVIEW LIVE (local only) — nobody else can see this.')
            else
              const Text('Preview is idle. Start Live below to enter local preview mode.', style: TextStyle(color: KazumiColors.inkSoft, fontSize: 13)),
            const SizedBox(height: 14),
            const PixelText('Stream setup', size: 18),
            const SizedBox(height: 8),
            TextField(controller: _titleCtrl, decoration: const InputDecoration(labelText: 'Stream title', border: OutlineInputBorder())),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    initialValue: _category,
                    decoration: const InputDecoration(labelText: 'Category', border: OutlineInputBorder()),
                    items: ['Just Chatting', 'Music', 'Gaming', 'Art'].map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                    onChanged: (v) => setState(() => _category = v ?? _category),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    initialValue: _privacy,
                    decoration: const InputDecoration(labelText: 'Privacy', border: OutlineInputBorder()),
                    items: ['Public', 'Followers only', 'Private'].map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                    onChanged: (v) => setState(() => _privacy = v ?? _privacy),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            const PixelText('Room', size: 16),
            const SizedBox(height: 6),
            Row(
              children: ['My Room', 'Gaming'].map((r) {
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: PixelChip(label: r, selected: _room == r, onTap: () => setState(() => _room = r)),
                );
              }).toList(),
            ),
            const SizedBox(height: 12),
            PixelCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const PixelText('Your avatar (display only)', size: 16),
                  const Text('Appearance changes are Store-only — the Studio never edits your avatar. Your equipped look is the LIVE look everywhere.', style: TextStyle(fontSize: 12, color: KazumiColors.inkSoft)),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      AnimatedAvatar(style: state.userStyle, size: 72),
                      const SizedBox(width: 10),
                      Expanded(
                        child: FilledButton(
                          onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const StoreScreen())),
                          child: const Text('Open Store to change look'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            const PixelText('Head tilt (glides smoothly)', size: 16),
            Slider(value: _tilt, min: -1, max: 1, onChanged: (v) => setState(() => _tilt = v)),
            if (_room == 'Gaming') ...[
              const PixelText('Avatar overlay size', size: 16),
              Slider(value: _avatarSize, min: 56, max: 140, onChanged: (v) => setState(() => _avatarSize = v)),
              const PixelText('Avatar overlay position', size: 16),
              Slider(value: _overlayX, min: -1, max: 1, onChanged: (v) => setState(() => _overlayX = v)),
              const Text('Overlay glides to its new position (AnimatedPositioned, 400ms ease).', style: TextStyle(fontSize: 12, color: KazumiColors.inkSoft)),
            ],
            const SizedBox(height: 12),
            PixelCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const PixelText('Mic level test', size: 16),
                  const Text(
                    'Your mouth above moves with your REAL mic volume, smoothed so it opens proportionally and closes gently when you stop. No random mouth loop, no fake audio.',
                    style: TextStyle(fontSize: 12, color: KazumiColors.inkSoft),
                  ),
                  const SizedBox(height: 8),
                  ValueListenableBuilder<String>(
                    valueListenable: _mic.status,
                    builder: (context, status, _) => Text(status, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                  ),
                  const SizedBox(height: 8),
                  ValueListenableBuilder<double>(
                    valueListenable: _mic.level,
                    builder: (context, level, _) => AnimatedContainer(
                      duration: const Duration(milliseconds: 120),
                      curve: Curves.easeOutCubic,
                      height: 14,
                      width: double.infinity,
                      alignment: Alignment.centerLeft,
                      decoration: BoxDecoration(color: KazumiColors.creamDark, borderRadius: BorderRadius.circular(8)),
                      child: FractionallySizedBox(
                        widthFactor: level.clamp(0.0, 1.0),
                        child: Container(decoration: BoxDecoration(color: KazumiColors.pinkDeep, borderRadius: BorderRadius.circular(8))),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: FilledButton(
                          onPressed: () async {
                            if (_mic.running) {
                              await _mic.stop();
                            } else {
                              await _mic.start();
                            }
                            if (mounted) setState(() {});
                          },
                          child: Text(_mic.running ? 'Stop mic test' : 'Test mic'),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () async {
                            final perm = await Permission.camera.request();
                            if (!context.mounted) return;
                            setState(() => _cameraGranted = perm.isGranted);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  perm.isGranted
                                      ? 'Camera permission granted — avatar preview continues (camera compositing is not connected in this local preview).'
                                      : 'Camera permission denied — you can still preview with your avatar.',
                                ),
                              ),
                            );
                          },
                          child: Text(_cameraGranted ? 'Camera allowed ✓' : 'Enable camera'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 350),
              transitionBuilder: (child, anim) => FadeTransition(opacity: anim, child: ScaleTransition(scale: anim, child: child)),
              child: _live
                  ? SizedBox(
                      key: const ValueKey('end'),
                      width: double.infinity,
                      child: FilledButton(
                        style: FilledButton.styleFrom(backgroundColor: Colors.red),
                        onPressed: () async {
                          await _mic.stop();
                          setState(() => _live = false);
                        },
                        child: const Text('End Live (local preview)'),
                      ),
                    )
                  : SizedBox(
                      key: const ValueKey('start'),
                      width: double.infinity,
                      child: FilledButton(
                        onPressed: () {
                          setState(() => _live = true);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Local preview started: “${_titleCtrl.text}” · $_category · $_privacy. Not a real broadcast.')),
                          );
                        },
                        child: const Text('Start Live (local preview)'),
                      ),
                    ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Connection status: local preview only. Tracking, blinking and mouth movement run on-device and are free. Broadcast transport is not connected.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12, color: KazumiColors.inkSoft),
            ),
          ],
        ),
      ),
    );
  }
}
