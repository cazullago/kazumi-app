import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'screens/onboarding.dart';
import 'screens/shell.dart';
import 'state.dart';
import 'theme.dart';

/// Crash-proof bootstrap (startup lesson): ensureInitialized + all startup
/// init + every runApp call happen in ONE zone. runZonedGuarded's onError
/// only logs — it never calls runApp (that reintroduces the zone mismatch).
/// Any init failure renders an in-app error screen with message, stack
/// snippet, Copy and Retry — never a silent "keeps stopping".
void main() {
  runZonedGuarded(() async {
    WidgetsFlutterBinding.ensureInitialized();
    try {
      final state = await KazumiState.load();
      runApp(KazumiApp(state: state));
    } catch (e, st) {
      runApp(KazumiErrorApp(error: e, stack: st));
    }
  }, (error, stack) {
    // Log only. Never runApp from here.
    debugPrint('Kazumi zone error: $error\n$stack');
  });
}

class KazumiApp extends StatelessWidget {
  final KazumiState state;
  const KazumiApp({super.key, required this.state});
  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<KazumiState>.value(
      value: state,
      child: MaterialApp(
        title: 'Kazumi',
        debugShowCheckedModeBanner: false,
        theme: KazumiTheme.light,
        home: Consumer<KazumiState>(
          builder: (context, s, _) => AnimatedSwitcher(
            duration: const Duration(milliseconds: 400),
            switchInCurve: Curves.easeInOutCubic,
            switchOutCurve: Curves.easeInCubic,
            transitionBuilder: (child, anim) => FadeTransition(opacity: anim, child: child),
            child: s.onboardingDone ? const ShellScreen(key: ValueKey('shell')) : const OnboardingScreen(key: ValueKey('onboarding')),
          ),
        ),
      ),
    );
  }
}

class KazumiErrorApp extends StatelessWidget {
  final Object error;
  final StackTrace stack;
  const KazumiErrorApp({super.key, required this.error, required this.stack});
  @override
  Widget build(BuildContext context) {
    final snippet = stack.toString().split('\n').take(12).join('\n');
    return MaterialApp(
      title: 'Kazumi',
      debugShowCheckedModeBanner: false,
      theme: KazumiTheme.light,
      home: Scaffold(
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: ListView(
              children: [
                const PixelText('KAZUMI', size: 28, color: KazumiColors.pinkDeep),
                const SizedBox(height: 12),
                const Text('Kazumi could not start cleanly. This screen explains why instead of closing silently.', style: TextStyle(fontWeight: FontWeight.w700)),
                const SizedBox(height: 12),
                PixelCard(child: Text('Error: $error')),
                const SizedBox(height: 12),
                PixelCard(child: Text(snippet, style: const TextStyle(fontFamily: 'monospace', fontSize: 12))),
                const SizedBox(height: 16),
                FilledButton(
                  onPressed: () {
                    Clipboard.setData(ClipboardData(text: 'Kazumi startup error: $error\n$snippet'));
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Error details copied.')));
                  },
                  child: const Text('Copy error details'),
                ),
                const SizedBox(height: 8),
                OutlinedButton(
                  onPressed: () => main(),
                  child: const Text('Retry'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
