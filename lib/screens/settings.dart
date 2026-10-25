import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models.dart';
import '../state.dart';
import '../theme.dart';

/// Privacy, safety, moderation, and data deletion.
/// v1 is local-only: local deletion works; server deletion is N/A.
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});
  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _allowRequests = true;
  bool _showOnline = true;
  bool _hideBlockedChat = true;

  @override
  Widget build(BuildContext context) {
    final state = context.watch<KazumiState>();
    return Scaffold(
      appBar: AppBar(title: const Text('Privacy & Safety')),
      body: PixelBackground(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            const PixelText('Privacy settings', size: 18),
            const SizedBox(height: 8),
            SwitchListTile(value: _allowRequests, onChanged: (v) => setState(() => _allowRequests = v), title: const Text('Allow message requests from non-followers')),
            SwitchListTile(value: _showOnline, onChanged: (v) => setState(() => _showOnline = v), title: const Text('Show my online status')),
            SwitchListTile(value: _hideBlockedChat, onChanged: (v) => setState(() => _hideBlockedChat = v), title: const Text('Hide blocked users everywhere (including requests)')),
            FilledButton(
              onPressed: () => ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Privacy settings saved locally.'))),
              child: const Text('Save settings'),
            ),
            const SizedBox(height: 20),
            const PixelText('Chat moderation (creators)', size: 18),
            const SizedBox(height: 8),
            const PixelCard(
              child: Text(
                'As a creator, you can hide any live chat message from your stream view (tap “Hide (creator tools)” under a message while watching). Hidden messages stay hidden in your local view. Reports are recorded locally in v1 — there is no server moderation queue yet.',
              ),
            ),
            const SizedBox(height: 20),
            const PixelText('Blocked & muted', size: 18),
            const SizedBox(height: 8),
            if (state.blocked.isEmpty && state.muted.isEmpty) const PixelCard(child: Text('Nobody blocked or muted yet.')),
            ...state.blocked.map((id) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: PixelCard(child: Text('Blocked: $id — hidden from inbox and requests.')),
                )),
            ...state.muted.map((id) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: PixelCard(child: Text('Muted: $id')),
                )),
            const SizedBox(height: 20),
            const PixelText('Your avatar & AI data', size: 18),
            const SizedBox(height: 8),
            const PixelCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  DemoLabel(aiNotConnectedLabel),
                  SizedBox(height: 8),
                  Text('Your selfie, if you provided one, is stored on this device only. It is not used for facial recognition or identification and is not shared publicly. Deleting your local data below removes it from this app.'),
                ],
              ),
            ),
            const SizedBox(height: 20),
            const PixelText('Delete my data', size: 18),
            const SizedBox(height: 8),
            const PixelCard(
              child: Text(
                'Local data deletion works now: it clears your follows, posts, chats, inventory, Stars balance and avatar choices on this device, and returns you to onboarding.\n\nServer deletion is N/A for v1 — Kazumi stores nothing on a server, so there is no server copy to delete.',
              ),
            ),
            const SizedBox(height: 10),
            FilledButton(
              style: FilledButton.styleFrom(backgroundColor: Colors.red),
              onPressed: () async {
                final ok = await showDialog<bool>(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    title: const Text('Delete all local data?'),
                    content: const Text('This cannot be undone on this device. Your follows, posts, chats, Stars and avatar choices will be cleared.'),
                    actions: [
                      TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('Keep my data')),
                      FilledButton(style: FilledButton.styleFrom(backgroundColor: Colors.red), onPressed: () => Navigator.of(ctx).pop(true), child: const Text('Delete everything')),
                    ],
                  ),
                );
                if (ok == true) {
                  await state.clearAllLocalData();
                  if (context.mounted) {
                    Navigator.of(context).pop();
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Local data deleted.')));
                  }
                }
              },
              child: const Text('Delete all local data'),
            ),
          ],
        ),
      ),
    );
  }
}
