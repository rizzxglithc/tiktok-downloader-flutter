import 'package:intl/intl.dart';

enum StalkPlatform {
  tiktok,
  instagram,
  twitter,
  threads,
  youtube,
  github,
  roblox,
}

// 2. TIKTOK
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

// 3. TWITTER / X
class TwitterStalkProfile {
  final String id;
  final String username;
  final String name;
  final bool verified;
  final String verifiedType;
  final String description;
  final String location;
  final String createdAt;
  final int tweetsCount;
  final int followingCount;
  final int followersCount;
  final int likesCount;
  final int mediaCount;
  final String profileImage;
  final String bannerImage;

  const TwitterStalkProfile({
    required this.id,
    required this.username,
    required this.name,
    required this.verified,
    required this.verifiedType,
    required this.description,
    required this.location,
    required this.createdAt,
    required this.tweetsCount,
    required this.followingCount,
    required this.followersCount,
    required this.likesCount,
    required this.mediaCount,
    required this.profileImage,
    required this.bannerImage,
  });

  factory TwitterStalkProfile.fromJson(Map<String, dynamic> json) {
    final stats = (json['stats'] as Map<String, dynamic>?) ?? {};
    final profile = (json['profile'] as Map<String, dynamic>?) ?? {};

    return TwitterStalkProfile(
      id: (json['id'] ?? '').toString(),
      username: (json['username'] ?? '').toString(),
      name: (json['name'] ?? json['username'] ?? 'Twitter User').toString(),
      verified: json['verified'] == true,
      verifiedType: (json['verified_type'] ?? '').toString(),
      description: (json['description'] ?? '').toString(),
      location: (json['location'] ?? '').toString(),
      createdAt: (json['created_at'] ?? '').toString(),
      tweetsCount: int.tryParse(stats['tweets']?.toString() ?? '0') ?? 0,
      followingCount: int.tryParse(stats['following']?.toString() ?? '0') ?? 0,
      followersCount: int.tryParse(stats['followers']?.toString() ?? '0') ?? 0,
      likesCount: int.tryParse(stats['likes']?.toString() ?? '0') ?? 0,
      mediaCount: int.tryParse(stats['media']?.toString() ?? '0') ?? 0,
      profileImage: (profile['image'] ?? json['profile_image_url'] ?? '').toString(),
      bannerImage: (profile['banner'] ?? json['profile_banner_url'] ?? '').toString(),
    );
  }
}

// 4. THREADS
class ThreadsStalkProfile {
  final String id;
  final String username;
  final String name;
  final String bio;
  final String profilePicture;
  final bool isVerified;
  final int followers;
  final int threadsCount;
  final List<String> links;

  const ThreadsStalkProfile({
    required this.id,
    required this.username,
    required this.name,
    required this.bio,
    required this.profilePicture,
    required this.isVerified,
    required this.followers,
    required this.threadsCount,
    required this.links,
  });

  factory ThreadsStalkProfile.fromJson(Map<String, dynamic> json) {
    return ThreadsStalkProfile(
      id: (json['id'] ?? '').toString(),
      username: (json['username'] ?? '').toString(),
      name: (json['name'] ?? json['username'] ?? 'Threads User').toString(),
      bio: (json['bio'] ?? json['biography'] ?? '').toString(),
      profilePicture: (json['hd_profile_picture'] ?? json['profile_picture'] ?? json['profile_pic_url'] ?? '').toString(),
      isVerified: json['is_verified'] == true,
      followers: int.tryParse(json['followers']?.toString() ?? json['follower_count']?.toString() ?? '0') ?? 0,
      threadsCount: int.tryParse(json['threads_count']?.toString() ?? '0') ?? 0,
      links: (json['links'] as List?)?.map((e) => e.toString()).toList() ?? [],
    );
  }
}

// 5. INSTAGRAM
class InstagramStalkProfile {
  final String username;
  final String fullName;
  final String biography;
  final String externalUrl;
  final String profilePicUrl;
  final bool isPrivate;
  final bool isVerified;
  final int followersCount;
  final int followingCount;
  final int postsCount;

  const InstagramStalkProfile({
    required this.username,
    required this.fullName,
    required this.biography,
    required this.externalUrl,
    required this.profilePicUrl,
    required this.isPrivate,
    required this.isVerified,
    required this.followersCount,
    required this.followingCount,
    required this.postsCount,
  });

  factory InstagramStalkProfile.fromJson(Map<String, dynamic> json) {
    return InstagramStalkProfile(
      username: (json['username'] ?? '').toString(),
      fullName: (json['full_name'] ?? json['username'] ?? 'Instagram User').toString(),
      biography: (json['biography'] ?? '').toString(),
      externalUrl: (json['external_url'] ?? '').toString(),
      profilePicUrl: (json['profile_pic_url'] ?? '').toString(),
      isPrivate: json['is_private'] == true,
      isVerified: json['is_verified'] == true,
      followersCount: int.tryParse(json['followers_count']?.toString() ?? '0') ?? 0,
      followingCount: int.tryParse(json['following_count']?.toString() ?? '0') ?? 0,
      postsCount: int.tryParse(json['posts_count']?.toString() ?? '0') ?? 0,
    );
  }
}

// 6. YOUTUBE
class YouTubeVideoItem {
  final String videoId;
  final String title;
  final String thumbnail;
  final String publishedTime;
  final String viewCount;
  final String duration;
  final String videoUrl;

  const YouTubeVideoItem({
    required this.videoId,
    required this.title,
    required this.thumbnail,
    required this.publishedTime,
    required this.viewCount,
    required this.duration,
    required this.videoUrl,
  });
}

class YouTubeStalkProfile {
  final String username;
  final String name;
  final String subscriberCount;
  final String videoCount;
  final String avatarUrl;
  final String channelUrl;
  final String description;
  final List<YouTubeVideoItem> latestVideos;

  const YouTubeStalkProfile({
    required this.username,
    required this.name,
    required this.subscriberCount,
    required this.videoCount,
    required this.avatarUrl,
    required this.channelUrl,
    required this.description,
    required this.latestVideos,
  });
}

// 7. GITHUB
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

// 8. ROBLOX
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
