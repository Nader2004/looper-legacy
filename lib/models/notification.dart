import 'package:cloud_firestore/cloud_firestore.dart';

class Notification {
  final String id;
  final String title;
  final String body;
  final String navigator;
  final String contentId;
  final String symbol;
  final String userId;
  const Notification({
    this.id,
    this.title,
    this.body,
    this.navigator,
    this.contentId,
    this.symbol,
    this.userId,
  });

  factory Notification.fromJSON(Map<String, dynamic> notif) {
    return Notification(
      title: notif['notification']['title'],
      body: notif['notification']['body'],
      userId: notif['data']['userId'],
      navigator: notif['data']['navigator'],
      contentId: notif['data']['contentId'],
      symbol: notif['data']['symbol'],
    );
  }

  factory Notification.fromDoc(DocumentSnapshot doc) {
    return Notification(
      id: doc.id,
      title: doc.data()['title'],
      body: doc.data()['body'],
      userId: doc.data()['userId'],
      navigator: doc.data()['navigator'],
      contentId: doc.data()['contentId'],
      symbol: doc.data()['symbol'],
    );
  }
}
