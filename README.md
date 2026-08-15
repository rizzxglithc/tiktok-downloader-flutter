# 🚀 TikTok Downloader Pro (Flutter Mobile App)

A modern, production-grade TikTok Downloader application built with **Flutter**, **Clean Architecture**, and a sleek **Dark Futuristic Glassmorphism UI**.

---

## ✨ Features

- 💎 **Dark Futuristic Glassmorphic UI**: Frosted surfaces with `BackdropFilter`, glowing neon accents, and smooth animations.
- ⚡ **Real TikTok API Integration**: Fetches video metadata, dynamic covers, author details, HD watermark-free video streams, and MP3 audio streams.
- 🎬 **In-App Video Preview Player**: Custom player controls (play/pause, timeline seeker, audio mute/unmute, and fullscreen).
- 📥 **Streaming Download Engine**: High-speed chunked streaming with `Dio`, real-time speed calculation, cancellation support, and auto-cleanup.
- 🖼️ **Gallery & Scoped Storage Integration**: Automatically registers MP4 videos to the device's Gallery / Photos album.
- 🎵 **Audio Extraction**: Clean MP3 download option for original sound.
- 📜 **Persistent History & Search**: Offline storage for downloads, filterable by Video/Audio, with instant in-app playback and system share sheet.
- 📋 **Smart Clipboard Integration**: Auto-detects and extracts valid TikTok URLs from dirty text.
- ⚙️ **Comprehensive Settings**: Storage space analyzer, auto-save preference, and download cache cleaner.

---

## 🛠️ Tech Stack & Architecture

- **Framework**: Flutter 3.24+ / Dart
- **Architecture**: Clean Architecture (Presentation, Domain, Data, Services)
- **State Management**: Provider
- **Networking & Download**: Dio (Streaming + CancelToken)
- **Media**: `video_player`, `cached_network_image`, `gal` (Gallery saving), `open_filex`, `share_plus`
- **Storage**: `shared_preferences`, `path_provider`
- **CI/CD**: GitHub Actions for automated Android APK builds.
