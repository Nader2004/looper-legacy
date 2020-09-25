import 'package:cloud_firestore/cloud_firestore.dart';

class Comment {
  final String id;
  final String authorId;
  final String author;
  final String authorImage;
  final String content;
  final String media;
  final String timestamp;
  final List<dynamic> likedPeople;
  final int replies;
  final int likes;
  final int type;
  const Comment({
    this.id,
    this.authorId,
    this.author,
    this.authorImage,
    this.content,
    this.media,
    this.timestamp,
    this.likedPeople,
    this.replies,
    this.likes,
    this.type,
  });

  factory Comment.fromDoc(DocumentSnapshot doc) {
    return Comment(
      id: doc.id,
      authorId: doc.data()['authorId'],
      author: doc.data()['author'],
      authorImage: doc.data()['author-image'],
      content: doc.data()['content'],
      media: doc.data()['media'],
      timestamp: doc.data()['timestamp'],
      replies: doc.data()['replies'],
      likedPeople: doc.data()['liked-people'],
      likes: doc.data()['likes'],
      type: doc.data()['type'],
    );
  }
}
