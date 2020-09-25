import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:looper/models/userModel.dart';
import 'package:looper/services/personality.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:superellipse_shape/superellipse_shape.dart';
import 'package:looper/Pages/home-Pages/global/profile.dart';
import 'package:looper/services/database.dart';
import 'package:looper/services/notifications.dart';

class PNDShowCasePage extends StatefulWidget {
  @override
  State<StatefulWidget> createState() => _PNDShowCasePageState();
}

class _PNDShowCasePageState extends State<PNDShowCasePage> {
  String _id = 'empty';
  String _userName = '';
  bool _isFollowing = false;
  Map<String, dynamic> _personalityType;
  FirebaseFirestore _firestore;

  @override
  void initState() {
    _firestore = FirebaseFirestore.instance;
    super.initState();
    setPrefs();
  }

  void setPrefs() async {
    final SharedPreferences _prefs = await SharedPreferences.getInstance();
    final DocumentSnapshot _doc =
        await _firestore.collection('users').doc(_prefs.get('id')).get();
    setState(() {
      _id = _prefs.get('id');
      _userName = _doc.data()['username'];
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: Text(
          'Similar People',
          style: TextStyle(color: Colors.black),
        ),
        centerTitle: true,
        iconTheme: IconThemeData.fallback(),
      ),
      body: FutureBuilder(
          future: _firestore.collection('users').doc(_id).get(),
          builder: (context, AsyncSnapshot<DocumentSnapshot> snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Center(
                child: CircularProgressIndicator(
                  strokeWidth: 1.2,
                  valueColor: AlwaysStoppedAnimation(Colors.white),
                ),
              );
            }
            _personalityType = snapshot.data.data()['personality-type'];
            return StreamBuilder(
                stream: PersonalityService.setUserPersonalityStream(
                  _personalityType,
                  _firestore,
                  true,
                ),
                builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return Center(
                      child: SpinKitThreeBounce(
                        color: Colors.black,
                        size: 30,
                      ),
                    );
                  } else {
                    return Padding(
                      padding: EdgeInsets.only(top: 10),
                      child: GridView.builder(
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          childAspectRatio: 0.7,
                        ),
                        itemBuilder: (contex, index) {
                          final User _user =
                              User.fromDoc(snapshot.data.docs[index]);
                          return _buildSimilirPeopleCard(
                            name: _user.username,
                            photo: _user.profileImageUrl,
                            id: _user.id,
                          );
                        },
                        itemCount: snapshot.data.docs.length,
                      ),
                    );
                  }
                });
          }),
    );
  }

  Widget _buildSimilirPeopleCard({
    String photo,
    String name,
    String id,
  }) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Stack(
        children: [
          Positioned.fill(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: GestureDetector(
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => ProfilePage(
                        userId: id,
                      ),
                    ),
                  );
                },
                child: CachedNetworkImage(
                  imageUrl: photo,
                  fit: BoxFit.cover,
                ),
              ),
            ),
          ),
          Align(
            alignment: Alignment.bottomCenter,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.end,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(
                  name,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Padding(
                  padding: EdgeInsets.symmetric(vertical: 2),
                  child: FlatButton(
                    shape: SuperellipseShape(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    color: Colors.black,
                    onPressed: () {
                      if (_isFollowing == false) {
                        DatabaseService.followUser(
                          id,
                          _userName,
                        );
                        NotificationsService.sendNotification(
                          'New Follower',
                          '$_userName followed you',
                          id,
                        );
                        NotificationsService.subscribeToTopic(id);
                        setState(() {
                          _isFollowing = true;
                        });
                      } else {
                        DatabaseService.unFollowUser(id);
                        NotificationsService.unsubscribeFromTopic(id);
                        setState(() {
                          _isFollowing = false;
                        });
                      }
                    },
                    textColor: Colors.white,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _isFollowing == true
                            ? Icon(
                                Icons.check,
                                size: 14,
                                color: Colors.white,
                              )
                            : SizedBox.shrink(),
                        _isFollowing == true
                            ? SizedBox(width: 5)
                            : SizedBox.shrink(),
                        Text(
                          _isFollowing == true ? 'Following' : 'FOLLOW',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
