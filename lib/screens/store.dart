import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../avatar.dart';
import '../models.dart';
import '../state.dart';
import '../theme.dart';

/// Store + Inventory. STORE-ONLY RULE: every appearance change lives here.
/// Buying needs an explicit confirmation dialog; equip/remove is free and
/// permanent; preview never changes the equipped avatar.
class StoreScreen extends StatefulWidget {
  const StoreScreen({super.key});
  @override
  State<StoreScreen> createState() => _StoreScreenState();
}

class _StoreScreenState extends State<StoreScreen> {
  String _cat = 'All';
  StoreItem? _preview;

  @override
  Widget build(BuildContext context) {
    final state = context.watch<KazumiState>();
    final items = _cat == 'All' ? storeItems : storeItems.where((i) => i.category == _cat).toList();
    final previewStyle = _preview == null ? state.userStyle : state.previewWith(_preview!);
    final ownedItems = storeItems.where((i) => state.owned.contains(i.id)).toList();
    return Scaffold(
      appBar: AppBar(title: const Text('Store')),
      body: PixelBackground(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            PixelCard(
              child: Row(
                children: [
                  const Text('⭐', style: TextStyle(fontSize: 28)),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('${state.stars} Stars', style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18)),
                        const Text('In-app Stars only — no real-money purchases in v1.', style: TextStyle(fontSize: 12, color: KazumiColors.inkSoft)),
                      ],
                    ),
                  ),
                  TextButton(
                    onPressed: () => _showHistory(context, state),
                    child: const Text('History'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            // Smooth equip preview: cross-fades + scales, never snaps.
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 400),
              switchInCurve: Curves.easeOutCubic,
              switchOutCurve: Curves.easeInCubic,
              transitionBuilder: (child, anim) => FadeTransition(
                opacity: anim,
                child: ScaleTransition(scale: Tween<double>(begin: 0.94, end: 1).animate(anim), child: child),
              ),
              child: PixelCard(
                key: ValueKey(_preview == null ? 'equipped:${state.equippedSignature}' : 'preview:${_preview!.id}'),
                child: Column(
                  children: [
                    AnimatedAvatar(style: previewStyle, size: 150, tilt: 0.15),
                    const SizedBox(height: 6),
                    Text(
                      _preview == null ? 'Your current look (equipped = LIVE look)' : 'Preview: ${_preview!.name} — preview only, your avatar has not changed',
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                    if (_preview != null)
                      TextButton(
                        onPressed: () => setState(() => _preview = null),
                        child: const Text('Back to my current look'),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 14),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: ['All', 'Hairstyle', 'Hair Color', 'Eyes', 'Outfit', 'Accessory', 'Art Style', 'Service'].map((c) {
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: PixelChip(label: c, selected: _cat == c, onTap: () => setState(() => _cat = c)),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 12),
            ...items.map((item) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: PixelCard(
                    child: Row(
                      children: [
                        Text(item.glyph, style: const TextStyle(fontSize: 28)),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(item.name, style: const TextStyle(fontWeight: FontWeight.w800)),
                              Text(item.description, style: const TextStyle(fontSize: 12, color: KazumiColors.inkSoft)),
                              Text('${item.priceStars} Stars · ${item.category}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Column(
                          children: [
                            OutlinedButton(onPressed: () => setState(() => _preview = item), child: const Text('Preview')),
                            const SizedBox(height: 4),
                            _ActionButton(item: item),
                          ],
                        ),
                      ],
                    ),
                  ),
                )),
            const SizedBox(height: 20),
            const PixelText('My inventory', size: 18),
            const SizedBox(height: 8),
            const Text('Owned items are permanent. Equip/Remove is free — removing reverts to your base look, re-equipping is free, no repurchase.', style: TextStyle(color: KazumiColors.inkSoft, fontSize: 13)),
            const SizedBox(height: 10),
            if (ownedItems.isEmpty) const PixelCard(child: Text('Nothing owned yet. Buy an item above to start your collection.')),
            ...ownedItems.map((item) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: PixelCard(
                    child: Row(
                      children: [
                        Text(item.glyph, style: const TextStyle(fontSize: 24)),
                        const SizedBox(width: 10),
                        Expanded(child: Text(item.name, style: const TextStyle(fontWeight: FontWeight.w700))),
                        if (item.category != 'Service') _ActionButton(item: item),
                        if (item.category == 'Service') const Text('Service owned', style: TextStyle(color: KazumiColors.inkSoft, fontSize: 12)),
                      ],
                    ),
                  ),
                )),
            const SizedBox(height: 10),
            const Text('Tracking, blinking, expressions and mouth movement are core and free — never charged.', style: TextStyle(fontSize: 12, color: KazumiColors.inkSoft)),
          ],
        ),
      ),
    );
  }

  void _showHistory(BuildContext context, KazumiState state) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Transaction history'),
        content: SizedBox(
          width: double.maxFinite,
          child: state.transactions.isEmpty
              ? const Text('No transactions yet.')
              : ListView(children: state.transactions.map((t) => Padding(padding: const EdgeInsets.only(bottom: 6), child: Text('• $t'))).toList()),
        ),
        actions: [TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('Close'))],
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final StoreItem item;
  const _ActionButton({required this.item});
  @override
  Widget build(BuildContext context) {
    final state = context.watch<KazumiState>();
    final owned = state.owned.contains(item.id);
    final equipped = state.isEquipped(item);
    if (item.category == 'Service') {
      if (owned) return const Text('Owned ✓', style: TextStyle(fontWeight: FontWeight.w700));
      return FilledButton(
        onPressed: () => _confirmBuy(context, state, item),
        child: Text('Buy · ${item.priceStars}⭐'),
      );
    }
    if (!owned) {
      return FilledButton(
        onPressed: () => _confirmBuy(context, state, item),
        child: Text('Buy · ${item.priceStars}⭐'),
      );
    }
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 300),
      transitionBuilder: (child, anim) => FadeTransition(opacity: anim, child: child),
      child: equipped
          ? OutlinedButton(key: const ValueKey('eq'), onPressed: () => state.toggleEquip(item), child: const Text('Remove (free)'))
          : FilledButton(key: const ValueKey('ne'), onPressed: () => state.toggleEquip(item), child: const Text('Equip (free)')),
    );
  }

  Future<void> _confirmBuy(BuildContext context, KazumiState state, StoreItem item) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Buy ${item.name}?'),
        content: Text(
          '${item.priceStars} Stars will be deducted (you have ${state.stars}). This purchase is permanent and the item stays in your inventory forever. ${item.category == 'Service' ? '$aiNotConnectedLabel.' : 'Equipping is free after purchase.'}',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.of(ctx).pop(true), child: const Text('Confirm purchase')),
        ],
      ),
    );
    if (ok != true || !context.mounted) return;
    final success = await state.buyItem(item);
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          success
              ? item.category == 'Service'
                  ? '${item.name} purchased. Regeneration queued (Store service). $aiNotConnectedLabel.'
                  : '${item.name} purchased! Equip it for free from the Store or your inventory.'
              : 'Could not buy ${item.name} — check your Stars balance.',
        ),
      ),
    );
  }
}
