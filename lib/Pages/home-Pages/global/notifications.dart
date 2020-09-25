import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:looper/models/notification.dart' as not;
import 'package:looper/models/userModel.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:looper/Pages/home-Pages/global/profile.dart';
import 'package:visibility_detector/visibility_detector.dart';

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
                            return VisibilityDetector(
                              key: Key(_notif.id),
                              onVisibilityChanged: (VisibilityInfo info) {
                                final double _percent =
                                    info.visibleFraction * 100;
                                if (_percent == 100) {
                                  FirebaseFirestore.instance
                                      .collection('users')
                                      .doc(_userId)
                                      .collection('notifications')
                                      .doc(_notif.id)
                                      .delete();
                                }
                              },
                              child: ListTile(
                                leading: ClipRRect(
                                  borderRadius: BorderRadius.circular(50),
                                  child: CachedNetworkImage(
                                    imageUrl: _user.profileImageUrl,
                                    fit: BoxFit.cover,
                                    height: 50,
                                    width: 50,
                                  ),
                                ),
                                title: Text(_notif.title),
                                subtitle: Text(_notif.body),
                                trailing: Icon(
                                  Icons.arrow_forward_ios,
                                  color: Colors.grey,
                                ),
                                onTap: () {
                                  Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (context) => ProfilePage(
                                        userId: _user.id,
                                      ),
                                    ),
                                  );
                                },
                              ),
                            );
                          });
                    });
              },
            ),
    );
  }
}
