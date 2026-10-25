import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'models.dart';

/// App state, persisted locally only (SharedPreferences / local JSON).
/// No backend, no server account: v1 is fully on-device.
class KazumiState extends ChangeNotifier {
  KazumiState._();
  static Future<KazumiState> load() async {
    final s = KazumiState._();
    await s._load();
    return s;
  }

  // Visible for tests: build an in-memory state without touching prefs.
  KazumiState.test()
      : _prefsReady = true,
        stars = 500;

  bool _prefsReady = false;
  SharedPreferences? _prefs;

  bool onboardingDone = false;
  bool consentGiven = false;
  String userName = 'You';
  String userBio = 'New Kazumi creator — cozy pixel-lofi vibes.';
  bool aiApproved = false; // approved placeholder avatar (NOT an AI likeness)
  bool aiAwaiting = true; // true until a real AI generation lands

  int stars = 500;
  final Set<String> owned = {'hair_long_placeholder'};
  final Map<String, String> equipped = {}; // category -> item id
  final List<String> transactions = [];
  final Set<String> following = {};
  final Set<String> likedPosts = {};
  final Set<String> blocked = {};
  final Set<String> muted = {};
  final List<Post> userPosts = [];
  final Map<String, List<ChatMessage>> chats = {}; // conversation id -> messages
  final Map<String, List<ChatMessage>> liveChats = {}; // creator id -> live chat
  final Map<String, int> liveReactions = {};

  AvatarStyle get baseStyle => const AvatarStyle();
  AvatarStyle get userStyle {
    var style = baseStyle;
    for (final entry in equipped.entries) {
      final item = findStoreItem(entry.value);
      if (item != null) style = item.applyTo(style);
    }
    return style;
  }

  String get equippedSignature => userStyle.signature;

  Future<void> _load() async {
    try {
      _prefs = await SharedPreferences.getInstance();
      _prefsReady = true;
      onboardingDone = _prefs!.getBool('onboardingDone') ?? false;
      consentGiven = _prefs!.getBool('consentGiven') ?? false;
      userName = _prefs!.getString('userName') ?? 'You';
      userBio = _prefs!.getString('userBio') ?? userBio;
      aiApproved = _prefs!.getBool('aiApproved') ?? false;
      stars = _prefs!.getInt('stars') ?? 500;
      owned.addAll(_prefs!.getStringList('owned') ?? []);
      final eq = _prefs!.getString('equipped');
      if (eq != null) {
        final m = jsonDecode(eq) as Map<String, dynamic>;
        m.forEach((k, v) => equipped[k] = v as String);
      }
      transactions.addAll(_prefs!.getStringList('transactions') ?? []);
      following.addAll(_prefs!.getStringList('following') ?? []);
      likedPosts.addAll(_prefs!.getStringList('likedPosts') ?? []);
      blocked.addAll(_prefs!.getStringList('blocked') ?? []);
      muted.addAll(_prefs!.getStringList('muted') ?? []);
      final posts = _prefs!.getString('userPosts');
      if (posts != null) {
        for (final j in jsonDecode(posts) as List) {
          userPosts.add(Post.fromJson(j as Map<String, dynamic>));
        }
      }
      final ch = _prefs!.getString('chats');
      if (ch != null) {
        final m = jsonDecode(ch) as Map<String, dynamic>;
        m.forEach((k, v) {
          chats[k] = (v as List).map((e) => ChatMessage.fromJson(e as Map<String, dynamic>)).toList();
        });
      }
    } catch (_) {
      // Local-only app: a corrupt prefs file must never block launch.
      _prefsReady = false;
    }
    _seedDemoChats();
    notifyListeners();
  }

  void _seedDemoChats() {
    chats.putIfAbsent('mikachan', () => [
          ChatMessage(id: 'm1', sender: 'MikaChan', text: 'Welcome to my pixel room! Thanks for stopping by.', at: DateTime.now().subtract(const Duration(hours: 2))),
          ChatMessage(id: 'm2', sender: 'You', text: 'Your room is so cozy!', at: DateTime.now().subtract(const Duration(hours: 1))),
        ]);
    chats.putIfAbsent('sakura', () => [
          ChatMessage(id: 's1', sender: 'SakuraPixel', text: 'New pixel art drop on Friday!', at: DateTime.now().subtract(const Duration(days: 1))),
        ]);
    chats.putIfAbsent('req_1', () => [
          ChatMessage(id: 'r1', sender: 'PixelFan99', text: 'Hi! Love your streams!', at: DateTime.now().subtract(const Duration(hours: 5))),
        ]);
    for (final c in demoCreators.where((c) => c.isLive)) {
      liveChats.putIfAbsent(c.id, () => [
            ChatMessage(id: '${c.id}-1', sender: 'StarWatcher', text: 'This room is so cozy!!', at: DateTime.now().subtract(const Duration(minutes: 12))),
            ChatMessage(id: '${c.id}-2', sender: 'LofiLena', text: 'The music tonight is perfect', at: DateTime.now().subtract(const Duration(minutes: 6))),
            ChatMessage(id: '${c.id}-3', sender: 'PixelPete', text: 'Hi MikaChan!', at: DateTime.now().subtract(const Duration(minutes: 2))),
          ]);
      liveReactions.putIfAbsent(c.id, () => 0);
    }
  }

