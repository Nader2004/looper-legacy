import 'package:cloud_firestore/cloud_firestore.dart';

class Talent {
  final String id;
  final String creatorId;
  final String creatorName;
  final Map<String, dynamic> creatorPersonality;
  final String creatorProfileImage;
  final String videoUrl;
  final String category;
  final String caption;
  final String talentName;
  final String movieFilter;
  final List<dynamic> clapedPeople;
  final List<dynamic> yesCountedPeople;
  final List<dynamic> noCountedPeople;
  final List<dynamic> goldenStaredPeople;
  final List<dynamic> viewedPeople;
  final int claps;
  final int yesCount;
  final int noCount;
  final int viewsCount;
  final int commentCount;
  final int goldenStars;
  final String timestamp;
  const Talent({
    this.id,
    this.creatorId,
    this.creatorName,
    this.creatorPersonality,
    this.commentCount,
    this.goldenStars,
    this.creatorProfileImage,
    this.category,
    this.caption,
    this.talentName,
    this.movieFilter,
    this.videoUrl,
    this.clapedPeople,
    this.yesCountedPeople,
    this.noCountedPeople,
    this.goldenStaredPeople,
    this.viewedPeople,
    this.claps,
    this.noCount,
    this.yesCount,
    this.viewsCount,
    this.timestamp,
  });

  factory Talent.fromDoc(DocumentSnapshot doc) {
    return Talent(
      id: doc.id,
      creatorId: doc.data()['creatorId'],
      creatorName: doc.data()['creator-name'],
      creatorPersonality: doc.data()['creator-personality'],
      creatorProfileImage: doc.data()['creator-image'],
      category: doc.data()['category'],
      caption: doc.data()['caption'],
      talentName: doc.data()['talent-name'],
      videoUrl: doc.data()['videoUrl'],
      movieFilter: doc.data()['movieFilter'],
      commentCount: doc.data()['commentCount'],
      goldenStars: doc.data()['goldenstars'],
      viewsCount: doc.data()['viewsCount'],
      clapedPeople: doc.data()['claped-people'],
      yesCountedPeople: doc.data()['yes-counted-people'],
      noCountedPeople: doc.data()['no-counted-people'],
      goldenStaredPeople: doc.data()['golden-stared-people'],
      viewedPeople: doc.data()['viewed-people'],
      claps: doc.data()['claps'],
      yesCount: doc.data()['yesCount'],
      noCount: doc.data()['noCount'],
      timestamp: doc.data()['timestamp'],
    );
  }
}
