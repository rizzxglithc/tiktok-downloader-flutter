import 'package:intl/intl.dart';

enum StalkPlatform {
  freefire,
  tiktok,
  github,
  roblox,
}

class FreeFireProfile {
  final String accountId;
  final String nickname;
  final String region;
  final String regionName;
  final int level;
  final int exp;
  final int liked;
  final int rank;
  final int rankingPoints;
  final int csRank;
  final int csRankingPoints;
  final int primeLevel;
  final String creditScore;
  final String createAt;
  final String lastLoginAt;
  final String clanName;
  final int clanLevel;
  final int clanMemberNum;
  final int clanCapacity;
  final String petName;
  final int petLevel;
  final String signature;

  const FreeFireProfile({
    required this.accountId,
    required this.nickname,
    required this.region,
    required this.regionName,
    required this.level,
    required this.exp,
    required this.liked,
    required this.rank,
    required this.rankingPoints,
    required this.csRank,
    required this.csRankingPoints,
    required this.primeLevel,
    required this.creditScore,
    required this.createAt,
    required this.lastLoginAt,
    required this.clanName,
    required this.clanLevel,
    required this.clanMemberNum,
    required this.clanCapacity,
    required this.petName,
    required this.petLevel,
    required this.signature,
  });

  static const Map<String, String> regionMap = {
    'ID': 'Indonesia',
    'IND': 'India',
    'BD': 'Bangladesh',
    'PK': 'Pakistan',
    'SG': 'Singapore',
    'TH': 'Thailand',
    'VN': 'Vietnam',
    'TW': 'Taiwan',
    'BR': 'Brazil',
    'NA': 'North America',
    'EU': 'Europe',
    'ME': 'Middle East',
    'RU': 'Russia',
  };

  static String formatUnixTimestamp(dynamic timestamp) {
    if (timestamp == null) return '—';
    try {
      final ts = int.tryParse(timestamp.toString());
      if (ts == null || ts == 0) return '—';
      final dt = DateTime.fromMillisecondsSinceEpoch(ts * 1000);
      return DateFormat('d MMMM yyyy, HH:mm', 'id_ID').format(dt);
    } catch (_) {
      try {
        final ts = int.parse(timestamp.toString());
        final dt = DateTime.fromMillisecondsSinceEpoch(ts * 1000);
        return '${dt.day}/${dt.month}/${dt.year} ${dt.hour}:${dt.minute.toString().padLeft(2, '0')}';
      } catch (_) {
        return timestamp.toString();
      }
    }
  }

  factory FreeFireProfile.fromJson(Map<String, dynamic> json) {
    final basic = (json['basicInfo'] as Map<String, dynamic>?) ?? {};
    final clan = (json['clanBasicInfo'] as Map<String, dynamic>?) ?? {};
    final pet = (json['petInfo'] as Map<String, dynamic>?) ?? {};
    final social = (json['socialInfo'] as Map<String, dynamic>?) ?? {};
    final credit = (json['creditScoreInfo'] as Map<String, dynamic>?) ?? {};
    final prime = (basic['primeInfo'] as Map<String, dynamic>?) ?? {};

    final rawRegion = (basic['region'] ?? 'Unknown').toString();
    final regionName = regionMap[rawRegion] ?? rawRegion;

    return FreeFireProfile(
      accountId: (basic['accountId'] ?? '').toString(),
      nickname: (basic['nickname'] ?? 'Player FF').toString(),
      region: rawRegion,
      regionName: regionName,
      level: int.tryParse(basic['level']?.toString() ?? '0') ?? 0,
      exp: int.tryParse(basic['exp']?.toString() ?? '0') ?? 0,
      liked: int.tryParse(basic['liked']?.toString() ?? '0') ?? 0,
      rank: int.tryParse(basic['rank']?.toString() ?? '0') ?? 0,
      rankingPoints: int.tryParse(basic['rankingPoints']?.toString() ?? '0') ?? 0,
      csRank: int.tryParse(basic['csRank']?.toString() ?? '0') ?? 0,
      csRankingPoints: int.tryParse(basic['csRankingPoints']?.toString() ?? '0') ?? 0,
      primeLevel: int.tryParse(prime['primeLevel']?.toString() ?? '0') ?? 0,
      creditScore: (credit['creditScore'] ?? '100').toString(),
      createAt: formatUnixTimestamp(basic['createAt']),
      lastLoginAt: formatUnixTimestamp(basic['lastLoginAt']),
      clanName: (clan['clanName'] ?? '').toString(),
      clanLevel: int.tryParse(clan['clanLevel']?.toString() ?? '0') ?? 0,
      clanMemberNum: int.tryParse(clan['memberNum']?.toString() ?? '0') ?? 0,
      clanCapacity: int.tryParse(clan['capacity']?.toString() ?? '0') ?? 0,
      petName: (pet['name'] ?? '').toString(),
      petLevel: int.tryParse(pet['level']?.toString() ?? '0') ?? 0,
      signature: (social['signature'] ?? '').toString(),
    );
  }
}

