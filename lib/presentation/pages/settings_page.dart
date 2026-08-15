import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/utils/formatters.dart';
import '../providers/settings_provider.dart';
import '../widgets/custom_toast.dart';
import '../widgets/glass_card.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final settingsProvider = context.watch<SettingsProvider>();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Pengaturan'),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          children: [
            // Section 1: Preferensi Unduhan
            const Padding(
              padding: EdgeInsets.only(left: 4, bottom: 8),
              child: Text(
                'Preferensi Unduhan',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            GlassCard(
              padding: const EdgeInsets.symmetric(vertical: 4),
              borderRadius: 18,
              child: Column(
                children: [
                  SwitchListTile(
                    value: settingsProvider.autoSaveToGallery,
                    onChanged: (val) => settingsProvider.setAutoSaveToGallery(val),
                    activeColor: AppColors.primary,
                    title: const Text(
                      'Simpan Otomatis ke Galeri',
                      style: TextStyle(color: AppColors.textPrimary, fontSize: 14, fontWeight: FontWeight.w600),
                    ),
                    subtitle: const Text(
                      'Video MP4 langsung muncul di aplikasi Foto/Galeri HP.',
                      style: TextStyle(color: AppColors.textMuted, fontSize: 12),
                    ),
                  ),
                  const Divider(color: Colors.white10, height: 1, indent: 16, endIndent: 16),
                  SwitchListTile(
                    value: settingsProvider.hdByDefault,
                    onChanged: (val) => settingsProvider.setHdByDefault(val),
                    activeColor: AppColors.primary,
                    title: const Text(
                      'Kualitas HD sebagai Utama',
                      style: TextStyle(color: AppColors.textPrimary, fontSize: 14, fontWeight: FontWeight.w600),
                    ),
                    subtitle: const Text(
                      'Selalu gunakan resolusi tertinggi jika tersedia di server.',
                      style: TextStyle(color: AppColors.textMuted, fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Section 2: Penyimpanan & Cache
            const Padding(
              padding: EdgeInsets.only(left: 4, bottom: 8),
              child: Text(
                'Penyimpanan & Cache',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            GlassCard(
              padding: const EdgeInsets.all(16),
              borderRadius: 18,
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Penyimpanan Unduhan',
                            style: TextStyle(color: AppColors.textPrimary, fontSize: 14, fontWeight: FontWeight.w600),
                          ),
                          SizedBox(height: 2),
                          Text(
                            'Total file yang tersimpan di memori',
                            style: TextStyle(color: AppColors.textMuted, fontSize: 12),
                          ),
                        ],
                      ),
                      Text(
                        Formatters.formatBytes(settingsProvider.storageUsedBytes),
                        style: const TextStyle(
                          color: AppColors.primary,
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.surface,
                      foregroundColor: AppColors.error,
                      elevation: 0,
                      side: const BorderSide(color: Colors.white10),
                      minimumSize: const Size.fromHeight(44),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    icon: const Icon(Icons.cleaning_services_rounded, size: 18),
                    label: const Text('Bersihkan Cache Unduhan'),
                    onPressed: () => _confirmClearCache(context, settingsProvider),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Section 3: Tentang & Disclaimer
            const Padding(
              padding: EdgeInsets.only(left: 4, bottom: 8),
              child: Text(
                'Tentang Aplikasi',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            GlassCard(
              padding: const EdgeInsets.all(16),
              borderRadius: 18,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.verified_rounded, color: AppColors.primary, size: 20),
                      SizedBox(width: 8),
                      Text(
                        'TikTok Downloader Pro',
                        style: TextStyle(color: AppColors.textPrimary, fontSize: 15, fontWeight: FontWeight.w700),
                      ),
                      Spacer(),
                      Text('v1.0.0', style: TextStyle(color: AppColors.textMuted, fontSize: 12)),
                    ],
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Aplikasi pengunduh video & audio TikTok tanpa watermark berkecepatan tinggi dengan antarmuka Glassmorphism modern.',
                    style: TextStyle(color: AppColors.textSecondary, fontSize: 12, height: 1.4),
                  ),
                  const SizedBox(height: 12),
                  const Divider(color: Colors.white10, height: 1),
                  const SizedBox(height: 12),
                  const Text(
                    'Pemberitahuan Hak Cipta:',
                    style: TextStyle(color: AppColors.warning, fontSize: 12, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Aplikasi ini ditujukan untuk penggunaan pribadi dan backup konten milik Anda. Pastikan Anda memiliki izin dari pembuat konten sebelum mengunduh atau membagikan ulang video/audio.',
                    style: TextStyle(color: AppColors.textMuted, fontSize: 11, height: 1.3),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  void _confirmClearCache(BuildContext context, SettingsProvider settingsProvider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: BorderSide(color: AppColors.glassBorder),
        ),
        title: const Text('Bersihkan Cache?', style: TextStyle(color: Colors.white, fontSize: 16)),
        content: const Text(
          'Semua file unduhan di folder lokal aplikasi akan dibersihkan.',
          style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal', style: TextStyle(color: AppColors.textMuted)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () async {
              Navigator.pop(context);
              await settingsProvider.clearCache();
              if (context.mounted) {
                CustomToast.show(context, message: 'Cache berhasil dibersihkan.', type: ToastType.success);
              }
            },
            child: const Text('Bersihkan', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}
