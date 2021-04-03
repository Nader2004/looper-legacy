import 'dart:async';
import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:esys_flutter_share/esys_flutter_share.dart';
import 'package:fab_circular_menu/fab_circular_menu.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_snake_navigationbar/flutter_snake_navigationbar.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:looper/Pages/home-Pages/chat/chat_page.dart';
import 'package:looper/Pages/home-Pages/global/profile.dart';
import 'package:looper/Pages/home-Pages/global/search.dart';
import 'package:looper/creation/challenge-create.dart';
import 'package:looper/creation/love-create.dart';
import 'package:looper/creation/post-create.dart';
import 'package:looper/creation/sport-create.dart';
import 'package:looper/creation/talent-create.dart';
import 'package:looper/models/userModel.dart';
import 'package:looper/services/database.dart';
import 'package:looper/services/personality.dart';
import 'package:looper/widgets/post-native-ad.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shimmer/shimmer.dart';
import 'package:tutorial_coach_mark/tutorial_coach_mark.dart';
import 'package:percent_indicator/percent_indicator.dart';

import '../../../widgets/post.dart';

import '../../../widgets/pnd-showcase.dart';

Future<dynamic> _handleNotification(bool isFirstTime, dynamic callBack) async {
  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();
  const AndroidNotificationDetails androidPlatformChannelSpecifics =
      AndroidNotificationDetails(
    '2021',
    'Looper Channel',
    'This is Looper\'s Notifications Channel',
    importance: Importance.max,
    priority: Priority.high,
  );
  const NotificationDetails platformChannelSpecifics =
      NotificationDetails(android: androidPlatformChannelSpecifics);
  FirebaseMessaging.instance.setForegroundNotificationPresentationOptions(
    alert: true,
    badge: true,
    sound: true,
  );
  if (isFirstTime == true) {
    await flutterLocalNotificationsPlugin
        .show(
          0,
          'Welcome to Looper 😀',
          'You have 5 new people to chat with',
          platformChannelSpecifics,
        )
        .then((_) => callBack);
  } else {
    await flutterLocalNotificationsPlugin
        .periodicallyShow(
          0,
          'You have new people 😉',
          'Check out 5 new people to chat with',
          RepeatInterval.daily,
          platformChannelSpecifics,
        )
        .then((_) => callBack);
  }
}

Future<dynamic> _handleGeneralNotification(String title, String body,
    {bool firstTime = false}) async {
  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();
  const AndroidNotificationDetails androidPlatformChannelSpecifics =
      AndroidNotificationDetails(
    '2021',
    'Looper Channel',
    'This is Looper\'s Notifications Channel',
    importance: Importance.max,
    priority: Priority.high,
  );
  const NotificationDetails platformChannelSpecifics =
      NotificationDetails(android: androidPlatformChannelSpecifics);
  FirebaseMessaging.instance.setForegroundNotificationPresentationOptions(
    alert: true,
    badge: true,
    sound: true,
  );
  if (firstTime == false) {
    await flutterLocalNotificationsPlugin.periodicallyShow(
      0,
      title,
      body,
      RepeatInterval.daily,
      platformChannelSpecifics,
    );
  } else {
    await flutterLocalNotificationsPlugin.show(
      0,
      title,
      body,
      platformChannelSpecifics,
    );
  }
}

class GlobePage extends StatefulWidget {
  final bool firstTime;
  const GlobePage({Key key, this.firstTime = false}) : super(key: key);

  @override
  _GlobePageState createState() => _GlobePageState();
}