class TikTokStalkProfile {
  final String username;
  final String nickname;
  final String avatarUrl;
  final String signature;
  final String bioLink;
  final bool verified;
  final bool privateAccount;
  final int followersCount;
  final int followingCount;
  final int heartCount;
  final int videoCount;
  final int friendCount;

  const TikTokStalkProfile({
    required this.username,
    required this.nickname,
    required this.avatarUrl,
    required this.signature,
    required this.bioLink,
    required this.verified,
    required this.privateAccount,
    required this.followersCount,
    required this.followingCount,
    required this.heartCount,
    required this.videoCount,
    required this.friendCount,
  });

  factory TikTokStalkProfile.fromJson(Map<String, dynamic> json) {
    final user = (json['user'] as Map<String, dynamic>?) ?? json;
    final stats = (json['stats'] as Map<String, dynamic>?) ?? {};

    return TikTokStalkProfile(
      username: (user['uniqueId'] ?? user['username'] ?? user['id'] ?? '').toString(),
      nickname: (user['nickname'] ?? user['name'] ?? 'TikTok User').toString(),
      avatarUrl: (user['avatarLarger'] ?? user['avatarMedium'] ?? user['avatarThumb'] ?? user['avatar_url'] ?? '').toString(),
      signature: (user['signature'] ?? user['bio'] ?? '').toString(),
      bioLink: (user['bioLink']?['link'] ?? user['bio_url'] ?? '').toString(),
      verified: user['verified'] == true || user['is_verified'] == true,
      privateAccount: user['privateAccount'] == true || user['is_private'] == true,
      followersCount: int.tryParse(stats['followerCount']?.toString() ?? stats['followers']?.toString() ?? '0') ?? 0,
      followingCount: int.tryParse(stats['followingCount']?.toString() ?? stats['following']?.toString() ?? '0') ?? 0,
      heartCount: int.tryParse(stats['heartCount']?.toString() ?? stats['heart']?.toString() ?? stats['likes']?.toString() ?? '0') ?? 0,
      videoCount: int.tryParse(stats['videoCount']?.toString() ?? stats['videos']?.toString() ?? '0') ?? 0,
      friendCount: int.tryParse(stats['friendCount']?.toString() ?? '0') ?? 0,
    );
  }
}

class GitHubStalkProfile {
  final String username;
  final String name;
  final String avatarUrl;
  final String bio;
  final String company;
  final String blog;
  final String location;
  final String email;
  final int publicRepos;
  final int publicGists;
  final int followers;
  final int following;
  final String createdAt;
  final String updatedAt;
  final String profileUrl;

  const GitHubStalkProfile({
    required this.username,
    required this.name,
    required this.avatarUrl,
    required this.bio,
    required this.company,
    required this.blog,
    required this.location,
    required this.email,
    required this.publicRepos,
    required this.publicGists,
    required this.followers,
    required this.following,
    required this.createdAt,
    required this.updatedAt,
    required this.profileUrl,
  });

  factory GitHubStalkProfile.fromJson(Map<String, dynamic> json) {
    return GitHubStalkProfile(
      username: (json['login'] ?? '').toString(),
      name: (json['name'] ?? json['login'] ?? 'GitHub User').toString(),
      avatarUrl: (json['avatar_url'] ?? '').toString(),
      bio: (json['bio'] ?? '').toString(),
      company: (json['company'] ?? '').toString(),
      blog: (json['blog'] ?? '').toString(),
      location: (json['location'] ?? '').toString(),
      email: (json['email'] ?? '').toString(),
      publicRepos: int.tryParse(json['public_repos']?.toString() ?? '0') ?? 0,
      publicGists: int.tryParse(json['public_gists']?.toString() ?? '0') ?? 0,
      followers: int.tryParse(json['followers']?.toString() ?? '0') ?? 0,
      following: int.tryParse(json['following']?.toString() ?? '0') ?? 0,
      createdAt: (json['created_at'] ?? '').toString(),
      updatedAt: (json['updated_at'] ?? '').toString(),
      profileUrl: (json['html_url'] ?? 'https://github.com/${json['login']}').toString(),
    );
  }
}

class RobloxStalkProfile {
  final int userId;
  final String username;
  final String displayName;
  final bool isBanned;
  final bool hasVerifiedBadge;
  final String description;
  final String created;
  final String presence;
  final String avatarHeadshot;
  final String avatarFullBody;
  final int friendsCount;
  final int followersCount;
  final int followingCount;

  const RobloxStalkProfile({
    required this.userId,
    required this.username,
    required this.displayName,
    required this.isBanned,
    required this.hasVerifiedBadge,
    required this.description,
    required this.created,
    required this.presence,
    required this.avatarHeadshot,
    required this.avatarFullBody,
    required this.friendsCount,
    required this.followersCount,
    required this.followingCount,
  });
}
