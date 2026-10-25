# Kazumi

Cute pixel-lofi anime VTuber livestreaming + social app (Flutter, Android).

**v1 is local-only**: all data (follows, Stars, inventory, chats, posts) is stored
on-device with SharedPreferences. No backend, no server account.

## Highlights

- **Bottom nav**: Home, Discover, LIVE (raised centre), Messages, Profile + Go LIVE.
- **LIVE discovery + watch**: My Room LIVE (pixel-lofi bedroom) and Gaming LIVE
  (gameplay placeholder + avatar overlay), live chat saved locally, reactions,
  Follow toggle. Viewer counts are **demo data, labelled as demo** — never real.
- **LIVE Studio**: My Room / Gaming, title/category/privacy, avatar position &
  size, mic level test. **Local preview only** — LiveKit/WebRTC not connected.
- **Animated avatar (animation upgrade)**: layered avatar with separate smooth
  drivers — gentle sine breathing, slow hair sway, natural blinks every ~3.8s
  (quick ~170ms eased close), head tilt lerped over 450ms (easeInOutCubic),
  and a mic-driven mouth smoothed by an exponential moving average on real
  mic amplitude (no random mouth loop; closes smoothly when silent).
  All transitions use eased AnimatedSwitcher/AnimatedContainer/AnimatedPositioned
  (~300–500ms) — no snapping.
- **Store-only appearance**: no free avatar editor anywhere. All appearance
  changes are Store items bought with in-app Stars (no real money), with an
  explicit confirmation dialog, permanent inventory, and free Equip/Remove.
  Equipped look = LIVE look everywhere. Preview never changes your avatar.
- **AI avatar**: consent-first onboarding. Labelled exactly
  “AI transformation: not connected yet — integration required”. The avatar
  shown is a placeholder, never presented as an AI likeness. Later AI
  regeneration is a Store service.
- **Safety**: report/block/mute, creator chat-hide tools, privacy settings,
  local data deletion (server deletion N/A for local-only v1).

## Build

CI (`.github/workflows/build-apk.yml`, Flutter 3.47.5, Java 17) runs
`flutter analyze --no-fatal-infos`, `flutter test`, `flutter build apk --debug`
and `flutter build appbundle --release`, and uploads both artifacts.

Debug builds are signed with a fresh debug key per CI run: **uninstall any
previous Kazumi APK before installing a new one**.

## Remaining before store release

Play Console enrollment ($25), a release upload keystore, a privacy policy URL,
and future iOS work. LiveKit/WebRTC live transport and AI image generation are
not connected in v1.
