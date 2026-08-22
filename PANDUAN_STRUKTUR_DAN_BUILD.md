# 📖 Panduan Lengkap Struktur Proyek & Cara Build APK (MyDownloader Pro)

Dokumentasi resmi ini memuat panduan lengkap mengenai arsitektur kode sumber, struktur direktori, alur data (*Data Flow*), konfigurasi izin Android, hingga langkah-langkah kompilasi (*Build*) menjadi file APK/AAB yang siap diinstal atau dipublikasikan.

---

## 📑 Daftar Isi
1. [Tentang Proyek](#1-tentang-proyek)
2. [Prasyarat Sistem (Prerequisites)](#2-prasyarat-sistem-prerequisites)
3. [Struktur Direktori & Arsitektur (Clean Architecture)](#3-struktur-direktori--arsitektur-clean-architecture)
4. [Alur Kerja Kode (Data Flow)](#4-alur-kerja-kode-data-flow)
5. [Daftar Dependensi & Plugin](#5-daftar-dependensi--plugin)
6. [Konfigurasi Android & Permissions](#6-konfigurasi-android--permissions)
7. [Langkah-Langkah Build APK (Debug & Release)](#7-langkah-langkah-build-apk-debug--release)
8. [Automasi Build dengan GitHub Actions (CI/CD)](#8-automasi-build-dengan-github-actions-cicd)
9. [Solusi Masalah Umum (Troubleshooting)](#9-solusi-masalah-umum-troubleshooting)

---

## 1. Tentang Proyek

**MyDownloader Pro** adalah aplikasi Android multifungsi yang dibangun menggunakan framework **Flutter** dan bahasa pemrograman **Dart**. Aplikasi ini memiliki 2 fitur inti:
1. **Multi-Platform Downloader**: Mengunduh video tanpa watermark, audio MP3, story, dan carousel foto dari **TikTok, Douyin (抖音), Instagram, Facebook, Twitter/X, YouTube, Threads, CapCut, Spotify, SoundCloud, Apple Music, TeraBox, Pinterest, SnackVideo, Kuaishou**, dll.
2. **OSINT Stalker Hub**: Melacak statistik publik profil pengguna (Followers, Following, Likes, Bio, Tweets, Repositori, Avatar HD) dari **TikTok, Instagram, Twitter/X, Threads, YouTube, GitHub, dan Roblox**.

---

## 2. Prasyarat Sistem (Prerequisites)

Sebelum menjalankan atau mengompilasi proyek ini, pastikan komputer/laptop Anda telah terpasang:

| Komponen | Versi yang Direkomendasikan | Catatan |
| :--- | :--- | :--- |
| **Flutter SDK** | `v3.24.0` atau lebih baru (`stable channel`) | [Download Flutter](https://docs.flutter.dev/get-started/install) |
| **Dart SDK** | `v3.5.0` atau lebih baru (termasuk di dalam Flutter) | Otomatis terpasang |
| **Java Development Kit (JDK)** | **JDK 17** (OpenJDK / Zulu JDK 17) | Wajib JDK 17 untuk Gradle modern |
| **Android SDK** | API Level 34 (Android 14) / Min SDK 21 | Via Android Studio SDK Manager |
| **Editor / IDE** | VS Code atau Android Studio | Pasang ekstensi Flutter & Dart |

---

## 3. Struktur Direktori & Arsitektur (Clean Architecture)

Aplikasi ini mengadopsi pola **Clean Architecture** berlapis (*Layered Architecture*) yang memisahkan logika bisnis (*Domain*), antarmuka (*Presentation*), dan data (*Data & Services*):

```text
/root/web
├── android/                        # Konfigurasi Native Android (Gradle, Manifest, Icons)
│   ├── app/
│   │   ├── build.gradle            # Konfigurasi compileSdk, minSdk, targetSdk, signing
│   │   └── src/main/
│   │       ├── AndroidManifest.xml # Izin internet, storage, dan Quick Share intent-filter
│   │       └── res/                # Ikon aplikasi & tema native
│   └── build.gradle                # Gradle buildscript & dependencies
├── assets/                         # Aset gambar statis & logo aplikasi (app_logo.png)
├── lib/                            # Kode sumber utama Flutter (Dart)
│   ├── core/                       # Komponen fondasi & utilitas global
│   │   ├── constants/
│   │   │   ├── api_constants.dart  # URL endpoint scraper & base URL
│   │   │   └── app_colors.dart     # Skema warna neon dark theme
│   │   ├── errors/
│   │   │   └── app_exceptions.dart # Custom Exception & penanganan error
│   │   ├── network/
│   │   │   └── api_client.dart     # Wrapper HTTP client (Dio) dengan interceptor
│   │   ├── theme/
│   │   │   └── app_theme.dart      # Tema Material 3 Glassmorphism
│   │   └── utils/
│   │       ├── formatters.dart     # Format ukuran file (MB/GB), angka singkat (1.2M), tanggal
│   │       └── url_validator.dart  # Regex deteksi platform & validasi URL
│   │
│   ├── data/                       # Lapisan data (Remote & Local)
│   │   ├── datasources/
│   │   │   ├── local_history_datasource.dart    # SharedPreferences local storage
│   │   │   ├── stalker_remote_datasource.dart  # Scraper TikTok, IG, X, Threads, YouTube, GitHub, Roblox
│   │   │   └── tiktok_remote_datasource.dart   # Scraper TikWM, Douyin (Snaptik), SC, TeraBox, CapCut
│   │   ├── models/
│   │   │   ├── download_item_model.dart        # DTO model riwayat unduhan
│   │   │   └── tiktok_video_model.dart         # DTO model media unduhan universal
│   │   └── repositories/
│   │       ├── history_repository_impl.dart    # Implementasi repository riwayat
│   │       └── tiktok_repository_impl.dart     # Implementasi repository media
│   │
│   ├── domain/                     # Lapisan logika bisnis murni (Pure Dart, tanpa UI)
│   │   ├── entities/
│   │   │   ├── download_item.dart  # Entitas item unduhan
│   │   │   ├── stalk_models.dart   # Entitas profil Stalker (TikTok, Twitter, IG, dll)
│   │   │   └── tiktok_video.dart   # Entitas universal video/audio
│   │   ├── repositories/
│   │   │   ├── history_repository.dart         # Interface kontrak repository riwayat
│   │   │   └── tiktok_repository.dart          # Interface kontrak repository media
│   │   └── usecases/
│   │       ├── get_tiktok_video_usecase.dart   # UseCase ambil detail media
│   │       ├── get_history_usecase.dart        # UseCase ambil riwayat
│   │       ├── save_history_usecase.dart       # UseCase simpan riwayat
│   │       └── delete_history_usecase.dart     # UseCase hapus riwayat
│   │
│   ├── presentation/               # Lapisan UI & State Management
│   │   ├── pages/
│   │   │   ├── main_navigation_page.dart       # Navigasi utama (PageView + Floating Navbar)
│   │   │   ├── home_page.dart                  # Halaman Beranda / Downloader
│   │   │   ├── stalker_page.dart               # Halaman Stalker Hub (OSINT Lookup)
│   │   │   ├── downloads_page.dart             # Halaman antrean proses unduh aktif
│   │   │   ├── history_page.dart               # Halaman riwayat unduhan offline
│   │   │   ├── settings_page.dart              # Halaman pengaturan & panduan
│   │   │   ├── video_result_page.dart          # Halaman hasil scraping & opsi unduh
│   │   │   └── video_viewer_page.dart          # Halaman pemutar video fullscreen
│   │   ├── providers/
│   │   │   ├── download_provider.dart          # Provider antrean unduhan (Dio streaming)
│   │   │   ├── history_provider.dart           # Provider filter & data riwayat
│   │   │   ├── settings_provider.dart          # Provider preferensi & storage analyser
│   │   │   ├── stalker_provider.dart           # Provider pelacakan profil akun
│   │   │   └── tiktok_provider.dart            # Provider ekstraksi tautan media
│   │   └── widgets/
│   │       ├── custom_toast.dart               # Toast notifikasi kustom
│   │       ├── glass_button.dart               # Tombol bergaya frosted glass
│   │       ├── glass_card.dart                 # Kartu transparan dengan blur filter
│   │       ├── glass_text_field.dart           # Input field bergaya futuristik
│   │       ├── gradient_progress_bar.dart      # Progress bar gradasi download
│   │       ├── shimmer_loader.dart             # Animasi loading shimmer
│   │       └── video_preview_player.dart       # Video player widget dengan kontrol kustom
│   │
│   ├── services/                   # Layanan sistem native & background service
│   │   ├── clipboard_service.dart  # Layanan deteksi papan klip (Clipboard)
│   │   ├── download_engine.dart    # Engine download streaming multi-chunk + Gal integration
│   │   ├── media_storage_service.dart # Layanan simpan galeri & share media
│   │   ├── quick_share_service.dart   # Layanan penerima tautan dari menu Share Android
│   │   └── settings_service.dart   # Layanan persistent settings
│   │
│   └── main.dart                   # Entry point aplikasi (Inisialisasi provider & tema)
├── pubspec.yaml                    # Konfigurasi dependensi packages & aset
└── README.md                       # Ringkasan proyek
```

---

## 4. Alur Kerja Kode (Data Flow)

1. **Input / Quick Share**:
   - Pengguna menempelkan tautan pada `HomePage` ATAU membagikan video langsung dari aplikasi media sosial menggunakan menu *"Bagikan ke MyDownloader"*.
   - `QuickShareService` mendeteksi tautan melalui Android `Intent Filter` dan meneruskannya ke `HomePage`.
2. **Validasi & Deteksi Platform**:
   - `UrlValidator.detectPlatform(url)` mendeteksi jenis platform (TikTok, Douyin, Instagram, SoundCloud, dll.).
3. **Scraping & Resolusi Media**:
   - `TikTokProvider` memanggil `GetTikTokVideoUseCase` -> `TikTokRepository` -> `TikTokRemoteDataSource`.
   - DataSource mengeksekusi request HTTP ke API scraper yang sesuai, mengekstrak resolusi HD, MP3, cover, dan slide foto.
4. **Unduh & Penyimpanan Galeri**:
   - Pengguna memilih opsi (Unduh Video HD / Audio MP3 / Foto).
   - `DownloadProvider` menjalankan `DownloadEngine` menggunakan `Dio.download` secara *streaming* dengan pelacakan *speed* (KB/s) dan persentase *progress*.
   - Setelah selesai, `MediaStorageService` mendaftarkan file ke Galeri HP (*Scoped Storage Android*).
5. **Penyimpanan Riwayat**:
   - Item otomatis tersimpan ke `LocalHistoryDataSource` (`SharedPreferences`) dan dapat diputar offline kapan saja.

---

## 5. Daftar Dependensi & Plugin (`pubspec.yaml`)

```yaml
dependencies:
  flutter:
    sdk: flutter
  provider: ^6.1.2             # State management reaktif
  dio: ^5.7.0                  # HTTP client & streaming file downloader
  video_player: ^2.9.2         # Pemutar video internal
  cached_network_image: ^3.4.1 # Cache gambar profil & cover media
  shared_preferences: ^2.3.3   # Penyimpanan data lokal offline
  path_provider: ^2.1.5        # Manajemen path direktori penyimpanan perangkat
  open_filex: ^4.6.0           # Membuka file hasil unduhan dengan aplikasi bawaan
  share_plus: ^10.1.2          # Membagikan file/teks ke aplikasi lain
  intl: ^0.20.1                # Format tanggal & angka lokal Indonesia
  flutter_svg: ^2.0.16         # Rendering ikon SVG
  shimmer: ^3.0.0              # Animasi loading placeholder
  gal: ^2.3.1                  # Integrasi penyimpanan langsung ke Galeri Android/iOS
```

---

## 6. Konfigurasi Android & Permissions

File konfigurasi berada di `android/app/src/main/AndroidManifest.xml`:

- **Izin Jaringan & Penyimpanan**:
  ```xml
  <uses-permission android:name="android.intent.action.INTERNET"/>
  <uses-permission android:name="android.permission.ACCESS_NETWORK_STATE"/>
  <uses-permission android:name="android.permission.WRITE_EXTERNAL_STORAGE" android:maxSdkVersion="28"/>
  <uses-permission android:name="android.permission.READ_EXTERNAL_STORAGE" android:maxSdkVersion="32"/>
  <uses-permission android:name="android.permission.READ_MEDIA_VIDEO"/>
  <uses-permission android:name="android.permission.READ_MEDIA_AUDIO"/>
  <uses-permission android:name="android.permission.READ_MEDIA_IMAGES"/>
  ```

- **Quick Share Intent Filter (Menerima tautan dari aplikasi lain)**:
  ```xml
  <intent-filter>
      <action android:name="android.intent.action.SEND"/>
      <category android:name="android.intent.category.DEFAULT"/>
      <data android:mimeType="text/plain"/>
  </intent-filter>
  ```

---

## 7. Langkah-Langkah Build APK (Debug & Release)

### Langkah 1: Buka Terminal dan Masuk ke Direktori Proyek
```bash
cd /path/ke/folder/project
```

### Langkah 2: Verifikasi Lingkungan Flutter
Pastikan tidak ada kendala pada instalasi Flutter:
```bash
flutter doctor -v
```

### Langkah 3: Ambil Seluruh Dependensi
```bash
flutter pub get
```

### Langkah 4: Jalankan Aplikasi dalam Mode Debug (Testing)
Hubungkan HP Android dengan USB Debugging aktif atau jalankan Emulator:
```bash
flutter run
```

### Langkah 5: Kompilasi APK Rilis (Universal Release APK)
Perintah ini menghasilkan 1 file APK universal yang mendukung semua arsitektur prosesor Android (arm64-v8a, armeabi-v7a, x86_64):
```bash
flutter build apk --release
```
*File APK yang dihasilkan akan berada di*:
`build/app/outputs/flutter-apk/app-release.apk`

### Langkah 6: Kompilasi Split APK (Ukuran File Jauh Lebih Kecil ~15 MB)
Jika Anda ingin ukuran APK lebih ramping untuk masing-masing tipe prosesor:
```bash
flutter build apk --split-per-abi --release
```
*File APK yang dihasilkan*:
- `app-arm64-v8a-release.apk` (Untuk 90%+ HP Android modern 64-bit)
- `app-armeabi-v7a-release.apk` (Untuk HP Android 32-bit lama)
- `app-x86_64-release.apk` (Untuk Emulator PC)

### Langkah 7: Kompilasi Android App Bundle (.aab untuk Google Play Store)
```bash
flutter build appbundle --release
```
*File AAB yang dihasilkan*:
`build/app/outputs/bundle/release/app-release.aab`

---

## 8. Automasi Build dengan GitHub Actions (CI/CD)

Proyek ini telah dilengkapi dengan script otomatisasi CI/CD di `.github/workflows/build-apk.yml`. Setiap kali Anda melakukan `git push` ke branch `main`, GitHub Actions akan:
1. Memasang JDK 17 & Flutter SDK stable secara otomatis.
2. Mengunduh dependensi (`flutter pub get`).
3. Mengompilasi APK Release (`flutter build apk --release`).
4. Mengunggah hasil build sebagai *Artifact* dan *GitHub Release*.

---

## 9. Solusi Masalah Umum (Troubleshooting)

1. **Error: `Java version mismatch` / `Unsupported class file version`**:
   - **Penyebab**: Menggunakan Java versi 8 atau Java 21 yang tidak kompatibel dengan Gradle tertentu.
   - **Solusi**: Pasang dan gunakan **Java JDK 17**. Set environment variable `JAVA_HOME` ke direktori JDK 17.

2. **Error: `Gradle build daemon disappeared`**:
   - **Solusi**: Bersihkan cache build dengan menjalankan:
     ```bash
     flutter clean
     flutter pub get
     flutter build apk --release
     ```

3. **Error Izin Penyimpanan Galeri di Android 13+**:
   - **Solusi**: Aplikasi sudah menggunakan library `gal` dan `Scoped Storage API` sehingga tidak memerlukan izin `WRITE_EXTERNAL_STORAGE` manual pada Android 13 ke atas.

---

*Dokumen ini dibuat untuk MyDownloader Pro. Hak Cipta & Source Code Bebas Digunakan untuk Pengembangan Lebih Lanjut.*
