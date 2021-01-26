import 'dart:convert';
import 'package:flushbar/flushbar.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:looper/Pages/home-Pages/global/globe.dart';
import 'package:looper/models/notification.dart' as not;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

class NotificationsService {
  static String _id;
  static FirebaseMessaging _fcm = FirebaseMessaging();
  static const String serverToken =
      'AAAA-QO9xBE:APA91bFd5w4aky2m_eZJlLpGEHPo9YpLnTFq7upwrVNIGJbK-CA3es0OCi5rGO_zEHCp_mQ-iEQUOVERTeIj8XxW_hT7U2MyK61jpOaypDTJf9wrJOKv9UV8YaPX7wwUGQFCKD8TpKcn';

  static void configureFcm(BuildContext context) async {
    final SharedPreferences _prefs = await SharedPreferences.getInstance();
    _id = _prefs.get('id');

    _fcm.configure(
      onMessage: (Map<String, dynamic> message) async {
        final not.Notification _notif = not.Notification.fromJSON(message);
        Flushbar(
          backgroundColor: Colors.grey[700],
          flushbarPosition: FlushbarPosition.TOP,
          title: _notif.title,
          message: _notif.body,
          duration: Duration(seconds: 5),
          margin: EdgeInsets.symmetric(horizontal: 10),
          borderRadius: 16,
        )..show(context);
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
      },
      onLaunch: (Map<String, dynamic> message) async {
        final not.Notification _notif = not.Notification.fromJSON(message);
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => GlobePage(),
          ),
        );
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
      },
      onResume: (Map<String, dynamic> message) async {
        final not.Notification _notif = not.Notification.fromJSON(message);
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => GlobePage(),
          ),
        );
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
      },
    );
    _fcm.requestNotificationPermissions(
      const IosNotificationSettings(
        sound: true,
        badge: true,
        alert: true,
        provisional: true,
      ),
    );

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
    await _fcm.requestNotificationPermissions(
      const IosNotificationSettings(
          sound: true, badge: true, alert: true, provisional: false),
    );
    final DocumentSnapshot doc =
        await FirebaseFirestore.instance.collection('users').doc(peerId).get();

    await http.post(
      'https://fcm.googleapis.com/fcm/send',
      headers: <String, String>{
        'Content-Type': 'application/json',
        'Authorization': 'key=$serverToken',
      },
      body: jsonEncode(
        <String, dynamic>{
          'notification': <String, dynamic>{
            'body': body,
            'title': title,
          },
          'priority': 'high',
          'data': <String, dynamic>{
            'click_action': 'FLUTTER_NOTIFICATION_CLICK',
            'id': '1',
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
    await _fcm.requestNotificationPermissions(
      const IosNotificationSettings(
          sound: true, badge: true, alert: true, provisional: false),
    );
    final SharedPreferences _prefs = await SharedPreferences.getInstance();
    final String id = _prefs.get('id');
    await http.post(
      'https://fcm.googleapis.com/fcm/send',
      headers: <String, String>{
        'Content-Type': 'application/json',
        'Authorization': 'key=$serverToken',
      },
      body: jsonEncode(
        <String, dynamic>{
          'notification': <String, dynamic>{
            'body': body,
            'title': title,
          },
          'priority': 'high',
          'data': <String, dynamic>{
            'click_action': 'FLUTTER_NOTIFICATION_CLICK',
            'id': '1',
            'status': 'done',
            'userId': senderId,
            'contentId': contentId,
            'navigator': navigator,
            'symbol': symbol,
          },
          'to': '/topics/following-$id',
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
