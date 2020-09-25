import 'package:cloud_firestore/cloud_firestore.dart';

class Post {
  final String id;
  final String authorId;
  final String authorName;
  final Map<String, dynamic> authorPersonality;
  final String authorImage;
  final String shareAuthorName;
  final Map<String, dynamic> question;
  final List<dynamic> mediaUrl;
  final Map<String, dynamic> gif;
  final String audioUrl;
  final String audioImage;
  final String audioDescribtion;
  final String text;
  final String caption;
  final String location;
  final List<dynamic> reactions;
  final List<dynamic> likedPeople;
  final List<dynamic> viewedPeople;
  final List<dynamic> option1People;
  final List<dynamic> option2People;
  final int likeCount;
  final int answersCount;
  final int reactionsCount;
  final int commentCount;
  final int shareCount;
  final int viewsCount;
  final int option1Count;
  final int option2Count;
  final int type;
  final bool isShared;
  final String timestamp;
  const Post({
    this.id,
    this.authorId,
    this.authorName,
    this.authorPersonality,
    this.authorImage,
    this.shareAuthorName,
    this.question,
    this.mediaUrl,
    this.audioUrl,
    this.audioImage,
    this.audioDescribtion,
    this.text,
    this.caption,
    this.gif,
    this.location,
    this.reactions,
    this.viewedPeople,
    this.likedPeople,
    this.option1People,
    this.option2People,
    this.likeCount,
    this.answersCount,
    this.shareCount,
    this.reactionsCount,
    this.commentCount,
    this.viewsCount,
    this.option1Count,
    this.option2Count,
    this.type,
    this.isShared,
    this.timestamp,
  });

  factory Post.fromDoc(DocumentSnapshot doc) {
    return Post(
      id: doc.id,
      authorId: doc.data()['author'],
      authorName: doc.data()['author-name'],
      authorPersonality: doc.data()['author-personality'],
      authorImage: doc.data()['author-image'],
      shareAuthorName: doc.data()['share-author-name'],
      text: doc.data()['text'],
      gif: doc.data()['gif'],
      caption: doc.data()['caption'],
      location: doc.data()['location'],
      reactions: doc.data()['reactions'],
      likeCount: doc.data()['likes'],
      answersCount: doc.data()['answersCount'],
      reactionsCount: doc.data()['reactionsCount'],
      viewedPeople: doc.data()['viewed-people'],
      likedPeople: doc.data()['liked-people'],
      commentCount: doc.data()['commentCount'],
      shareCount: doc.data()['shareCount'],
      viewsCount: doc.data()['viewsCount'],
      option1Count: doc.data()['option1Count'],
      option2Count: doc.data()['option2Count'],
      option1People: doc.data()['option1-people'],
      option2People: doc.data()['option2-people'],
      type: doc.data()['type'],
      question: doc.data()['question'],
      mediaUrl: doc.data()['mediaUrl'],
      audioUrl: doc.data()['audio'],
      audioImage: doc.data()['audioImage'],
      audioDescribtion: doc.data()['audioDescribtion'],
      isShared: doc.data()['isShared'],
      timestamp: doc.data()['timestamp'],
    );
  }
}
