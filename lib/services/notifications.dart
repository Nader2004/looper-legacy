import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:looper/models/notification.dart' as not;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

Future<dynamic> _handleNotification(RemoteMessage message) async {
  final not.Notification _notif = not.Notification.fromMessage(message);
  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();
  const AndroidNotificationDetails androidPlatformChannelSpecifics =
      AndroidNotificationDetails(
    '2021',
    'Looper Channel',
    'This is Looper\'s Notifications Channel',
    importance: Importance.max,
    priority: Priority.high,
  );
  const NotificationDetails platformChannelSpecifics =
      NotificationDetails(android: androidPlatformChannelSpecifics);
  FirebaseMessaging.instance.setForegroundNotificationPresentationOptions(
    alert: true,
    badge: true,
    sound: true,
  );
  await flutterLocalNotificationsPlugin.show(
    0,
    _notif.title,
    _notif.body,
    platformChannelSpecifics,
  );
}

class NotificationsService {
  static String _id;
  static FirebaseMessaging _fcm = FirebaseMessaging.instance;
  static const String serverToken =
      'AAAA-QO9xBE:APA91bFd5w4aky2m_eZJlLpGEHPo9YpLnTFq7upwrVNIGJbK-CA3es0OCi5rGO_zEHCp_mQ-iEQUOVERTeIj8XxW_hT7U2MyK61jpOaypDTJf9wrJOKv9UV8YaPX7wwUGQFCKD8TpKcn';

  static void configureFcm(BuildContext context) async {
    final SharedPreferences _prefs = await SharedPreferences.getInstance();
    _id = _prefs.get('id');

    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      final not.Notification _notif = not.Notification.fromMessage(message);
      FirebaseFirestore.instance
          .collection('users')
          .doc(_id)
          .collection('notifications')
          .add({
        'title': _notif.title,
        'body': _notif.body,
        'userId': _notif.userId,
        'navigator': _notif.navigator,
        'contentId': _notif.contentId,
        'symbol': _notif.symbol,
        'timestamp': DateTime.now().millisecondsSinceEpoch,
        'seen': false,
      });
      if (!Platform.isIOS) {
        _handleNotification(message);
      }
    });

    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      final not.Notification _notif = not.Notification.fromMessage(message);
      FirebaseFirestore.instance
          .collection('users')
          .doc(_id)
          .collection('notifications')
          .add({
        'title': _notif.title,
        'body': _notif.body,
        'userId': _notif.userId,
        'navigator': _notif.navigator,
        'contentId': _notif.contentId,
        'symbol': _notif.symbol,
        'timestamp': DateTime.now().millisecondsSinceEpoch,
        'seen': false,
      });
      _handleNotification(message);
    });

    FirebaseMessaging.instance
        .getInitialMessage()
        .then((RemoteMessage message) {
      if (message != null) {
        final not.Notification _notif = not.Notification.fromMessage(message);
        FirebaseFirestore.instance
            .collection('users')
            .doc(_id)
            .collection('notifications')
            .add({
          'title': _notif.title,
          'body': _notif.body,
          'userId': _notif.userId,
          'navigator': _notif.navigator,
          'contentId': _notif.contentId,
          'symbol': _notif.symbol,
          'timestamp': DateTime.now().millisecondsSinceEpoch,
          'seen': false,
        });
        _handleNotification(message);
      } else {
        return;
      }
    });

    _fcm.getToken().then((String token) async {
      final SharedPreferences _prefs = await SharedPreferences.getInstance();
      _id = _prefs.get('id');
      FirebaseFirestore.instance.collection('users').doc(_id).set(
        {
          'token': token,
        },
        SetOptions(merge: true),
      );
    });
  }

  static void sendNotification(
      String title, String body, String peerId, String navigator,
      [String contentId]) async {
    final DocumentSnapshot doc =
        await FirebaseFirestore.instance.collection('users').doc(peerId).get();
    await http.post(
      Uri.parse('https://fcm.googleapis.com/fcm/send'),
      headers: <String, String>{
        'Content-Type': 'application/json',
        'Authorization': 'key=$serverToken',
      },
      body: jsonEncode(
        <String, dynamic>{
          'notification': <String, dynamic>{
            'body': body,
            'title': title,
            'sound': 'default',
          },
          'priority': 'high',
          'content_available': true,
          'mutable_content': true,
          'data': <String, dynamic>{
            'id': '1',
            'body': body,
            'title': title,
            'click_action': 'FLUTTER_NOTIFICATION_CLICK',
            'status': 'done',
            'userId': peerId,
            'contentId': contentId,
            'navigator': navigator,
            'symbol': '',
          },
          'to': doc.data()['token'],
        },
      ),
    );
  }

  static void sendNotificationToFollowers(String title, String body,
      String senderId, String navigator, String symbol,
      [String contentId]) async {
    final SharedPreferences _prefs = await SharedPreferences.getInstance();
    final String id = _prefs.get('id');
    await http.post(
      Uri.parse('https://fcm.googleapis.com/fcm/send'),
      headers: <String, String>{
        'Content-Type': 'application/json',
        'Authorization': 'key=$serverToken',
      },
      body: jsonEncode(
        <String, dynamic>{
          'notification': <String, dynamic>{
            'body': body,
            'title': title,
            'sound': 'default',
          },
          'priority': 'high',
          'content_available': true,
          'mutable_content': true,
          'data': <String, dynamic>{
            'id': '1',
            'body': body,
            'title': title,
            'click_action': 'FLUTTER_NOTIFICATION_CLICK',
            'status': 'done',
            'userId': senderId,
            'contentId': contentId,
            'navigator': navigator,
            'symbol': symbol,
          },
          'token': '/topics/following-$id',
        },
      ),
    );
  }

  static void subscribeToTopic(String userId) {
    _fcm.subscribeToTopic('following-$userId');
  }

  static void unsubscribeFromTopic(String userId) {
    _fcm.unsubscribeFromTopic('following-$userId');
  }
}
