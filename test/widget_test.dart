import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kazumi/avatar.dart';
import 'package:kazumi/models.dart';
import 'package:kazumi/screens/live.dart';
import 'package:kazumi/screens/messages.dart';
import 'package:kazumi/screens/onboarding.dart';
import 'package:kazumi/screens/store.dart';
import 'package:kazumi/screens/home.dart';
import 'package:kazumi/state.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<void> pumpScreen(WidgetTester tester, KazumiState state, Widget screen) async {
  await tester.pumpWidget(
    ChangeNotifierProvider<KazumiState>.value(
      value: state,
      // Home/LIVE screens rely on the Shell's Scaffold; give every screen
      // one here (nesting is harmless for screens that bring their own).
      child: MaterialApp(home: Scaffold(body: screen)),
    ),
  );
  await tester.pump(const Duration(milliseconds: 100));
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('Onboarding shows consent + AI-not-connected label, continues after consent', (tester) async {
    final state = KazumiState.test();
    await pumpScreen(tester, state, const OnboardingScreen());
    expect(find.textContaining('AI transformation: not connected yet'), findsWidgets);
    expect(find.textContaining('I understand and consent'), findsOneWidget);
    // Continue is disabled before consent: tapping does nothing.
    // Lazy ListView: drag to build the offscreen button, then tap it.
    final list = find.byType(ListView).first;
    final continueBtn = find.widgetWithText(FilledButton, 'Continue to Kazumi');
    await tester.drag(list, const Offset(0, -1200));
    await tester.pump(const Duration(milliseconds: 200));
    await tester.tap(continueBtn);
    await tester.pump(const Duration(milliseconds: 100));
    expect(state.onboardingDone, isFalse);
    // Consent, then continue works.
    await tester.drag(list, const Offset(0, 1200));
    await tester.pump(const Duration(milliseconds: 200));
    await tester.tap(find.byType(Checkbox));
    await tester.pump(const Duration(milliseconds: 100));
    await tester.drag(list, const Offset(0, -1200));
    await tester.pump(const Duration(milliseconds: 200));
    await tester.tap(continueBtn);
    await tester.pump(const Duration(milliseconds: 100));
    expect(state.onboardingDone, isTrue);
    expect(state.consentGiven, isTrue);
  });

  testWidgets('Store buy requires confirmation, then equip/remove are free', (tester) async {
    final state = KazumiState.test();
    expect(state.stars, 500);
    await pumpScreen(tester, state, const StoreScreen());
    // Category switch BEFORE any dialog opens (Lurniq test lesson).
    await tester.tap(find.widgetWithText(ChoiceChip, 'Hairstyle'));
    await tester.pump(const Duration(milliseconds: 200));
    // Buy the first hairstyle (Twin Tails, 80 Stars) — confirm dialog first.
    final buy = find.widgetWithText(FilledButton, 'Buy · 80⭐');
    await tester.ensureVisible(buy.first);
    await tester.pump(const Duration(milliseconds: 100));
    await tester.tap(buy.first);
    await tester.pump(const Duration(milliseconds: 200));
    expect(find.text('Confirm purchase'), findsOneWidget);
    await tester.tap(find.widgetWithText(FilledButton, 'Confirm purchase'));
    await tester.pump(const Duration(milliseconds: 200));
    expect(state.owned.contains('hair_twin'), isTrue);
    expect(state.stars, 420);
    expect(state.transactions.first, contains('Twin Tails'));
    // Preview must NOT change the equipped avatar.
    final before = state.equippedSignature;
    final preview = find.widgetWithText(OutlinedButton, 'Preview');
    await tester.ensureVisible(preview.first);
    await tester.pump(const Duration(milliseconds: 100));
    await tester.tap(preview.first);
    await tester.pump(const Duration(milliseconds: 300));
    expect(state.equippedSignature, before);
    // Equip (free), then remove (free, reverts to base).
    final equip = find.widgetWithText(FilledButton, 'Equip (free)');
    await tester.ensureVisible(equip.first);
    await tester.pump(const Duration(milliseconds: 100));
    await tester.tap(equip.first);
    await tester.pump(const Duration(milliseconds: 200));
    expect(state.isEquipped(findStoreItem('hair_twin')!), isTrue);
    final remove = find.widgetWithText(OutlinedButton, 'Remove (free)');
    await tester.ensureVisible(remove.first);
    await tester.pump(const Duration(milliseconds: 100));
    await tester.tap(remove.first);
    await tester.pump(const Duration(milliseconds: 200));
    expect(state.isEquipped(findStoreItem('hair_twin')!), isFalse);
    expect(state.equippedSignature, before);
  });

  testWidgets('Chat send saves message locally', (tester) async {
    final state = KazumiState.test();
    final convo = Conversation(id: 'mikachan', name: 'MikaChan', style: mikaStyle);
    await pumpScreen(tester, state, ChatDetailScreen(conversation: convo));
    await tester.enterText(find.byType(TextField), 'Hello MikaChan!');
    await tester.pump(const Duration(milliseconds: 100));
    await tester.tap(find.widgetWithText(FilledButton, 'Send'));
    await tester.pump(const Duration(milliseconds: 200));
    expect(state.chats['mikachan']?.length, 1);
    expect(state.chats['mikachan']?.first.text, 'Hello MikaChan!');
    expect(find.text('Hello MikaChan!'), findsWidgets);
  });

  testWidgets('Follow toggle works from Home', (tester) async {
    final state = KazumiState.test();
    await pumpScreen(tester, state, const HomeScreen());
    final follow = find.widgetWithText(FilledButton, 'Follow');
    await tester.ensureVisible(follow.first);
    await tester.pump(const Duration(milliseconds: 100));
    await tester.tap(follow.first);
    await tester.pump(const Duration(milliseconds: 200));
    expect(state.isFollowing('mikachan'), isTrue);
    expect(find.widgetWithText(OutlinedButton, 'Following ✓'), findsWidgets);
  });

  test('All creators have illustrated portraits (v1.0.1, no blob avatars)', () {
    expect(demoCreators.length, greaterThanOrEqualTo(9));
    for (final c in demoCreators) {
      expect(c.portrait, startsWith('assets/portraits/'));
      expect(c.portrait, endsWith('.jpg'));
    }
    expect(portraitForStyle(mikaStyle), 'assets/portraits/mikachan.jpg');
    expect(portraitForStyle(const AvatarStyle(hairStyle: 'Twin Tails')), 'assets/portraits/sakurapixel.jpg');
  });

  testWidgets('Live discovery labels demo viewers, never as real', (tester) async {
    final state = KazumiState.test();
    await pumpScreen(tester, state, const LiveDiscoveryScreen());
    expect(find.textContaining('demo data, not real viewers'), findsOneWidget);
    expect(find.textContaining('Demo viewers:'), findsWidgets);
  });
}
