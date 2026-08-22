# 🚀 MyDownloader Pro - Ultimate Media Downloader & Stalker Hub

Aplikasi mobile berbasis **Flutter** dengan arsitektur **Clean Architecture** dan antarmuka **Dark Futuristic Glassmorphism UI** untuk mengunduh media dari berbagai platform sosial dan melacak profil publik secara instan.

---

## 🌟 Fitur Utama

### 📥 1. Multi-Platform Media Downloader
- **TikTok & Douyin (抖音)**: Unduh video tanpa watermark (No Watermark HD), Story, Slide Foto (Carousel), dan audio MP3 original bitrate.
- **Instagram**: Unduh Reels, Feed Video, Carousel Foto, dan IGTV.
- **Facebook**: Unduh video publik resolusi SD & HD.
- **Twitter / X**: Unduh video HD & GIF dari tweet.
- **YouTube**: Unduh video dan audio YouTube.
- **Threads**: Unduh video & media dari postingan Threads Meta.
- **CapCut**: Unduh template & video CapCut tanpa watermark.
- **Spotify, SoundCloud & Apple Music**: Ekstraksi dan unduh streaming musik audio MP3 kualitas jernih.
- **TeraBox**: Ekstraksi tautan unduhan langsung tanpa limit.
- **Pinterest, SnackVideo, Kuaishou**: Unduh video & gambar publik tanpa watermark.

### 🕵️‍♂️ 2. OSINT Stalker Hub (Pelacak Profil)
- **TikTok**: Cek Followers, Following, Total Likes, Bio, dan Foto Profil HD (720p).
- **Instagram**: Cek Total Postingan, Followers, Following, Bio, dan Foto Profil HD.
- **Twitter / X**: Cek Total Tweets, Followers, Following, Likes, Tanggal Pembuatan Akun, dan Bio.
- **Threads**: Cek Bio, Followers, Status Verifikasi, dan Avatar HD.
- **YouTube**: Cek Subscribers, Total Video, Channel Name & Preview.
- **GitHub**: Cek Repositori Publik, Followers, Following, Bio, dan Profil Developer.
- **Roblox**: Cek Avatar 3D, Display Name, Username, dan Status Pemain.

### ⚡ 3. Pengalaman Pengguna (UI/UX)
- **🔄 Gesture Swipe Navigation**: Geser layar ke kiri atau kanan untuk berpindah halaman dengan animasi mulus (*Bouncing Physics*).
- **💎 Dark Glassmorphism**: Permukaan *frosted glass* modern dengan efek `BackdropFilter` dan aksen neon dinamis.
- **🚀 Quick Share**: Mendukung menu "Bagikan ke MyDownloader" bawaan HP untuk mengunduh otomatis tanpa salin-tempel manual.
- **🎬 In-App Video & Audio Player**: Putar video langsung di dalam aplikasi sebelum atau sesudah mengunduh.
- **📜 Riwayat Offline**: Database lokal untuk mengelola, memutar, atau membagikan kembali media yang telah diunduh.

---

## 📂 Struktur Proyek (Clean Architecture)

```
lib/
├── core/                   # Utilitas global, tema, konstanta, dan network client
│   ├── constants/          # AppColors, ApiConstants
│   ├── errors/             # Custom Exceptions & Error Handler
│   ├── network/            # Dio API Client & Interceptors
│   ├── theme/              # Glassmorphism Dark Theme
│   └── utils/              # Formatters, UrlValidator
├── data/                   # Implementasi data, remote API, dan local storage
│   ├── datasources/        # TikTok/Media Scraper & Stalker Data Sources
│   ├── models/             # Data Transfer Objects (DTO) & JSON Parsers
│   └── repositories/       # Implementasi Repository Domain
├── domain/                 # Entitas bisnis, interface repository, dan UseCases
│   ├── entities/           # Media & Stalker Data Models
│   ├── repositories/       # Abstract Repository Contracts
│   └── usecases/           # Business Logic UseCases
├── presentation/           # Antarmuka Pengguna (UI) & State Management
│   ├── pages/              # MainNavigation, Home, Stalker, Downloads, History, Settings
│   ├── providers/          # ChangeNotifier State Providers
│   └── widgets/            # GlassCard, GlassTextField, ShimmerLoader, VideoPlayer
└── services/               # Layanan OS: Storage, Clipboard, QuickShare, Settings
```

---

## 🛠️ Panduan Build APK

Untuk panduan lengkap langkah demi langkah cara mengompilasi APK release, silakan baca file [PANDUAN_STRUKTUR_DAN_BUILD.md](PANDUAN_STRUKTUR_DAN_BUILD.md).

```bash
# 1. Install dependencies
flutter pub get

# 2. Jalankan di perangkat
flutter run

# 3. Build APK Release
flutter build apk --release
```

