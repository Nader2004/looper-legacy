import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:looper/creation/sport-create.dart';
import 'package:looper/services/database.dart';
import 'package:looper/services/personality.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../widgets/sport.dart';
import 'package:looper/widgets/sport-native-ad.dart';

class SportsRoom extends StatefulWidget {
  SportsRoom({Key key}) : super(key: key);

  @override
  _SportsRoomState createState() => _SportsRoomState();
}

class _SportsRoomState extends State<SportsRoom> {
  String _userId = 'empty';
  int _selectedIndex = 1;
  List<IconData> _icons = [
    MdiIcons.trophy,
    MdiIcons.soccer,
    MdiIcons.football,
    MdiIcons.basketball,
    MdiIcons.swim,
    MdiIcons.volleyball,
    MdiIcons.baseballBat,
    MdiIcons.tennis,
    MdiIcons.tableTennis,
    MdiIcons.run,
    MdiIcons.armFlex,
  ];
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
          'sports',
          'creatorId',
          _querySnapshot,
        ),
        PersonalityService.getCompatibleContentStream(
          _personalityType,
          _firestore,
          'sports',
          'creator-personality',
        ),
      ]);
    });
  }

  List<DocumentSnapshot> getSportList(QuerySnapshot snapshot) {
    if (_selectedIndex == 1) {
      List<DocumentSnapshot> soccer = [];
      snapshot.docs.forEach((element) {
        if (element.data()['category'] == 'soccer') {
          soccer.add(element);
        }
      });
      return soccer;
    } else if (_selectedIndex == 2) {
      List<DocumentSnapshot> americanFootball = [];
      snapshot.docs.forEach((element) {
        if (element.data()['category'] == 'american football') {
          americanFootball.add(element);
        }
      });
      return americanFootball;
    } else if (_selectedIndex == 3) {
      List<DocumentSnapshot> basketball = [];
      snapshot.docs.forEach((element) {
        if (element.data()['category'] == 'basketball') {
          basketball.add(element);
        }
      });
      return basketball;
    } else if (_selectedIndex == 4) {
      List<DocumentSnapshot> swimming = [];
      snapshot.docs.forEach((element) {
        if (element.data()['category'] == 'swimming') {
          swimming.add(element);
        }
      });
      return swimming;
    } else if (_selectedIndex == 5) {
      List<DocumentSnapshot> volley = [];
      snapshot.docs.forEach((element) {
        if (element.data()['category'] == 'volley') {
          volley.add(element);
        }
      });
      return volley;
    } else if (_selectedIndex == 6) {
      List<DocumentSnapshot> baseball = [];
      snapshot.docs.forEach((element) {
        if (element.data()['category'] == 'baseball') {
          baseball.add(element);
        }
      });
      return baseball;
    } else if (_selectedIndex == 7) {
      List<DocumentSnapshot> tennis = [];
      snapshot.docs.forEach((element) {
        if (element.data()['category'] == 'tennis') {
          tennis.add(element);
        }
      });
      return tennis;
    } else if (_selectedIndex == 8) {
      List<DocumentSnapshot> tableTennis = [];
      snapshot.docs.forEach((element) {
        if (element.data()['category'] == 'table tennis') {
          tableTennis.add(element);
        }
      });
      return tableTennis;
    } else if (_selectedIndex == 9) {
      List<DocumentSnapshot> running = [];
      snapshot.docs.forEach((element) {
        if (element.data()['category'] == 'running') {
          running.add(element);
        }
      });
      return running;
    } else if (_selectedIndex == 10) {
      List<DocumentSnapshot> gym = [];
      snapshot.docs.forEach((element) {
        if (element.data()['category'] == 'gym') {
          gym.add(element);
        }
      });
      return gym;
    } else {
      return snapshot.docs;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children: <Widget>[
          LayoutBuilder(builder: (context, constraint) {
            return SingleChildScrollView(
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraint.maxHeight),
                child: IntrinsicHeight(
                  child: NavigationRail(
                    selectedIndex: _selectedIndex,
                    groupAlignment: -0.7,
                    onDestinationSelected: (int index) {
                      setState(() {
                        _selectedIndex = index;
                      });
                      if (index == 0) {
                        Navigator.of(context).pop();
                      }
                    },
                    labelType: NavigationRailLabelType.selected,
                    destinations: [
                      NavigationRailDestination(
                        icon: Icon(Icons.close),
                        label: Text('Close'),
                      ),
                      NavigationRailDestination(
                        icon: Icon(_icons[0]),
                        label: Text('Trending'),
                      ),
                      NavigationRailDestination(
                        icon: Icon(_icons[1]),
                        label: Text('Soccer'),
                      ),
                      NavigationRailDestination(
                        icon: Icon(_icons[2]),
                        label: Text('Football'),
                      ),
                      NavigationRailDestination(
                        icon: Icon(_icons[3]),
                        label: Text('Basketball'),
                      ),
                      NavigationRailDestination(
                        icon: Icon(_icons[4]),
                        label: Text('Swimming'),
                      ),
                      NavigationRailDestination(
                        icon: Icon(_icons[5]),
                        label: Text('Volley'),
                      ),
                      NavigationRailDestination(
                        icon: Icon(_icons[6]),
                        label: Text('Baseball'),
                      ),
                      NavigationRailDestination(
                        icon: Icon(_icons[7]),
                        label: Text('Tennis'),
                      ),
                      NavigationRailDestination(
                        icon: Icon(_icons[8]),
                        label: Text('Ping Pong'),
                      ),
                      NavigationRailDestination(
                        icon: Icon(_icons[9]),
                        label: Text('Running'),
                      ),
                      NavigationRailDestination(
                        icon: Icon(_icons[10]),
                        label: Text('Gym'),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }),
          VerticalDivider(thickness: 1, width: 1),
          // This is the main content.
          Expanded(
            child: FutureBuilder(
                future: _future,
                builder: (context, AsyncSnapshot<List<dynamic>> snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return Center(
                      child: CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation(Colors.black),
                      ),
                    );
                  }
                  if (snapshot.data == null) {
                    return SizedBox.shrink();
                  }
                  if (snapshot.data[0].documents.isEmpty &&
                      snapshot.data[1].documents.isEmpty) {
                    return Container(
                      margin: EdgeInsets.only(
                        top: MediaQuery.of(context).size.height / 2.5,
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            MdiIcons.plusNetworkOutline,
                            color: Colors.black,
                            size: 60,
                          ),
                          SizedBox(height: 8),
                          Text(
                            'No Sports uploaded yet',
                            style: GoogleFonts.aBeeZee(
                              textStyle: TextStyle(
                                color: Colors.black,
                                fontSize: 20,
                              ),
                            ),
                          ),
                          SizedBox(height: 10),
                          OutlineButton(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            borderSide: BorderSide(color: Colors.black),
                            onPressed: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (context) => SportCreation(),
                                ),
                              );
                            },
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.add,
                                  color: Colors.black,
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
                    return ListView.separated(
                        itemCount: getSportList(snapshot.data[1]).length,
                        separatorBuilder: (context, index) {
                          if (index % 3 == 0 || index % 10 == 0) {
                            return SportNativeAd();
                          } else {
                            return SizedBox.shrink();
                          }
                        },
                        itemBuilder: (context, index) {
                          return Sport(
                            data: getSportList(snapshot.data[1])[index],
                          );
                        });
                  }
                  int lengthOfDocs = 0;
                  int querySnapShotCounter = 0;
                  snapshot.data.forEach((snap) {
                    lengthOfDocs = lengthOfDocs + snap.documents.length;
                  });
                  int counter = 0;
                  return ListView.separated(
                    separatorBuilder: (context, index) {
                      if (index % 3 == 0 || index % 10 == 0) {
                        return SportNativeAd();
                      } else {
                        return SizedBox.shrink();
                      }
                    },
                    itemBuilder: (context, int index) {
                      try {
                        final DocumentSnapshot doc = getSportList(
                          snapshot.data[querySnapShotCounter],
                        ).reversed.toList()[counter];
                        counter = counter + 1;
                        return Sport(data: doc);
                      } catch (RageError) {
                        querySnapShotCounter = querySnapShotCounter + 1;
                        counter = 0;
                        final DocumentSnapshot doc = getSportList(
                            snapshot.data[querySnapShotCounter])[counter];
                        counter = counter + 1;
                        return Sport(
                          data: doc,
                        );
                      }
                    },
                    itemCount: lengthOfDocs,
                  );
                }),
          ),
        ],
      ),
    );
  }
}
