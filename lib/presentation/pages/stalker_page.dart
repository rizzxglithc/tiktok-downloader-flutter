import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:share_plus/share_plus.dart';
import '../../core/constants/app_colors.dart';
import '../../core/utils/formatters.dart';
import '../../domain/entities/stalk_models.dart';
import '../providers/stalker_provider.dart';
import '../widgets/glass_card.dart';
import '../widgets/custom_toast.dart';

class StalkerPage extends StatefulWidget {
  const StalkerPage({super.key});

  @override
  State<StalkerPage> createState() => _StalkerPageState();
}

class _StalkerPageState extends State<StalkerPage> {
  final TextEditingController _inputController = TextEditingController();
  final FocusNode _focusNode = FocusNode();

  @override
  void dispose() {
    _inputController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _handleSearch() {
    final text = _inputController.text.trim();
    if (text.isEmpty) {
      CustomToast.showError(context, 'Masukkan UID atau username target.');
      return;
    }
    _focusNode.unfocus();
    context.read<StalkerProvider>().search(text);
  }

  Future<void> _handlePaste() async {
    final clipboardData = await Clipboard.getData(Clipboard.kTextPlain);
    if (clipboardData?.text != null && clipboardData!.text!.isNotEmpty) {
      setState(() {
        _inputController.text = clipboardData.text!.trim();
      });
      CustomToast.showInfo(context, 'Teks ditempel');
    }
  }

  void _shareReport(String title, String content) {
    Share.share('$title\n\n$content\n\n— Dilacak via MyDownloader Stalker Hub');
  }

  @override
  Widget build(BuildContext context) {
    final stalker = context.watch<StalkerProvider>();
    final screenWidth = MediaQuery.of(context).size.width;
    final isCompact = screenWidth < 360;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Row(
          children: [
            Icon(Icons.radar_rounded, color: AppColors.primary, size: 22),
            SizedBox(width: 10),
            Text('Stalker Hub', style: TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
        automaticallyImplyLeading: false,
        actions: [
          if (stalker.freeFireResult != null ||
              stalker.tikTokResult != null ||
              stalker.gitHubResult != null ||
              stalker.robloxResult != null)
            IconButton(
              icon: const Icon(Icons.refresh_rounded, color: AppColors.textSecondary),
              tooltip: 'Reset Pencarian',
              onPressed: () {
                _inputController.clear();
                stalker.clearResult();
              },
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(isCompact ? 14 : 20, 8, isCompact ? 14 : 20, 110),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. Hub Header Banner
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                gradient: LinearGradient(
                  colors: [
                    const Color(0xFF1E1E26),
                    const Color(0xFF141418),
                    AppColors.primary.withOpacity(0.08),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                border: Border.all(color: Colors.white10),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: AppColors.primary.withOpacity(0.3)),
                        ),
                        child: const Text(
                          'OSINT PROFILE LOOKUP',
                          style: TextStyle(color: AppColors.primary, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 0.5),
                        ),
                      ),
                      const Spacer(),
                      const Icon(Icons.travel_explore_rounded, color: Colors.white38, size: 20),
                    ],
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    'Lacak Informasi Akun & Statistik',
                    style: TextStyle(color: Colors.white, fontSize: 16.5, fontWeight: FontWeight.bold, letterSpacing: -0.3),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Cek detail akun game, media sosial, dan profil publik secara instan tanpa login.',
                    style: TextStyle(color: AppColors.textSecondary, fontSize: 12, height: 1.4),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),

            // 2. Platform Selector List
            const Text(
              'Pilih Platform Target',
              style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildPlatformCard(
                    platform: StalkPlatform.freefire,
                    title: 'Free Fire',
                    subtitle: 'Garena UID Info',
                    icon: Icons.local_fire_department_rounded,
                    accentColor: const Color(0xFFFF5722),
                    isSelected: stalker.currentPlatform == StalkPlatform.freefire,
                    onTap: () {
                      stalker.setPlatform(StalkPlatform.freefire);
                      _inputController.clear();
                    },
                  ),
                  const SizedBox(width: 10),
                  _buildPlatformCard(
                    platform: StalkPlatform.tiktok,
                    title: 'TikTok',
                    subtitle: 'User & Analytics',
                    icon: Icons.music_video_rounded,
                    accentColor: const Color(0xFFFE2C55),
                    isSelected: stalker.currentPlatform == StalkPlatform.tiktok,
                    onTap: () {
                      stalker.setPlatform(StalkPlatform.tiktok);
                      _inputController.clear();
                    },
                  ),
                  const SizedBox(width: 10),
                  _buildPlatformCard(
                    platform: StalkPlatform.github,
                    title: 'GitHub',
                    subtitle: 'Developer Profile',
                    icon: Icons.code_rounded,
                    accentColor: const Color(0xFF8B5CF6),
                    isSelected: stalker.currentPlatform == StalkPlatform.github,
                    onTap: () {
                      stalker.setPlatform(StalkPlatform.github);
                      _inputController.clear();
                    },
                  ),
                  const SizedBox(width: 10),
                  _buildPlatformCard(
                    platform: StalkPlatform.roblox,
                    title: 'Roblox',
                    subtitle: 'Player & 3D Avatar',
                    icon: Icons.videogame_asset_rounded,
                    accentColor: const Color(0xFFE11D48),
                    isSelected: stalker.currentPlatform == StalkPlatform.roblox,
                    onTap: () {
                      stalker.setPlatform(StalkPlatform.roblox);
                      _inputController.clear();
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),

            // 3. Search Input Section
            GlassCard(
              padding: const EdgeInsets.all(16),
              borderRadius: 20,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _getInputLabel(stalker.currentPlatform),
                    style: const TextStyle(color: Colors.white, fontSize: 13.5, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 10),
                  Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFF141418),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: Colors.white12),
                    ),
                    child: TextField(
                      controller: _inputController,
                      focusNode: _focusNode,
                      style: const TextStyle(color: Colors.white, fontSize: 14),
                      keyboardType: stalker.currentPlatform == StalkPlatform.freefire ? TextInputType.number : TextInputType.text,
                      textInputAction: TextInputAction.search,
                      onSubmitted: (_) => _handleSearch(),
                      decoration: InputDecoration(
                        hintText: _getInputHint(stalker.currentPlatform),
                        hintStyle: const TextStyle(color: AppColors.textMuted, fontSize: 13),
                        prefixIcon: const Icon(Icons.search_rounded, color: AppColors.textMuted, size: 20),
                        suffixIcon: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (_inputController.text.isNotEmpty)
                              IconButton(
                                icon: const Icon(Icons.close_rounded, color: AppColors.textMuted, size: 18),
                                onPressed: () => setState(() => _inputController.clear()),
                              ),
                            IconButton(
                              icon: const Icon(Icons.content_paste_rounded, color: AppColors.primary, size: 18),
                              tooltip: 'Tempel',
                              onPressed: _handlePaste,
                            ),
                          ],
                        ),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),

                  // Submit Search Button
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      onPressed: stalker.isLoading ? null : _handleSearch,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: Colors.black,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        elevation: 0,
                      ),
                      child: stalker.isLoading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black),
                            )
                          : const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.radar_rounded, color: Colors.black, size: 18),
                                SizedBox(width: 8),
                                Text(
                                  'Mulai Lacak Profil',
                                  style: TextStyle(color: Colors.black, fontSize: 14, fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                    ),
                  ),

                  // Recent Quick Searches
                  if (stalker.recentSearches.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: [
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 4),
                          child: Text('Cepat:', style: TextStyle(color: AppColors.textDisabled, fontSize: 11)),
                        ),
                        for (final q in stalker.recentSearches)
                          InkWell(
                            onTap: () {
                              _inputController.text = q;
                              _handleSearch();
                            },
                            borderRadius: BorderRadius.circular(12),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.06),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                q,
                                style: const TextStyle(color: AppColors.textSecondary, fontSize: 11, fontWeight: FontWeight.w500),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 20),

            // 4. Error Message Display
            if (stalker.errorMessage != null)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: AppColors.error.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.error.withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.error_outline_rounded, color: AppColors.error, size: 20),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        stalker.errorMessage!,
                        style: const TextStyle(color: Colors.white, fontSize: 12.5),
                      ),
                    ),
                  ],
                ),
              ),

            // 5. Result Display
            if (stalker.freeFireResult != null) _buildFreeFireCard(stalker.freeFireResult!),
            if (stalker.tikTokResult != null) _buildTikTokCard(stalker.tikTokResult!),
            if (stalker.gitHubResult != null) _buildGitHubCard(stalker.gitHubResult!),
            if (stalker.robloxResult != null) _buildRobloxCard(stalker.robloxResult!),
          ],
        ),
      ),
    );
  }

  String _getInputLabel(StalkPlatform platform) {
    switch (platform) {
      case StalkPlatform.freefire:
        return 'UID Pemain Free Fire';
      case StalkPlatform.tiktok:
        return 'Username Akun TikTok';
      case StalkPlatform.github:
        return 'Username GitHub';
      case StalkPlatform.roblox:
        return 'Username Akun Roblox';
    }
  }

  String _getInputHint(StalkPlatform platform) {
    switch (platform) {
      case StalkPlatform.freefire:
        return 'Contoh: 123456789 atau 298374194';
      case StalkPlatform.tiktok:
        return 'Contoh: mrbeast atau @tiktok';
      case StalkPlatform.github:
        return 'Contoh: torvalds atau flutter';
      case StalkPlatform.roblox:
        return 'Contoh: builderman atau Roblox';
    }
  }

  Widget _buildPlatformCard({
    required StalkPlatform platform,
    required String title,
    required String subtitle,
    required IconData icon,
    required Color accentColor,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 140,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isSelected ? accentColor.withOpacity(0.18) : const Color(0xFF16161A),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: isSelected ? accentColor : Colors.white10,
            width: isSelected ? 1.5 : 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: accentColor.withOpacity(0.2),
                    blurRadius: 16,
                    offset: const Offset(0, 4),
                  ),
                ]
              : null,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: isSelected ? accentColor : Colors.white.withOpacity(0.08),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: isSelected ? Colors.white : Colors.white70, size: 20),
            ),
            const SizedBox(height: 12),
            Text(
              title,
              style: TextStyle(
                color: isSelected ? Colors.white : Colors.white70,
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              subtitle,
              style: const TextStyle(color: AppColors.textMuted, fontSize: 11),
            ),
          ],
        ),
      ),
    );
  }

  // =========================================================================
  // FREE FIRE RESULT CARD
  // =========================================================================
  Widget _buildFreeFireCard(FreeFireProfile data) {
    return GlassCard(
      padding: const EdgeInsets.all(18),
      borderRadius: 22,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Row
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFFFF5722).withOpacity(0.15),
                  shape: BoxShape.circle,
                  border: Border.all(color: const Color(0xFFFF5722).withOpacity(0.3)),
                ),
                child: const Icon(Icons.local_fire_department_rounded, color: Color(0xFFFF5722), size: 28),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      data.nickname,
                      style: const TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.bold),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Text('UID: ${data.accountId}', style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                        const SizedBox(width: 4),
                        InkWell(
                          onTap: () {
                            Clipboard.setData(ClipboardData(text: data.accountId));
                            CustomToast.showSuccess(context, 'UID disalin!');
                          },
                          child: const Icon(Icons.copy_rounded, color: AppColors.primary, size: 14),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: Colors.white10,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '${data.regionName} (${data.region})',
                  style: const TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(color: Colors.white12, height: 1),
          const SizedBox(height: 14),

          // Key Stats Grid
          Row(
            children: [
              Expanded(child: _buildMetricTile('Level', '${data.level}', 'EXP: ${Formatters.formatCompactNumber(data.exp)}', Icons.star_rounded, const Color(0xFFFBBF24))),
              const SizedBox(width: 10),
              Expanded(child: _buildMetricTile('Likes', Formatters.formatCompactNumber(data.liked), 'Disukai', Icons.thumb_up_rounded, const Color(0xFF38BDF8))),
              const SizedBox(width: 10),
              Expanded(child: _buildMetricTile('Credit', data.creditScore, 'Skor Kredit', Icons.shield_rounded, const Color(0xFF34D399))),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(child: _buildMetricTile('BR Rank', '${data.rank}', '${data.rankingPoints} Pts', Icons.emoji_events_rounded, const Color(0xFFA78BFA))),
              const SizedBox(width: 10),
              Expanded(child: _buildMetricTile('CS Rank', '${data.csRank}', '${data.csRankingPoints} Pts', Icons.sports_martial_arts_rounded, const Color(0xFFF472B6))),
              const SizedBox(width: 10),
              Expanded(child: _buildMetricTile('Prime Lvl', '${data.primeLevel}', 'Status Prime', Icons.workspace_premium_rounded, const Color(0xFFF87171))),
            ],
          ),
          const SizedBox(height: 16),

          // Guild / Clan Info
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.04),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.white10),
            ),
            child: Row(
              children: [
                const Icon(Icons.castle_rounded, color: Color(0xFFFBBF24), size: 20),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        data.clanName.isNotEmpty ? '${data.clanName} (Lvl ${data.clanLevel})' : 'Tidak Ada Guild / Solo',
                        style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600),
                      ),
                      if (data.clanName.isNotEmpty)
                        Text(
                          'Anggota: ${data.clanMemberNum} / ${data.clanCapacity}',
                          style: const TextStyle(color: AppColors.textMuted, fontSize: 11),
                        ),
                    ],
                  ),
                ),
                if (data.petName.isNotEmpty) ...[
                  const Icon(Icons.pets_rounded, color: Color(0xFF38BDF8), size: 18),
                  const SizedBox(width: 6),
                  Text('${data.petName} (Lvl ${data.petLevel})', style: const TextStyle(color: Colors.white70, fontSize: 12)),
                ],
              ],
            ),
          ),
          const SizedBox(height: 12),

          // Bio Signature
          if (data.signature.isNotEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.3),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.format_quote_rounded, color: AppColors.textMuted, size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      data.signature,
                      style: const TextStyle(color: AppColors.textSecondary, fontSize: 12, fontStyle: FontStyle.italic),
                    ),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 14),

          // Timestamps
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Dibuat: ${data.createAt}', style: const TextStyle(color: AppColors.textDisabled, fontSize: 10.5)),
              Text('Login: ${data.lastLoginAt}', style: const TextStyle(color: AppColors.textDisabled, fontSize: 10.5)),
            ],
          ),
          const SizedBox(height: 16),

          // Share Button
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              icon: const Icon(Icons.share_rounded, size: 16),
              label: const Text('Bagikan Laporan Free Fire'),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.white,
                side: const BorderSide(color: Colors.white24),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: () {
                _shareReport(
                  '🔥 LAPORAN AKUN FREE FIRE',
                  'Nickname: ${data.nickname}\nUID: ${data.accountId}\nRegion: ${data.regionName}\nLevel: ${data.level} (EXP: ${data.exp})\nLikes: ${data.liked}\nBR Rank: ${data.rank} (${data.rankingPoints} Pts)\nCS Rank: ${data.csRank} (${data.csRankingPoints} Pts)\nGuild: ${data.clanName.isNotEmpty ? data.clanName : "Solo"}\nBio: ${data.signature}',
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // =========================================================================
  // TIKTOK RESULT CARD
  // =========================================================================
  Widget _buildTikTokCard(TikTokStalkProfile data) {
    return GlassCard(
      padding: const EdgeInsets.all(18),
      borderRadius: 22,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  width: 64,
                  height: 64,
                  color: const Color(0xFF1E1E24),
                  child: data.avatarUrl.isNotEmpty
                      ? CachedNetworkImage(
                          imageUrl: data.avatarUrl,
                          fit: BoxFit.cover,
                          errorWidget: (_, __, ___) => const Icon(Icons.person_rounded, color: Colors.white38, size: 30),
                        )
                      : const Icon(Icons.person_rounded, color: Colors.white38, size: 30),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            data.nickname,
                            style: const TextStyle(color: Colors.white, fontSize: 16.5, fontWeight: FontWeight.bold),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (data.verified) ...[
                          const SizedBox(width: 4),
                          const Icon(Icons.verified_rounded, color: Color(0xFF20D5EC), size: 16),
                        ],
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text('@${data.username}', style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(color: Colors.white12, height: 1),
          const SizedBox(height: 14),

          // Stats Row
          Row(
            children: [
              Expanded(child: _buildMetricTile('Followers', Formatters.formatCompactNumber(data.followersCount), 'Pengikut', Icons.people_rounded, const Color(0xFF38BDF8))),
              const SizedBox(width: 8),
              Expanded(child: _buildMetricTile('Following', Formatters.formatCompactNumber(data.followingCount), 'Mengikuti', Icons.person_add_rounded, const Color(0xFFA78BFA))),
              const SizedBox(width: 8),
              Expanded(child: _buildMetricTile('Likes', Formatters.formatCompactNumber(data.heartCount), 'Total Suka', Icons.favorite_rounded, const Color(0xFFFE2C55))),
              const SizedBox(width: 8),
              Expanded(child: _buildMetricTile('Videos', Formatters.formatCompactNumber(data.videoCount), 'Postingan', Icons.videocam_rounded, const Color(0xFF34D399))),
            ],
          ),
          const SizedBox(height: 14),

          // Bio
          if (data.signature.isNotEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.04),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(data.signature, style: const TextStyle(color: AppColors.textSecondary, fontSize: 12.5, height: 1.4)),
            ),

          if (data.bioLink.isNotEmpty) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.link_rounded, color: AppColors.primary, size: 16),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    data.bioLink,
                    style: const TextStyle(color: AppColors.primary, fontSize: 12, decoration: TextDecoration.underline),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ],
          const SizedBox(height: 16),

          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              icon: const Icon(Icons.share_rounded, size: 16),
              label: const Text('Bagikan Profil TikTok'),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.white,
                side: const BorderSide(color: Colors.white24),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: () {
                _shareReport(
                  '🎵 PROFIL TIKTOK',
                  'Nama: ${data.nickname} (@${data.username})\nFollowers: ${data.followersCount}\nFollowing: ${data.followingCount}\nTotal Likes: ${data.heartCount}\nTotal Video: ${data.videoCount}\nBio: ${data.signature}',
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // =========================================================================
  // GITHUB RESULT CARD
  // =========================================================================
  Widget _buildGitHubCard(GitHubStalkProfile data) {
    return GlassCard(
      padding: const EdgeInsets.all(18),
      borderRadius: 22,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  width: 64,
                  height: 64,
                  color: const Color(0xFF1E1E24),
                  child: data.avatarUrl.isNotEmpty
                      ? CachedNetworkImage(
                          imageUrl: data.avatarUrl,
                          fit: BoxFit.cover,
                          errorWidget: (_, __, ___) => const Icon(Icons.code_rounded, color: Colors.white38, size: 30),
                        )
                      : const Icon(Icons.code_rounded, color: Colors.white38, size: 30),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      data.name,
                      style: const TextStyle(color: Colors.white, fontSize: 16.5, fontWeight: FontWeight.bold),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text('@${data.username}', style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(color: Colors.white12, height: 1),
          const SizedBox(height: 14),

          Row(
            children: [
              Expanded(child: _buildMetricTile('Repos', '${data.publicRepos}', 'Publik', Icons.source_rounded, const Color(0xFF38BDF8))),
              const SizedBox(width: 10),
              Expanded(child: _buildMetricTile('Followers', Formatters.formatCompactNumber(data.followers), 'Pengikut', Icons.people_rounded, const Color(0xFFA78BFA))),
              const SizedBox(width: 10),
              Expanded(child: _buildMetricTile('Following', Formatters.formatCompactNumber(data.following), 'Mengikuti', Icons.person_add_rounded, const Color(0xFF34D399))),
              const SizedBox(width: 10),
              Expanded(child: _buildMetricTile('Gists', '${data.publicGists}', 'Snippets', Icons.snippet_folder_rounded, const Color(0xFFFBBF24))),
            ],
          ),
          const SizedBox(height: 14),

          if (data.bio.isNotEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.04),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(data.bio, style: const TextStyle(color: AppColors.textSecondary, fontSize: 12.5, height: 1.4)),
            ),
          const SizedBox(height: 10),

          if (data.company.isNotEmpty) _buildDetailRow(Icons.business_rounded, data.company),
          if (data.location.isNotEmpty) _buildDetailRow(Icons.location_on_rounded, data.location),
          if (data.blog.isNotEmpty) _buildDetailRow(Icons.language_rounded, data.blog),
          if (data.email.isNotEmpty) _buildDetailRow(Icons.email_rounded, data.email),
          const SizedBox(height: 16),

          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              icon: const Icon(Icons.share_rounded, size: 16),
              label: const Text('Bagikan Profil GitHub'),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.white,
                side: const BorderSide(color: Colors.white24),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: () {
                _shareReport(
                  '🐙 PROFIL GITHUB DEVELOPER',
                  'Nama: ${data.name} (@${data.username})\nBio: ${data.bio}\nPublic Repos: ${data.publicRepos}\nFollowers: ${data.followers}\nFollowing: ${data.following}\nLink: ${data.profileUrl}',
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // =========================================================================
  // ROBLOX RESULT CARD
  // =========================================================================
  Widget _buildRobloxCard(RobloxStalkProfile data) {
    return GlassCard(
      padding: const EdgeInsets.all(18),
      borderRadius: 22,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  width: 70,
                  height: 70,
                  color: const Color(0xFF1E1E24),
                  child: data.avatarHeadshot.isNotEmpty
                      ? CachedNetworkImage(
                          imageUrl: data.avatarHeadshot,
                          fit: BoxFit.cover,
                          errorWidget: (_, __, ___) => const Icon(Icons.videogame_asset_rounded, color: Colors.white38, size: 32),
                        )
                      : const Icon(Icons.videogame_asset_rounded, color: Colors.white38, size: 32),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            data.displayName,
                            style: const TextStyle(color: Colors.white, fontSize: 16.5, fontWeight: FontWeight.bold),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (data.hasVerifiedBadge) ...[
                          const SizedBox(width: 4),
                          const Icon(Icons.verified_rounded, color: Color(0xFF38BDF8), size: 16),
                        ],
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text('@${data.username} • ID: ${data.userId}', style: const TextStyle(color: AppColors.textSecondary, fontSize: 12.5)),
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: data.presence.contains('Online') || data.presence.contains('Game')
                            ? const Color(0xFF22C55E).withOpacity(0.15)
                            : Colors.white10,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        data.presence,
                        style: TextStyle(
                          color: data.presence.contains('Online') || data.presence.contains('Game') ? const Color(0xFF4ADE80) : AppColors.textMuted,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(color: Colors.white12, height: 1),
          const SizedBox(height: 14),

          // Stats
          Row(
            children: [
              Expanded(child: _buildMetricTile('Friends', '${data.friendsCount}', 'Teman', Icons.group_rounded, const Color(0xFF38BDF8))),
              const SizedBox(width: 10),
              Expanded(child: _buildMetricTile('Followers', Formatters.formatCompactNumber(data.followersCount), 'Pengikut', Icons.people_outline_rounded, const Color(0xFFA78BFA))),
              const SizedBox(width: 10),
              Expanded(child: _buildMetricTile('Following', Formatters.formatCompactNumber(data.followingCount), 'Mengikuti', Icons.person_add_rounded, const Color(0xFF34D399))),
            ],
          ),
          const SizedBox(height: 14),

          if (data.description.isNotEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.04),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(data.description, style: const TextStyle(color: AppColors.textSecondary, fontSize: 12.5, height: 1.4)),
            ),
          const SizedBox(height: 16),

          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              icon: const Icon(Icons.share_rounded, size: 16),
              label: const Text('Bagikan Profil Roblox'),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.white,
                side: const BorderSide(color: Colors.white24),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: () {
                _shareReport(
                  '🧱 PROFIL ROBLOX PLAYER',
                  'Display Name: ${data.displayName}\nUsername: @${data.username}\nUser ID: ${data.userId}\nStatus: ${data.presence}\nFriends: ${data.friendsCount}\nFollowers: ${data.followersCount}\nBio: ${data.description}',
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricTile(String title, String value, String subtitle, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.04),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.06)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 14),
              const SizedBox(width: 4),
              Text(title, style: TextStyle(color: color, fontSize: 10.5, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 4),
          Text(value, style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold)),
          const SizedBox(height: 1),
          Text(subtitle, style: const TextStyle(color: AppColors.textMuted, fontSize: 9.5), maxLines: 1, overflow: TextOverflow.ellipsis),
        ],
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Icon(icon, color: AppColors.textMuted, size: 14),
          const SizedBox(width: 8),
          Expanded(
            child: Text(text, style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
          ),
        ],
      ),
    );
  }
}
