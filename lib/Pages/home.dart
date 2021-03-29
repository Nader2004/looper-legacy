import 'dart:async';
import 'dart:io';
import 'dart:ui';

import 'package:badges/badges.dart';
import 'package:connectivity/connectivity.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:looper/Pages/home-Pages/global/notifications.dart';
import 'package:looper/Pages/profile-pages/bookmarks.dart';
import 'package:looper/Pages/profile-pages/liked.dart';
import 'package:looper/Pages/profile-pages/shared.dart';
import 'package:looper/Pages/rooms/challenge.dart';
import 'package:looper/Pages/rooms/love.dart';
import 'package:looper/Pages/rooms/sports.dart';
import 'package:looper/Pages/rooms/talents.dart';
import 'package:looper/models/userModel.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:looper/services/notifications.dart';
import 'package:tutorial_coach_mark/tutorial_coach_mark.dart';

import '../Pages/home-Pages/global/globe.dart';
import '../Pages/home-Pages/global/profile.dart';
import '../Pages/profile-pages/account-settings.dart';
import 'home-Pages/chat/chat_list.dart';

class HomePage extends StatefulWidget {
  static const String id = 'home';
  final bool firstTime;
  final String userId;
  const HomePage({Key key, this.userId, this.firstTime = false})
      : super(key: key);
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with TickerProviderStateMixin {
  String _id = 'empty';
  bool _showGlobe = false;
  FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin;
  TutorialCoachMark tutorialCoachMark;
  List<TargetFocus> _targets = [];
  GlobalKey homeTabKey = GlobalKey();
  GlobalKey talentTabKey = GlobalKey();
  GlobalKey loveTabKey = GlobalKey();
  GlobalKey challengesTabKey = GlobalKey();
  GlobalKey sportsTabKey = GlobalKey();
  GlobalKey chatKey = GlobalKey();
  GlobalKey notificationsKey = GlobalKey();
  GlobalKey menuKey = GlobalKey();
  StreamSubscription _onlineStatusSubscribtion;

  @override
  void initState() {
    super.initState();
    _addLocalPersonalityFile();
    flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('looper');
    final IOSInitializationSettings initializationSettingsIOS =
        IOSInitializationSettings();
    final InitializationSettings initializationSettings =
        InitializationSettings(
            android: initializationSettingsAndroid,
            iOS: initializationSettingsIOS);
    flutterLocalNotificationsPlugin.initialize(
      initializationSettings,
    );
    NotificationsService.configureFcm(context);
    setPrefs();
    if (widget.firstTime == true) {
      _targets.add(
        TargetFocus(
          identify: 'Target 0',
          keyTarget: homeTabKey,
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
                      'This is the home page',
                      style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          fontSize: 20.0),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(top: 10.0),
                      child: Text(
                        'Here you will explore people thoughts from all over the world and discover a list of compatible people',
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
          keyTarget: talentTabKey,
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
                      'This is the Talents page',
                      style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          fontSize: 20.0),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(top: 10.0),
                      child: Text(
                        'Here you will explore short videos about people\'s talents and you can clap, comment, judge with YES or NO and interact with the videos. ',
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
          keyTarget: loveTabKey,
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
                      'This is the Love matching page',
                      style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          fontSize: 20.0),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(top: 10.0),
                      child: Text(
                        'Here you can swipe between people that might interest you and you can create a Relationship with them. You can even see wish cards and if you\'re right for that wish give it a try 😉',
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
          keyTarget: challengesTabKey,
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
                      'This is the Challenges page',
                      style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          fontSize: 20.0),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(top: 10.0),
                      child: Text(
                        'Here you will explore short videos about people making challenges about anything and you can comment, like or dislike and interact with the videos.',
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
          identify: 'Target 4',
          keyTarget: sportsTabKey,
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
                      'This is the Sports page',
                      style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          fontSize: 20.0),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(top: 10.0),
                      child: Text(
                        'Here you will explore short videos about different sport types and people interested in each type',
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
          identify: 'Target 5',
          keyTarget: chatKey,
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
                      'This is the chat page',
                      style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          fontSize: 20.0),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(top: 10.0),
                      child: Text(
                        'Here you can send messages to your following people or anyone else and see the incoming messages too',
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
          identify: 'Target 6',
          keyTarget: notificationsKey,
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
                      'This is the Notifications page',
                      style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          fontSize: 20.0),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(top: 10.0),
                      child: Text(
                        'Here you will see all of the incoming notifications including chat messages',
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
          identify: 'Target 7',
          keyTarget: menuKey,
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
                      'This is the menu',
                      style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          fontSize: 20.0),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(top: 10.0),
                      child: Text(
                        'Here you can access your profile, account settings, your bookmarks and more..',
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
    } else {
      setState(() {
        _showGlobe = true;
      });
    }
  }

  void _afterLayout(_) {
    Future.delayed(Duration(milliseconds: 100));
    showTutorial();
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
        setState(() {
          _showGlobe = true;
        });
      },
      onSkip: () {
        setState(() {
          _showGlobe = true;
        });
      },
    )..show();
  }

  void setPrefs() async {
    final SharedPreferences _prefs = await SharedPreferences.getInstance();
    if (!_prefs.containsKey('id')) {
      _prefs.setString('id', widget.userId);
    }
    setState(() {
      _id = _prefs.get('id');
    });
    _onlineStatusSubscribtion = Connectivity()
        .onConnectivityChanged
        .listen((ConnectivityResult result) async {
      if (result == ConnectivityResult.wifi ||
          result == ConnectivityResult.mobile) {
        await FirebaseFirestore.instance.collection('users').doc(_id).set(
          {
            'isActive': true,
          },
          SetOptions(merge: true),
        );
      } else {
        await FirebaseFirestore.instance.collection('users').doc(_id).update(
          {
            'isActive': false,
          },
        );
      }
    });
  }

  Future<String> get _localPath async {
    final directory = await getApplicationDocumentsDirectory();
    return directory.path;
  }

  Future<void> _addLocalPersonalityFile() async {
    final path = await _localPath;
    if (!File('$path/personality.txt').existsSync()) {
      File('$path/personality.txt').writeAsString('');
    }
  }

  Widget _buildCircularButton({Widget child, Function callBack}) {
    return Container(
      height: 50,
      width: 50,
      child: FlatButton(
        shape: CircleBorder(),
        onPressed: callBack,
        child: child,
      ),
    );
  }

  Widget _buildDrawer() {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          FutureBuilder(
              future:
                  FirebaseFirestore.instance.collection('users').doc(_id).get(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting)
                  return SizedBox.shrink();
                final User _user = User.fromDoc(snapshot.data);
                return DrawerHeader(
                  decoration: BoxDecoration(
                      image: DecorationImage(
                    fit: BoxFit.cover,
                    image: CachedNetworkImageProvider(_user.profileImageUrl),
                  )),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(100),
                        child: CachedNetworkImage(
                          imageUrl: _user.profileImageUrl,
                          height: MediaQuery.of(context).size.width * 0.3,
                          width: MediaQuery.of(context).size.width * 0.3,
                          fit: BoxFit.cover,
                        ),
                      ),
                      SizedBox(height: 6),
                      Text(
                        _user.username,
                        style: TextStyle(
                          fontSize: 24,
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                );
              }),
          ListTile(
            leading: Icon(
              MdiIcons.accountArrowRightOutline,
              color: Colors.grey[700],
            ),
            title: Text(
              'Profile',
              style: TextStyle(
                color: Colors.grey[700],
                fontSize: 22,
                fontWeight: FontWeight.w600,
              ),
            ),
            trailing: Icon(
              Icons.arrow_forward_ios,
              color: Colors.grey[700],
            ),
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => ProfilePage(
                    userId: _id,
                  ),
                ),
              );
            },
          ),
          ListTile(
            leading: Icon(
              MdiIcons.bookmarkCheckOutline,
              color: Colors.grey[700],
            ),
            title: Text(
              'Bookmarks',
              style: TextStyle(
                color: Colors.grey[700],
                fontSize: 22,
                fontWeight: FontWeight.w600,
              ),
            ),
            trailing: Icon(
              Icons.arrow_forward_ios,
              color: Colors.grey[700],
            ),
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => BookmarksListPage(),
              ),
            ),
          ),
          ListTile(
            leading: Icon(
              Icons.favorite_border,
              color: Colors.grey[700],
            ),
            title: Text(
              'Likes',
              style: TextStyle(
                color: Colors.grey[700],
                fontSize: 22,
                fontWeight: FontWeight.w600,
              ),
            ),
            trailing: Icon(
              Icons.arrow_forward_ios,
              color: Colors.grey[700],
            ),
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => LikedListPage(),
              ),
            ),
          ),
          ListTile(
            leading: Icon(
              MdiIcons.shareAllOutline,
              color: Colors.grey[700],
            ),
            title: Text(
              'Shared',
              style: TextStyle(
                color: Colors.grey[700],
                fontSize: 22,
                fontWeight: FontWeight.w600,
              ),
            ),
            trailing: Icon(
              Icons.arrow_forward_ios,
              color: Colors.grey[700],
            ),
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => SharedListPage(),
              ),
            ),
          ),
          ListTile(
            leading: Icon(
              MdiIcons.accountCogOutline,
              color: Colors.grey[700],
            ),
            title: Text(
              'Account Settings',
              style: TextStyle(
                color: Colors.grey[700],
                fontSize: 22,
                fontWeight: FontWeight.w600,
              ),
            ),
            trailing: Icon(
              Icons.arrow_forward_ios,
              color: Colors.grey[700],
            ),
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => AccountSettingsPage(),
                ),
              );
            },
          ),
          ListTile(
            leading: Icon(
              MdiIcons.informationOutline,
              color: Colors.grey[700],
            ),
            title: Text(
              'About Looper',
              style: TextStyle(
                color: Colors.grey[700],
                fontSize: 22,
                fontWeight: FontWeight.w600,
              ),
            ),
            trailing: Icon(
              Icons.arrow_forward_ios,
              color: Colors.grey[700],
            ),
            onTap: () => showAboutDialog(
              context: context,
              applicationName: 'Looper',
              applicationVersion: '1.0.9',
              applicationLegalese:
                  'Looper uses the PND Technology, which is based on the ibm personality insights service to analyze your Personality through your Activity. We do not share any data or spy on our users!',
              applicationIcon: Icon(
                MdiIcons.infinity,
                size: 50,
                color: Colors.black,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  dispose() {
    super.dispose();
    _onlineStatusSubscribtion.cancel();
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        return false;
      },
      child: DefaultTabController(
        length: 5,
        child: Scaffold(
          backgroundColor: Colors.grey[50],
          drawer: _buildDrawer(),
          body: NestedScrollView(
            headerSliverBuilder:
                (BuildContext context, bool innerBoxIsScrolled) {
              return <Widget>[
                SliverOverlapAbsorber(
                  handle:
                      NestedScrollView.sliverOverlapAbsorberHandleFor(context),
                  sliver: SliverSafeArea(
                    top: false,
                    sliver: SliverAppBar(
                      leading: IconButton(
                        key: menuKey,
                        icon: Icon(
                          MdiIcons.accountDetails,
                          size: 25,
                        ),
                        onPressed: () => Scaffold.of(context).openDrawer(),
                      ),
                      backgroundColor: Colors.white,
                      iconTheme: IconThemeData.fallback(),
                      title: Row(
                        children: <Widget>[
                          Text(
                            'L',
                            style: TextStyle(
                              color: Colors.black,
                              fontSize: 33,
                            ),
                          ),
                          Container(
                            margin:
                                EdgeInsets.only(left: 1, right: 1, top: 2.5),
                            child: Icon(
                              MdiIcons.infinity,
                              color: Colors.black,
                              size: 33,
                            ),
                          ),
                          Text(
                            'per',
                            style: TextStyle(
                              color: Colors.black,
                              fontSize: 33,
                            ),
                          ),
                        ],
                      ),
                      actions: <Widget>[
                        StreamBuilder(
                            stream: FirebaseFirestore.instance
                                .collection('users')
                                .doc(_id)
                                .collection('notifications')
                                .snapshots(),
                            builder: (context,
                                AsyncSnapshot<QuerySnapshot> snapshot) {
                              if (snapshot.connectionState ==
                                  ConnectionState.waiting) {
                                return _buildCircularButton(
                                  child: FaIcon(
                                    FontAwesomeIcons.bell,
                                    key: notificationsKey,
                                    color: Colors.black,
                                    size: 21,
                                  ),
                                  callBack: () {
                                    Navigator.of(context).push(
                                      MaterialPageRoute(
                                        builder: (context) =>
                                            NotificationsPage(),
                                      ),
                                    );
                                  },
                                );
                              }
                              if (snapshot.data.size == 0) {
                                return _buildCircularButton(
                                  child: FaIcon(
                                    FontAwesomeIcons.bell,
                                    key: notificationsKey,
                                    color: Colors.black,
                                    size: 21,
                                  ),
                                  callBack: () {
                                    Navigator.of(context).push(
                                      MaterialPageRoute(
                                        builder: (context) =>
                                            NotificationsPage(),
                                      ),
                                    );
                                  },
                                );
                              }
                              return Badge(
                                position: BadgePosition.topEnd(top: 5, end: 1),
                                badgeContent: Text(
                                  snapshot.data.size.toString(),
                                  style: TextStyle(color: Colors.white),
                                ),
                                badgeColor: Colors.red,
                                animationType: BadgeAnimationType.slide,
                                child: _buildCircularButton(
                                  child: FaIcon(
                                    FontAwesomeIcons.bell,
                                    key: notificationsKey,
                                    color: Colors.black,
                                    size: 21,
                                  ),
                                  callBack: () {
                                    Navigator.of(context).push(
                                      MaterialPageRoute(
                                        builder: (context) =>
                                            NotificationsPage(),
                                      ),
                                    );
                                  },
                                ),
                              );
                            }),
                        Container(
                          margin: EdgeInsets.only(right: 5),
                          child: _buildCircularButton(
                            child: Icon(
                              Icons.chat_bubble_outline,
                              key: chatKey,
                              color: Colors.black,
                              size: 21,
                            ),
                            callBack: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (context) => ChatList(),
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                      floating: true,
                      pinned: true,
                      snap: false,
                      primary: true,
                      forceElevated: innerBoxIsScrolled,
                      bottom: TabBar(
                        unselectedLabelColor: Colors.grey,
                        labelColor: Colors.black,
                        indicatorColor: Colors.black,
                        tabs: [
                          Tab(
                            key: homeTabKey,
                            icon: Icon(MdiIcons.homeVariant),
                          ),
                          Tab(
                            key: talentTabKey,
                            icon: Icon(MdiIcons.starShooting),
                          ),
                          Tab(
                            key: loveTabKey,
                            icon: Icon(MdiIcons.heart),
                          ),
                          Tab(
                            key: challengesTabKey,
                            icon: Icon(MdiIcons.flagCheckered),
                          ),
                          Tab(
                            key: sportsTabKey,
                            icon: Icon(MdiIcons.trophy),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ];
            },
            body: TabBarView(
              physics: NeverScrollableScrollPhysics(),
              children: [
                _showGlobe == false
                    ? Container()
                    : GlobePage(firstTime: widget.firstTime),
                TalentRoom(),
                LoveRoom(),
                ChallengeRoom(),
                SportsRoom(),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
