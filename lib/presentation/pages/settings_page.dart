import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import '../../core/constants/app_colors.dart';
import '../../core/utils/formatters.dart';
import '../providers/settings_provider.dart';
import '../providers/history_provider.dart';
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

  void _showQuickShareGuide() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF18181B),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.share_rounded, color: Colors.white, size: 22),
            SizedBox(width: 10),
            Text(
              'Cara Pakai Quick Share',
              style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _GuideStep(
              step: '1',
              title: 'Buka Media Sosial',
              desc: 'Buka aplikasi TikTok, Instagram, Twitter/X, atau YouTube.',
            ),
            SizedBox(height: 12),
            _GuideStep(
              step: '2',
              title: 'Klik Tombol "Bagikan"',
              desc: 'Klik ikon Share / Bagikan pada video, slide, atau lagu.',
            ),
            SizedBox(height: 12),
            _GuideStep(
              step: '3',
              title: 'Pilih "MyDownloader"',
              desc: 'Pilih MyDownloader di daftar menu, aplikasi akan otomatis memproses tautan tanpa copy-paste manual!',
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Mengerti', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
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
                      borderRadius: BorderRadius.circular(14),
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
                          'Versi 1.2.0 • Universal Media Downloader',
                          style: TextStyle(color: AppColors.textMuted, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // 2. Quick Share Feature Spotlight
            const Text(
              'Fitur Unggulan',
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
              onTap: _showQuickShareGuide,
              child: Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.white10,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.share_rounded, color: Colors.white, size: 20),
                  ),
                  SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Quick Share (Unduh via Menu Bagikan)',
                          style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold),
                        ),
                        SizedBox(height: 2),
                        Text(
                          'Unduh langsung dari TikTok, IG, FB tanpa copy-paste',
                          style: TextStyle(color: AppColors.textMuted, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                  Icon(Icons.chevron_right_rounded, color: AppColors.textMuted, size: 20),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // 3. Storage Section
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
                      final shouldClear = await showDialog<bool>(
                        context: context,
                        builder: (ctx) => AlertDialog(
                          backgroundColor: const Color(0xFF18181B),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          title: const Row(
                            children: [
                              Icon(Icons.cleaning_services_rounded, color: AppColors.primary, size: 20),
                              SizedBox(width: 10),
                              Text('Hapus Cache & Riwayat?', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                            ],
                          ),
                          content: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Ukuran cache saat ini: ${Formatters.formatBytes(settings.storageUsedBytes)}',
                                style: const TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w600),
                              ),
                              const SizedBox(height: 8),
                              const Text(
                                'Membersihkan cache akan menghapus file sementara, thumbnail gambar, dan mengosongkan daftar video secara responsif.',
                                style: TextStyle(color: AppColors.textSecondary, fontSize: 13, height: 1.4),
                              ),
                            ],
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(ctx, false),
                              child: const Text('Batal', style: TextStyle(color: AppColors.textMuted)),
                            ),
                            ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.error,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                              ),
                              onPressed: () => Navigator.pop(ctx, true),
                              child: const Text('Bersihkan', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                            ),
                          ],
                        ),
                      );

                      if (shouldClear == true && context.mounted) {
                        await settings.clearCache();
                        if (context.mounted) {
                          await context.read<HistoryProvider>().clearAll();
                          CustomToast.showSuccess(context, 'Cache dan daftar riwayat video berhasil dibersihkan');
                        }
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

            // 4. Download Preferences
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

            // 5. App Sharing & Disclaimer
            GlassCard(
              padding: const EdgeInsets.all(16),
              borderRadius: 16,
              onTap: () {
                Share.share('Unduh video tanpa watermark, slide foto, dan musik dari TikTok, IG, FB, dll dengan MyDownloader Pro!');
              },
              child: const Row(
                children: [
                  Icon(Icons.share_outlined, color: Colors.white, size: 20),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Bagikan Aplikasi MyDownloader',
                      style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w500),
                    ),
                  ),
                  Icon(Icons.chevron_right_rounded, color: AppColors.textMuted, size: 18),
                ],
              ),
            ),
            const SizedBox(height: 16),

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
                      'MyDownloader adalah aplikasi utilitas independen dan tidak berafiliasi resmi dengan TikTok, Instagram, Meta, atau platform lainnya. Gunakan untuk kebutuhan pengunduhan media pribadi yang sah.',
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

class _GuideStep extends StatelessWidget {
  final String step;
  final String title;
  final String desc;

  const _GuideStep({
    required this.step,
    required this.title,
    required this.desc,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 22,
          height: 22,
          decoration: const BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
          ),
          alignment: Alignment.center,
          child: Text(
            step,
            style: const TextStyle(color: Colors.black, fontSize: 11, fontWeight: FontWeight.bold),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 2),
              Text(
                desc,
                style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
