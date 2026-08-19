import 'dart:convert';
import 'package:dio/dio.dart';
import '../../core/errors/app_exceptions.dart';
import '../../domain/entities/stalk_models.dart';

class StalkerRemoteDataSource {
  final Dio _dio;

  StalkerRemoteDataSource({Dio? dio})
      : _dio = dio ??
            Dio(
              BaseOptions(
                connectTimeout: const Duration(seconds: 15),
                receiveTimeout: const Duration(seconds: 15),
                sendTimeout: const Duration(seconds: 15),
              ),
            );

  // =========================================================================
  // 1. FREE FIRE STALKER (Adenpedia API)
  // =========================================================================
  Future<FreeFireProfile> stalkFreeFire(String uid) async {
    final cleanUid = uid.trim().replaceAll(RegExp(r'\D'), '');
    if (cleanUid.isEmpty) {
      throw const ApiException('Masukkan UID Free Fire yang valid (hanya angka).');
    }

    final url = 'https://adenpedia.my.id/radenbaru/info.php?uid=$cleanUid';

    try {
      final response = await _dio.get(
        url,
        options: Options(
          responseType: ResponseType.plain,
          headers: {
            'Accept': 'application/json, text/plain, */*',
            'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0.0.0 Safari/537.36',
          },
        ),
      );

      final rawData = response.data.toString();
      final Map<String, dynamic> json = jsonDecode(rawData);

      if (json['basicInfo'] == null) {
        throw const ApiException('UID Free Fire tidak ditemukan atau server sedang maintenance.');
      }

      return FreeFireProfile.fromJson(json);
    } on DioException catch (e) {
      throw ApiException('Gagal menghubungi server Free Fire (${e.message})');
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('Terjadi kesalahan saat memproses data Free Fire: $e');
    }
  }

