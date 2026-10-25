import 'package:flutter/material.dart';

/// Appearance of an avatar. Store items change these fields; nothing else does.
class AvatarStyle {
  final String hairStyle; // Long Wavy, Twin Tails, Short Bob, Ponytail
  final Color hairColor;
  final Color eyeColor;
  final String outfit; // Lofi Hoodie, Star Dress, Cozy Sweater, Gaming Tee
  final String accessory; // Cat Ears, None, Angel Wings, Star Halo
  final String artStyle; // Genshin-style, Pixel Pop, Pastel Dream
  const AvatarStyle({
    this.hairStyle = 'Long Wavy',
    this.hairColor = const Color(0xFFB9A7E8),
    this.eyeColor = const Color(0xFF8B5CF6),
    this.outfit = 'Lofi Hoodie',
    this.accessory = 'Cat Ears',
    this.artStyle = 'Genshin-style',
  });

  AvatarStyle copyWith({
    String? hairStyle,
    Color? hairColor,
    Color? eyeColor,
    String? outfit,
    String? accessory,
    String? artStyle,
  }) {
    return AvatarStyle(
      hairStyle: hairStyle ?? this.hairStyle,
      hairColor: hairColor ?? this.hairColor,
      eyeColor: eyeColor ?? this.eyeColor,
      outfit: outfit ?? this.outfit,
      accessory: accessory ?? this.accessory,
      artStyle: artStyle ?? this.artStyle,
    );
  }

  /// Signature changes whenever the equipped look changes — drives
  /// AnimatedSwitcher keys so equip previews cross-fade instead of snapping.
  String get signature => '$hairStyle|${hairColor.toARGB32()}|${eyeColor.toARGB32()}|$outfit|$accessory|$artStyle';

  Map<String, dynamic> toJson() => {
        'hairStyle': hairStyle,
        'hairColor': hairColor.toARGB32(),
        'eyeColor': eyeColor.toARGB32(),
        'outfit': outfit,
        'accessory': accessory,
        'artStyle': artStyle,
      };

  factory AvatarStyle.fromJson(Map<String, dynamic> j) => AvatarStyle(
        hairStyle: j['hairStyle'] as String? ?? 'Long Wavy',
        hairColor: Color(j['hairColor'] as int? ?? 0xFFB9A7E8),
        eyeColor: Color(j['eyeColor'] as int? ?? 0xFF8B5CF6),
        outfit: j['outfit'] as String? ?? 'Lofi Hoodie',
        accessory: j['accessory'] as String? ?? 'Cat Ears',
        artStyle: j['artStyle'] as String? ?? 'Genshin-style',
      );
}

/// MikaChan — the demo/example creator. Consistent everywhere, NOT the user.
const mikaStyle = AvatarStyle(
  hairStyle: 'Long Wavy',
  hairColor: Color(0xFFB9A7E8),
  eyeColor: Color(0xFF8B5CF6),
  outfit: 'Star Dress',
  accessory: 'Cat Ears',
  artStyle: 'Genshin-style',
);

class Creator {
  final String id;
  final String name;
  final String handle;
  final String bio;
  final int followers;
  final String category;
  final bool isLive;
  final AvatarStyle style;
  final String room;
  const Creator({
    required this.id,
    required this.name,
    required this.handle,
    required this.bio,
    required this.followers,
    required this.category,
    required this.isLive,
    required this.style,
    required this.room,
  });
}

