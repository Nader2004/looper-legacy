import 'dart:async';
import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:esys_flutter_share/esys_flutter_share.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:looper/creation/post-create.dart';
import 'package:looper/models/userModel.dart';
import 'package:looper/services/database.dart';
import 'package:looper/services/personality.dart';
import 'package:looper/widgets/post-native-ad.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shimmer/shimmer.dart';
import 'package:tutorial_coach_mark/tutorial_coach_mark.dart';
import 'package:tutorial_coach_mark/animated_focus_light.dart';
import 'package:stringprocess/stringprocess.dart';

import '../../../widgets/post.dart';

import '../../../widgets/pnd-showcase.dart';

class GlobePage extends StatefulWidget {
  final bool firstTime;
  const GlobePage({Key key, this.firstTime = false}) : super(key: key);

  @override
  _GlobePageState createState() => _GlobePageState();
}

class _GlobePageState extends State<GlobePage> {
  String _userId = 'empty';
  FirebaseFirestore _firestore;
  Map<String, dynamic> _personalityType;
  QuerySnapshot _querySnapshot;
  List<String> _followIds = [];
  List<String> _ids = [];
  List<TargetFocus> _targets = [];
  GlobalKey keyPersonalities = GlobalKey();
  GlobalKey progressKey = GlobalKey();
  GlobalKey postKey = GlobalKey();
  Stream<QuerySnapshot> _compatableUsers;
  Future<List<dynamic>> _future;

