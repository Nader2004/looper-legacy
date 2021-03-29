import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:looper/models/notification.dart' as not;
import 'package:looper/models/userModel.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:looper/Pages/home-Pages/global/profile.dart';
import 'package:looper/widgets/post.dart';
import 'package:looper/widgets/talent.dart';
import 'package:looper/widgets/sport.dart';
import 'package:looper/widgets/challenge.dart';
import 'package:looper/Pages/home-Pages/chat/chat_list.dart';

class NotificationsPage extends StatefulWidget {
  NotificationsPage({Key key}) : super(key: key);

  @override
  _NotificationsPageState createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage> {
  String _userId = 'empty';
  Future<QuerySnapshot> _future;

  @override
  void initState() {
    super.initState();
    setPrefs();
  }

  void setPrefs() async {
    final SharedPreferences _prefs = await SharedPreferences.getInstance();
    setState(() {
      _userId = _prefs.get('id');
      _future = FirebaseFirestore.instance
          .collection('users')
          .doc(_userId)
          .collection('notifications')
          .orderBy('timestamp', descending: true)
          .get();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        elevation: 0.5,
        backgroundColor: Colors.white,
        iconTheme: IconThemeData.fallback(),
        centerTitle: true,
        title: Text(
          'Notifications',
          style: TextStyle(color: Colors.black),
        ),
      ),
      body: _userId == 'empty'
          ? SizedBox.shrink()
          : FutureBuilder(
              future: _future,
              builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation(
                        Colors.black,
                      ),
                      strokeWidth: 1.2,
                    ),
                  );
                }
                if (snapshot.data.size == 0) {
                  return Center(
                    child: Text(
                      'You don\'t have new notifications',
                      style: TextStyle(
                        color: Colors.grey,
                        fontSize: 18,
                      ),
                    ),
                  );
                }
                return ListView.separated(
                    separatorBuilder: (context, index) => Divider(),
                    itemCount: snapshot.data.size,
                    itemBuilder: (context, index) {
                      final not.Notification _notif = not.Notification.fromDoc(
                        snapshot.data.docs[index],
                      );
                      return FutureBuilder(
                          future: FirebaseFirestore.instance
                              .collection('users')
                              .doc(_notif.userId)
                              .get(),
                          builder: (context,
                              AsyncSnapshot<DocumentSnapshot> usersnapshot) {
                            if (usersnapshot.connectionState ==
                                ConnectionState.waiting) {
                              return SizedBox.shrink();
                            }
                            final User _user = User.fromDoc(usersnapshot.data);
                            return ListTile(
                              leading: GestureDetector(
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => ProfilePage(
                                        userId: _notif.userId,
                                      ),
                                    ),
                                  );
                                },
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(50),
                                  child: CachedNetworkImage(
                                    imageUrl: _user.profileImageUrl,
                                    fit: BoxFit.cover,
                                    height: 50,
                                    width: 50,
                                  ),
                                ),
                              ),
                              title: Text(_notif.title),
                              subtitle: Text(_notif.body),
                              trailing: Icon(
                                Icons.arrow_forward_ios,
                                color: Colors.grey,
                              ),
                              onTap: _notif.navigator == 'special'
                                  ? null
                                  : () {
                                      if (_notif.navigator == 'profile') {
                                        Navigator.of(context).push(
                                          MaterialPageRoute(
                                            builder: (context) => ProfilePage(
                                              userId: _user.id,
                                            ),
                                          ),
                                        );
                                      } else if (_notif.navigator == 'chat') {
                                        Navigator.of(context).push(
                                          MaterialPageRoute(
                                            builder: (context) => ChatList(),
                                          ),
                                        );
                                      } else {
                                        Navigator.of(context).push(
                                          MaterialPageRoute(
                                            builder: (context) =>
                                                NotificationViewPage(
                                              navigator: _notif.navigator,
                                              notifBody: _notif.body,
                                              contentId: _notif.contentId,
                                              symbol: _notif.symbol,
                                            ),
                                          ),
                                        );
                                      }
                                      FirebaseFirestore.instance
                                          .collection('users')
                                          .doc(_userId)
                                          .collection('notifications')
                                          .doc(_notif.id)
                                          .delete();
                                    },
                            );
                          });
                    });
              },
            ),
    );
  }
}

