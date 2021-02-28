import 'dart:async';
import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:esys_flutter_share/esys_flutter_share.dart';
import 'package:flutter/material.dart';
import 'package:flutter_toggle_tab/flutter_toggle_tab.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:looper/Pages/home-Pages/chat/chat_page.dart';
import 'package:looper/Pages/home-Pages/global/profile.dart';
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
import 'package:percent_indicator/percent_indicator.dart';

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
  String _userImage = '';
  String _groupId = '';
  int _yearOfBirth = 0;
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
  Future<QuerySnapshot> _discoveredUsers;
  Future<QuerySnapshot> _numberOfAccounts;
  Future<List<dynamic>> _future;
  int _selectedIndex = 0;

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
                    ),
                    Padding(
                      padding: const EdgeInsets.only(top: 20.0),
                      child: Text(
                        '(Click the white Area)',
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
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
                    ),
                    Padding(
                      padding: const EdgeInsets.only(top: 20.0),
                      child: Text(
                        '(Click the white Area)',
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
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
                        fontSize: 20.0,
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(top: 10.0),
                      child: Text(
                        'Do you think about something and wanna share it with the world, just click here',
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(top: 20.0),
                      child: Text(
                        '(Click the white Area)',
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
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
    }, onClickSkip: () {
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
    _yearOfBirth = _user.data()['birthdate']['year'];
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
      _userImage = _user.data()['profilePictureUrl'];
      _personalityType = _user?.data()['personality-type'];
      _compatableUsers = PersonalityService.setUserPersonalityStream(
        _personalityType,
        _firestore,
      );
      _discoveredUsers =
          FirebaseFirestore.instance.collection('users').limit(50).get();
      _numberOfAccounts = FirebaseFirestore.instance.collection('users').get();
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
            style: GoogleFonts.comfortaa(
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

  void _setGroupChatId(String userId) {
    if (_userId.hashCode < userId.hashCode) {
      _groupId = '$userId-$_userId';
    } else {
      _groupId = '$_userId-$userId';
    }
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
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  MdiIcons.transitConnectionVariant,
                  color: Colors.grey,
                  size: 30,
                ),
                SizedBox(height: 5),
                Column(
                  children: [
                    Text(
                      'Analyzing  your Personality',
                      style: TextStyle(
                        color: Colors.grey,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 12),
                    FutureBuilder(
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
                        final double _percentage = (_textWordCount / 1500);
                        final double _textPercentage =
                            (_textWordCount / 1500) * 100;
                        return CircularPercentIndicator(
                          radius: 60.0,
                          lineWidth: 5.0,
                          center:
                              Text(_textPercentage.toStringAsFixed(2) + '%'),
                          percent: _percentage,
                          progressColor: Colors.black,
                        );
                      },
                    ),
                  ],
                ),
                SizedBox(height: 5),
                Divider(),
                Column(
                  children: [
                    Padding(
                      padding: EdgeInsets.symmetric(
                        vertical: 15,
                      ),
                      child: FlutterToggleTab(
                        width: 50,
                        height: 40,
                        borderRadius: 40,
                        selectedIndex: _selectedIndex,
                        labels: ['', '', ''],
                        icons: [MdiIcons.earth, MdiIcons.faceWoman, Icons.face],
                        selectedBackgroundColors: [
                          Colors.black,
                          Colors.black,
                        ],
                        initialIndex: 0,
                        selectedLabelIndex: (int index) {
                          setState(() {
                            _selectedIndex = index;
                            if (index == 0) {
                              _discoveredUsers = FirebaseFirestore.instance
                                  .collection('users')
                                  .limit(50)
                                  .get();
                            } else if (index == 1) {
                              _discoveredUsers = FirebaseFirestore.instance
                                  .collection('users')
                                  .where('gender', isEqualTo: 'Female')
                                  .limit(50)
                                  .get();
                            } else {
                              _discoveredUsers = FirebaseFirestore.instance
                                  .collection('users')
                                  .where('gender', isEqualTo: 'Male')
                                  .limit(50)
                                  .get();
                            }
                          });
                        },
                        selectedTextStyle: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.w600),
                        unSelectedTextStyle: TextStyle(
                            color: Colors.grey,
                            fontSize: 14,
                            fontWeight: FontWeight.w400),
                      ),
                    ),
                    SizedBox(height: 5),
                    FutureBuilder(
                      future: _discoveredUsers,
                      builder:
                          (context, AsyncSnapshot<QuerySnapshot> snapshot) {
                        if (!snapshot.hasData) {
                          return SizedBox.shrink();
                        } else {
                          List<User> _suggestedUsers = [];
                          snapshot.data.docs.forEach((querySnapshot) {
                            final User _user = User.fromDoc(querySnapshot);
                            if (_user.birthdate['year'] == _yearOfBirth) {
                              _suggestedUsers.add(_user);
                            }
                            if (_user.birthdate['year'] == _yearOfBirth - 1) {
                              _suggestedUsers.add(_user);
                            }
                            if (_user.birthdate['year'] == _yearOfBirth - 2) {
                              _suggestedUsers.add(_user);
                            }
                            if (_user.birthdate['year'] == _yearOfBirth - 3) {
                              _suggestedUsers.add(_user);
                            }
                            if (_user.birthdate['year'] == _yearOfBirth - 4) {
                              _suggestedUsers.add(_user);
                            }
                            if (_user.birthdate['year'] == _yearOfBirth - 5) {
                              _suggestedUsers.add(_user);
                            }
                            if (_user.birthdate['year'] == _yearOfBirth + 1) {
                              _suggestedUsers.add(_user);
                            }
                            if (_user.birthdate['year'] == _yearOfBirth + 2) {
                              _suggestedUsers.add(_user);
                            }
                            if (_user.birthdate['year'] == _yearOfBirth + 3) {
                              _suggestedUsers.add(_user);
                            }
                            if (_user.birthdate['year'] == _yearOfBirth + 4) {
                              _suggestedUsers.add(_user);
                            }
                            if (_user.birthdate['year'] == _yearOfBirth + 5) {
                              _suggestedUsers.add(_user);
                            }
                          });
                          return Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                height: MediaQuery.of(context).size.height / 3,
                                child: ListView.builder(
                                  scrollDirection: Axis.horizontal,
                                  itemBuilder: (context, int index) {
                                    final User _user = _suggestedUsers[index];
                                    return GestureDetector(
                                      onTap: () {
                                        Navigator.of(context).push(
                                          MaterialPageRoute(
                                            builder: (context) => ProfilePage(
                                              userId: _user.id,
                                            ),
                                          ),
                                        );
                                      },
                                      child: Stack(
                                        children: <Widget>[
                                          Container(
                                            width: MediaQuery.of(context)
                                                    .size
                                                    .width /
                                                3,
                                            height: MediaQuery.of(context)
                                                    .size
                                                    .height /
                                                3,
                                            margin: EdgeInsets.symmetric(
                                                horizontal: 5),
                                            child: ClipRRect(
                                              borderRadius:
                                                  BorderRadius.circular(16),
                                              child: CachedNetworkImage(
                                                imageUrl: _user.profileImageUrl,
                                                fit: BoxFit.cover,
                                              ),
                                            ),
                                          ),
                                          Positioned.fill(
                                            child: Container(
                                              width: MediaQuery.of(context)
                                                      .size
                                                      .width /
                                                  3,
                                              height: MediaQuery.of(context)
                                                      .size
                                                      .height /
                                                  3,
                                              margin: EdgeInsets.symmetric(
                                                  horizontal: 5),
                                              decoration: BoxDecoration(
                                                color: Colors.black54
                                                    .withOpacity(0.5),
                                                borderRadius:
                                                    BorderRadius.circular(16),
                                              ),
                                            ),
                                          ),
                                          Positioned.fill(
                                            child: Align(
                                              alignment: Alignment(1.6, 2.0),
                                              child: Column(
                                                children: [
                                                  _user.status == '' ||
                                                          _user.status == null
                                                      ? SizedBox.shrink()
                                                      : FlatButton(
                                                          shape: CircleBorder(),
                                                          onPressed: () {},
                                                          color: Colors.white,
                                                          child: Icon(
                                                            _user.status ==
                                                                    'single'
                                                                ? MdiIcons.heart
                                                                : MdiIcons
                                                                    .heartMultiple,
                                                            size: 18,
                                                            color:
                                                                Colors.red[700],
                                                          ),
                                                        ),
                                                  FlatButton(
                                                    shape: CircleBorder(),
                                                    onPressed: () {
                                                      FirebaseFirestore.instance
                                                          .collection('users')
                                                          .doc(_userId)
                                                          .collection(
                                                              'global-chatters')
                                                          .doc(_user.id)
                                                          .set({});
                                                      _setGroupChatId(_user.id);
                                                      FirebaseFirestore.instance
                                                          .collection(
                                                              'global-chat')
                                                          .doc(_groupId)
                                                          .set({});
                                                      Navigator.of(context)
                                                          .push(
                                                        MaterialPageRoute(
                                                          builder: (context) =>
                                                              ChatPage(
                                                            followerId:
                                                                _user.id,
                                                            followerName:
                                                                _user.username,
                                                            id: _userId,
                                                            groupId: _groupId,
                                                            isGlobal: true,
                                                          ),
                                                        ),
                                                      );
                                                    },
                                                    color: Colors.white,
                                                    child: Transform.rotate(
                                                      angle: -0.5,
                                                      child: Icon(
                                                        Icons.send,
                                                        size: 18,
                                                        color: Colors.blue,
                                                      ),
                                                    ),
                                                  ),
                                                ],
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
                                      ),
                                    );
                                  },
                                  itemCount: _suggestedUsers.length,
                                ),
                              ),
                              SizedBox(height: 25),
                              FutureBuilder(
                                  future: _numberOfAccounts,
                                  builder: (context, usersSnapshot) {
                                    if (!usersSnapshot.hasData) {
                                      return SizedBox.shrink();
                                    }
                                    return Text(
                                      '${usersSnapshot.data.size} People joined',
                                      style: GoogleFonts.quicksand(
                                        fontSize: 22,
                                        fontWeight: FontWeight.w600,
                                        textStyle: TextStyle(
                                          color: Colors.grey[700],
                                        ),
                                      ),
                                    );
                                  }),
                            ],
                          );
                        }
                      },
                    ),
                  ],
                ),
              ],
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
      child: Row(
        children: [
          Container(
            height: 40,
            width: 40,
            decoration: BoxDecoration(shape: BoxShape.circle),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(50),
              child: GestureDetector(
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => ProfilePage(
                        userId: _userId,
                      ),
                    ),
                  );
                },
                child: CachedNetworkImage(
                  imageUrl: _userImage,
                  placeholder: (context, url) => Container(
                    color: Colors.grey[400],
                  ),
                  fit: BoxFit.cover,
                ),
              ),
            ),
          ),
          SizedBox(width: 10),
          GestureDetector(
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
        ],
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
        body: RefreshIndicator(
          backgroundColor: Colors.black,
          color: Colors.white,
          onRefresh: () async {
            setState(() {
              Future.delayed(Duration(seconds: 3));
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
          },
          child: ListView(
            children: <Widget>[
              _buildSimilarPeople(),
              Padding(
                padding: EdgeInsets.symmetric(vertical: 10),
                child: _postCreation(),
              ),
              Container(
                color: Colors.white,
                padding: EdgeInsets.symmetric(
                  horizontal: MediaQuery.of(context).size.width / 5,
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
                  style: GoogleFonts.comfortaa(
                    fontWeight: FontWeight.bold,
                    fontSize: 35,
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
                    if (snapshot.data[0].docs.isEmpty &&
                        snapshot.data[1].docs.isEmpty) {
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
                    for (DocumentSnapshot doc in snapshot.data[0].docs) {
                      _ids.add(doc.data()['author']);
                    }
                    if (_followIds != _ids) {
                      return Container(
                        margin: EdgeInsets.only(bottom: 80),
                        child: ListView.separated(
                            shrinkWrap: true,
                            physics: ScrollPhysics(),
                            itemCount: snapshot.data[1].docs.length,
                            separatorBuilder: (context, index) {
                              if (index % 3 == 0 || index % 10 == 0) {
                                return PostNativeAd();
                              } else {
                                return SizedBox.shrink();
                              }
                            },
                            itemBuilder: (context, index) {
                              return PostWidget(
                                snapshot: snapshot.data[1].docs[index],
                              );
                            }),
                      );
                    }
                    int lengthOfDocs = 0;
                    int querySnapShotCounter = 0;
                    snapshot.data.forEach((snap) {
                      lengthOfDocs = lengthOfDocs + snap.docs.length;
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
                                .data[querySnapShotCounter].docs
                                .toList()[counter];
                            counter = counter + 1;
                            return PostWidget(
                              snapshot: doc,
                            );
                          } catch (RangeError) {
                            querySnapShotCounter = querySnapShotCounter + 1;
                            counter = 0;
                            final DocumentSnapshot doc = snapshot
                                .data[querySnapShotCounter].docs
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
        ),
      );
    } else {
      return Container();
    }
  }
}
