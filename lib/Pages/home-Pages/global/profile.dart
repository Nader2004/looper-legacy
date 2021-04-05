import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_linkify/flutter_linkify.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';
import 'package:superellipse_shape/superellipse_shape.dart';
import 'package:looper/models/userModel.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:video_player/video_player.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:flutter_toggle_tab/flutter_toggle_tab.dart';
import 'package:looper/Pages/home-Pages/chat/chat_page.dart';
import 'package:looper/services/database.dart';
import 'package:looper/services/notifications.dart';
import 'package:looper/widgets/post.dart';

class ProfilePage extends StatefulWidget {
  final String userId;
  const ProfilePage({Key key, this.userId}) : super(key: key);

  @override
  _ProfilePageState createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  String _id = 'empty';
  String _groupId = '';
  String _userName = '';
  String _userBio = '';
  String _userStatus = '';
  int _creationSelectedIndex = 0;
  int _likesSelectedIndex = 0;
  bool _isFollowing = false;
  TextEditingController _bioController;
  Stream<QuerySnapshot> _blockedUsers;
  Future<DocumentSnapshot> _userFuture;
  Future<QuerySnapshot> _following;
  Future<QuerySnapshot> _followers;
  Future<QuerySnapshot> _generalFuture;
  Future<QuerySnapshot> _generalLikesFuture;
  Future<QuerySnapshot> _postCreation;
  Future<QuerySnapshot> _talentCreation;
  Future<QuerySnapshot> _sportCreation;
  Future<QuerySnapshot> _challengeCreation;
  Future<QuerySnapshot> _comedyCreation;
  Future<QuerySnapshot> _postLikes;
  Future<QuerySnapshot> _talentLikes;
  Future<QuerySnapshot> _sportLikes;
  Future<QuerySnapshot> _challengeLikes;
  Future<QuerySnapshot> _comedyLikes;

  @override
  void initState() {
    super.initState();
    setPrefs();
  }

  void setPrefs() async {
    _bioController = TextEditingController();
    final SharedPreferences _prefs = await SharedPreferences.getInstance();
    final DocumentSnapshot _doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(_prefs.get('id'))
        .get();
    final bool isFollowing =
        await DatabaseService.checkIsFollowing(widget.userId);
    setState(() {
      _id = _prefs.get('id');
      _blockedUsers = FirebaseFirestore.instance
          .collection('users')
          .doc(_id)
          .collection('blocked-users')
          .snapshots();
      _isFollowing = isFollowing;
      _userName = _doc.data()['username'];

      _userFuture = FirebaseFirestore.instance
          .collection('users')
          .doc(widget.userId)
          .get();
      _following = FirebaseFirestore.instance
          .collection('users')
          .doc(widget.userId)
          .collection('following')
          .get();
      _followers = FirebaseFirestore.instance
          .collection('users')
          .doc(widget.userId)
          .collection('followers')
          .get();
      _postCreation = FirebaseFirestore.instance
          .collection('posts')
          .where('author', isEqualTo: widget.userId)
          .get();
      _generalFuture = _postCreation;
      _sportCreation = FirebaseFirestore.instance
          .collection('sports')
          .where('creatorId', isEqualTo: widget.userId)
          .get();
      _talentCreation = FirebaseFirestore.instance
          .collection('talents')
          .where('creatorId', isEqualTo: widget.userId)
          .get();
      _comedyCreation = FirebaseFirestore.instance
          .collection('comedy')
          .where('authorId', isEqualTo: widget.userId)
          .get();
      _challengeCreation = FirebaseFirestore.instance
          .collection('challenge')
          .where('creatorId', isEqualTo: widget.userId)
          .get();
      _postLikes = FirebaseFirestore.instance
          .collection('posts')
          .where('liked-people', arrayContains: widget.userId)
          .orderBy('timestamp', descending: true)
          .get();
      _talentLikes = FirebaseFirestore.instance
          .collection('talents')
          .where('yes-counted-people', arrayContains: widget.userId)
          .orderBy('timestamp', descending: true)
          .get();
      _comedyLikes = FirebaseFirestore.instance
          .collection('comedy')
          .where('laughed-people', arrayContains: widget.userId)
          .orderBy('timestamp', descending: true)
          .get();
      _sportLikes = FirebaseFirestore.instance
          .collection('sports')
          .where('liked-people', arrayContains: widget.userId)
          .orderBy('timestamp', descending: true)
          .get();
      _challengeCreation = FirebaseFirestore.instance
          .collection('challenge')
          .where('liked-people', arrayContains: widget.userId)
          .orderBy('timestamp', descending: true)
          .get();
    });
  }

  void _setGroupChatId() {
    if (_id.hashCode < widget.userId.hashCode) {
      _groupId = '${widget.userId}-$_id';
    } else {
      _groupId = '$_id-${widget.userId}';
    }
  }

