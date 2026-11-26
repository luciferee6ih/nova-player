<p align="center">
  <img src="assets/branding/readme_logo.png" width="140" />
</p>

<h1 align="center">NOVA Player</h1>

<p align="center">
  <b>An offline music player for Android with a Liquid Glass look.</b><br />
  Word-synced lyrics, album-coloured themes, a deep equalizer, and your own music library.
</p>

<p align="center" dir="rtl">
  <b>پخش‌کننده‌ی آفلاین موسیقی برای اندروید، با طراحی شیشه‌ای (Liquid Glass).</b><br />
  متن همگام کلمه‌به‌کلمه، رنگ‌بندی از روی کاور آلبوم، اکولایزر کامل، و کتابخانه‌ی موسیقی خودتان.
</p>

<p align="center">
  <a href="https://github.com/luciferee6ih/nova-player/releases/latest"><img height="20" src="https://img.shields.io/github/v/release/luciferee6ih/nova-player?style=flat-square&color=7c3aed" /></a>
  <img height="20" src="https://img.shields.io/badge/platform-Android-blueviolet?style=flat-square" />
  <img height="20" src="https://img.shields.io/badge/license-GPL--3.0-green?style=flat-square" />
</p>

<p align="center">
  <a href="#english">English</a> · <a href="#فارسی">فارسی</a>
</p>

<p align="center">
  <a href="https://github.com/luciferee6ih/nova-player/releases/latest"><b>⬇ Download / دانلود</b></a>
</p>

---

## English

### Download

Grab the latest APK from [Releases](https://github.com/luciferee6ih/nova-player/releases/latest). It's a single file that works on any phone running Android 10 or newer.

### About

Just your own music files, no account, no ads, no internet needed. Here's what's inside:

- Floating Liquid Glass navigation bar (classic style available in Settings)
- Beat Glass: a glass visualizer that moves with the music (optional)
- Harmonic Queue: BPM and musical key for each track, with smooth key-matched ordering (optional)
- Local library with albums, artists, genres, folders, playlists and smart views
- Line- and word-synced lyrics (local `.lrc`, embedded tags, or online sources), with a lyrics editor
- 18-band equalizer, AutoEQ headphone correction, ReplayGain, crossfade and gapless playback
- Several Now Playing styles and dynamic colours from the artwork
- Full Persian and English interface with right-to-left layout
- "Reduce effects" turns on automatically on slower phones for smooth scrolling

### Build from source

Requirements: Flutter **3.47.7**, Git.

```bash
git clone https://github.com/luciferee6ih/nova-player.git
cd nova-player
flutter pub get
flutter analyze
flutter test
flutter build apk --flavor github --release
```

Release builds are signed with `android/key.properties` when present, otherwise with the debug key.

> Note: `appambit_sdk_flutter` 1.2.x ships a file with the wrong case
> (`AppambitSdkFlutterPlugin.kt`). On Linux/macOS hosts, rename it in your pub cache to
> `AppAmbitSdkFlutterPlugin.kt` after `flutter pub get` (the CI workflows do this automatically).
> Crash reporting through it is **off** by default.

### Contact

- Telegram: [@theluciferee](https://t.me/theluciferee)
- Channel: [@theacproject](https://t.me/theacproject)
- Found a bug or have an idea? Open an [issue](https://github.com/luciferee6ih/nova-player/issues)

---

<div dir="rtl">

## فارسی

### دانلود

آخرین نسخه رو از [صفحه‌ی ریلیزها](https://github.com/luciferee6ih/nova-player/releases/latest) بگیر. یه فایل APK هست که روی همه‌ی گوشی‌های اندروید ۱۰ به بالا نصب می‌شه.

### درباره‌ی NOVA

یه موزیک‌پلیر برای آهنگ‌های خود گوشیت؛ بدون اکانت، بدون تبلیغ و بدون نیاز به اینترنت. چیزهایی که داره:

- نوار ناوبری شناور شیشه‌ای (Liquid Glass)؛ حالت کلاسیک هم در تنظیمات هست
- Beat Glass: نمایشگر شیشه‌ای که با ریتم آهنگ حرکت می‌کند (اختیاری)
- صف هارمونیک: نمایش BPM و گام هر آهنگ و چیدن نرم آهنگ‌ها بر اساس گام (اختیاری)
- کتابخانه‌ی محلی با آلبوم، خواننده، ژانر، پوشه، پلی‌لیست و نماهای هوشمند
- متن آهنگ همگام خط‌به‌خط و کلمه‌به‌کلمه (فایل ‎`.lrc`‎، تگ داخلی یا منابع آنلاین) همراه با ویرایشگر متن
- اکولایزر ۱۸ باند، اصلاح صدای هدفون (AutoEQ)، ReplayGain، کراس‌فید و پخش بدون فاصله
- چند سبک صفحه‌ی پخش و رنگ‌بندی خودکار از روی کاور
- رابط کامل فارسی و انگلیسی با چینش راست‌به‌چپ
- حالت «کاهش افکت‌ها» روی گوشی‌های ضعیف‌تر خودکار روشن می‌شود تا اسکرول روان بماند

### ساخت از سورس

نیازمندی‌ها: Flutter نسخه‌ی **3.47.7** و Git. دستورها مثل بخش انگلیسی است.

### ارتباط

- تلگرام: [‎@theluciferee](https://t.me/theluciferee)
- کانال: [‎@theacproject](https://t.me/theacproject)
- باگ دیدی یا ایده داری؟ تو [Issues](https://github.com/luciferee6ih/nova-player/issues) بنویس

</div>

---

## License / مجوز

NOVA Player is free software under the **GNU General Public License v3.0**. See [LICENSE](LICENSE).

<div dir="rtl">

NOVA Player نرم‌افزار آزاد تحت مجوز **GPL-3.0** است. جزئیات در [LICENSE](LICENSE).

</div>