  Future<void> _save() async {
    if (!_prefsReady || _prefs == null) return;
    try {
      final p = _prefs!;
      await p.setBool('onboardingDone', onboardingDone);
      await p.setBool('consentGiven', consentGiven);
      await p.setString('userName', userName);
      await p.setString('userBio', userBio);
      await p.setBool('aiApproved', aiApproved);
      await p.setInt('stars', stars);
      await p.setStringList('owned', owned.toList());
      await p.setString('equipped', jsonEncode(equipped));
      await p.setStringList('transactions', transactions);
      await p.setStringList('following', following.toList());
      await p.setStringList('likedPosts', likedPosts.toList());
      await p.setStringList('blocked', blocked.toList());
      await p.setStringList('muted', muted.toList());
      await p.setString('userPosts', jsonEncode(userPosts.map((e) => e.toJson()).toList()));
      await p.setString('chats', jsonEncode(chats.map((k, v) => MapEntry(k, v.map((e) => e.toJson()).toList()))));
    } catch (_) {
      // Never crash on a save failure.
    }
  }

  Future<void> completeOnboarding({required bool consent, required String name}) async {
    consentGiven = consent;
    onboardingDone = true;
    if (name.trim().isNotEmpty) userName = name.trim();
    aiAwaiting = true;
    notifyListeners();
    await _save();
  }

  /// Profile text only — avatar appearance can only change in the Store.
  Future<void> updateProfileText({required String name, required String bio}) async {
    if (name.trim().isNotEmpty) userName = name.trim();
    userBio = bio;
    notifyListeners();
    await _save();
  }

  Future<void> approveAvatarPlaceholder() async {
    aiApproved = true;
    notifyListeners();
    await _save();
  }

  bool isFollowing(String id) => following.contains(id);
  Future<void> toggleFollow(String id) async {
    if (following.contains(id)) {
      following.remove(id);
    } else {
      following.add(id);
    }
    notifyListeners();
    await _save();
  }

  /// Returns true on success. Buying always asks for confirmation in UI first.
  Future<bool> buyItem(StoreItem item) async {
    if (owned.contains(item.id)) return false;
    if (stars < item.priceStars) return false;
    stars -= item.priceStars;
    owned.add(item.id);
    transactions.insert(0, 'Bought ${item.name} for ${item.priceStars} Stars — ${DateTime.now().toIso8601String().substring(0, 10)}');
    notifyListeners();
    await _save();
    return true;
  }

  /// Free equip / remove. Removing reverts that category to the base look.
  Future<void> toggleEquip(StoreItem item) async {
    if (item.category == 'Service') return;
    if (equipped[item.category] == item.id) {
      equipped.remove(item.category);
      transactions.insert(0, 'Removed ${item.name} (free) — ${DateTime.now().toIso8601String().substring(0, 10)}');
    } else {
      equipped[item.category] = item.id;
      transactions.insert(0, 'Equipped ${item.name} (free) — ${DateTime.now().toIso8601String().substring(0, 10)}');
    }
    notifyListeners();
    await _save();
  }

  bool isEquipped(StoreItem item) => equipped[item.category] == item.id;

  /// Preview only — never writes to equipped.
  AvatarStyle previewWith(StoreItem item) => item.applyTo(userStyle);

  Future<void> sendMessage(String convoId, String text) async {
    final t = text.trim();
    if (t.isEmpty) return;
    final list = chats.putIfAbsent(convoId, () => []);
    list.add(ChatMessage(id: 'u${DateTime.now().millisecondsSinceEpoch}', sender: 'You', text: t, at: DateTime.now()));
    notifyListeners();
    await _save();
  }

  Future<void> sendLiveChat(String creatorId, String text) async {
    final t = text.trim();
    if (t.isEmpty) return;
    final list = liveChats.putIfAbsent(creatorId, () => []);
    list.add(ChatMessage(id: 'l${DateTime.now().millisecondsSinceEpoch}', sender: 'You', text: t, at: DateTime.now()));
    notifyListeners();
  }

  Future<void> addReaction(String creatorId, String emoji) async {
    liveReactions[creatorId] = (liveReactions[creatorId] ?? 0) + 1;
    final list = liveChats.putIfAbsent(creatorId, () => []);
    list.add(ChatMessage(id: 'r${DateTime.now().millisecondsSinceEpoch}', sender: 'You', text: 'sent $emoji', at: DateTime.now()));
    notifyListeners();
  }

  Future<void> hideLiveMessage(String creatorId, String messageId) async {
    final list = liveChats[creatorId];
    if (list == null) return;
    final i = list.indexWhere((m) => m.id == messageId);
    if (i >= 0) list[i] = list[i].copyWith(hidden: true);
    notifyListeners();
  }

  Future<void> toggleLikePost(String postId) async {
    if (likedPosts.contains(postId)) {
      likedPosts.remove(postId);
    } else {
      likedPosts.add(postId);
    }
    notifyListeners();
    await _save();
  }

  Future<void> addPost(String text, String kind) async {
    final t = text.trim();
    if (t.isEmpty) return;
    userPosts.insert(
      0,
      Post(id: 'p${DateTime.now().millisecondsSinceEpoch}', authorId: 'you', authorName: userName, authorStyle: userStyle, text: t, kind: kind, created: DateTime.now()),
    );
    notifyListeners();
    await _save();
  }

  Future<void> blockUser(String id) async {
    blocked.add(id);
    chats.remove(id);
    notifyListeners();
    await _save();
  }

  Future<void> muteUser(String id) async {
    if (muted.contains(id)) {
      muted.remove(id);
    } else {
      muted.add(id);
    }
    notifyListeners();
    await _save();
  }

  Future<void> clearAllLocalData() async {
    following.clear();
    likedPosts.clear();
    blocked.clear();
    muted.clear();
    userPosts.clear();
    chats.clear();
    owned.retainWhere((e) => e == 'hair_long_placeholder');
    equipped.clear();
    transactions.clear();
    stars = 500;
    onboardingDone = false;
    consentGiven = false;
    aiApproved = false;
    _seedDemoChats();
    notifyListeners();
    await _save();
  }
}