class NotificationViewPage extends StatefulWidget {
  final String notifBody;
  final String navigator;
  final String contentId;
  final String symbol;
  NotificationViewPage({
    Key key,
    this.notifBody,
    this.navigator,
    this.contentId,
    this.symbol,
  }) : super(key: key);

  @override
  _NotificationViewPageState createState() => _NotificationViewPageState();
}

class _NotificationViewPageState extends State<NotificationViewPage> {
  DocumentSnapshot _documentSnapshot;

  @override
  void initState() {
    super.initState();
    if (widget.navigator.contains('creation')) {
      if (widget.navigator.contains('post')) {
        FirebaseFirestore.instance
            .collection('posts')
            .where('timestamp', isEqualTo: widget.symbol)
            .get()
            .then(
              (value) => setState(() => _documentSnapshot = value.docs[0]),
            );
      } else if (widget.navigator.contains('talent')) {
        FirebaseFirestore.instance
            .collection('talents')
            .where('timestamp', isEqualTo: widget.symbol)
            .get()
            .then(
              (value) => setState(() => _documentSnapshot = value.docs[0]),
            );
      } else if (widget.navigator.contains('sport')) {
        FirebaseFirestore.instance
            .collection('sports')
            .where('timestamp', isEqualTo: widget.symbol)
            .get()
            .then(
              (value) => setState(() => _documentSnapshot = value.docs[0]),
            );
      } else if (widget.navigator.contains('comedy')) {
        FirebaseFirestore.instance
            .collection('comedy')
            .where('timestamp', isEqualTo: widget.symbol)
            .get()
            .then(
              (value) => setState(() => _documentSnapshot = value.docs[0]),
            );
      } else {
        FirebaseFirestore.instance
            .collection('challenge')
            .where('timestamp', isEqualTo: widget.symbol)
            .get()
            .then(
              (value) => setState(() => _documentSnapshot = value.docs[0]),
            );
      }
    } else {
      if (widget.navigator == 'post') {
        print('isPost');
        FirebaseFirestore.instance
            .collection('posts')
            .doc(widget.contentId)
            .get()
            .then(
              (value) => setState(() => _documentSnapshot = value),
            );
      } else if (widget.navigator == 'talent') {
        FirebaseFirestore.instance
            .collection('talents')
            .doc(widget.contentId)
            .get()
            .then(
              (value) => setState(() => _documentSnapshot = value),
            );
      } else if (widget.navigator == 'sport') {
        FirebaseFirestore.instance
            .collection('sports')
            .doc(widget.contentId)
            .get()
            .then(
              (value) => setState(() => _documentSnapshot = value),
            );
      } else if (widget.navigator == 'comedy') {
        FirebaseFirestore.instance
            .collection('comedy')
            .doc(widget.contentId)
            .get()
            .then(
              (value) => setState(() => _documentSnapshot = value),
            );
      } else {
        FirebaseFirestore.instance
            .collection('challenge')
            .doc(widget.contentId)
            .get()
            .then(
              (value) => setState(() => _documentSnapshot = value),
            );
      }
    }
  }

  Widget _buildContent() {
    if (widget.navigator.contains('post')) {
      return PostWidget(snapshot: _documentSnapshot);
    } else if (widget.navigator.contains('talent')) {
      return Talent(data: _documentSnapshot);
    } else if (widget.navigator.contains('sport')) {
      return Sport(data: _documentSnapshot);
    } else if (widget.navigator.contains('challenge')) {
      return Challenge(data: _documentSnapshot);
    }  else {
      return SizedBox.shrink();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        elevation: 0.5,
        backgroundColor: Colors.white,
        iconTheme: IconThemeData.fallback(),
        centerTitle: true,
        title: Text(
          widget.notifBody,
          style: TextStyle(color: Colors.black),
        ),
      ),
      body: _documentSnapshot == null
          ? Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation(
                  Colors.black,
                ),
                strokeWidth: 1.2,
              ),
            )
          : _buildContent(),
    );
  }
}