const demoCreators = <Creator>[
  Creator(
    id: 'mikachan',
    name: 'MikaChan',
    handle: '@mikachan',
    bio: 'Lofi nights, cozy chats & starlight songs. Your pixel-lofi roommate.',
    followers: 128400,
    category: 'Just Chatting',
    isLive: true,
    style: mikaStyle,
    room: 'My Room',
  ),
  Creator(
    id: 'sakura',
    name: 'SakuraPixel',
    handle: '@sakurapixel',
    bio: 'Pixel art streams and chill beats every Friday.',
    followers: 84200,
    category: 'Art',
    isLive: true,
    style: AvatarStyle(hairStyle: 'Twin Tails', hairColor: Color(0xFFFFB7D5), eyeColor: Color(0xFFEC4899), outfit: 'Star Dress', accessory: 'Star Halo'),
    room: 'My Room',
  ),
  Creator(
    id: 'luna',
    name: 'LunaLoFi',
    handle: '@lunalofi',
    bio: 'Midnight lofi radio, study with me.',
    followers: 96100,
    category: 'Music',
    isLive: false,
    style: AvatarStyle(hairStyle: 'Long Wavy', hairColor: Color(0xFF8EA8E8), eyeColor: Color(0xFF3B82F6), outfit: 'Cozy Sweater', accessory: 'None'),
    room: 'My Room',
  ),
  Creator(
    id: 'kiko',
    name: 'KikoPlays',
    handle: '@kikoplays',
    bio: 'Cozy games, chaotic energy, zero rage quits (mostly).',
    followers: 57300,
    category: 'Gaming',
    isLive: true,
    style: AvatarStyle(hairStyle: 'Short Bob', hairColor: Color(0xFF7ED6A5), eyeColor: Color(0xFF059669), outfit: 'Gaming Tee', accessory: 'Cat Ears'),
    room: 'Gaming',
  ),
  Creator(
    id: 'mochi',
    name: 'MochiMimi',
    handle: '@mochimimi',
    bio: 'Baking streams + tiny pixel room tours.',
    followers: 41100,
    category: 'Just Chatting',
    isLive: false,
    style: AvatarStyle(hairStyle: 'Ponytail', hairColor: Color(0xFFFFD166), eyeColor: Color(0xFFB45309), outfit: 'Cozy Sweater', accessory: 'Star Halo'),
    room: 'My Room',
  ),
  Creator(
    id: 'ren',
    name: 'RenStar',
    handle: '@renstar',
    bio: 'Singing covers under pixel stars.',
    followers: 68900,
    category: 'Music',
    isLive: false,
    style: AvatarStyle(hairStyle: 'Long Wavy', hairColor: Color(0xFFE8E8E8), eyeColor: Color(0xFF7C6BD9), outfit: 'Star Dress', accessory: 'Angel Wings'),
    room: 'My Room',
  ),
];

class Post {
  final String id;
  final String authorId;
  final String authorName;
  final AvatarStyle authorStyle;
  final String text;
  final String kind; // text, room, photo
  final DateTime created;
  const Post({required this.id, required this.authorId, required this.authorName, required this.authorStyle, required this.text, required this.kind, required this.created});
  Map<String, dynamic> toJson() => {'id': id, 'authorId': authorId, 'authorName': authorName, 'text': text, 'kind': kind, 'created': created.toIso8601String()};
  factory Post.fromJson(Map<String, dynamic> j) => Post(
        id: j['id'] as String,
        authorId: j['authorId'] as String,
        authorName: j['authorName'] as String,
        authorStyle: mikaStyle,
        text: j['text'] as String,
        kind: j['kind'] as String,
        created: DateTime.tryParse(j['created'] as String? ?? '') ?? DateTime.now(),
      );
}

class ChatMessage {
  final String id;
  final String sender;
  final String text;
  final DateTime at;
  final bool hidden;
  const ChatMessage({required this.id, required this.sender, required this.text, required this.at, this.hidden = false});
  ChatMessage copyWith({bool? hidden}) => ChatMessage(id: id, sender: sender, text: text, at: at, hidden: hidden ?? this.hidden);
  Map<String, dynamic> toJson() => {'id': id, 'sender': sender, 'text': text, 'at': at.toIso8601String(), 'hidden': hidden};
  factory ChatMessage.fromJson(Map<String, dynamic> j) => ChatMessage(
        id: j['id'] as String,
        sender: j['sender'] as String,
        text: j['text'] as String,
        at: DateTime.tryParse(j['at'] as String? ?? '') ?? DateTime.now(),
        hidden: j['hidden'] as bool? ?? false,
      );
}

class Conversation {
  final String id;
  final String name;
  final AvatarStyle style;
  final bool isRequest;
  Conversation({required this.id, required this.name, required this.style, this.isRequest = false});
}

class StoreItem {
  final String id;
  final String name;
  final String category; // Hairstyle, Hair Color, Eyes, Outfit, Accessory, Art Style, Service
  final int priceStars;
  final String glyph;
  final String description;
  final String? applyKey; // null for services (e.g. AI regeneration)
  final String? applyValue;
  final int? applyColor;
  const StoreItem({
    required this.id,
    required this.name,
    required this.category,
    required this.priceStars,
    required this.glyph,
    required this.description,
    this.applyKey,
    this.applyValue,
    this.applyColor,
  });

  AvatarStyle applyTo(AvatarStyle s) {
    switch (applyKey) {
      case 'hairStyle':
        return s.copyWith(hairStyle: applyValue);
      case 'hairColor':
        return s.copyWith(hairColor: applyColor == null ? s.hairColor : Color(applyColor!));
      case 'eyeColor':
        return s.copyWith(eyeColor: applyColor == null ? s.eyeColor : Color(applyColor!));
      case 'outfit':
        return s.copyWith(outfit: applyValue);
      case 'accessory':
        return s.copyWith(accessory: applyValue);
      case 'artStyle':
        return s.copyWith(artStyle: applyValue);
      default:
        return s;
    }
  }
}

