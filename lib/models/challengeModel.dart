import 'package:cloud_firestore/cloud_firestore.dart';

class Challenge {
  final String id;
  final String creatorId;
  final String creatorName;
  final Map<String, dynamic> creatorPersonality;
  final String creatorProfileImage;
  final String videoUrl;
  final String category;
  final List<dynamic> likedPeople;
  final List<dynamic> disLikedPeople;
  final List<dynamic> neutralPeople;
  final List<dynamic> viewedPeople;
  final bool isLive;
  final bool trending;
  final int likes;
  final int neutral;
  final int disLikes;
  final int viewsCount;
  final int comments;
  final String timestamp;
  const Challenge({
    this.id,
    this.creatorId,
    this.creatorName,
    this.creatorPersonality,
    this.creatorProfileImage,
    this.category,
    this.likedPeople,
    this.disLikedPeople,
    this.neutralPeople,
    this.viewedPeople,
    this.videoUrl,
    this.viewsCount,
    this.likes,
    this.disLikes,
    this.neutral,
    this.comments,
    this.isLive,
    this.trending,
    this.timestamp,
  });

  factory Challenge.fromDoc(DocumentSnapshot doc) {
    return Challenge(
      id: doc.id,
      creatorId: doc.data()['creatorId'],
      creatorName: doc.data()['creator-name'],
      creatorPersonality: doc.data()['creator-personality'],
      creatorProfileImage: doc.data()['creator-image'],
      category: doc.data()['category'],
      likedPeople: doc.data()['liked-people'],
      disLikedPeople: doc.data()['disliked-people'],
      neutralPeople: doc.data()['neutral-people'],
      viewedPeople: doc.data()['viewed-people'],
      videoUrl: doc.data()['videoUrl'],
      viewsCount: doc.data()['viewsCount'],
      comments: doc.data()['commentCount'],
      likes: doc.data()['likes'],
      neutral: doc.data()['neutral'],
      disLikes: doc.data()['disLikes'],
      isLive: doc.data()['isLive'],
      trending: doc.data()['trending'],
      timestamp: doc.data()['timestamp'],
    );
  }
}
