import 'package:flutter/material.dart';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_bounce/flutter_bounce.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:looper/creation/comedy-create.dart';
import 'package:looper/models/comedyModel.dart';
import 'package:looper/services/database.dart';
import 'package:looper/services/personality.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:video_player/video_player.dart';
import '../../widgets/comedy-joke.dart';
import 'package:looper/widgets/comedy-native-ad.dart';

class ComedyRoom extends StatefulWidget {
  ComedyRoom({Key key}) : super(key: key);

  @override
  _ComedyRoomState createState() => _ComedyRoomState();
}

class _ComedyRoomState extends State<ComedyRoom> {
  String _userId = 'empty';
  FirebaseFirestore _firestore;
  Map<String, dynamic> _personalityType;
  VideoPlayerController _controller;
  QuerySnapshot _querySnapshot;
  List<String> _ids = [];
  List<String> _followIds = [];
  Future<List<dynamic>> _shows;
  Future<List<dynamic>> _comedies;

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
      _shows = Future.wait([
        DatabaseService.getFollowedContentFeed(
          'comedy',
          'creatorId',
          _querySnapshot,
        ),
        PersonalityService.getCompatibleContentStream(
          _personalityType,
          _firestore,
          'comedy',
          'author-personality',
        ),
      ]);
      _comedies = Future.wait([
        DatabaseService.getFollowedContentFeed(
          'comedy',
          'creatorId',
          _querySnapshot,
        ),
        PersonalityService.getCompatibleContentStream(
          _personalityType,
          _firestore,
          'comedy',
          'author-personality',
        ),
      ]);
    });
  }

  List<DocumentSnapshot> getComedyShowList(QuerySnapshot snapshot) {
    List<DocumentSnapshot> shows = [];
    snapshot.docs.forEach((element) {
      if (element.data()['type'] == 'show') {
        shows.add(element);
      }
    });
    return shows;
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(
          'Comedy',
          style: TextStyle(color: Colors.black),
        ),
        centerTitle: true,
        elevation: 0.5,
        iconTheme: IconThemeData.fallback(),
        backgroundColor: Colors.white,
      ),
      body: ListView(
        children: <Widget>[
          FutureBuilder(
              future: _shows,
              builder: (context, AsyncSnapshot<List<dynamic>> snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(
                    child: SpinKitWanderingCubes(
                      color: Colors.black,
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
                        SizedBox(height: 10),
                        Icon(
                          MdiIcons.plusCircleOutline,
                          color: Colors.black,
                          size: 30,
                        ),
                        SizedBox(height: 8),
                        Text(
                          'No Comedy shows uploaded yet',
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
                                builder: (context) => ComedyCreation(),
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
                  return Container(
                    height: MediaQuery.of(context).size.width / 2.4,
                    child: ListView.builder(
                        shrinkWrap: true,
                        scrollDirection: Axis.horizontal,
                        physics: ScrollPhysics(),
                        itemCount: getComedyShowList(snapshot.data[1]).length,
                        itemBuilder: (context, index) {
                          return ComedyShow(
                            data: getComedyShowList(snapshot.data[1])[index],
                            userId: _userId,
                          );
                        }),
                  );
                }
                int lengthOfDocs = 0;
                int querySnapShotCounter = 0;
                snapshot.data.forEach((snap) {
                  lengthOfDocs = lengthOfDocs + snap.documents.length;
                });

                int counter = 0;
                return Container(
                  height: MediaQuery.of(context).size.width / 2.4,
                  margin: EdgeInsets.symmetric(vertical: 10),
                  child: ListView.builder(
                      itemCount: lengthOfDocs,
                      scrollDirection: Axis.horizontal,
                      shrinkWrap: true,
                      itemBuilder: (context, int index) {
                        try {
                          final DocumentSnapshot doc = getComedyShowList(
                            snapshot.data[querySnapShotCounter],
                          ).reversed.toList()[counter];
                          counter = counter + 1;
                          return ComedyShow(
                            data: doc,
                            userId: _userId,
                          );
                        } catch (RageError) {
                          querySnapShotCounter = querySnapShotCounter + 1;
                          counter = 0;
                          final DocumentSnapshot doc = getComedyShowList(
                            snapshot.data[querySnapShotCounter],
                          ).reversed.toList()[counter];
                          counter = counter + 1;
                          return ComedyShow(
                            data: doc,
                            userId: _userId,
                          );
                        }
                      }),
                );
              }),
          Divider(),
          FutureBuilder(
            future: _comedies,
            builder: (context, AsyncSnapshot<List<dynamic>> snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return Center(
                  child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation(Colors.black),
                    strokeWidth: 1.2,
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
                        MdiIcons.plusNetworkOutline,
                        color: Colors.black,
                        size: 60,
                      ),
                      SizedBox(height: 8),
                      Text(
                        'No Comedies uploaded yet',
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
                              builder: (context) => ComedyCreation(),
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
                    shrinkWrap: true,
                    physics: ScrollPhysics(),
                    itemCount: snapshot.data[1].documents.length,
                    separatorBuilder: (context, index) {
                      if (index % 3 == 0 || index % 10 == 0) {
                        return ComedyNativeAd();
                      } else {
                        return SizedBox.shrink();
                      }
                    },
                    itemBuilder: (context, index) {
                      if (snapshot.data[1].documents[index].data()['type'] !=
                          'show') {
                        return ComedyJoke(
                          data: snapshot.data[1].documents[index],
                        );
                      } else {
                        return Container();
                      }
                    });
              }
              int lengthOfDocs = 0;
              int querySnapShotCounter = 0;
              snapshot.data.forEach((snap) {
                lengthOfDocs = lengthOfDocs + snap.documents.length;
              });
              int counter = 0;
              return Column(
                children: <Widget>[
                  Flexible(
                    child: Container(
                      height: MediaQuery.of(context).size.height,
                      child: ListView.separated(
                        shrinkWrap: true,
                        separatorBuilder: (context, index) {
                          if (index % 3 == 0 || index % 10 == 0) {
                            return ComedyNativeAd();
                          } else {
                            return SizedBox.shrink();
                          }
                        },
                        itemBuilder: (context, int index) {
                          if (snapshot.data[1].documents[index]
                                  .data()['type'] !=
                              'show') {
                            try {
                              final DocumentSnapshot doc = snapshot
                                  .data[querySnapShotCounter].documents.reversed
                                  .toList()[counter];
                              counter = counter + 1;
                              return ComedyJoke(
                                data: doc,
                              );
                            } catch (RangeError) {
                              querySnapShotCounter = querySnapShotCounter + 1;
                              counter = 0;
                              final DocumentSnapshot doc = snapshot
                                  .data[querySnapShotCounter].documents.reversed
                                  .toList()[counter];
                              counter = counter + 1;
                              return ComedyJoke(
                                data: doc,
                              );
                            }
                          } else {
                            return Container();
                          }
                        },
                        itemCount: lengthOfDocs,
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

class ComedyShow extends StatefulWidget {
  final String userId;
  final DocumentSnapshot data;
  ComedyShow({Key key, this.data, this.userId}) : super(key: key);

  @override
  _ComedyShowState createState() => _ComedyShowState();
}

class _ComedyShowState extends State<ComedyShow> {
  Comedy _comedyShow;
  VideoPlayerController _controller;
  @override
  void initState() {
    _comedyShow = Comedy.fromDoc(widget.data);
    _controller = VideoPlayerController.network(_comedyShow.mediaUrl);
    _controller.initialize().then((_) => setState(() {}));
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 10),
      child: Column(
        children: <Widget>[
          ClipRRect(
            borderRadius: BorderRadius.circular(50),
            child: Container(
              height: MediaQuery.of(context).size.width / 5,
              width: MediaQuery.of(context).size.width / 5,
              color: !_controller.value.initialized
                  ? Colors.grey[400]
                  : Colors.transparent,
              child: !_controller.value.initialized
                  ? Container()
                  : OverflowBox(
                      alignment: Alignment.center,
                      child: FittedBox(
                        fit: BoxFit.cover,
                        child: Container(
                          width: MediaQuery.of(context).size.width,
                          height: MediaQuery.of(context).size.width /
                              _controller.value.aspectRatio,
                          child: VideoPlayer(_controller),
                        ),
                      ),
                    ),
            ),
          ),
          SizedBox(height: 5),
          Row(
            children: <Widget>[
              Icon(Icons.group, color: Colors.grey),
              SizedBox(width: 5),
              Text(
                _comedyShow.visitCount.toString(),
                style: TextStyle(color: Colors.grey),
              ),
            ],
          ),
          FlatButton(
            onPressed: () {
              DatabaseService.addVisit(_comedyShow.id);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ShowPage(
                    userId: widget.userId,
                    comedy: widget.data,
                  ),
                ),
              );
            },
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            textColor: Colors.white,
            color: Colors.deepPurpleAccent,
            child: Text('JOIN'),
          ),
        ],
      ),
    );
  }
}

class ShowPage extends StatefulWidget {
  final String userId;
  final DocumentSnapshot comedy;
  ShowPage({Key key, this.comedy, this.userId}) : super(key: key);

  @override
  _ShowPageState createState() => _ShowPageState();
}

class _ShowPageState extends State<ShowPage> {
  VideoPlayerController _controller;
  Comedy _comedyShow;
  @override
  void initState() {
    _comedyShow = Comedy.fromDoc(widget.comedy);
    _controller = VideoPlayerController.network(_comedyShow.mediaUrl);
    _controller.initialize().then((_) => setState(() {}));
    _controller.play();
    super.initState();
  }

  @override
  void dispose() {
    DatabaseService.removeVisit(_comedyShow.id);
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: Text(
          _comedyShow.caption != ''
              ? '${_comedyShow.caption} by ${_comedyShow.authorName}'
              : '${_comedyShow.authorName}\'s comedy show',
          style: GoogleFonts.abrilFatface(),
        ),
      ),
      body: Stack(
        children: [
          Positioned.fill(
            child: !_controller.value.initialized
                ? Center(
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation(Colors.white),
                    ),
                  )
                : VideoPlayer(_controller),
          ),
          Align(
            alignment: Alignment.topCenter,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  height: 30,
                  padding: EdgeInsets.all(8),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    color: Colors.grey.withOpacity(0.5),
                  ),
                  child: Text(
                    _comedyShow.laughs.toString() + ' Laughs',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Align(
            alignment: Alignment.bottomCenter,
            child: Row(
              children: [
                Container(
                  height: 25,
                  width: MediaQuery.of(context).size.width / 1.2,
                  margin: EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    '${_comedyShow.visitCount.toString()} PEOPLE JOINED',
                  ),
                ),
                Bounce(
                  duration: Duration(milliseconds: 100),
                  onPressed: () {
                    DatabaseService.laugh(
                      _comedyShow.id,
                      widget.userId,
                    );
                  },
                  child: Text(
                    '😂',
                    style: TextStyle(fontSize: 30),
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
