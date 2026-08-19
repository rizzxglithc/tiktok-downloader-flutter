import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../services/quick_share_service.dart';
import '../providers/download_provider.dart';
import '../providers/history_provider.dart';
import 'home_page.dart';
import 'stalker_page.dart';
import 'downloads_page.dart';
import 'history_page.dart';
import 'settings_page.dart';

class MainNavigationPage extends StatefulWidget {
  const MainNavigationPage({super.key});

  @override
  State<MainNavigationPage> createState() => _MainNavigationPageState();
}

class _MainNavigationPageState extends State<MainNavigationPage> {
  int _currentIndex = 0;

  final List<Widget> _pages = const [
    HomePage(),
    StalkerPage(),
    DownloadsPage(),
    HistoryPage(),
    SettingsPage(),
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final downloadProvider = context.read<DownloadProvider>();
      final historyProvider = context.read<HistoryProvider>();

      downloadProvider.onDownloadCompleted = () {
        historyProvider.loadHistory();
      };

      // If a share comes in, switch to Home tab
      QuickShareService.onSharedUrlReceived.listen((_) {
        if (mounted && _currentIndex != 0) {
          setState(() => _currentIndex = 0);
        }
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final downloadProvider = context.watch<DownloadProvider>();
    final activeCount = downloadProvider.activeCount;

    return Scaffold(
      backgroundColor: AppColors.background,
      extendBody: true,
      body: IndexedStack(
        index: _currentIndex,
        children: _pages,
      ),
      bottomNavigationBar: _buildPremiumFloatingNavbar(activeCount),
    );
  }

  Widget _buildPremiumFloatingNavbar(int activeCount) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isCompact = screenWidth < 360;

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.fromLTRB(isCompact ? 8 : 12, 0, isCompact ? 8 : 12, 10),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(30),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 28, sigmaY: 28),
            child: Container(
              height: 64,
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 5),
              decoration: BoxDecoration(
                color: const Color(0xFF121214).withOpacity(0.94),
                borderRadius: BorderRadius.circular(30),
                border: Border.all(
                  color: const Color(0xFF28282C),
                  width: 1.2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.65),
                    blurRadius: 28,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildNavItem(0, Icons.download_for_offline_rounded, 'Unduh'),
                  _buildNavItem(1, Icons.radar_rounded, 'Stalk'),
                  _buildNavItem(2, Icons.cloud_download_rounded, 'Proses', badgeCount: activeCount),
                  _buildNavItem(3, Icons.history_rounded, 'Riwayat'),
                  _buildNavItem(4, Icons.settings_rounded, 'Setelan'),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(int index, IconData icon, String label, {int badgeCount = 0}) {
    final isSelected = _currentIndex == index;

    return GestureDetector(
      onTap: () {
        setState(() => _currentIndex = index);
        if (index == 3) {
          context.read<HistoryProvider>().loadHistory();
        }
      },
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOutCubic,
        padding: EdgeInsets.symmetric(
          horizontal: isSelected ? 12 : 7,
          vertical: 8,
        ),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: Colors.white.withOpacity(0.25),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Stack(
          clipBehavior: Clip.none,
          alignment: Alignment.center,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  icon,
                  color: isSelected ? Colors.black : AppColors.textMuted,
                  size: 21,
                ),
                if (isSelected) ...[
                  const SizedBox(width: 6),
                  Text(
                    label,
                    style: const TextStyle(
                      color: Colors.black,
                      fontSize: 12.5,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.2,
                    ),
                  ),
                ],
              ],
            ),
            if (badgeCount > 0 && !isSelected)
              Positioned(
                top: -4,
                right: -6,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    '$badgeCount',
                    style: const TextStyle(
                      color: Colors.black,
                      fontSize: 9,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
