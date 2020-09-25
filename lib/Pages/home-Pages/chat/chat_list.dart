import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_toggle_tab/flutter_toggle_tab.dart';
import 'package:looper/Pages/home-Pages/chat/chat_page.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:looper/models/userModel.dart';
import 'package:looper/services/database.dart';

class ChatList extends StatefulWidget {
  ChatList({Key key}) : super(key: key);

  @override
  _ChatListState createState() => _ChatListState();
}

class _ChatListState extends State<ChatList> {
  Future<QuerySnapshot> _future;
  int _selectedIndex = 0;
  String _id = 'empty';
  String _userName = '';

  String _groupId = '';

  @override
  void initState() {
    super.initState();
    setPrefs();
  }

  void setPrefs() async {
    final SharedPreferences _prefs = await SharedPreferences.getInstance();
    final DocumentSnapshot _user = await FirebaseFirestore.instance
        .collection('users')
        .doc(_prefs.get('id'))
        .get();
    setState(() {
      _id = _prefs.get('id');
      _userName = _user.data()['username'];
      _future = FirebaseFirestore.instance
          .collection('users')
          .doc(_id)
          .collection('following')
          .get();
    });
  }

  void _setGroupChatId(String followerId) {
    if (_id.hashCode < followerId.hashCode) {
      _groupId = '$followerId-$_id';
    } else {
      _groupId = '$_id-$followerId';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[200],
      appBar: AppBar(
        elevation: 0.5,
        backgroundColor: Colors.white,
        iconTheme: IconThemeData.fallback(),
        centerTitle: true,
        title: Text(
          'Messages',
          style: TextStyle(color: Colors.black),
        ),
      ),
      body: Stack(
        children: [
          Positioned.fill(
            child: FutureBuilder(
              future: _future,
              builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting)
                  return Center(
                    child: CircularProgressIndicator(),
                  );
                if (snapshot.data == null) {
                  return SizedBox.shrink();
                }
                if (snapshot.data.docs.length == 0) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          MdiIcons.messageTextClock,
                          size: 80,
                          color: Colors.grey,
                        ),
                        SizedBox(height: 10),
                        Text(
                          _selectedIndex == 1
                              ? 'Search for people globally and start chat !'
                              : 'Follow some people to start chatting !',
                          style: TextStyle(
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  );
                }
                return ListView.separated(
                    itemCount: snapshot.data.docs.length,
                    separatorBuilder: (context, index) => Divider(),
                    itemBuilder: (context, index) {
                      final User _followingUser =
                          User.fromDoc(snapshot.data.docs[index]);
                      _setGroupChatId(_followingUser.id);
                      return Container(
                        padding: EdgeInsets.symmetric(vertical: 5),
                        color: Colors.white,
                        child: FutureBuilder(
                            future: FirebaseFirestore.instance
                                .collection('users')
                                .doc(_followingUser.id)
                                .get(),
                            builder: (context, snapshot) {
                              if (snapshot.connectionState ==
                                  ConnectionState.waiting) {
                                return SizedBox.shrink();
                              }
                              final User _user = User.fromDoc(snapshot.data);
                              return ListTile(
                                leading: ClipRRect(
                                  borderRadius: BorderRadius.circular(40),
                                  child: CachedNetworkImage(
                                    imageUrl: _user.profileImageUrl,
                                    height: 50,
                                    width: 50,
                                    fit: BoxFit.cover,
                                  ),
                                ),
                                title: Text(
                                  _user.username,
                                ),
                                subtitle: StreamBuilder(
                                    stream: FirebaseFirestore.instance
                                        .collection(_selectedIndex == 0
                                            ? 'chat'
                                            : 'global-chat')
                                        .doc(_groupId)
                                        .collection('messages')
                                        .snapshots(),
                                    builder: (context,
                                        AsyncSnapshot<QuerySnapshot>
                                            docsnapshot) {
                                      if (docsnapshot.connectionState ==
                                          ConnectionState.waiting) {
                                        return SizedBox.shrink();
                                      }
                                      return Text(
                                        docsnapshot.data.docs.length == 0
                                            ? 'Start chatting now'
                                            : docsnapshot.data.docs.length == 1
                                                ? docsnapshot.data.docs[0]
                                                            .data()['type'] ==
                                                        0
                                                    ? docsnapshot.data.docs[0]
                                                        .data()['content']
                                                    : docsnapshot.data.docs[0].data()['type'] == 1
                                                        ? 'Shared a photo'
                                                        : docsnapshot.data.docs[0].data()['type'] == 2
                                                            ? 'Shared a video'
                                                            : 'Shared an audio'
                                                : docsnapshot.data.docs[docsnapshot.data.docs.length - 1]
                                                            .data()['type'] ==
                                                        0
                                                    ? docsnapshot.data.docs[docsnapshot.data.docs.length - 1]
                                                        .data()['content']
                                                    : docsnapshot.data.docs[docsnapshot.data.docs.length - 1].data()['type'] == 1
                                                        ? 'Shared a photo'
                                                        : docsnapshot.data
                                                                    .docs[docsnapshot.data.docs.length - 1]
                                                                    .data()['type'] ==
                                                                2
                                                            ? 'Shared a video'
                                                            : 'Shared an audio',
                                        overflow: TextOverflow.ellipsis,
                                      );
                                    }),
                                trailing: StreamBuilder(
                                    stream: FirebaseFirestore.instance
                                        .collection(_selectedIndex == 0
                                            ? 'chat'
                                            : 'global-chat')
                                        .doc(_groupId)
                                        .collection('messages')
                                        .snapshots(),
                                    builder: (context,
                                        AsyncSnapshot<QuerySnapshot>
                                            docsnapshot) {
                                      if (docsnapshot.connectionState ==
                                          ConnectionState.waiting) {
                                        return SizedBox.shrink();
                                      }
                                      return docsnapshot.data.docs.length == 0
                                          ? Icon(
                                              Icons.arrow_forward_ios,
                                              size: 18,
                                              color: Colors.black,
                                            )
                                          : Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                Text(
                                                  docsnapshot.data.docs
                                                              .length ==
                                                          1
                                                      ? DatabaseService
                                                          .getMessageTiming(
                                                          docsnapshot
                                                                  .data.docs[0]
                                                                  .data()[
                                                              'timestamp'],
                                                        )
                                                      : DatabaseService
                                                          .getMessageTiming(
                                                          docsnapshot
                                                              .data
                                                              .docs[docsnapshot
                                                                      .data
                                                                      .docs
                                                                      .length -
                                                                  1]
                                                              .data()['timestamp'],
                                                        ),
                                                ),
                                                SizedBox(width: 5),
                                                Icon(
                                                  Icons.arrow_forward_ios,
                                                  size: 18,
                                                  color: Colors.black,
                                                ),
                                              ],
                                            );
                                    }),
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => ChatPage(
                                        id: _id,
                                        followerId: _followingUser.id,
                                        followerName: _userName,
                                        groupId: _groupId,
                                        isGlobal:
                                            _selectedIndex == 1 ? true : false,
                                      ),
                                    ),
                                  );
                                },
                              );
                            }),
                      );
                    });
              },
            ),
          ),
          Align(
            alignment: Alignment.bottomCenter,
            child: Padding(
              padding: EdgeInsets.all(10),
              child: FlutterToggleTab(
                width: 40,
                borderRadius: 40,
                labels: ['', ''],
                icons: [MdiIcons.lock, MdiIcons.earth],
                selectedBackgroundColors: [
                  Colors.black,
                  Colors.black,
                ],
                initialIndex: 0,
                selectedIndex: _selectedIndex,
                selectedLabelIndex: (int index) {
                  setState(
                    () {
                      _selectedIndex = index;
                      if (_selectedIndex == 0) {
                        _future = FirebaseFirestore.instance
                            .collection('users')
                            .doc(_id)
                            .collection('following')
                            .get();
                      } else {
                        _future = FirebaseFirestore.instance
                            .collection('users')
                            .doc(_id)
                            .collection('global-chatters')
                            .get();
                      }
                    },
                  );
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
          ),
        ],
      ),
    );
  }
}