  @override
  void initState() {
    super.initState();
    _firestore = FirebaseFirestore.instance;

    setPrefs();
    PersonalityService.analyzePersonality();
    if (widget.firstTime != false) {
      _targets.add(
        TargetFocus(
          identify: 'Target 0',
          keyTarget: keyPersonalities,
          color: Colors.blue,
          contents: [
            ContentTarget(
              align: AlignContent.bottom,
              child: Container(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      'Discover a List of compatible people',
                      style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          fontSize: 20.0),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(top: 10.0),
                      child: Text(
                        'Here you will see a list of people who are compatible with you. These people are similar to your personality',
                        style: TextStyle(color: Colors.white),
                      ),
                    )
                  ],
                ),
              ),
            )
          ],
          shape: ShapeLightFocus.RRect,
          radius: 5,
        ),
      );
      _targets.add(
        TargetFocus(
          identify: 'Target 1',
          keyTarget: progressKey,
          color: Colors.blue,
          contents: [
            ContentTarget(
              align: AlignContent.bottom,
              child: Container(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      'Your personality recognition Progress',
                      style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          fontSize: 20.0),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(top: 10.0),
                      child: Text(
                        'Here you will see a list of people who are compatible with you. These people are similar to your personality',
                        style: TextStyle(color: Colors.white),
                      ),
                    )
                  ],
                ),
              ),
            )
          ],
          shape: ShapeLightFocus.RRect,
          radius: 5,
        ),
      );
      _targets.add(
        TargetFocus(
          identify: 'Target 2',
          keyTarget: postKey,
          color: Colors.blue,
          contents: [
            ContentTarget(
              align: AlignContent.bottom,
              child: Container(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      'Share your thought from here',
                      style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          fontSize: 20.0),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(top: 10.0),
                      child: Text(
                        'Do you think about something and wanna share it with the world, just click here',
                        style: TextStyle(color: Colors.white),
                      ),
                    )
                  ],
                ),
              ),
            )
          ],
          shape: ShapeLightFocus.RRect,
          radius: 5,
        ),
      );
      WidgetsBinding.instance.addPostFrameCallback(_afterLayout);
    }
  }

  void _afterLayout(_) {
    Future.delayed(Duration(seconds: 3), () {
      showTutorial();
    });
  }

  void showTutorial() {
    TutorialCoachMark(context,
        targets: _targets, // List<TargetFocus>
        colorShadow: Colors.red, // DEFAULT Colors.black
        alignSkip: Alignment.bottomRight,
        textSkip: "SKIP",
        paddingFocus: 10,
        focusAnimationDuration: Duration(milliseconds: 500),
        pulseAnimationDuration: Duration(milliseconds: 500), onFinish: () {
      showPostMethod();
    },  onClickSkip: () {
      showPostMethod();
    })
      ..show();
  }

 void showPostMethod() {
   _firestore
        .collection('posts')
        .where('author', isEqualTo: _userId)
        .get()
        .then((QuerySnapshot snapshot) {
      if (snapshot.docs.isEmpty) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => Dialog(
            backgroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadiusDirectional.circular(20),
            ),
            child: IntrinsicHeight(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Padding(
                    padding: EdgeInsets.only(
                      right: MediaQuery.of(context).size.width / 1.6,
                    ),
                    child: IconButton(
                      onPressed: () {
                        Navigator.pop(context);
                      },
                      icon: Icon(Icons.close, color: Colors.black),
                    ),
                  ),
                  Padding(
                    padding: EdgeInsets.all(8.0),
                    child: Icon(
                      MdiIcons.infinity,
                      color: Colors.black,
                      size: 50,
                    ),
                  ),
                  Text(
                    'Welcome to Looper',
                    style: TextStyle(
                      fontSize: 25,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Padding(
                    padding: EdgeInsets.all(8.0),
                    child: Icon(
                      MdiIcons.earth,
                      color: Colors.black,
                      size: 50,
                    ),
                  ),
                  Text(
                    'Start by sharing a thought',
                    style: TextStyle(
                      fontSize: 20,
                    ),
                  ),
                  Padding(
                    padding: EdgeInsets.symmetric(
                      vertical: 20,
                      horizontal: 20,
                    ),
                    child: Container(
                      color: Colors.white,
                      height: MediaQuery.of(context).size.height / 20,
                      child: OutlineButton(
                        onPressed: () {
                          Navigator.pop(context);
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => PostCreationPage(),
                            ),
                          );
                        },
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(5),
                        ),
                        borderSide: BorderSide(color: Colors.black),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.add,
                              size: 20,
                              color: Colors.black,
                            ),
                            SizedBox(width: 5),
                            Text(
                              'create your thought',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      }
    });
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
      _personalityType = _user?.data()['personality-type'];
      _compatableUsers = PersonalityService.setUserPersonalityStream(
        _personalityType,
        _firestore,
      );
      _future = Future.wait([
        DatabaseService.getFollowedContentFeed(
          'posts',
          'author',
          _querySnapshot,
        ),
        PersonalityService.getCompatibleContentStream(
          _personalityType,
          _firestore,
          'posts',
          'author-personality',
        ),
      ]);
    });
    
  }

  Future<String> get _localPath async {
    final directory = await getApplicationDocumentsDirectory();
    return directory.path;
  }

  Future<File> get _localPersonalityFile async {
    final path = await _localPath;
    return File('$path/personality.txt');
  }

  Widget _buildTopSimilaritiesText() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: <Widget>[
        Container(
          margin: EdgeInsets.only(
            left: 17.5,
            top: 15,
          ),
          child: Text(
            'Discover',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 35,
            ),
          ),
        ),
        Container(
          margin: EdgeInsets.only(
              right: _personalityType == null ? 20 : 10,
              top: _personalityType == null ? 16 : 6),
          child: _personalityType.isEmpty
              ? FutureBuilder(
                  future: _localPersonalityFile,
                  builder: (
                    context,
                    AsyncSnapshot<File> file,
                  ) {
                    if (file.connectionState == ConnectionState.waiting) {
                      return SizedBox.shrink();
                    }
                    final StringProcessor _tps = StringProcessor();
                    final String _text = file.data.readAsStringSync();
                    final int _textWordCount = _tps.getWordCount(_text);
                    final double _percentage = (_textWordCount / 1500) * 100;
                    final double _percentageLeft = 100 - _percentage;
                    print(_percentage);
                    return Text(
                      '${_percentageLeft.toStringAsFixed(1)}% left',
                      key: progressKey,
                      style: GoogleFonts.abel(
                        fontSize: 24,
                      ),
                    );
                  },
                )
              : Shimmer.fromColors(
                  baseColor: Colors.red,
                  highlightColor: Colors.yellow,
                  child: Row(
                    children: <Widget>[
                      Container(
                        margin: EdgeInsets.only(
                          top: 15,
                          bottom: 6,
                        ),
                        child: GestureDetector(
                          onTap: _personalityType == null
                              ? null
                              : () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => PNDShowCasePage(),
                                    ),
                                  );
                                },
                          child: Row(
                            children: <Widget>[
                              Container(
                                margin: EdgeInsets.only(right: 2),
                                child: Text(
                                  'WATCH ALL',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 17.5,
                                    color: Colors.red,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
        ),
      ],
    );
  }

  Widget _buildSimilarUserWidget(DocumentSnapshot snapshot) {
    final User _user = User.fromDoc(snapshot);
    return Stack(
      children: <Widget>[
        Container(
          width: MediaQuery.of(context).size.width / 3.7,
          height: MediaQuery.of(context).size.width / 2,
          margin: EdgeInsets.symmetric(horizontal: 5),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: CachedNetworkImage(
              imageUrl: _user.profileImageUrl,
              fit: BoxFit.cover,
            ),
          ),
        ),
        Positioned.fill(
          child: Align(
            alignment: Alignment.bottomCenter,
            child: Padding(
              padding: EdgeInsets.all(10),
              child: Text(
                _user.username,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSimilarPeopleWidget() {
    return StreamBuilder(
        stream: _compatableUsers,
        builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
          if (snapshot.data == null) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    MdiIcons.transitConnectionVariant,
                    color: Colors.grey,
                    size: 30,
                  ),
                  SizedBox(height: 5),
                  Text(
                    'Analyzing..',
                    style: TextStyle(
                      color: Colors.grey,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 8),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        MdiIcons.headDotsHorizontal,
                        color: Colors.grey,
                        size: 25,
                      ),
                      SizedBox(width: 5),
                      Text(
                        'create posts, jokes, talents, challenges...',
                        style: TextStyle(
                          color: Colors.grey,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 5),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        MdiIcons.ticket,
                        color: Colors.grey,
                        size: 25,
                      ),
                      SizedBox(width: 5),
                      Text(
                        'like, comment, clap, interact...',
                        style: TextStyle(
                          color: Colors.grey,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 10),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        MdiIcons.recordCircleOutline,
                        color: Colors.green,
                        size: 20,
                      ),
                      SizedBox(width: 5),
                      Text(
                        'Stay Active',
                        style: TextStyle(
                          color: Colors.green,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(width: 20),
                    ],
                  ),
                ],
              ),
            );
          } else {
            return Container(
              height: MediaQuery.of(context).size.width / 2,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemBuilder: (context, int index) =>
                    _buildSimilarUserWidget(snapshot.data.docs[index]),
                itemCount: snapshot.data.docs.length,
              ),
            );
          }
        });
  }

  Widget _postCreation() {
    return Container(
      key: postKey,
      color: Colors.white,
      padding: EdgeInsets.symmetric(
        vertical: 13,
        horizontal: MediaQuery.of(context).size.width / 15,
      ),
      height: MediaQuery.of(context).size.height / 10,
      width: MediaQuery.of(context).size.width,
      alignment: Alignment.centerLeft,
      child: GestureDetector(
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => PostCreationPage(),
          ),
        ),
        child: Text(
          'What do you think...?',
          style: TextStyle(
            color: Colors.grey,
            fontWeight: FontWeight.w600,
            fontSize: 20,
          ),
        ),
      ),
    );
  }

  Widget _buildSimilarPeople() {
    return Padding(
      padding: EdgeInsets.only(
        bottom: 10,
      ),
      child: Column(
        key: keyPersonalities,
        mainAxisAlignment: MainAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          _buildTopSimilaritiesText(),
          SizedBox(height: 10),
          Padding(
            padding: EdgeInsets.only(left: 15),
            child: _buildSimilarPeopleWidget(),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_userId != 'empty') {
      return Scaffold(
        body: ListView(
          children: <Widget>[
            _buildSimilarPeople(),
            Padding(
              padding: EdgeInsets.symmetric(vertical: 10),
              child: _postCreation(),
            ),
            Container(
              color: Colors.white,
              padding: EdgeInsets.symmetric(
                horizontal: MediaQuery.of(context).size.width / 4,
                vertical: 5,
              ),
              child: OutlineButton(
                onPressed: () {
                  Share.text(
                    'Invite your friends to Looper via..',
                    'Hello there. You are invited to Looper. A new social media app that will connect you to amazing people. To download the app you can use the following link https://play.google.com/store/apps/details?id=com.app.looper&hl=en-GB&ah=gndMBVH4KxJfvz1x85LPq04vnaw (for android) , https://apps.apple.com/eg/app/looper-social/id1537223572 (for ios), Hope you enjoy it 👌',
                    'text/plain',
                  );
                },
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(5),
                ),
                borderSide: BorderSide(color: Colors.blue),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.group_add,
                      size: 20,
                      color: Colors.blue,
                    ),
                    SizedBox(width: 5),
                    Text(
                      'invite your friends',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.blue,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: EdgeInsets.symmetric(vertical: 10, horizontal: 30),
              child: Text(
                'Thoughts',
                style: TextStyle(
                  fontSize: 35,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            FutureBuilder(
              future: _future,
              builder: (context, AsyncSnapshot<List<dynamic>> snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(
                    child: CircularProgressIndicator(
                      strokeWidth: 1.2,
                      valueColor: AlwaysStoppedAnimation(Colors.black),
                    ),
                  );
                } else {
                  if (snapshot.data == null) {
                    return SizedBox.shrink();
                  }
                  if (snapshot.data[0].documents.isEmpty &&
                      snapshot.data[1].documents.isEmpty) {
                    return Center(
                      child: Column(
                        children: [
                          Icon(
                            MdiIcons.viewGridPlusOutline,
                            color: Colors.grey,
                            size: 60,
                          ),
                          SizedBox(height: 8),
                          Text(
                            'No Posts uploaded yet',
                            style: GoogleFonts.aBeeZee(
                              textStyle: TextStyle(
                                color: Colors.grey,
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
                                  builder: (context) => PostCreationPage(),
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
                    _ids.add(doc.data()['author']);
                  }
                  if (_followIds != _ids) {
                    return Container(
                      margin: EdgeInsets.only(bottom: 80),
                      child: ListView.separated(
                          shrinkWrap: true,
                          physics: ScrollPhysics(),
                          itemCount: snapshot.data[1].documents.length,
                          separatorBuilder: (context, index) {
                            if (index % 3 == 0 || index % 10 == 0) {
                              return PostNativeAd();
                            } else {
                              return SizedBox.shrink();
                            }
                          },
                          itemBuilder: (context, index) {
                            return PostWidget(
                              snapshot: snapshot.data[1].documents[index],
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
                  return ListView.separated(
                      shrinkWrap: true,
                      physics: ScrollPhysics(),
                      itemCount: lengthOfDocs,
                      separatorBuilder: (context, index) {
                        if (index % 3 == 0 || index % 10 == 0) {
                          return PostNativeAd();
                        } else {
                          return SizedBox.shrink();
                        }
                      },
                      itemBuilder: (context, index) {
                        try {
                          final DocumentSnapshot doc = snapshot
                              .data[querySnapShotCounter].documents
                              .toList()[counter];
                          counter = counter + 1;
                          return PostWidget(
                            snapshot: doc,
                          );
                        } catch (RangeError) {
                          querySnapShotCounter = querySnapShotCounter + 1;
                          counter = 0;
                          final DocumentSnapshot doc = snapshot
                              .data[querySnapShotCounter].documents
                              .toList()[counter];
                          counter = counter + 1;
                          return PostWidget(
                            snapshot: doc,
                          );
                        }
                      });
                }
              },
            ),
          ],
        ),
      );
    } else {
      return Container();
    }
  }
}
