import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/utils/formatters.dart';
import '../providers/settings_provider.dart';
import '../widgets/glass_card.dart';
import '../widgets/custom_toast.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<SettingsProvider>().calculateStorageUsed();
    });
  }

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsProvider>();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Pengaturan'),
        automaticallyImplyLeading: false,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 10, 20, 100),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. App Profile / Version Banner
            GlassCard(
              padding: const EdgeInsets.all(16),
              borderRadius: 18,
              child: Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E1E22),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.borderLight, width: 1),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: Image.asset(
                      'assets/app_logo.png',
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => const Icon(
                        Icons.download_rounded,
                        color: Colors.white,
                        size: 30,
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'MyDownloader Pro',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 2),
                        Text(
                          'Versi 1.1.0 (Universal Multi-Platform & Slides)',
                          style: TextStyle(color: AppColors.textMuted, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // 2. Storage Section
            const Text(
              'Penyimpanan & Memori',
              style: TextStyle(
                color: Colors.white,
                fontSize: 15,
                fontWeight: FontWeight.bold,
                letterSpacing: -0.2,
              ),
            ),
            const SizedBox(height: 10),
            GlassCard(
              padding: const EdgeInsets.all(16),
              borderRadius: 16,
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.storage_rounded, color: Colors.white, size: 20),
                          SizedBox(width: 10),
                          Text(
                            'Kapasitas File Unduhan',
                            style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w500),
                          ),
                        ],
                      ),
                      Text(
                        Formatters.formatBytes(settings.storageUsedBytes),
                        style: const TextStyle(color: AppColors.textSecondary, fontSize: 13, fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  const Divider(color: AppColors.border, height: 1),
                  const SizedBox(height: 14),
                  InkWell(
                    onTap: () async {
                      await settings.clearCache();
                      if (context.mounted) {
                        CustomToast.showSuccess(context, 'Cache aplikasi berhasil dibersihkan');
                      }
                    },
                    borderRadius: BorderRadius.circular(10),
                    child: const Padding(
                      padding: EdgeInsets.symmetric(vertical: 4),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.cleaning_services_rounded, color: AppColors.textSecondary, size: 18),
                              SizedBox(width: 10),
                              Text(
                                'Bersihkan Cache Gambar & Video',
                                style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
                              ),
                            ],
                          ),
                          Icon(Icons.chevron_right_rounded, color: AppColors.textMuted, size: 18),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // 3. Download Preferences
            const Text(
              'Preferensi',
              style: TextStyle(
                color: Colors.white,
                fontSize: 15,
                fontWeight: FontWeight.bold,
                letterSpacing: -0.2,
              ),
            ),
            const SizedBox(height: 10),
            GlassCard(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              borderRadius: 16,
              child: Column(
                children: [
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text(
                      'Simpan Otomatis ke Galeri',
                      style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w500),
                    ),
                    subtitle: const Text(
                      'Otomatis tampil di aplikasi Galeri / Foto HP Anda',
                      style: TextStyle(color: AppColors.textMuted, fontSize: 12),
                    ),
                    value: settings.autoSaveToGallery,
                    activeColor: Colors.white,
                    activeTrackColor: Colors.white30,
                    onChanged: (value) => settings.setAutoSaveToGallery(value),
                  ),
                  const Divider(color: AppColors.border, height: 1),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text(
                      'Kualitas Full HD sebagai Utama',
                      style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w500),
                    ),
                    subtitle: const Text(
                      'Prioritaskan media resolusi tertinggi saat tersedia',
                      style: TextStyle(color: AppColors.textMuted, fontSize: 12),
                    ),
                    value: settings.hdByDefault,
                    activeColor: Colors.white,
                    activeTrackColor: Colors.white30,
                    onChanged: (value) => settings.setHdByDefault(value),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // 4. Disclaimer Card
            GlassCard(
              padding: const EdgeInsets.all(14),
              borderRadius: 14,
              child: const Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.info_outline_rounded, color: AppColors.textMuted, size: 18),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'MyDownloader adalah aplikasi utilitas independen dan tidak berafiliasi resmi dengan TikTok, Instagram, atau Meta. Gunakan untuk kebutuhan pengunduhan media pribadi yang sah.',
                      style: TextStyle(color: AppColors.textMuted, fontSize: 11, height: 1.4),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
