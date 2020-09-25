import 'package:flutter/material.dart';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:looper/creation/challenge-create.dart';
import 'package:looper/services/database.dart';
import 'package:looper/services/personality.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../widgets/challenge.dart';
import 'package:looper/widgets/minimized-native-ad.dart';

class ChallengeRoom extends StatefulWidget {
  ChallengeRoom({Key key}) : super(key: key);

  @override
  _ChallengeRoomState createState() => _ChallengeRoomState();
}

class _ChallengeRoomState extends State<ChallengeRoom> {
  String _userId = 'empty';
  FirebaseFirestore _firestore;
  Map<String, dynamic> _personalityType;
  QuerySnapshot _querySnapshot;
  List<String> _ids = [];
  List<String> _followIds = [];
  Future<List<dynamic>> _future;

  @override
  void initState() {
    super.initState();
    _firestore = FirebaseFirestore.instance;
    setPrefs();
    PersonalityService.analyzePersonality();
  }

  void setPrefs() async {
    final SharedPreferences _prefs = await SharedPreferences.getInstance();
    final DocumentSnapshot _user =
        await _firestore.collection('users').doc(_prefs.get('id')).get();
    _querySnapshot = await _firestore
        .collection('users')
        .doc(_userId)
        .collection('following')
        .get();
    for (DocumentSnapshot doc in _querySnapshot.docs) {
      _followIds.add(doc.data()['creatorId']);
    }
    setState(() {
      _userId = _prefs.get('id');
      _personalityType = _user.data()['personality-type'];
      _future = Future.wait([
        DatabaseService.getFollowedContentFeed(
          'challenge',
          'creatorId',
          _querySnapshot,
        ),
        PersonalityService.getCompatibleContentStream(
          _personalityType,
          _firestore,
          'challenge',
          'creator-personality',
        ),
      ]);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: FutureBuilder(
        future: _future,
        builder: (context, AsyncSnapshot<List<dynamic>> snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(
                    strokeWidth: 1.2,
                    valueColor: AlwaysStoppedAnimation(Colors.white),
                  ),
                ],
              ),
            );
          }
          if (snapshot.data == null) {
            return SizedBox.shrink();
          }
          if (snapshot.data[0].documents.isEmpty &&
              snapshot.data[1].documents.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    MdiIcons.flagPlus,
                    color: Colors.white,
                    size: 60,
                  ),
                  SizedBox(height: 8),
                  Text(
                    'No Challenges uploaded yet',
                    style: GoogleFonts.aBeeZee(
                      textStyle: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                      ),
                    ),
                  ),
                  SizedBox(height: 10),
                  OutlineButton(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    borderSide: BorderSide(color: Colors.white),
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => ChallengeCreation(),
                        ),
                      );
                    },
                    textColor: Colors.white,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.add,
                          color: Colors.white,
                        ),
                        SizedBox(width: 5),
                        Text('create one now'),
                      ],
                    ),
                  ),
                ],
              ),
            );
          }
          for (DocumentSnapshot doc in snapshot.data[0].documents) {
            _ids.add(doc.data()['creatorId']);
          }
          if (_followIds != _ids) {
            return PageView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: snapshot.data[1].documents.length,
                itemBuilder: (context, index) {
                  if (index % 3 == 0 || index % 10 == 0) {
                    return Column(
                      children: [
                        Flexible(
                          child: Challenge(
                            data: snapshot.data[1].documents[index],
                          ),
                        ),
                        MinimizedNativeAd(),
                      ],
                    );
                  }
                  return Challenge(
                    data: snapshot.data[1].documents[index],
                  );
                });
          }
          int lengthOfDocs = 0;
          int querySnapShotCounter = 0;
          snapshot.data.forEach((snap) {
            lengthOfDocs = lengthOfDocs + snap.documents.length;
          });
          int counter = 0;
          return PageView.builder(
            itemCount: lengthOfDocs,
            scrollDirection: Axis.horizontal,
            itemBuilder: (context, int index) {
              try {
                final DocumentSnapshot doc = snapshot
                    .data[querySnapShotCounter].documents.reversed
                    .toList()[counter];
                counter = counter + 1;
                if (index % 3 == 0 || index % 10 == 0) {
                  return Column(
                    children: [
                      Flexible(
                        child: Challenge(
                          data: doc,
                        ),
                      ),
                      MinimizedNativeAd(),
                    ],
                  );
                }
                return Challenge(
                  data: doc,
                );
              } catch (RangeError) {
                querySnapShotCounter = querySnapShotCounter + 1;
                counter = 0;
                final DocumentSnapshot doc = snapshot
                    .data[querySnapShotCounter].documents.reversed
                    .toList()[counter];
                counter = counter + 1;
                if (index % 3 == 0 || index % 10 == 0) {
                  return Column(
                    children: [
                      Flexible(
                        child: Challenge(
                          data: doc,
                        ),
                      ),
                      MinimizedNativeAd(),
                    ],
                  );
                }
                return Challenge(
                  data: doc,
                );
              }
            },
          );
        },
      ),
    );
  }
}
