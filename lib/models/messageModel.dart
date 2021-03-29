import 'package:cloud_firestore/cloud_firestore.dart';

class Message {
  final String id;
  final String author;
  final String peerId;
  final String seenBy;
  final String content;
  final int type;
  final bool seen;
  final String timestamp;
  const Message({
    this.id,
    this.author,
    this.peerId,
    this.seenBy,
    this.content,
    this.type,
    this.seen,
    this.timestamp,
  });
  factory Message.fromDoc(DocumentSnapshot doc) {
    return Message(
      id: doc.data()['id'],
      author: doc.data()['from'],
      peerId: doc.data()['to'],
      seenBy: doc.data()['seenBy'],
      content: doc.data()['content'],
      type: doc.data()['type'],
      seen: doc.data()['seen'],
      timestamp: doc.data()['timestamp'],
    );
  }
}
