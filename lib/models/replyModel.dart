import 'package:cloud_firestore/cloud_firestore.dart';

class Reply {
  final String id;
  final String author;
  final String content;
  final String timestamp;
  final int replies;
  final int likes;
  final int type;
  const Reply({
    this.id,
    this.author,
    this.content,
    this.timestamp,
    this.replies,
    this.likes,
    this.type,
  });

  factory Reply.fromDoc(DocumentSnapshot doc) {
    return Reply(
      id: doc.id,
      author: doc.data()['author'],
      content: doc.data()['content'],
      timestamp: doc.data()['timestamp'],
      replies: doc.data()['replies'],
      likes: doc.data()['likes'],
      type: doc.data()['type'],
    );
  }
}
