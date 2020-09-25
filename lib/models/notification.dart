import 'package:cloud_firestore/cloud_firestore.dart';

class Notification {
  final String id;
  final String title;
  final String body;
  final String userId;
  const Notification({
    this.id,
    this.title,
    this.body,
    this.userId,
  });

  factory Notification.fromJSON(Map<String, dynamic> notif) {
    return Notification(
      title: notif['notification']['title'],
      body: notif['notification']['body'],
      userId: notif['data']['userId'],
    );
  }

  factory Notification.fromDoc(DocumentSnapshot doc) {
    return Notification(
      id: doc.id,
      title: doc.data()['title'],
      body: doc.data()['body'],
      userId: doc.data()['userId'],
    );
  }
}
