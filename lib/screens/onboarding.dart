import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../avatar.dart';
import '../models.dart';
import '../state.dart';
import '../theme.dart';

/// Consent-first onboarding. The selfie is only for avatar creation:
/// not facial recognition / identification, not shared publicly, deletable.
/// The AI transformation itself is NOT connected yet — the avatar shown
/// here is a clearly-labelled placeholder, never presented as an AI likeness.
class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});
  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  bool _consent = false;
  bool _photoPicked = false;
  bool _approved = false;
  final _nameCtrl = TextEditingController();
  final _picker = ImagePicker();

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  Future<void> _pick(ImageSource source) async {
    try {
      final file = await _picker.pickImage(source: source, maxWidth: 1024);
      if (file != null && mounted) {
        setState(() => _photoPicked = true);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Photo selected and kept on this device only. AI generation is not connected yet, so no AI avatar was created from it.')),
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Photo picker unavailable — you can continue without a photo.')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<KazumiState>();
    return Scaffold(
      body: PixelBackground(
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              const PixelText('KAZUMI', size: 34, color: KazumiColors.pinkDeep),
              const Text('Cute pixel-lofi VTuber streams, made yours.', style: TextStyle(fontSize: 16, color: KazumiColors.inkSoft)),
              const SizedBox(height: 20),
              const PixelCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    PixelText('Before we create your avatar', size: 17),
                    SizedBox(height: 8),
                    Text(
                      'Your selfie is used only to create your avatar. It is NOT used for facial recognition or identification, it is NOT shared publicly, and you can delete it any time from Privacy & Safety.',
                      style: TextStyle(height: 1.4),
                    ),
                    SizedBox(height: 8),
                    DemoLabel(aiNotConnectedLabel),
                    SizedBox(height: 6),
                    Text(
                      'Required server-side image-model integration: a hosted image model endpoint, secure selfie upload, generation job handling, and a review/approve step. Until that ships, what you see below is a placeholder avatar — not an AI likeness of you.',
                      style: TextStyle(fontSize: 13, color: KazumiColors.inkSoft, height: 1.4),
                    ),
                  ],
                ),
              ),
              CheckboxListTile(
                value: _consent,
                onChanged: (v) => setState(() => _consent = v ?? false),
                title: const Text('I understand and consent to using my selfie only for avatar creation'),
                controlAffinity: ListTileControlAffinity.leading,
              ),
              TextField(
                controller: _nameCtrl,
                decoration: const InputDecoration(labelText: 'Display name', border: OutlineInputBorder(), hintText: 'e.g. StarDust'),
              ),
              const SizedBox(height: 14),
              const PixelText('Your selfie (optional)', size: 16),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _consent ? () => _pick(ImageSource.camera) : null,
                      icon: const Icon(Icons.camera_alt_outlined),
                      label: const Text('Take selfie'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _consent ? () => _pick(ImageSource.gallery) : null,
                      icon: const Icon(Icons.photo_outlined),
                      label: const Text('Upload photo'),
                    ),
                  ),
                ],
              ),
              if (_photoPicked) const Padding(padding: EdgeInsets.only(top: 8), child: Text('✓ Photo selected (stored on this device only).', style: TextStyle(fontWeight: FontWeight.w700))),
              const SizedBox(height: 16),
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 400),
                switchInCurve: Curves.easeOutCubic,
                switchOutCurve: Curves.easeInCubic,
                transitionBuilder: (child, anim) => FadeTransition(opacity: anim, child: ScaleTransition(scale: Tween<double>(begin: 0.96, end: 1).animate(anim), child: child)),
                child: PixelCard(
                  key: ValueKey(state.equippedSignature),
                  child: Column(
                    children: [
                      AnimatedAvatar(style: state.userStyle, size: 150, tilt: 0.2),
                      const SizedBox(height: 8),
                      const Text('Awaiting AI generation', style: TextStyle(fontWeight: FontWeight.w800)),
                      const Text('Placeholder avatar — not an AI likeness. Store items you equip will layer onto this look.', textAlign: TextAlign.center, style: TextStyle(color: KazumiColors.inkSoft)),
                      const SizedBox(height: 8),
                      const Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          Chip(label: Text('Face: soft oval (placeholder)')),
                          Chip(label: Text('Eyes: gem (placeholder)')),
                          Chip(label: Text('Hair: long wavy (placeholder)')),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              FilledButton(
                onPressed: _consent
                    ? () async {
                        await state.approveAvatarPlaceholder();
                        if (mounted) setState(() => _approved = true);
                      }
                    : null,
                child: Text(_approved ? '✓ Placeholder avatar approved' : 'Approve placeholder avatar'),
              ),
              const SizedBox(height: 8),
              FilledButton(
                onPressed: _consent
                    ? () async {
                        await state.completeOnboarding(consent: true, name: _nameCtrl.text);
                      }
                    : null,
                child: const Text('Continue to Kazumi'),
              ),
              TextButton(
                onPressed: () async {
                  await state.completeOnboarding(consent: false, name: _nameCtrl.text);
                },
                child: const Text('Continue without a selfie'),
              ),
              const Text(
                'Continuing without a selfie uses the same placeholder avatar. You can revisit avatar creation from your Profile any time.',
                textAlign: TextAlign.center,
                style: TextStyle(color: KazumiColors.inkSoft, fontSize: 13),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
