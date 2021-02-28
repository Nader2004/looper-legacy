import 'package:flutter/material.dart';

import 'package:cool_nav/cool_nav.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:looper/creation/talent-create.dart';
import 'package:looper/services/database.dart';
import 'package:looper/services/personality.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../widgets/talent.dart';
import 'package:looper/widgets/minimized-native-ad.dart';

class TalentRoom extends StatefulWidget {
  TalentRoom({Key key}) : super(key: key);

  @override
  _TalentRoomState createState() => _TalentRoomState();
}

class _TalentRoomState extends State<TalentRoom> {
  String _userId = 'empty';
  int _selectedIndex = 0;
  FirebaseFirestore _firestore;
  Map<String, dynamic> _personalityType;
  QuerySnapshot _querySnapshot;
  List<String> _followIds = [];
  List<String> _ids = [];
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
          'talents',
          'creatorId',
          _querySnapshot,
        ),
        PersonalityService.getCompatibleContentStream(
          _personalityType,
          _firestore,
          'talents',
          'creator-personality',
        ),
      ]);
    });
  }

  Future<DocumentSnapshot> getUserData() async {
    final DocumentSnapshot _user =
        await _firestore.collection('users').doc(_userId).get();
    return _user;
  }

  List<DocumentSnapshot> getTalentList(QuerySnapshot snapshot) {
    if (_selectedIndex == 0) {
      List<DocumentSnapshot> songs = [];
      snapshot.docs.forEach((element) {
        if (element.data()['category'] == 'Singing') {
          songs.add(element);
        }
      });
      return songs;
    } else if (_selectedIndex == 1) {
      List<DocumentSnapshot> dances = [];
      snapshot.docs.forEach((element) {
        if (element.data()['category'] == 'Dancing') {
          dances.add(element);
        }
      });
      return dances;
    } else if (_selectedIndex == 2) {
      List<DocumentSnapshot> acts = [];
      snapshot.docs.forEach((element) {
        if (element.data()['category'] == 'Acting') {
          acts.add(element);
        }
      });
      return acts;
    } else if (_selectedIndex == 3) {
      List<DocumentSnapshot> paints = [];
      snapshot.docs.forEach((element) {
        if (element.data()['category'] == 'Painting') {
          paints.add(element);
        }
      });
      return paints;
    } else if (_selectedIndex == 4) {
      List<DocumentSnapshot> paints = [];
      snapshot.docs.forEach((element) {
        if (element.data()['category'] == 'Magic') {
          paints.add(element);
        }
      });
      return paints;
    } else {
      List<DocumentSnapshot> tricks = [];
      snapshot.docs.forEach((element) {
        if (element.data()['category'] == 'Special') {
          tricks.add(element);
        }
      });
      return tricks;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      bottomNavigationBar: SpotlightBottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (int index) => setState(() => _selectedIndex = index),
        darkTheme: true,
        items: [
          SpotlightBottomNavigationBarItem(
            icon: Icons.music_note,
          ),
          SpotlightBottomNavigationBarItem(
            icon: FontAwesomeIcons.child,
          ),
          SpotlightBottomNavigationBarItem(
            icon: FontAwesomeIcons.film,
          ),
          SpotlightBottomNavigationBarItem(
            icon: FontAwesomeIcons.brush,
          ),
          SpotlightBottomNavigationBarItem(
            icon: FontAwesomeIcons.magic,
          ),
          SpotlightBottomNavigationBarItem(
            icon: FontAwesomeIcons.star,
          ),
        ],
      ),
      body: FutureBuilder(
          future: _future,
          builder: (
            context,
            AsyncSnapshot<List<dynamic>> snapshot,
          ) {
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
            if (snapshot.data[0].docs.isEmpty &&
                snapshot.data[1].docs.isEmpty) {
              return Stack(
                children: [
                  Positioned(
                    top: 25,
                    left: 15,
                    child: IconButton(
                      icon: Icon(
                        Icons.close,
                        size: 25,
                        color: Colors.white,
                      ),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ),
                  Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          MdiIcons.shapePlus,
                          color: Colors.white,
                          size: 60,
                        ),
                        SizedBox(height: 8),
                        Text(
                          'No Talents uploaded yet',
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
                                builder: (context) => TalentCreation(),
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
                  ),
                ],
              );
            }
            for (DocumentSnapshot doc in snapshot.data[0].docs) {
              _ids.add(doc.data()['creatorId']);
            }
            if (_followIds != _ids) {
              return Stack(
                children: [
                  Positioned(
                    top: 25,
                    left: 15,
                    child: IconButton(
                      icon: Icon(
                        Icons.close,
                        size: 25,
                        color: Colors.white,
                      ),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ),
                  PageView.builder(
                      scrollDirection: Axis.vertical,
                      itemCount: getTalentList(snapshot.data[1]).length,
                      itemBuilder: (context, index) {
                        if (index % 3 == 0 || index % 10 == 0) {
                          return Column(
                            children: [
                              Flexible(
                                child: Talent(
                                  data: getTalentList(snapshot.data[1])[index],
                                ),
                              ),
                              MinimizedNativeAd(),
                            ],
                          );
                        }
                        return Talent(
                          data: getTalentList(snapshot.data[1])[index],
                        );
                      }),
                ],
              );
            }
            int lengthOfDocs = 0;
            int querySnapShotCounter = 0;
            snapshot.data.forEach((snap) {
              lengthOfDocs = lengthOfDocs + snap.docs.length;
            });

            int counter = 0;
            return Stack(
              children: [
                Positioned(
                  top: 25,
                  left: 15,
                  child: IconButton(
                    icon: Icon(
                      Icons.close,
                      size: 25,
                      color: Colors.white,
                    ),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ),
                PageView.builder(
                  scrollDirection: Axis.vertical,
                  itemBuilder: (context, index) {
                    try {
                      final DocumentSnapshot doc = getTalentList(
                        snapshot.data[querySnapShotCounter],
                      ).reversed.toList()[counter];
                      counter = counter + 1;
                      if (index % 3 == 0 || index % 10 == 0) {
                        return Column(
                          children: [
                            Flexible(
                              child: Talent(
                                data: doc,
                              ),
                            ),
                            MinimizedNativeAd(),
                          ],
                        );
                      }
                      return Talent(data: doc);
                    } catch (RageError) {
                      querySnapShotCounter = querySnapShotCounter + 1;
                      counter = 0;
                      final DocumentSnapshot doc = getTalentList(
                          snapshot.data[querySnapShotCounter])[counter];
                      counter = counter + 1;
                      if (index % 3 == 0 || index % 10 == 0) {
                        return Column(
                          children: [
                            Flexible(
                              child: Talent(
                                data: doc,
                              ),
                            ),
                            MinimizedNativeAd(),
                          ],
                        );
                      }
                      return Talent(
                        data: doc,
                      );
                    }
                  },
                  itemCount: lengthOfDocs,
                ),
              ],
            );
          }),
    );
  }
}