  // =========================================================================
  // 2. GITHUB STALKER (Official GitHub API)
  // =========================================================================
  Future<GitHubStalkProfile> stalkGitHub(String username) async {
    final cleanUser = username.trim().replaceAll('@', '');
    if (cleanUser.isEmpty) {
      throw const ApiException('Masukkan username GitHub yang valid.');
    }

    final url = 'https://api.github.com/users/$cleanUser';

    try {
      final response = await _dio.get(
        url,
        options: Options(
          headers: {
            'Accept': 'application/vnd.github.v3+json',
            'User-Agent': 'MyDownloader-App',
          },
        ),
      );

      if (response.statusCode == 200 && response.data is Map<String, dynamic>) {
        return GitHubStalkProfile.fromJson(response.data);
      } else {
        throw const ApiException('User GitHub tidak ditemukan.');
      }
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) {
        throw const ApiException('Akun GitHub tidak ditemukan.');
      }
      throw ApiException('Gagal mengambil data GitHub (${e.message})');
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('Terjadi kesalahan: $e');
    }
  }

  // =========================================================================
  // 3. ROBLOX STALKER (Roblox Official Public APIs)
  // =========================================================================
  Future<RobloxStalkProfile> stalkRoblox(String username) async {
    final cleanUser = username.trim().replaceAll('@', '');
    if (cleanUser.isEmpty) {
      throw const ApiException('Masukkan username Roblox yang valid.');
    }

    try {
      // 1. Resolve User ID from Username
      final lookupRes = await _dio.post(
        'https://users.roblox.com/v1/usernames/users',
        data: jsonEncode({
          'usernames': [cleanUser],
          'excludeBannedUsers': false,
        }),
        options: Options(
          headers: {'Content-Type': 'application/json', 'User-Agent': 'Mozilla/5.0'},
        ),
      );

      final List users = lookupRes.data?['data'] ?? [];
      if (users.isEmpty) {
        throw const ApiException('Username Roblox tidak ditemukan.');
      }

      final int userId = users[0]['id'];
      final String verifiedName = users[0]['name'] ?? cleanUser;
      final String displayName = users[0]['displayName'] ?? verifiedName;
      final bool hasVerifiedBadge = users[0]['hasVerifiedBadge'] == true;

      // 2. Fetch User Detail
      final detailRes = await _dio.get(
        'https://users.roblox.com/v1/users/$userId',
        options: Options(headers: {'User-Agent': 'Mozilla/5.0'}),
      );
      final detailData = detailRes.data is Map<String, dynamic> ? detailRes.data : <String, dynamic>{};
      final String description = (detailData['description'] ?? '').toString();
      final String createdRaw = (detailData['created'] ?? '').toString();
      final bool isBanned = detailData['isBanned'] == true;

      // 3. Fetch Avatar Headshot & Full Body
      String avatarHeadshot = '';
      String avatarFullBody = '';
      try {
        final headshotRes = await _dio.get(
          'https://thumbnails.roblox.com/v1/users/avatar-headshot?userIds=$userId&size=420x420&format=Png&isCircular=false',
          options: Options(headers: {'User-Agent': 'Mozilla/5.0'}),
        );
        final list = headshotRes.data?['data'] as List?;
        if (list != null && list.isNotEmpty) {
          avatarHeadshot = (list[0]['imageUrl'] ?? '').toString();
        }
      } catch (_) {}

      try {
        final bodyRes = await _dio.get(
          'https://thumbnails.roblox.com/v1/users/avatar?userIds=$userId&size=720x720&format=Png&isCircular=false',
          options: Options(headers: {'User-Agent': 'Mozilla/5.0'}),
        );
        final list = bodyRes.data?['data'] as List?;
        if (list != null && list.isNotEmpty) {
          avatarFullBody = (list[0]['imageUrl'] ?? '').toString();
        }
      } catch (_) {}

      // 4. Fetch Friends & Followers Count
      int friendsCount = 0;
      int followersCount = 0;
      int followingCount = 0;
      try {
        final friendsRes = await _dio.get(
          'https://friends.roblox.com/v1/users/$userId/friends/count',
          options: Options(headers: {'User-Agent': 'Mozilla/5.0'}),
        );
        friendsCount = int.tryParse(friendsRes.data?['count']?.toString() ?? '0') ?? 0;
      } catch (_) {}

      try {
        final followersRes = await _dio.get(
          'https://friends.roblox.com/v1/users/$userId/followers/count',
          options: Options(headers: {'User-Agent': 'Mozilla/5.0'}),
        );
        followersCount = int.tryParse(followersRes.data?['count']?.toString() ?? '0') ?? 0;
      } catch (_) {}

      try {
        final followingsRes = await _dio.get(
          'https://friends.roblox.com/v1/users/$userId/followings/count',
          options: Options(headers: {'User-Agent': 'Mozilla/5.0'}),
        );
        followingCount = int.tryParse(followingsRes.data?['count']?.toString() ?? '0') ?? 0;
      } catch (_) {}

      // 5. Fetch Presence
      String presenceStr = 'Offline';
      try {
        final presenceRes = await _dio.post(
          'https://presence.roblox.com/v1/presence/users',
          data: jsonEncode({
            'userIds': [userId]
          }),
          options: Options(
            headers: {'Content-Type': 'application/json', 'User-Agent': 'Mozilla/5.0'},
          ),
        );
        final pList = presenceRes.data?['userPresences'] as List?;
        if (pList != null && pList.isNotEmpty) {
          final int pType = pList[0]['userPresenceType'] ?? 0;
          switch (pType) {
            case 1:
              presenceStr = 'Online (Website)';
              break;
            case 2:
              presenceStr = 'In Game 🎮';
              break;
            case 3:
              presenceStr = 'In Studio 🛠️';
              break;
            default:
              presenceStr = 'Offline';
          }
        }
      } catch (_) {}

      return RobloxStalkProfile(
        userId: userId,
        username: verifiedName,
        displayName: displayName,
        isBanned: isBanned,
        hasVerifiedBadge: hasVerifiedBadge,
        description: description,
        created: createdRaw,
        presence: presenceStr,
        avatarHeadshot: avatarHeadshot,
        avatarFullBody: avatarFullBody.isNotEmpty ? avatarFullBody : avatarHeadshot,
        friendsCount: friendsCount,
        followersCount: followersCount,
        followingCount: followingCount,
      );
    } on DioException catch (e) {
      throw ApiException('Gagal memproses profil Roblox (${e.message})');
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('Terjadi kesalahan: $e');
    }
  }

  // =========================================================================
  // 4. TIKTOK STALKER (Universal Data & Web Extraction)
  // =========================================================================
  Future<TikTokStalkProfile> stalkTikTok(String username) async {
    final cleanUser = username.trim().replaceAll('@', '');
    if (cleanUser.isEmpty) {
      throw const ApiException('Masukkan username TikTok yang valid.');
    }

    // 1. Direct Web Scraping with Rehydration JSON
    try {
      final response = await _dio.get(
        'https://www.tiktok.com/@$cleanUser',
        options: Options(
          responseType: ResponseType.plain,
          headers: {
            'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0.0.0 Safari/537.36',
            'Accept': 'text/html,application/xhtml+xml,application/xml;q=0.9,image/avif,image/webp,*/*;q=0.8',
            'Accept-Language': 'id-ID,id;q=0.9,en-US;q=0.8,en;q=0.7',
          },
        ),
      );

      final html = response.data.toString();
      final match = RegExp(r'<script id="__UNIVERSAL_DATA_FOR_REHYDRATION__" type="application/json">(.*?)</script>').firstMatch(html);
      if (match != null) {
        final jsonData = jsonDecode(match.group(1)!);
        final userScope = jsonData['__DEFAULT_SCOPE__']?['webapp.user-detail'];
        if (userScope != null && userScope['userInfo'] != null) {
          return TikTokStalkProfile.fromJson(userScope['userInfo']);
        }
      }
    } catch (_) {}

    // 2. Secondary Scraper: TikWM / SSS API Fallback
    try {
      final res = await _dio.get(
        'https://tikwm.com/api/user/info?unique_id=$cleanUser',
        options: Options(
          headers: {
            'User-Agent': 'Mozilla/5.0 (Linux; Android 10; K) AppleWebKit/537.36 Mobile Safari/537.36',
          },
        ),
      );
      if (res.data is Map<String, dynamic> && res.data['data'] != null) {
        return TikTokStalkProfile.fromJson(res.data['data']);
      }
    } catch (_) {}

    // 3. Third API Fallback: Urlebird API
    try {
      final res = await _dio.get(
        'https://api.tiklydown.eu.org/api/stalk?username=$cleanUser',
        options: Options(headers: {'User-Agent': 'Mozilla/5.0'}),
      );
      if (res.data is Map<String, dynamic> && res.data['result'] != null) {
        return TikTokStalkProfile.fromJson(res.data['result']);
      }
    } catch (_) {}

    throw const ApiException('Akun TikTok tidak ditemukan atau profil bersifat privat.');
  }
}