const storeItems = <StoreItem>[
  StoreItem(id: 'hair_twin', name: 'Twin Tails', category: 'Hairstyle', priceStars: 80, glyph: '🎀', description: 'Bouncy twin tails with sway animation.', applyKey: 'hairStyle', applyValue: 'Twin Tails'),
  StoreItem(id: 'hair_bob', name: 'Short Bob', category: 'Hairstyle', priceStars: 70, glyph: '✂️', description: 'Chic short bob, soft and light.', applyKey: 'hairStyle', applyValue: 'Short Bob'),
  StoreItem(id: 'hair_pony', name: 'High Ponytail', category: 'Hairstyle', priceStars: 90, glyph: '🌟', description: 'High ponytail that sways as you move.', applyKey: 'hairStyle', applyValue: 'Ponytail'),
  StoreItem(id: 'color_rose', name: 'Rose Pink Hair', category: 'Hair Color', priceStars: 60, glyph: '🌸', description: 'Soft rose-pink gradient hair.', applyKey: 'hairColor', applyColor: 0xFFFFB7D5),
  StoreItem(id: 'color_ocean', name: 'Ocean Blue Hair', category: 'Hair Color', priceStars: 60, glyph: '🌊', description: 'Cool ocean-blue gradient hair.', applyKey: 'hairColor', applyColor: 0xFF8EA8E8),
  StoreItem(id: 'color_mint', name: 'Mint Hair', category: 'Hair Color', priceStars: 60, glyph: '🍃', description: 'Fresh mint gradient hair.', applyKey: 'hairColor', applyColor: 0xFF7ED6A5),
  StoreItem(id: 'eyes_gold', name: 'Golden Gem Eyes', category: 'Eyes', priceStars: 100, glyph: '✨', description: 'Warm golden gem eyes with sparkle.', applyKey: 'eyeColor', applyColor: 0xFFD97706),
  StoreItem(id: 'eyes_rose', name: 'Rose Gem Eyes', category: 'Eyes', priceStars: 100, glyph: '💗', description: 'Rose gem eyes with soft shine.', applyKey: 'eyeColor', applyColor: 0xFFEC4899),
  StoreItem(id: 'outfit_dress', name: 'Star Dress', category: 'Outfit', priceStars: 150, glyph: '👗', description: 'Twinkling star dress, MikaChan style.', applyKey: 'outfit', applyValue: 'Star Dress'),
  StoreItem(id: 'outfit_sweater', name: 'Cozy Sweater', category: 'Outfit', priceStars: 120, glyph: '🧶', description: 'Chunky cozy sweater for lofi nights.', applyKey: 'outfit', applyValue: 'Cozy Sweater'),
  StoreItem(id: 'outfit_gaming', name: 'Gaming Tee', category: 'Outfit', priceStars: 110, glyph: '🎮', description: 'Casual gaming tee.', applyKey: 'outfit', applyValue: 'Gaming Tee'),
  StoreItem(id: 'acc_wings', name: 'Angel Wings', category: 'Accessory', priceStars: 200, glyph: '🪽', description: 'Soft glowing angel wings.', applyKey: 'accessory', applyValue: 'Angel Wings'),
  StoreItem(id: 'acc_halo', name: 'Star Halo', category: 'Accessory', priceStars: 180, glyph: '💫', description: 'Floating star halo.', applyKey: 'accessory', applyValue: 'Star Halo'),
  StoreItem(id: 'acc_catears', name: 'Cat Ears + Bow', category: 'Accessory', priceStars: 90, glyph: '🐱', description: 'Black cat ears with a pink bow.', applyKey: 'accessory', applyValue: 'Cat Ears'),
  StoreItem(id: 'style_pixel', name: 'Pixel Pop Style', category: 'Art Style', priceStars: 130, glyph: '🟪', description: 'Chunkier pixel rendering for your avatar.', applyKey: 'artStyle', applyValue: 'Pixel Pop'),
  StoreItem(id: 'ai_regen', name: 'AI Avatar Regeneration', category: 'Service', priceStars: 250, glyph: '🤖', description: 'Regenerate your AI avatar from a new selfie. This is a Store service — it queues a regeneration request; the AI transformation itself is not connected yet (see onboarding).', applyKey: null),
];

StoreItem? findStoreItem(String id) {
  for (final i in storeItems) {
    if (i.id == id) return i;
  }
  return null;
}

const aiNotConnectedLabel = 'AI transformation: not connected yet — integration required';