class _GlobePageState extends State<GlobePage>
    with AutomaticKeepAliveClientMixin<GlobePage> {
  String _userId = 'empty';
  String _userImage = '';
  String _userGender = '';
  String _userStatus = '';
  String _userTalent = '';
  String _text = '';
  String _groupId = '';
  int _yearOfBirth = 0;
  int _bottomIndex = 0;
  FirebaseFirestore _firestore;
  Map<String, dynamic> _personalityType;
  QuerySnapshot _querySnapshot;
  List<String> _followIds = [];
  List<String> _ids = [];
  List<TargetFocus> _targets = [];
  GlobalKey keyPersonalities = GlobalKey();
  GlobalKey progressKey = GlobalKey();
  GlobalKey chatsKey = GlobalKey();
  GlobalKey fabKey = GlobalKey();

  List<DocumentSnapshot> _userLoveCards;
  List<DocumentSnapshot> _userLoverCards;
  List<DocumentSnapshot> _userTalents;

  Stream<QuerySnapshot> _compatableUsers;
  Future<QuerySnapshot> _discoveredUsers;
  Future<QuerySnapshot> _numberOfAccounts;
  Future<List<dynamic>> _future;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _firestore = FirebaseFirestore.instance;
    setPrefs();
    PersonalityService.analyzePersonality();
    getUserPersonalityFile();
    if (widget.firstTime != false) {
      _targets.add(
        TargetFocus(
          identify: 'Target 0',
          keyTarget: keyPersonalities,
          color: Colors.blue,
          contents: [
            TargetContent(
              align: ContentAlign.bottom,
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
            TargetContent(
              align: ContentAlign.bottom,
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
          keyTarget: chatsKey,
          color: Colors.blue,
          contents: [
            TargetContent(
              align: ContentAlign.bottom,
              child: Container(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      'Chat with some suggested people',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        fontSize: 20.0,
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(top: 10.0),
                      child: Text(
                        'Before your personality gets recognized, you will see a List of People you can chat with to speed up your Personality recognition process',
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
          identify: 'Target 3',
          keyTarget: fabKey,
          color: Colors.blue,
          contents: [
            TargetContent(
              align: ContentAlign.bottom,
              child: Container(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      'This is the creation mode',
                      style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          fontSize: 20.0),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(top: 10.0),
                      child: Text(
                        'Here you can create different types of content like : your thoughts, talent short videos, love cards and wishes, sport short videos.',
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

  Future<void> getUserPersonalityFile() async {
    final File file = await _localPersonalityFile;
    final String _personalityText = await file.readAsString();
    setState(() {
      _text = _personalityText;
    });
  }

  void _afterLayout(_) {
    Future.delayed(Duration(seconds: 2), () {
      showTutorial();
    });
  }

  void showTutorial() {
    TutorialCoachMark(
      context,
      targets: _targets, // List<TargetFocus>
      colorShadow: Colors.red, // DEFAULT Colors.black
      alignSkip: Alignment.bottomRight,
      textSkip: "SKIP",
      paddingFocus: 10,
      focusAnimationDuration: Duration(milliseconds: 500),
      pulseAnimationDuration: Duration(milliseconds: 500),
      onFinish: () {
        showPostMethod();
      },
      onSkip: () {
        showPostMethod();
      },
    )..show();
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
        _handleGeneralNotification(
          'Start by sharing a thought',
          'Hey, how about creating a thought 💭',
        );
      }
    });
  }

  void _setUserNotifications() {
    Future.delayed(
      Duration(seconds: 35),
      () {
        if (_userStatus == 'single') {
          if (_userLoveCards.isEmpty && _userLoverCards.isEmpty) {
            if (widget.firstTime == true) {
              _handleGeneralNotification(
                'Are you single, then here you go 😍',
                'Looking for a good relationship, create your love card now',
                firstTime: true,
              );
            } else {
              _handleGeneralNotification(
                'Create a good Relationship 🥰',
                'Check out the Love room and create your love card and your wish 💘',
              );
            }
          }
        }
        if (_userTalent.isNotEmpty) {
          if (_userTalents.isEmpty) {
            if (widget.firstTime == true) {
              _handleGeneralNotification(
                'Do you love $_userTalent 🤩',
                'If you do, then go show the world by creating a short talent video',
                firstTime: true,
              );
            } else {
              _handleGeneralNotification(
                'Don\'t be embarrassed 💪 !',
                'Show your talent to the world by creating a short video.',
              );
            }
          }
        }
      },
    );
  }

  void setPrefs() async {
    final SharedPreferences _prefs = await SharedPreferences.getInstance();
    final QuerySnapshot _loveCards = await _firestore
        .collection('love-cards')
        .where('authorId', isEqualTo: _userId)
        .get();
    final QuerySnapshot _loverCards = await _firestore
        .collection('lover-cards')
        .where('authorId', isEqualTo: _userId)
        .get();
    final QuerySnapshot _talents = await _firestore
        .collection('lover-cards')
        .where('authorId', isEqualTo: _userId)
        .get();
    final DocumentSnapshot _user =
        await _firestore.collection('users').doc(_prefs.get('id')).get();
    _yearOfBirth = _user.data()['birthdate']['year'];
    _userGender = _user.data()['gender'];
    _userStatus = _user.data()['status'];
    _userTalent = _user.data()['talent'] == null ? '' : _user.data()['talent'];
    _querySnapshot = await _firestore
        .collection('users')
        .doc(_userId)
        .collection('following')
        .get();
    _userLoveCards = _loveCards.docs;
    _userLoverCards = _loverCards.docs;
    _userTalents = _talents.docs;
    if (!_prefs.containsKey('lastDocId')) {
      _prefs.setString('lastDocId', '');
    }
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
      _handleNotification(
        widget.firstTime,
        doChatSuggestions(),
      );
      _setUserNotifications();
    });
  }

  doChatSuggestions() async {
    if (_personalityType.isEmpty) {
      final SharedPreferences _prefs = await SharedPreferences.getInstance();
      setState(() {
        if (_userStatus == 'single') {
          if (_prefs.getString('lastDocId').isEmpty) {
            _discoveredUsers = FirebaseFirestore.instance
                .collection('users')
                .where('birthdate.year', whereIn: [
                  _yearOfBirth + 5,
                  _yearOfBirth + 4,
                  _yearOfBirth + 3,
                  _yearOfBirth + 2,
                  _yearOfBirth + 1,
                  _yearOfBirth - 1,
                  _yearOfBirth - 2,
                  _yearOfBirth - 3,
                  _yearOfBirth - 4,
                  _yearOfBirth - 5,
                ])
                .where('status', isEqualTo: 'single')
                .where(
                  'gender',
                  isEqualTo: _userGender == 'Female' ? 'Male' : 'Female',
                )
                .limit(5)
                .get();
            _discoveredUsers.then(
              (value) {
                _prefs.setString('lastDocId', value.docs.last.id);
                print(_prefs.getString('lastDocId'));
              },
            );
          } else {
            FirebaseFirestore.instance
                .collection('users')
                .where('id', isEqualTo: _prefs.getString('lastDocId'))
                .get()
                .then((value) {
              _discoveredUsers = FirebaseFirestore.instance
                  .collection('users')
                  .startAfterDocument(value.docs.first)
                  .where('birthdate.year', whereIn: [
                    _yearOfBirth + 5,
                    _yearOfBirth + 4,
                    _yearOfBirth + 3,
                    _yearOfBirth + 2,
                    _yearOfBirth + 1,
                    _yearOfBirth - 1,
                    _yearOfBirth - 2,
                    _yearOfBirth - 3,
                    _yearOfBirth - 4,
                    _yearOfBirth - 5,
                  ])
                  .where('status', isEqualTo: 'single')
                  .where(
                    'gender',
                    isEqualTo: _userGender == 'Female' ? 'Male' : 'Female',
                  )
                  .limit(5)
                  .get();
              _discoveredUsers.then(
                (value) => _prefs.setString('lastDocId', value.docs.last.id),
              );
            });
          }
        } else {
          if (_prefs.getString('lastDocId').isEmpty) {
            _discoveredUsers = FirebaseFirestore.instance
                .collection('users')
                .where('birthdate.year', whereIn: [
                  _yearOfBirth + 5,
                  _yearOfBirth + 4,
                  _yearOfBirth + 3,
                  _yearOfBirth + 2,
                  _yearOfBirth + 1,
                  _yearOfBirth - 1,
                  _yearOfBirth - 2,
                  _yearOfBirth - 3,
                  _yearOfBirth - 4,
                  _yearOfBirth - 5,
                ])
                .limit(5)
                .get();
            _discoveredUsers.then(
              (value) => _prefs.setString('lastDocId', value.docs.last.id),
            );
          } else {
            FirebaseFirestore.instance
                .collection('users')
                .where('id', isEqualTo: _prefs.getString('lastDocId'))
                .get()
                .then((value) {
              _discoveredUsers = FirebaseFirestore.instance
                  .collection('users')
                  .startAfterDocument(value.docs.first)
                  .where('birthdate.year', whereIn: [
                    _yearOfBirth + 5,
                    _yearOfBirth + 4,
                    _yearOfBirth + 3,
                    _yearOfBirth + 2,
                    _yearOfBirth + 1,
                    _yearOfBirth - 1,
                    _yearOfBirth - 2,
                    _yearOfBirth - 3,
                    _yearOfBirth - 4,
                    _yearOfBirth - 5,
                  ])
                  .limit(5)
                  .get();
              _discoveredUsers.then(
                (value) => _prefs.setString('lastDocId', value.docs.last.id),
              );
            });
          }
        }
      });
    }
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
    final int _textWordCount = _text.split(' ').length;
    final double _percentage = (_textWordCount / 100) * 100;
    final double _percentageLeft = 100 - _percentage;
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
              ? Text(
                  '${_percentageLeft.toStringAsFixed(1)}% left',
                  key: progressKey,
                  style: GoogleFonts.abel(
                    fontSize: 24,
                  ),
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
            final int _textWordCount = _text.split(' ').length;
            final double _percentage = ((_textWordCount / 1000)) * 10;
            final double _textPercentage = (_textWordCount / 100) * 100;
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
                  key: keyPersonalities,
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
                    CircularPercentIndicator(
                      radius: 60.0,
                      lineWidth: 5.0,
                      center: Text(_textPercentage.toStringAsFixed(2) + '%'),
                      percent: _percentage,
                      progressColor: Colors.black,
                    ),
                  ],
                ),
                SizedBox(height: 5),
                Divider(),
                FutureBuilder(
                  future: _discoveredUsers,
                  builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
                    if (!snapshot.hasData) {
                      return SizedBox.shrink();
                    } else {
                      List<User> _suggestedUsers = snapshot.data.docs
                          .map((doc) => User.fromDoc(doc))
                          .toList();

                      return Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            margin: EdgeInsets.only(right: 10),
                            child: Card(
                              elevation: 10,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Column(
                                children: [
                                  Padding(
                                    padding: EdgeInsets.symmetric(vertical: 15),
                                    child: Text(
                                      'Start a chat with 👋',
                                      key: chatsKey,
                                      style: GoogleFonts.comfortaa(
                                        fontSize: 22,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                  Container(
                                    height: MediaQuery.of(context).size.height /
                                        4.2,
                                    padding: EdgeInsets.all(10),
                                    child: ListView.builder(
                                      scrollDirection: Axis.horizontal,
                                      itemBuilder: (context, int index) {
                                        final User _user =
                                            _suggestedUsers[index];
                                        return GestureDetector(
                                          onTap: () {
                                            Navigator.of(context).push(
                                              MaterialPageRoute(
                                                builder: (context) =>
                                                    ProfilePage(
                                                  userId: _user.id,
                                                ),
                                              ),
                                            );
                                          },
                                          child: Container(
                                            margin: EdgeInsets.symmetric(
                                              horizontal: 10,
                                            ),
                                            child: Column(
                                              children: <Widget>[
                                                ClipRRect(
                                                  borderRadius:
                                                      BorderRadius.circular(
                                                          100),
                                                  child: CachedNetworkImage(
                                                    imageUrl:
                                                        _user.profileImageUrl,
                                                    fit: BoxFit.cover,
                                                    height:
                                                        MediaQuery.of(context)
                                                                .size
                                                                .height /
                                                            9,
                                                    width:
                                                        MediaQuery.of(context)
                                                                .size
                                                                .height /
                                                            9,
                                                  ),
                                                ),
                                                SizedBox(height: 10),
                                                TextButton(
                                                  style: TextButton.styleFrom(
                                                    padding:
                                                        EdgeInsets.symmetric(
                                                            horizontal: 20),
                                                    backgroundColor:
                                                        Colors.black,
                                                    shape:
                                                        RoundedRectangleBorder(
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                        20,
                                                      ),
                                                    ),
                                                  ),
                                                  onPressed: () {
                                                    FirebaseFirestore.instance
                                                        .collection('users')
                                                        .doc(_userId)
                                                        .collection(
                                                            'global-chatters')
                                                        .doc(_user.id)
                                                        .set(
                                                      {
                                                        'timestamp': '',
                                                      },
                                                      SetOptions(
                                                        merge: true,
                                                      ),
                                                    );
                                                    _setGroupChatId(_user.id);
                                                    FirebaseFirestore.instance
                                                        .collection(
                                                            'global-chat')
                                                        .doc(_groupId)
                                                        .set({});
                                                    Navigator.of(context).push(
                                                      MaterialPageRoute(
                                                        builder: (context) =>
                                                            ChatPage(
                                                          followerId: _user.id,
                                                          followerName:
                                                              _user.username,
                                                          id: _userId,
                                                          groupId: _groupId,
                                                          isGlobal: true,
                                                        ),
                                                      ),
                                                    );
                                                  },
                                                  child: Row(
                                                    children: [
                                                      Text(
                                                        'send',
                                                        style: TextStyle(
                                                          color: Colors.white,
                                                          fontSize: 15,
                                                        ),
                                                      ),
                                                      SizedBox(width: 10),
                                                      Icon(
                                                        Icons.send,
                                                        size: 15,
                                                        color: Colors.white,
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        );
                                      },
                                      itemCount: _suggestedUsers.length,
                                    ),
                                  ),
                                ],
                              ),
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

  Widget _buildBottomNavigationBar() {
    return SnakeNavigationBar.color(
      snakeShape: SnakeShape.indicator,
      currentIndex: _bottomIndex,
      unselectedItemColor: Colors.grey,
      selectedItemColor: Colors.black,
      snakeViewColor: Colors.black,
      elevation: 10,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(15),
        ),
      ),
      onTap: (int index) {
        setState(() {
          _bottomIndex = index;
        });
      },
      items: [
        BottomNavigationBarItem(
          icon: Icon(MdiIcons.post),
        ),
        BottomNavigationBarItem(
          icon: FaIcon(
            FontAwesomeIcons.search,
          ),
        ),
      ],
    );
  }

  Widget _buildfabCustomMenu() {
    return FabCircularMenu(
      ringWidth: 115,
      ringColor: Colors.black,
      fabColor: Colors.white,
      fabOpenIcon: Icon(
        MdiIcons.infinity,
        key: fabKey,
        color: Colors.black,
        size: 28,
      ),
      fabCloseIcon: Icon(
        Icons.close,
        color: Colors.black,
        size: 28,
      ),
      children: <Widget>[
        GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => PostCreationPage(),
              ),
            );
          },
          child: Icon(
            MdiIcons.cards,
            size: 30,
            color: Colors.white,
          ),
        ),
        GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => LoveCreation(),
              ),
            );
          },
          child: Icon(
            MdiIcons.heart,
            size: 30,
            color: Colors.white,
          ),
        ),
        GestureDetector(
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => TalentCreation(),
              ),
            );
          },
          child: Icon(
            MdiIcons.star,
            size: 30,
            color: Colors.white,
          ),
        ),
        GestureDetector(
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => ChallengeCreation(),
              ),
            );
          },
          child: Icon(
            MdiIcons.flagCheckered,
            size: 30,
            color: Colors.white,
          ),
        ),
        GestureDetector(
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => SportCreation(),
              ),
            );
          },
          child: Icon(
            MdiIcons.baseball,
            size: 30,
            color: Colors.white,
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_userId != 'empty') {
      return Scaffold(
        floatingActionButton:
            _bottomIndex == 1 ? SizedBox.shrink() : _buildfabCustomMenu(),
        bottomNavigationBar: _buildBottomNavigationBar(),
        body: _bottomIndex == 1
            ? SearchPage()
            : RefreshIndicator(
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
                      padding:
                          EdgeInsets.symmetric(vertical: 10, horizontal: 30),
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
                      builder:
                          (context, AsyncSnapshot<List<dynamic>> snapshot) {
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
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
                                          builder: (context) =>
                                              PostCreationPage(),
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
                                  querySnapShotCounter =
                                      querySnapShotCounter + 1;
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
