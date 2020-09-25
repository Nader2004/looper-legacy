import 'package:cloud_firestore/cloud_firestore.dart';

class Message {
  final String id;
  final String author;
  final String peerId;
  final String content;
  final int type;
  final String timestamp;
  const Message({
    this.id,
    this.author,
    this.peerId,
    this.content,
    this.type,
    this.timestamp,
  });
  factory Message.fromDoc(DocumentSnapshot doc) {
    return Message(
      id: doc.data()['id'],
      author: doc.data()['from'],
      peerId: doc.data()['to'],
      content: doc.data()['content'],
      type: doc.data()['type'],
      timestamp: doc.data()['timestamp'],
    );
  }
}