  void _showBioDialog() {
    showDialog(
      context: context,
      builder: (context) => AnimatedContainer(
        duration: Duration(milliseconds: 300),
        child: AlertDialog(
          content: Row(
            children: <Widget>[
              Expanded(
                child: TextField(
                  controller: _bioController,
                  autofocus: true,
                  decoration: InputDecoration(
                    labelText: 'Your Bio',
                  ),
                  maxLength: 150,
                ),
              ),
            ],
          ),
          actions: <Widget>[
            FlatButton(
                child: Text('CANCEL'),
                onPressed: () {
                  _bioController.clear();
                  Navigator.pop(context);
                }),
            FlatButton(
                child: Text('DONE'),
                onPressed: () {
                  if (_bioController.text.length != 0) {
                    Navigator.pop(context);
                    setState(() => _userBio = _bioController.text);
                    print(_userBio);
                    FirebaseFirestore.instance.collection('users').doc(_id).set(
                      {'bio': _bioController.text},
                      SetOptions(merge: true),
                    );
                    Fluttertoast.showToast(
                      msg: 'Revisit your profile to see ur update',
                    );
                  } else {
                    Fluttertoast.showToast(msg: 'Add your bio first');
                  }
                })
          ],
        ),
      ),
    );
  }

  void _showStatusDialog() {
    showDialog(
      context: context,
      builder: (context) => AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        child: AlertDialog(
          content: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: <Widget>[
              Container(
                decoration: BoxDecoration(
                  border: Border.all(
                    color: Colors.grey[300],
                  ),
                  borderRadius: BorderRadius.circular(5),
                ),
                child: ButtonTheme(
                  height: 20,
                  minWidth: MediaQuery.of(context).size.width / 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(5),
                  ),
                  child: FlatButton(
                    color: Colors.grey[50],
                    onPressed: () {
                      setState(() {
                        _userStatus = 'single';
                      });
                      Navigator.pop(context);
                      FirebaseFirestore.instance
                          .collection('users')
                          .doc(_id)
                          .set(
                        {'status': _userStatus},
                        SetOptions(merge: true),
                      );
                      Fluttertoast.showToast(
                        msg: 'Revisit your profile to see ur update',
                      );
                    },
                    child: Row(
                      children: <Widget>[
                        Container(
                          margin: EdgeInsets.only(right: 25),
                          child: Icon(
                            MdiIcons.account,
                            color: Colors.black,
                            size: 50,
                          ),
                        ),
                        Text(
                          'SINGLE',
                          style: TextStyle(
                            fontSize: 18.5,
                            fontWeight: FontWeight.w400,
                            color: Colors.black,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              SizedBox(height: 15),
              Container(
                decoration: BoxDecoration(
                  border: Border.all(
                    color: Colors.grey[300],
                  ),
                  borderRadius: BorderRadius.circular(5),
                ),
                child: ButtonTheme(
                  height: 20,
                  minWidth: MediaQuery.of(context).size.width / 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(5),
                  ),
                  child: FlatButton(
                    color: Colors.white,
                    onPressed: () {
                      setState(() {
                        _userStatus = 'couple';
                      });
                      Navigator.pop(context);
                      FirebaseFirestore.instance
                          .collection('users')
                          .doc(_id)
                          .set(
                        {'status': _userStatus},
                        SetOptions(merge: true),
                      );
                    },
                    child: Row(
                      children: <Widget>[
                        Container(
                          margin: EdgeInsets.only(right: 25),
                          child: Icon(
                            MdiIcons.accountMultiple,
                            color: Colors.black,
                            size: 50,
                          ),
                        ),
                        Text(
                          'COUPLE',
                          style: TextStyle(
                            fontSize: 18.5,
                            fontWeight: FontWeight.w400,
                            color: Colors.black,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
          actions: <Widget>[
            FlatButton(
                child: const Text('CANCEL'),
                onPressed: () {
                  Navigator.pop(context);
                }),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return _id == 'empty'
        ? SizedBox.shrink()
        : Scaffold(
            appBar: AppBar(
              elevation: 0.5,
              backgroundColor: Colors.white,
              iconTheme: IconThemeData.fallback(),
              centerTitle: true,
              title: FutureBuilder(
                  future: _userFuture,
                  builder: (context, AsyncSnapshot<DocumentSnapshot> snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return SizedBox.shrink();
                    }
                    return Text(
                      snapshot.data.data()['username'],
                      style: TextStyle(color: Colors.black),
                    );
                  }),
              actions: [
                _id == widget.userId
                    ? SizedBox.shrink()
                    : StreamBuilder(
                        stream: _blockedUsers,
                        builder:
                            (context, AsyncSnapshot<QuerySnapshot> snapshot) {
                          if (snapshot.connectionState ==
                              ConnectionState.waiting) {
                            return SizedBox.shrink();
                          }
                          final List<String> blockedUsers =
                              snapshot.data.docs.map((e) => e.id).toList();

                          return FlatButton(
                            child: Row(
                              children: [
                                Icon(
                                  Icons.block,
                                  color: blockedUsers.contains(widget.userId)
                                      ? Colors.red
                                      : Colors.blue,
                                  size: 18,
                                ),
                                SizedBox(width: 5),
                                Text(
                                  blockedUsers.contains(widget.userId)
                                      ? 'Unblock'
                                      : 'Block',
                                  style: TextStyle(
                                    color: blockedUsers.contains(widget.userId)
                                        ? Colors.red
                                        : Colors.blue,
                                    fontSize: 16,
                                  ),
                                ),
                              ],
                            ),
                            onPressed: () {
                              if (!blockedUsers.contains(widget.userId)) {
                                DatabaseService.blockUser(
                                  _id,
                                  widget.userId,
                                );
                              } else {
                                DatabaseService.unBlockUser(
                                  _id,
                                  widget.userId,
                                );
                              }
                            },
                          );
                        }),
              ],
            ),
            body: StreamBuilder(
                stream: _blockedUsers,
                builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return Center(
                      child: CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation(
                          Colors.black,
                        ),
                        strokeWidth: 1.2,
                      ),
                    );
                  }
                  final List<String> blockedUsers =
                      snapshot.data.docs.map((e) => e.id).toList();
                  return DefaultTabController(
                    length: 2,
                    child: NestedScrollView(
                      headerSliverBuilder: (context, _) => [
                        SliverList(
                          delegate: SliverChildListDelegate(
                            [
                              FutureBuilder(
                                  future: _userFuture,
                                  builder: (context, snapshot) {
                                    if (snapshot.connectionState ==
                                        ConnectionState.waiting) {
                                      return Center(
                                        child: CircularProgressIndicator(
                                          strokeWidth: 1.2,
                                          valueColor: AlwaysStoppedAnimation(
                                              Colors.black),
                                        ),
                                      );
                                    }

                                    final User _user =
                                        User.fromDoc(snapshot.data);
                                    _userBio = _user.bio;
                                    _userStatus = _user.status;
                                    return Column(
                                      children: <Widget>[
                                        SizedBox(height: 20),
                                        ClipRRect(
                                          borderRadius:
                                              BorderRadius.circular(100),
                                          child: CachedNetworkImage(
                                            imageUrl: _user.profileImageUrl,
                                            height: MediaQuery.of(context)
                                                    .size
                                                    .width /
                                                3,
                                            width: MediaQuery.of(context)
                                                    .size
                                                    .width /
                                                3,
                                            fit: BoxFit.cover,
                                          ),
                                        ),
                                        SizedBox(height: 10),
                                        Text(
                                          _user.username,
                                          style: TextStyle(
                                            color: Colors.black,
                                            fontWeight: FontWeight.w600,
                                            fontSize: 24,
                                          ),
                                        ),
                                        SizedBox(height: 10),
                                        Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            Icon(
                                              MdiIcons.cakeVariant,
                                              color: Colors.grey,
                                            ),
                                            SizedBox(width: 5),
                                            Text(
                                              '${_user.birthdate['day']}/${_user.birthdate['month']}/${_user.birthdate['year']}',
                                              style: TextStyle(
                                                color: Colors.grey,
                                                fontSize: 16,
                                              ),
                                            ),
                                          ],
                                        ),
                                        SizedBox(
                                          height:
                                              _userBio != '' || _userBio != null
                                                  ? 10
                                                  : 16,
                                        ),
                                        _userBio != '' && _userBio != null
                                            ? SelectableLinkify(
                                                onOpen: (link) async {
                                                  if (await canLaunch(
                                                      link.url)) {
                                                    await launch(link.url);
                                                  } else {
                                                    Fluttertoast.showToast(
                                                      msg:
                                                          'can not launch this link',
                                                    );
                                                  }
                                                },
                                                text: _userBio,
                                                textAlign: TextAlign.center,
                                              )
                                            : SizedBox.shrink(),
                                        _userBio != '' || _userBio != null
                                            ? SizedBox(height: 10)
                                            : SizedBox.shrink(),
                                        Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            GestureDetector(
                                              onTap: () {
                                                Navigator.of(context).push(
                                                  MaterialPageRoute(
                                                    builder: (context) =>
                                                        FollowingList(
                                                      userId: _user.id,
                                                    ),
                                                  ),
                                                );
                                              },
                                              child: Column(
                                                children: [
                                                  FutureBuilder(
                                                      future: _following,
                                                      builder:
                                                          (context, snapshot) {
                                                        if (snapshot
                                                                .connectionState ==
                                                            ConnectionState
                                                                .waiting) {
                                                          return SizedBox
                                                              .shrink();
                                                        }
                                                        return Text(
                                                          snapshot.data.size
                                                              .toString(),
                                                          style: TextStyle(
                                                            color: Colors.grey,
                                                            fontSize: 18,
                                                            fontWeight:
                                                                FontWeight.w600,
                                                          ),
                                                        );
                                                      }),
                                                  SizedBox(height: 5),
                                                  Text(
                                                    'Following',
                                                    style: TextStyle(
                                                      color: Colors.grey,
                                                      fontSize: 18,
                                                      fontWeight:
                                                          FontWeight.w600,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                            SizedBox(width: 20),
                                            GestureDetector(
                                              onTap: () {
                                                Navigator.of(context).push(
                                                  MaterialPageRoute(
                                                    builder: (context) =>
                                                        FollowersList(
                                                      userId: _user.id,
                                                    ),
                                                  ),
                                                );
                                              },
                                              child: Column(
                                                children: [
                                                  FutureBuilder(
                                                      future: _followers,
                                                      builder:
                                                          (context, snapshot) {
                                                        if (snapshot
                                                                .connectionState ==
                                                            ConnectionState
                                                                .waiting) {
                                                          return SizedBox
                                                              .shrink();
                                                        }
                                                        return Text(
                                                          snapshot.data.size
                                                              .toString(),
                                                          style: TextStyle(
                                                            color: Colors.grey,
                                                            fontSize: 18,
                                                            fontWeight:
                                                                FontWeight.w600,
                                                          ),
                                                        );
                                                      }),
                                                  SizedBox(height: 5),
                                                  Text(
                                                    'Followers',
                                                    style: TextStyle(
                                                      color: Colors.grey,
                                                      fontSize: 18,
                                                      fontWeight:
                                                          FontWeight.w600,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ],
                                        ),
                                        _userStatus != '' && _userStatus != null
                                            ? Container(
                                                alignment: Alignment.center,
                                                margin:
                                                    EdgeInsets.only(top: 16),
                                                height: MediaQuery.of(context)
                                                        .size
                                                        .height /
                                                    17,
                                                width: _userStatus == 'single'
                                                    ? MediaQuery.of(context)
                                                            .size
                                                            .width /
                                                        3.3
                                                    : MediaQuery.of(context)
                                                            .size
                                                            .width /
                                                        2.4,
                                                decoration: BoxDecoration(
                                                  borderRadius:
                                                      BorderRadius.circular(7),
                                                  border: Border.all(
                                                    color: Colors.red,
                                                    width: 1.3,
                                                  ),
                                                ),
                                                child: Row(
                                                  mainAxisAlignment:
                                                      MainAxisAlignment.center,
                                                  children: [
                                                    Icon(
                                                      MdiIcons.heartMultiple,
                                                      color: Colors.red,
                                                    ),
                                                    SizedBox(width: 5),
                                                    Text(
                                                      _userStatus == 'single'
                                                          ? 'SINGLE'
                                                          : 'IN A RELATIONSHIP',
                                                      style: TextStyle(
                                                        color: Colors.red,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              )
                                            : SizedBox.shrink(),
                                        blockedUsers.contains(widget.userId)
                                            ? SizedBox(height: 30)
                                            : SizedBox.shrink(),
                                        blockedUsers.contains(widget.userId)
                                            ? Text(
                                                'You have blocked ${_user.username}',
                                                style: TextStyle(
                                                  fontSize: 25,
                                                  color: Colors.grey[700],
                                                  fontWeight: FontWeight.w600,
                                                ),
                                              )
                                            : SizedBox.shrink(),
                                        widget.userId == _id
                                            ? SizedBox.shrink()
                                            : SizedBox(height: 16),
                                        widget.userId == _id ||
                                                blockedUsers
                                                    .contains(widget.userId)
                                            ? SizedBox.shrink()
                                            : Row(
                                                mainAxisAlignment:
                                                    MainAxisAlignment.center,
                                                children: [
                                                  Container(
                                                    width:
                                                        MediaQuery.of(context)
                                                                .size
                                                                .width /
                                                            2.5,
                                                    height:
                                                        MediaQuery.of(context)
                                                                .size
                                                                .height /
                                                            14,
                                                    child: FlatButton(
                                                      shape: SuperellipseShape(
                                                        borderRadius:
                                                            BorderRadius
                                                                .circular(10),
                                                      ),
                                                      color: Colors.deepPurple,
                                                      onPressed: () {
                                                        FirebaseFirestore
                                                            .instance
                                                            .collection('users')
                                                            .doc(_id)
                                                            .collection(
                                                                'global-chatters')
                                                            .doc(widget.userId)
                                                            .set(
                                                          {
                                                            'timestamp': '',
                                                          },
                                                          SetOptions(
                                                            merge: true,
                                                          ),
                                                        );
                                                        _setGroupChatId();
                                                        Navigator.of(context)
                                                            .push(
                                                          MaterialPageRoute(
                                                            builder:
                                                                (context) =>
                                                                    ChatPage(
                                                              followerId:
                                                                  widget.userId,
                                                              followerName:
                                                                  _user
                                                                      .username,
                                                              id: _id,
                                                              groupId: _groupId,
                                                              isGlobal: true,
                                                            ),
                                                          ),
                                                        );
                                                      },
                                                      textColor: Colors.white,
                                                      child: Text('Chat'),
                                                    ),
                                                  ),
                                                  SizedBox(width: 10),
                                                  Container(
                                                    width:
                                                        MediaQuery.of(context)
                                                                .size
                                                                .width /
                                                            2.5,
                                                    height:
                                                        MediaQuery.of(context)
                                                                .size
                                                                .height /
                                                            14,
                                                    child: FlatButton(
                                                      shape: SuperellipseShape(
                                                        borderRadius:
                                                            BorderRadius
                                                                .circular(10),
                                                      ),
                                                      color: Colors.black,
                                                      onPressed: () {
                                                        if (_isFollowing ==
                                                            false) {
                                                          DatabaseService
                                                              .followUser(
                                                            widget.userId,
                                                            _userName,
                                                          );
                                                          NotificationsService
                                                              .sendNotification(
                                                            'New Follower',
                                                            '$_userName followed you',
                                                            widget.userId,
                                                            'profile',
                                                          );
                                                          NotificationsService
                                                              .subscribeToTopic(
                                                                  widget
                                                                      .userId);
                                                          setState(() {
                                                            _isFollowing = true;
                                                          });
                                                        } else {
                                                          DatabaseService
                                                              .unFollowUser(
                                                                  widget
                                                                      .userId);
                                                          NotificationsService
                                                              .unsubscribeFromTopic(
                                                                  widget
                                                                      .userId);
                                                          setState(() {
                                                            _isFollowing =
                                                                false;
                                                          });
                                                        }
                                                      },
                                                      textColor: Colors.white,
                                                      child: Row(
                                                        mainAxisSize:
                                                            MainAxisSize.min,
                                                        children: [
                                                          _isFollowing == true
                                                              ? Icon(
                                                                  Icons.check,
                                                                  size: 14,
                                                                  color: Colors
                                                                      .white,
                                                                )
                                                              : SizedBox
                                                                  .shrink(),
                                                          _isFollowing == true
                                                              ? SizedBox(
                                                                  width: 5)
                                                              : SizedBox
                                                                  .shrink(),
                                                          Text(
                                                            _isFollowing == true
                                                                ? 'Following'
                                                                : 'FOLLOW',
                                                            style: TextStyle(
                                                              fontWeight:
                                                                  FontWeight
                                                                      .w600,
                                                            ),
                                                          ),
                                                        ],
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                        blockedUsers.contains(widget.userId)
                                            ? SizedBox.shrink()
                                            : SizedBox(height: 20),
                                        widget.userId == _id
                                            ? Column(
                                                children: [
                                                  Container(
                                                    width:
                                                        MediaQuery.of(context)
                                                                .size
                                                                .width -
                                                            20,
                                                    child: OutlineButton(
                                                      onPressed: () =>
                                                          _showBioDialog(),
                                                      shape:
                                                          RoundedRectangleBorder(
                                                        borderRadius:
                                                            BorderRadius
                                                                .circular(5),
                                                      ),
                                                      borderSide: BorderSide(
                                                          color: Colors.blue),
                                                      textColor: Colors.blue,
                                                      child:
                                                          Text('Edit your bio'),
                                                    ),
                                                  ),
                                                  SizedBox(height: 10),
                                                  Container(
                                                    width:
                                                        MediaQuery.of(context)
                                                                .size
                                                                .width -
                                                            20,
                                                    child: OutlineButton(
                                                      onPressed: () =>
                                                          _showStatusDialog(),
                                                      shape:
                                                          RoundedRectangleBorder(
                                                        borderRadius:
                                                            BorderRadius
                                                                .circular(5),
                                                      ),
                                                      borderSide: BorderSide(
                                                          color: Colors.blue),
                                                      textColor: Colors.blue,
                                                      child: Text(
                                                        'Edit your status',
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              )
                                            : SizedBox.shrink(),
                                        blockedUsers.contains(widget.userId)
                                            ? SizedBox.shrink()
                                            : Divider(),
                                        blockedUsers.contains(widget.userId)
                                            ? SizedBox.shrink()
                                            : TabBar(
                                                indicatorColor: Colors.black,
                                                tabs: [
                                                  Padding(
                                                    padding:
                                                        EdgeInsets.all(8.0),
                                                    child: Icon(
                                                      MdiIcons.cards,
                                                      color: Colors.black,
                                                    ),
                                                  ),
                                                  Padding(
                                                    padding:
                                                        EdgeInsets.all(8.0),
                                                    child: Icon(
                                                      Icons.favorite,
                                                      color: Colors.black,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                      ],
                                    );
                                  }),
                            ],
                          ),
                        ),
                      ],
                      body: blockedUsers.contains(widget.userId)
                          ? SizedBox.shrink()
                          : Column(
                              children: [
                                Expanded(
                                  child: TabBarView(
                                    children: [
                                      Stack(
                                        children: [
                                          FutureBuilder(
                                            future: _generalFuture,
                                            builder: (context,
                                                AsyncSnapshot<QuerySnapshot>
                                                    snapshot) {
                                              if (snapshot.connectionState ==
                                                  ConnectionState.waiting) {
                                                return Center(
                                                  child:
                                                      CircularProgressIndicator(
                                                    strokeWidth: 1.2,
                                                    valueColor:
                                                        AlwaysStoppedAnimation(
                                                            Colors.black),
                                                  ),
                                                );
                                              } else {
                                                if (snapshot.data.docs.length ==
                                                    0) {
                                                  return Center(
                                                    child: Text(
                                                      'Nothing created yet',
                                                      style: TextStyle(
                                                        color: Colors.grey[600],
                                                        fontSize: 24,
                                                        fontWeight:
                                                            FontWeight.w600,
                                                      ),
                                                    ),
                                                  );
                                                }
                                                return _creationSelectedIndex ==
                                                        0
                                                    ? ListView.builder(
                                                        itemCount: snapshot
                                                            .data.docs.length,
                                                        itemBuilder:
                                                            (context, index) {
                                                          return PostWidget(
                                                            snapshot: snapshot
                                                                .data
                                                                .docs[index],
                                                          );
                                                        },
                                                      )
                                                    : GridView.builder(
                                                        gridDelegate:
                                                            SliverGridDelegateWithFixedCrossAxisCount(
                                                          crossAxisCount: 2,
                                                          childAspectRatio: 0.7,
                                                        ),
                                                        itemCount: snapshot
                                                            .data.docs.length,
                                                        itemBuilder:
                                                            (context, index) {
                                                          return VideoWidget(
                                                            videoUrl: snapshot
                                                                    .data
                                                                    .docs[index]
                                                                    .data()[
                                                                'videoUrl'],
                                                          );
                                                        },
                                                      );
                                              }
                                            },
                                          ),
                                          Align(
                                            alignment: Alignment.bottomCenter,
                                            child: Padding(
                                              padding: EdgeInsets.all(8),
                                              child: FlutterToggleTab(
                                                width: 80,
                                                borderRadius: 40,
                                                labels: ['', '', '', '', ''],
                                                icons: [
                                                  MdiIcons.cards,
                                                  MdiIcons.star,
                                                  MdiIcons.dramaMasks,
                                                  MdiIcons.baseball,
                                                  MdiIcons.flagCheckered,
                                                ],
                                                selectedBackgroundColors: [
                                                  Colors.black,
                                                  Colors.black,
                                                ],
                                                initialIndex: 0,
                                                selectedIndex:
                                                    _creationSelectedIndex,
                                                selectedLabelIndex:
                                                    (int index) {
                                                  setState(
                                                    () {
                                                      _creationSelectedIndex =
                                                          index;
                                                      if (_creationSelectedIndex ==
                                                          0) {
                                                        _generalFuture =
                                                            _postCreation;
                                                      } else if (_creationSelectedIndex ==
                                                          1) {
                                                        _generalFuture =
                                                            _talentCreation;
                                                      } else if (_creationSelectedIndex ==
                                                          2) {
                                                        _generalFuture =
                                                            _comedyCreation;
                                                      } else if (_creationSelectedIndex ==
                                                          3) {
                                                        _generalFuture =
                                                            _sportCreation;
                                                      } else if (_creationSelectedIndex ==
                                                          4) {
                                                        _generalFuture =
                                                            _challengeCreation;
                                                      } else {
                                                        return;
                                                      }
                                                    },
                                                  );
                                                },
                                                selectedTextStyle: TextStyle(
                                                    color: Colors.white,
                                                    fontSize: 18,
                                                    fontWeight:
                                                        FontWeight.w600),
                                                unSelectedTextStyle: TextStyle(
                                                    color: Colors.grey,
                                                    fontSize: 14,
                                                    fontWeight:
                                                        FontWeight.w400),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                      Stack(
                                        children: [
                                          FutureBuilder(
                                            future: _generalLikesFuture,
                                            builder: (context,
                                                AsyncSnapshot<QuerySnapshot>
                                                    snapshot) {
                                              if (snapshot.connectionState ==
                                                  ConnectionState.waiting) {
                                                return Center(
                                                  child:
                                                      CircularProgressIndicator(
                                                    strokeWidth: 1.2,
                                                    valueColor:
                                                        AlwaysStoppedAnimation(
                                                            Colors.black),
                                                  ),
                                                );
                                              } else {
                                                if (snapshot.data == null) {
                                                  return SizedBox.shrink();
                                                }
                                                if (snapshot.data.docs.length ==
                                                    0) {
                                                  return Center(
                                                    child: Text(
                                                      'Nothing liked yet',
                                                      style: TextStyle(
                                                        color: Colors.grey[600],
                                                        fontSize: 24,
                                                        fontWeight:
                                                            FontWeight.w600,
                                                      ),
                                                    ),
                                                  );
                                                }
                                                return _likesSelectedIndex == 0
                                                    ? ListView.builder(
                                                        itemCount: snapshot
                                                            .data.docs.length,
                                                        itemBuilder:
                                                            (context, index) {
                                                          return PostWidget(
                                                            snapshot: snapshot
                                                                .data
                                                                .docs[index],
                                                          );
                                                        },
                                                      )
                                                    : GridView.builder(
                                                        gridDelegate:
                                                            SliverGridDelegateWithFixedCrossAxisCount(
                                                          crossAxisCount: 2,
                                                          childAspectRatio: 0.7,
                                                        ),
                                                        itemCount: snapshot
                                                            .data.docs.length,
                                                        itemBuilder:
                                                            (context, index) {
                                                          return VideoWidget(
                                                            videoUrl: snapshot
                                                                    .data
                                                                    .docs[index]
                                                                    .data()[
                                                                'videoUrl'],
                                                          );
                                                        },
                                                      );
                                              }
                                            },
                                          ),
                                          Align(
                                            alignment: Alignment.bottomCenter,
                                            child: Padding(
                                              padding: EdgeInsets.all(8),
                                              child: FlutterToggleTab(
                                                width: 80,
                                                borderRadius: 40,
                                                labels: ['', '', '', '', ''],
                                                icons: [
                                                  MdiIcons.cards,
                                                  MdiIcons.star,
                                                  MdiIcons.dramaMasks,
                                                  MdiIcons.baseball,
                                                  MdiIcons.flagCheckered,
                                                ],
                                                selectedBackgroundColors: [
                                                  Colors.black,
                                                  Colors.black,
                                                ],
                                                initialIndex: 0,
                                                selectedIndex:
                                                    _likesSelectedIndex,
                                                selectedLabelIndex:
                                                    (int index) {
                                                  setState(
                                                    () {
                                                      _likesSelectedIndex =
                                                          index;
                                                      if (_likesSelectedIndex ==
                                                          0) {
                                                        _generalLikesFuture =
                                                            _postLikes;
                                                      } else if (_likesSelectedIndex ==
                                                          1) {
                                                        _generalLikesFuture =
                                                            _talentLikes;
                                                      } else if (_likesSelectedIndex ==
                                                          2) {
                                                        _generalLikesFuture =
                                                            _comedyLikes;
                                                      } else if (_likesSelectedIndex ==
                                                          3) {
                                                        _generalLikesFuture =
                                                            _sportLikes;
                                                      } else if (_likesSelectedIndex ==
                                                          4) {
                                                        _generalLikesFuture =
                                                            _challengeLikes;
                                                      } else {
                                                        return;
                                                      }
                                                    },
                                                  );
                                                },
                                                selectedTextStyle: TextStyle(
                                                    color: Colors.white,
                                                    fontSize: 18,
                                                    fontWeight:
                                                        FontWeight.w600),
                                                unSelectedTextStyle: TextStyle(
                                                    color: Colors.grey,
                                                    fontSize: 14,
                                                    fontWeight:
                                                        FontWeight.w400),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                    ),
                  );
                }),
          );
  }
}

class VideoWidget extends StatefulWidget {
  final String videoUrl;

  VideoWidget({Key key, this.videoUrl}) : super(key: key);

  @override
  _VideoWidgetState createState() => _VideoWidgetState();
}

class _VideoWidgetState extends State<VideoWidget> {
  VideoPlayerController _videoController;

  @override
  void initState() {
    super.initState();
    _videoController = VideoPlayerController.network(widget.videoUrl);
    _videoController.initialize()..then((_) => setState(() {}));
  }

  @override
  void dispose() {
    _videoController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: <Widget>[
        Container(
          width: MediaQuery.of(context).size.width / 2,
          height: MediaQuery.of(context).size.width / 2,
          child: !_videoController.value.isInitialized
              ? Container(color: Colors.grey[400])
              : OverflowBox(
                  alignment: Alignment.center,
                  child: FittedBox(
                    fit: BoxFit.cover,
                    child: Container(
                      width: MediaQuery.of(context).size.width,
                      height: MediaQuery.of(context).size.width /
                          _videoController.value.aspectRatio,
                      child: VideoPlayer(_videoController),
                    ),
                  ),
                ),
        ),
        Positioned(
          right: MediaQuery.of(context).size.width / 4.5,
          top: MediaQuery.of(context).size.width / 4.5,
          child: GestureDetector(
            child: FaIcon(
              FontAwesomeIcons.play,
              size: 20,
              color: Colors.white,
            ),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => VideoPreviewWidget(
                    videoPath: widget.videoUrl,
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class VideoPreviewWidget extends StatefulWidget {
  final String videoPath;
  VideoPreviewWidget({Key key, this.videoPath}) : super(key: key);

  @override
  _VideoPreviewWidgetState createState() => _VideoPreviewWidgetState();
}

class _VideoPreviewWidgetState extends State<VideoPreviewWidget> {
  VideoPlayerController _controller;
  double _opacity = 1.0;

  String get _duration =>
      _controller.value.duration?.toString()?.substring(2)?.split('.')?.first ??
      '';
  String get _position =>
      _controller.value.position?.toString()?.substring(2)?.split('.')?.first ??
      '';

  void _listener() {
    setState(() {
      if (_position == _duration) {
        _opacity = 1.0;
      }
    });
  }

  @override
  void initState() {
    super.initState();
    _controller = VideoPlayerController.network(
      widget.videoPath,
    );
    initFuture();
    _controller.addListener(_listener);
    print(widget.videoPath);
    _controller.initialize().then((_) => setState(() {}));
    _controller.play();
  }

  void initFuture() async {
    await Future.delayed(Duration(milliseconds: 1000));
  }

  @override
  void dispose() {
    _controller.dispose();
    _controller.removeListener(_listener);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        setState(() {
          if (_opacity == 1.0) {
            _opacity = 0.0;
          } else {
            _opacity = 1.0;
          }
        });
      },
      child: Scaffold(
        body: Stack(
          children: <Widget>[
            SizedBox.expand(
              child: FittedBox(
                fit: BoxFit.cover,
                child: SizedBox(
                  width: _controller.value.size?.width ?? 0,
                  height: _controller.value.size?.height ?? 0,
                  child: VideoPlayer(_controller),
                ),
              ),
            ),
            Align(
              alignment: Alignment.topRight,
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  vertical: 25,
                  horizontal: 10,
                ),
                child: IconButton(
                  icon: Icon(
                    Icons.close,
                    color: Colors.white,
                  ),
                  iconSize: 35,
                  onPressed: () {
                    Navigator.pop(context);
                  },
                ),
              ),
            ),
            Center(
              child: AnimatedOpacity(
                opacity: _opacity,
                duration: Duration(milliseconds: 350),
                curve: Curves.easeIn,
                child: FlatButton(
                  shape: CircleBorder(),
                  onPressed: () {
                    setState(() {
                      if (_controller.value.isPlaying) {
                        _controller.pause();
                        print(widget.videoPath);
                      } else if (!_controller.value.isPlaying &&
                          _position != _duration) {
                        _controller.play();
                        _opacity = 0.0;
                      } else if (_position == _duration) {
                        _controller.seekTo(Duration.zero);
                        _controller.play();
                        _opacity = 0.0;
                      } else {
                        return;
                      }
                    });
                  },
                  child: FaIcon(
                    _controller.value.isPlaying
                        ? Icons.pause
                        : _position == _duration
                            ? Icons.replay
                            : Icons.play_arrow,
                    color: Colors.white,
                    size: 50,
                  ),
                ),
              ),
            ),
            Align(
              alignment: Alignment.bottomCenter,
              child: VideoProgressIndicator(
                _controller,
                allowScrubbing: true,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class FollowingList extends StatefulWidget {
  final String id;
  final String userId;
  FollowingList({Key key, this.id, this.userId}) : super(key: key);

  @override
  _FollowingListState createState() => _FollowingListState();
}

class _FollowingListState extends State<FollowingList> {
  Stream _stream;

  @override
  void initState() {
    super.initState();
    _stream = FirebaseFirestore.instance
        .collection('users')
        .doc(widget.userId)
        .collection('following')
        .snapshots();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        elevation: 0.5,
        backgroundColor: Colors.white,
        iconTheme: IconThemeData.fallback(),
        centerTitle: true,
        title: Text(
          'Following',
          style: TextStyle(color: Colors.black),
        ),
      ),
      body: StreamBuilder<QuerySnapshot>(
          stream: _stream,
          builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Center(
                child: CircularProgressIndicator(
                  strokeWidth: 1.2,
                  valueColor: AlwaysStoppedAnimation(Colors.black),
                ),
              );
            }
            if (snapshot.data.size == 0) {
              return Center(
                child: Text(
                  'No Following yet',
                  style: TextStyle(
                    color: Colors.grey,
                    fontSize: 18,
                  ),
                ),
              );
            }
            return ListView.builder(
              itemCount: snapshot.data.size,
              itemBuilder: (BuildContext context, int index) {
                return FutureBuilder(
                    future: FirebaseFirestore.instance
                        .collection('users')
                        .doc(snapshot.data.docs[index].id)
                        .get(),
                    builder: (context, usersnapshot) {
                      if (usersnapshot.connectionState ==
                          ConnectionState.waiting) {
                        return SizedBox.shrink();
                      }

                      final User _user = User.fromDoc(usersnapshot.data);
                      return Padding(
                        padding: EdgeInsets.symmetric(vertical: 20),
                        child: ListTile(
                          leading: ClipRRect(
                            borderRadius: BorderRadius.circular(50),
                            child: CachedNetworkImage(
                              imageUrl: _user.profileImageUrl,
                              fit: BoxFit.cover,
                              height: 50,
                              width: 50,
                            ),
                          ),
                          title: Text(_user.username),
                          trailing: widget.id == widget.userId
                              ? FlatButton(
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(5),
                                  ),
                                  color: Colors.black,
                                  onPressed: () {
                                    DatabaseService.unFollowUser(_user.id);
                                  },
                                  textColor: Colors.white,
                                  child: Text('Unfollow'),
                                )
                              : Icon(
                                  Icons.arrow_forward_ios,
                                  color: Colors.grey,
                                ),
                          onTap: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (context) => ProfilePage(
                                  userId: _user.id,
                                ),
                              ),
                            );
                          },
                        ),
                      );
                    });
              },
            );
          }),
    );
  }
}

class FollowersList extends StatefulWidget {
  final String id;
  final String userId;
  FollowersList({Key key, this.id, this.userId}) : super(key: key);

  @override
  _FollowersListState createState() => _FollowersListState();
}

class _FollowersListState extends State<FollowersList> {
  Stream _stream;

  @override
  void initState() {
    super.initState();
    _stream = FirebaseFirestore.instance
        .collection('users')
        .doc(widget.userId)
        .collection('followers')
        .snapshots();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        elevation: 0.5,
        backgroundColor: Colors.white,
        iconTheme: IconThemeData.fallback(),
        centerTitle: true,
        title: Text(
          'Followers',
          style: TextStyle(color: Colors.black),
        ),
      ),
      body: StreamBuilder<QuerySnapshot>(
          stream: _stream,
          builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Center(
                child: CircularProgressIndicator(
                  strokeWidth: 1.2,
                  valueColor: AlwaysStoppedAnimation(Colors.black),
                ),
              );
            }
            if (snapshot.data.size == 0) {
              return Center(
                child: Text(
                  'No Followers yet',
                  style: TextStyle(
                    color: Colors.grey,
                    fontSize: 18,
                  ),
                ),
              );
            }
            return ListView.builder(
              itemCount: snapshot.data.size,
              itemBuilder: (BuildContext context, int index) {
                return FutureBuilder(
                    future: FirebaseFirestore.instance
                        .collection('users')
                        .doc(snapshot.data.docs[index].id)
                        .get(),
                    builder: (context, usersnapshot) {
                      if (usersnapshot.connectionState ==
                          ConnectionState.waiting) {
                        return SizedBox.shrink();
                      }

                      final User _user = User.fromDoc(usersnapshot.data);
                      return Padding(
                        padding: EdgeInsets.symmetric(vertical: 20),
                        child: ListTile(
                          leading: ClipRRect(
                            borderRadius: BorderRadius.circular(50),
                            child: CachedNetworkImage(
                              imageUrl: _user.profileImageUrl,
                              fit: BoxFit.cover,
                              height: 50,
                              width: 50,
                            ),
                          ),
                          title: Text(_user.username),
                          trailing: widget.id == widget.userId
                              ? FlatButton(
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(5),
                                  ),
                                  color: Colors.black,
                                  onPressed: () {
                                    FirebaseFirestore.instance
                                        .collection('users')
                                        .doc(widget.userId)
                                        .collection('followers')
                                        .doc(_user.id)
                                        .delete();
                                  },
                                  textColor: Colors.white,
                                  child: Text('Remove'),
                                )
                              : Icon(
                                  Icons.arrow_forward_ios,
                                  color: Colors.grey,
                                ),
                          onTap: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (context) => ProfilePage(
                                  userId: _user.id,
                                ),
                              ),
                            );
                          },
                        ),
                      );
                    });
              },
            );
          }),
    );
  }
}
