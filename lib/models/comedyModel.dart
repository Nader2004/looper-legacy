import 'package:cloud_firestore/cloud_firestore.dart';

class Comedy {
  final String id;
  final String authorId;
  final String authorName;
  final Map<String, dynamic> authorPersonality;
  final String authorImage;
  final String mediaUrl;
  final String caption;
  final String content;
  final String type;
  final List<dynamic> laughedPeople;
  final List<dynamic> viewedPeople;
  final int laughs;
  final int visitCount;
  final int viewsCount;
  final int commentCount;
  final String timestamp;
  const Comedy({
    this.id,
    this.authorId,
    this.authorName,
    this.authorPersonality,
    this.authorImage,
    this.commentCount,
    this.viewsCount,
    this.visitCount,
    this.laughs,
    this.laughedPeople,
    this.viewedPeople,
    this.mediaUrl,
    this.caption,
    this.content,
    this.type,
    this.timestamp,
  });

  factory Comedy.fromDoc(DocumentSnapshot doc) {
    return Comedy(
      id: doc.id,
      authorId: doc.data()['creatorId'],
      authorName: doc.data()['creator-name'],
      authorPersonality: doc.data()['author-personality'],
      authorImage: doc.data()['creator-image'],
      commentCount: doc.data()['commentCount'],
      viewsCount: doc.data()['viewsCount'],
      visitCount: doc.data()['visitCount'],
      laughs: doc.data()['laughs'],
      laughedPeople: doc.data()['laughed-people'],
      viewedPeople: doc.data()['viewed-people'],
      mediaUrl: doc.data()['mediaUrl'],
      caption: doc.data()['caption'],
      content: doc.data()['content'],
      type: doc.data()['type'],
      timestamp: doc.data()['timestamp'],
    );
  }
}
