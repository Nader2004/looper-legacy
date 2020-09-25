import 'package:cloud_firestore/cloud_firestore.dart';

class Sport {
  final String id;
  final String creatorId;
  final String creatorName;
  final Map<String, dynamic> creatorPersonality;
  final String creatorProfileImage;
  final String videoUrl;
  final String sportCategory;
  final List<dynamic> likedPeople;
  final List<dynamic> viewedPeople;
  final int likes;
  final int reactionsCount;
  final int viewsCount;
  final int commentCount;
  final String timestamp;
  const Sport({
    this.id,
    this.creatorId,
    this.creatorName,
    this.creatorPersonality,
    this.commentCount,
    this.creatorProfileImage,
    this.sportCategory,
    this.likedPeople,
    this.viewedPeople,
    this.videoUrl,
    this.likes,
    this.reactionsCount,
    this.viewsCount,
    this.timestamp,
  });

  factory Sport.fromDoc(DocumentSnapshot doc) {
    return Sport(
      id: doc.id,
      creatorId: doc.data()['creatorId'],
      creatorName: doc.data()['creator-name'],
      creatorPersonality: doc.data()['creator-personality'],
      creatorProfileImage: doc.data()['creator-image'],
      sportCategory: doc.data()['sportCategory'],
      likedPeople: doc.data()['liked-people'],
      viewedPeople: doc.data()['viewed-people'],
      videoUrl: doc.data()['videoUrl'],
      likes: doc.data()['likes'],
      reactionsCount: doc.data()['reactionsCount'],
      commentCount: doc.data()['commentCount'],
      viewsCount: doc.data()['viewsCount'],
      timestamp: doc.data()['timestamp'],
    );
  }
}
