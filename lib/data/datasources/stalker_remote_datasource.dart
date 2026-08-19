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

    throw const ApiException('Akun TikTok tidak ditemukan atau profil bersifat privat.');
  }

  // =========================================================================
  // 5. TWITTER / X STALKER (GraphQL Scraper & Fallbacks)
  // =========================================================================
  Future<TwitterStalkProfile> stalkTwitter(String username) async {
    final cleanUser = username.trim().replaceAll('@', '');
    if (cleanUser.isEmpty) {
      throw const ApiException('Masukkan username Twitter/X yang valid.');
    }

    // 1. Twitter GraphQL API with user-provided auth bearer & headers
    try {
      final url = 'https://x.com/i/api/graphql/32pL5BWe9WKeSK1MoPvFQQ/UserByScreenName?variables=%7B%22screen_name%22%3A%22$cleanUser%22%7D&features=%7B%22hidden_profile_subscriptions_enabled%22%3Atrue%2C%22profile_label_improvements_pcf_label_in_post_enabled%22%3Atrue%2C%22rweb_tipjar_consumption_enabled%22%3Atrue%2C%22responsive_web_graphql_exclude_directive_enabled%22%3Atrue%2C%22verified_phone_label_enabled%22%3Afalse%2C%22subscriptions_verification_info_is_identity_verified_enabled%22%3Atrue%2C%22subscriptions_verification_info_verified_since_enabled%22%3Atrue%2C%22highlights_tweets_tab_ui_enabled%22%3Atrue%2C%22responsive_web_twitter_article_notes_tab_enabled%22%3Atrue%2C%22subscriptions_feature_can_gift_premium%22%3Atrue%2C%22creator_subscriptions_tweet_preview_api_enabled%22%3Atrue%2C%22responsive_web_graphql_skip_user_profile_image_extensions_enabled%22%3Afalse%2C%22responsive_web_graphql_timeline_navigation_enabled%22%3Atrue%7D&fieldToggles=%7B%22withAuxiliaryUserLabels%22%3Afalse%7D';
      
      final res = await _dio.get(
        url,
        options: Options(
          headers: {
            'authority': 'x.com',
            'authorization': 'Bearer AAAAAAAAAAAAAAAAAAAAANRILgAAAAAAnNwIzUejRCOuH5E6I8xnZz4puTs%3D1Zv7ttfk8LF81IUq16cHjhLTvJu4FA33AGWWjCpTnA',
            'cookie': 'guest_id=v1%3A173113403636768133; night_mode=2; auth_token=72f94efba48d660d8b1220c5a1fa5b7a03a77c48; ct0=a0b42c9fa97da6bf8505d9fd66cbe549c3b4a33d028d877fb0ae9a1d1b61d814fa831a4f097249ee4dea9a41f5050d12bda9806ce1816e5522572b2f0a81a3bc4f9a9bd2f2fdf4edef38a7759d03648f;',
            'User-Agent': 'Mozilla/5.0 (Linux; Android 10; K) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/132.0.0.0 Mobile Safari/537.36',
          },
        ),
      );

      final userData = res.data?['data']?['user']?['result'];
      if (userData != null && userData['legacy'] != null) {
        final legacy = userData['legacy'];
        String profileImg = (legacy['profile_image_url_https'] ?? '').toString();
        if (profileImg.isNotEmpty) {
          profileImg = profileImg.replaceAll('_normal.', '_400x400.');
        }

        return TwitterStalkProfile(
          id: (userData['rest_id'] ?? '').toString(),
          username: (legacy['screen_name'] ?? cleanUser).toString(),
          name: (legacy['name'] ?? cleanUser).toString(),
          verified: userData['is_blue_verified'] == true || legacy['verified'] == true,
          verifiedType: (legacy['verified_type'] ?? '').toString(),
          description: (legacy['description'] ?? '').toString(),
          location: (legacy['location'] ?? '').toString(),
          createdAt: (legacy['created_at'] ?? '').toString(),
          tweetsCount: int.tryParse(legacy['statuses_count']?.toString() ?? '0') ?? 0,
          followingCount: int.tryParse(legacy['friends_count']?.toString() ?? '0') ?? 0,
          followersCount: int.tryParse(legacy['followers_count']?.toString() ?? '0') ?? 0,
          likesCount: int.tryParse(legacy['favourites_count']?.toString() ?? '0') ?? 0,
          mediaCount: int.tryParse(legacy['media_count']?.toString() ?? '0') ?? 0,
          profileImage: profileImg,
          bannerImage: (legacy['profile_banner_url'] ?? '').toString(),
        );
      }
    } catch (_) {}

    // 2. Web OpenGraph & Metadata Fallback
    try {
      final res = await _dio.get(
        'https://x.com/$cleanUser',
        options: Options(
          responseType: ResponseType.plain,
          headers: {'User-Agent': 'Mozilla/5.0 (compatible; Googlebot/2.1; +http://www.google.com/bot.html)'},
        ),
      );
      final html = res.data.toString();
      final titleMatch = RegExp(r'<meta property="og:title" content="(.*?)"').firstMatch(html);
      final descMatch = RegExp(r'<meta property="og:description" content="(.*?)"').firstMatch(html);
      final imageMatch = RegExp(r'<meta property="og:image" content="(.*?)"').firstMatch(html);

      if (titleMatch != null || imageMatch != null) {
        return TwitterStalkProfile(
          id: cleanUser,
          username: cleanUser,
          name: titleMatch != null ? titleMatch.group(1)!.replaceAll(' on X', '') : cleanUser,
          verified: false,
          verifiedType: '',
          description: descMatch?.group(1) ?? '',
          location: '',
          createdAt: '',
          tweetsCount: 0,
          followingCount: 0,
          followersCount: 0,
          likesCount: 0,
          mediaCount: 0,
          profileImage: imageMatch?.group(1) ?? '',
          bannerImage: '',
        );
      }
    } catch (_) {}

    throw const ApiException('Akun Twitter/X tidak ditemukan atau terproteksi.');
  }

  // =========================================================================
  // 6. THREADS STALKER
  // =========================================================================
  Future<ThreadsStalkProfile> stalkThreads(String username) async {
    final cleanUser = username.trim().replaceAll('@', '');
    if (cleanUser.isEmpty) {
      throw const ApiException('Masukkan username Threads yang valid.');
    }

    try {
      final response = await _dio.get(
        'https://www.threads.net/@$cleanUser',
        options: Options(
          responseType: ResponseType.plain,
          headers: {
            'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0.0.0 Safari/537.36',
            'Accept': 'text/html,application/xhtml+xml,application/xml;q=0.9,image/avif,image/webp,*/*;q=0.8',
            'Accept-Language': 'en-US,en;q=0.9',
          },
        ),
      );

      final html = response.data.toString();

      // Extract OG Metadata
      final titleMatch = RegExp(r'<meta property="og:title" content="(.*?)"').firstMatch(html);
      final descMatch = RegExp(r'<meta property="og:description" content="(.*?)"').firstMatch(html);
      final imgMatch = RegExp(r'<meta property="og:image" content="(.*?)"').firstMatch(html);

      String fullName = cleanUser;
      if (titleMatch != null) {
        final raw = titleMatch.group(1)!;
        fullName = raw.split('(')[0].trim();
      }

      int followers = 0;
      int threadsCount = 0;
      String bio = '';
      if (descMatch != null) {
        final rawDesc = descMatch.group(1)!;
        final parts = rawDesc.split('•');
        if (parts.isNotEmpty) {
          final fStr = parts[0].replaceAll(RegExp(r'[^\d.KMkm]'), '').trim();
          if (fStr.toLowerCase().endsWith('m')) {
            followers = ((double.tryParse(fStr.replaceAll(RegExp(r'[Mm]'), '')) ?? 0) * 1000000).toInt();
          } else if (fStr.toLowerCase().endsWith('k')) {
            followers = ((double.tryParse(fStr.replaceAll(RegExp(r'[Kk]'), '')) ?? 0) * 1000).toInt();
          } else {
            followers = int.tryParse(fStr) ?? 0;
          }
        }
        if (parts.length > 1) {
          threadsCount = int.tryParse(parts[1].replaceAll(RegExp(r'\D'), '')) ?? 0;
        }
        if (parts.length > 2) {
          bio = parts.sublist(2).join('•').trim();
        }
      }

      String picUrl = '';
      if (imgMatch != null) {
        picUrl = imgMatch.group(1)!.replaceAll('&amp;', '&');
      }

      return ThreadsStalkProfile(
        id: cleanUser,
        username: cleanUser,
        name: fullName.isNotEmpty ? fullName : cleanUser,
        bio: bio,
        profilePicture: picUrl,
        isVerified: html.contains('"is_verified":true'),
        followers: followers,
        threadsCount: threadsCount,
        links: [],
      );
    } on DioException catch (e) {
      throw ApiException('Gagal memuat profil Threads (${e.message})');
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('Terjadi kesalahan saat melacak Threads: $e');
    }
  }

  // =========================================================================
  // 7. INSTAGRAM STALKER
  // =========================================================================
  Future<InstagramStalkProfile> stalkInstagram(String username) async {
    final cleanUser = username.trim().replaceAll('@', '');
    if (cleanUser.isEmpty) {
      throw const ApiException('Masukkan username Instagram yang valid.');
    }

    // 1. Try web_profile_info with user-provided headers
    try {
      final res = await _dio.get(
        'https://www.instagram.com/api/v1/users/web_profile_info/?username=$cleanUser',
        options: Options(
          headers: {
            'authority': 'www.instagram.com',
            'accept': '*/*',
            'referer': 'https://www.instagram.com/$cleanUser/',
            'x-ig-app-id': '936619743392459',
            'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/132.0.0.0 Safari/537.36',
          },
        ),
      );

      final user = res.data?['data']?['user'];
      if (user != null) {
        return InstagramStalkProfile.fromJson(user);
      }
    } catch (_) {}

    // 2. HTML Meta Extraction Fallback
    try {
      final res = await _dio.get(
        'https://www.instagram.com/$cleanUser/',
        options: Options(
          responseType: ResponseType.plain,
          headers: {
            'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36',
            'Accept-Language': 'en-US,en;q=0.9',
          },
        ),
      );
      final html = res.data.toString();
      final titleMatch = RegExp(r'<meta property="og:title" content="(.*?)"').firstMatch(html);
      final descMatch = RegExp(r'<meta property="og:description" content="(.*?)"').firstMatch(html);
      final imgMatch = RegExp(r'<meta property="og:image" content="(.*?)"').firstMatch(html);

      if (titleMatch != null || imgMatch != null) {
        String fullName = cleanUser;
        if (titleMatch != null) {
          final raw = titleMatch.group(1)!;
          fullName = raw.split('(')[0].trim();
        }

        int followers = 0;
        int following = 0;
        int posts = 0;
        if (descMatch != null) {
          final rawDesc = descMatch.group(1)!;
          final fMatch = RegExp(r'([\d.,KMkm]+)\s*Followers').firstMatch(rawDesc);
          final foMatch = RegExp(r'([\d.,KMkm]+)\s*Following').firstMatch(rawDesc);
          final pMatch = RegExp(r'([\d.,KMkm]+)\s*Posts').firstMatch(rawDesc);
          if (fMatch != null) followers = int.tryParse(fMatch.group(1)!.replaceAll(RegExp(r'\D'), '')) ?? 0;
          if (foMatch != null) following = int.tryParse(foMatch.group(1)!.replaceAll(RegExp(r'\D'), '')) ?? 0;
          if (pMatch != null) posts = int.tryParse(pMatch.group(1)!.replaceAll(RegExp(r'\D'), '')) ?? 0;
        }

        return InstagramStalkProfile(
          username: cleanUser,
          fullName: fullName,
          biography: '',
          externalUrl: 'https://instagram.com/$cleanUser',
          profilePicUrl: imgMatch != null ? imgMatch.group(1)!.replaceAll('&amp;', '&') : '',
          isPrivate: html.contains('"is_private":true'),
          isVerified: html.contains('"is_verified":true'),
          followersCount: followers,
          followingCount: following,
          postsCount: posts,
        );
      }
    } catch (_) {}

    throw const ApiException('Akun Instagram tidak ditemukan atau profil dibatasi.');
  }

  // =========================================================================
  // 8. YOUTUBE CHANNEL STALKER
  // =========================================================================
  Future<YouTubeStalkProfile> stalkYouTube(String username) async {
    final cleanUser = username.trim().replaceAll('@', '');
    if (cleanUser.isEmpty) {
      throw const ApiException('Masukkan nama channel atau handle YouTube yang valid.');
    }

    try {
      final response = await _dio.get(
        'https://www.youtube.com/@$cleanUser',
        options: Options(
          responseType: ResponseType.plain,
          headers: {
            'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0.0.0 Safari/537.36',
            'Accept-Language': 'id-ID,id;q=0.9,en-US;q=0.8,en;q=0.7',
          },
        ),
      );

      final html = response.data.toString();

      // Extract OG Metadata
      final ogTitle = RegExp(r'<meta property="og:title" content="(.*?)"').firstMatch(html)?.group(1) ?? cleanUser;
      final ogImage = RegExp(r'<meta property="og:image" content="(.*?)"').firstMatch(html)?.group(1) ?? '';
      final ogDesc = RegExp(r'<meta property="og:description" content="(.*?)"').firstMatch(html)?.group(1) ?? '';
      final ogUrl = RegExp(r'<meta property="og:url" content="(.*?)"').firstMatch(html)?.group(1) ?? 'https://youtube.com/@$cleanUser';

      // Extract Subscriber Count
      String subCount = '—';
      final subMatch = RegExp(r'"subscriberCountText":\{"accessibility":\{"accessibilityData":\{"label":"(.*?)"\}\},"simpleText":"(.*?)"\}').firstMatch(html) ??
          RegExp(r'"subscriberCountText":\{"simpleText":"(.*?)"\}').firstMatch(html);
      if (subMatch != null) {
        subCount = subMatch.group(subMatch.groupCount) ?? '—';
      }

      // Extract Video Count
      String videoCount = '—';
      final vidMatch = RegExp(r'"videosCountText":\{"runs":\[\{"text":"(.*?)"\}').firstMatch(html);
      if (vidMatch != null) {
        videoCount = vidMatch.group(1) ?? '—';
      }

      // Extract Recent Videos
      final List<YouTubeVideoItem> recentVideos = [];
      final vidMatches = RegExp(r'\{"gridVideoRenderer":\{"videoId":"(.*?)","thumbnail":\{"thumbnails":\[\{"url":"(.*?)"\}].*?"title":\{"simpleText":"(.*?)"\}').allMatches(html);
      for (final vm in vidMatches.take(5)) {
        recentVideos.add(
          YouTubeVideoItem(
            videoId: vm.group(1) ?? '',
            thumbnail: vm.group(2) ?? '',
            title: vm.group(3) ?? 'Video YouTube',
            publishedTime: '',
            viewCount: '',
            duration: '',
            videoUrl: 'https://youtube.com/watch?v=${vm.group(1)}',
          ),
        );
      }

      return YouTubeStalkProfile(
        username: '@$cleanUser',
        name: ogTitle,
        subscriberCount: subCount,
        videoCount: videoCount,
        avatarUrl: ogImage,
        channelUrl: ogUrl,
        description: ogDesc,
        latestVideos: recentVideos,
      );
    } on DioException catch (e) {
      throw ApiException('Gagal memuat channel YouTube (${e.message})');
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('Terjadi kesalahan saat melacak channel YouTube: $e');
    }
  }
}
