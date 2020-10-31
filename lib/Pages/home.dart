import 'dart:io';
import 'dart:ui';

import 'package:badges/badges.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import 'package:flutter_snake_navigationbar/flutter_snake_navigationbar.dart';

import 'package:fab_circular_menu/fab_circular_menu.dart';

import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:looper/Pages/home-Pages/global/notifications.dart';
import 'package:looper/Pages/profile-pages/bookmarks.dart';
import 'package:looper/Pages/profile-pages/liked.dart';
import 'package:looper/Pages/profile-pages/shared.dart';
import 'package:looper/models/userModel.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:looper/services/notifications.dart';
import '../creation/post-create.dart';
import '../creation/talent-create.dart';
import '../creation/love-create.dart';
import '../creation/sport-create.dart';
import '../creation/comedy-create.dart';
import '../creation/challenge-create.dart';

import '../Pages/home-Pages/global/globe.dart';
import '../Pages/home-Pages/global/global-rooms.dart';
import '../Pages/home-Pages/global/search.dart';
import '../Pages/home-Pages/global/profile.dart';
import '../Pages/profile-pages/account-settings.dart';
import 'home-Pages/chat/chat_list.dart';

class HomePage extends StatefulWidget {
  static const String id = 'home';
  const HomePage({Key key}) : super(key: key);
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with TickerProviderStateMixin {
  int _bottomIndex = 1;
  String _id = 'empty';

  @override
  void initState() {
    setPrefs();
    super.initState();
    _addLocalPersonalityFile();
    NotificationsService.configureFcm(context);
  }

  void setPrefs() async {
    final SharedPreferences _prefs = await SharedPreferences.getInstance();
    setState(() {
      _id = _prefs.get('id');
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

  Widget _buildBottomNavigationBar() {
    return SnakeNavigationBar.color(
      snakeShape: SnakeShape.indicator,
      currentIndex: _bottomIndex,
      selectedItemColor: Colors.white,
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
          icon: FaIcon(
            FontAwesomeIcons.search,
          ),
        ),
        BottomNavigationBarItem(
          icon: FaIcon(
            FontAwesomeIcons.home,
          ),
        ),
        BottomNavigationBarItem(
          icon: FaIcon(
            FontAwesomeIcons.globe,
          ),
        ),
      ],
    );
  }

  Widget _buildGlobalRooms() {
    switch (_bottomIndex) {
      case 0:
        return SearchPage();
        break;
      case 1:
        return GlobePage();
        break;
      case 2:
        return GlobalRoomsPage();
        break;
      default:
        return Container();
    }
  }

  Widget _buildfabCustomMenu() {
    return FabCircularMenu(
      ringWidth: 115,
      ringColor: Colors.black,
      fabColor: Colors.white,
      fabOpenIcon: Icon(
        MdiIcons.infinity,
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
                builder: (context) => ComedyCreation(),
              ),
            );
          },
          child: Icon(
            MdiIcons.dramaMasks,
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

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      brightness: Brightness.light,
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          bottom: Radius.circular(10),
        ),
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
            margin: EdgeInsets.only(left: 1, right: 1, top: 2.5),
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
            builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return _buildCircularButton(
                  child: FaIcon(
                    FontAwesomeIcons.bell,
                    color: Colors.black,
                    size: 21,
                  ),
                  callBack: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => NotificationsPage(),
                      ),
                    );
                  },
                );
              }
              if (snapshot.data.size == 0) {
                return _buildCircularButton(
                  child: FaIcon(
                    FontAwesomeIcons.bell,
                    color: Colors.black,
                    size: 21,
                  ),
                  callBack: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => NotificationsPage(),
                      ),
                    );
                  },
                );
              }
              return Badge(
                badgeContent: Text(
                  snapshot.data.size.toString(),
                  style: TextStyle(color: Colors.white),
                ),
                badgeColor: Colors.red,
                animationType: BadgeAnimationType.slide,
                child: _buildCircularButton(
                  child: FaIcon(
                    FontAwesomeIcons.bell,
                    color: Colors.black,
                    size: 21,
                  ),
                  callBack: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => NotificationsPage(),
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
              applicationVersion: '1.0.0',
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
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        return false;
      },
      child: Scaffold(
        appBar: _bottomIndex == 1 ? _buildAppBar() : null,
        backgroundColor: Colors.grey[50],
        bottomNavigationBar: _buildBottomNavigationBar(),
        drawer: _buildDrawer(),
        floatingActionButton: _buildfabCustomMenu(),
        body: _buildGlobalRooms(),
      ),
    );
  }
}
