import 'dart:async';
import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:image_picker/image_picker.dart';
import 'package:looper/models/commentModel.dart';
import 'package:looper/services/notifications.dart';
import 'package:looper/services/personality.dart';
import 'package:looper/services/storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:visibility_detector/visibility_detector.dart';
import 'package:flutter_bounce/flutter_bounce.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:looper/Pages/home-Pages/global/profile.dart';
import 'package:looper/services/database.dart';
import 'package:video_player/video_player.dart';
import '../models/comedyModel.dart';

class ComedyJoke extends StatefulWidget {
  final DocumentSnapshot data;
  ComedyJoke({Key key, this.data}) : super(key: key);

  @override
  _ComedyJokeState createState() => _ComedyJokeState();
}

class _ComedyJokeState extends State<ComedyJoke> {
  String _userId = '';
  String _userName;
  String _userImage;
  String _commentMedia;
  bool _isLaugh = false;
  int _laughCounter = 0;
  int _commentCounter = 0;
  Comedy _comedy;
  Stream<QuerySnapshot> _blockedUsers;
  TextEditingController _textEditingController;

  @override
  void initState() {
    super.initState();
    getUserData();
  }

  void getUserData() async {
    final SharedPreferences _prefs = await SharedPreferences.getInstance();
    setState(() {
      _userId = _prefs.get('id');
      _blockedUsers = FirebaseFirestore.instance
          .collection('users')
          .doc(_userId)
          .collection('blocked-users')
          .snapshots();
      _comedy = Comedy.fromDoc(widget.data);
      _isLaugh = _comedy.laughedPeople.contains(_userId);
      _laughCounter = _comedy.laughs;
      _commentCounter = _comedy.commentCount;
      _textEditingController = TextEditingController();
    });
    final FirebaseFirestore _firestore = FirebaseFirestore.instance;
    final DocumentSnapshot _snapshot =
        await _firestore.collection('users').doc(_userId).get();
    _userName = _snapshot?.data()['username'];
    _userImage = _snapshot?.data()['profilePictureUrl'];
  }

  void _showMediaPicker(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        child: Container(
          height: 116,
          child: Column(
            children: <Widget>[
              ListTile(
                onTap: () async {
                  List<String> _media = [];
                  final ImagePicker _picker = ImagePicker();
                  final PickedFile _file =
                      await _picker.getImage(source: ImageSource.camera);
                  _commentMedia = _file.path;
                  if (_commentMedia.isNotEmpty) {
                    await PersonalityService.setImageInput(_commentMedia);
                    final String _commentDate =
                        TimeOfDay.fromDateTime(DateTime.now()).format(context);
                    FocusScope.of(context).requestFocus(FocusNode());
                    Navigator.pop(context);
                    if (_commentMedia.isNotEmpty) {
                      _media = await StorageService.uploadMediaFile(
                        [File(_commentMedia)],
                        'comments/media',
                      );
                    }
                    final Comment _comment = Comment(
                      author: _userName,
                      authorId: _userId,
                      authorImage: _userImage,
                      media: _media.first,
                      type: 1,
                      timestamp: _commentDate,
                    );
                    DatabaseService.addComment(
                      'comedy',
                      _comedy.id,
                      _comment,
                    );
                    NotificationsService.sendNotification(
                      'New comment',
                      '$_userName commented on your joke',
                      _comedy.authorId,
                      'comedy',
                      _comedy.id,
                    );
                    NotificationsService.sendNotificationToFollowers(
                      'New comment',
                      '$_userName commented on a joke',
                      _comedy.authorId,
                      'comedy',
                      _comedy.id,
                    );
                    setState(() {
                      _commentCounter++;
                    });
                  }
                },
                title: Text('Take a Photo'),
              ),
              ListTile(
                onTap: () async {
                  List<String> _media = [];
                  final ImagePicker _picker = ImagePicker();
                  final PickedFile _file =
                      await _picker.getImage(source: ImageSource.gallery);
                  _commentMedia = _file.path;
                  if (_commentMedia.isNotEmpty) {
                    await PersonalityService.setImageInput(_commentMedia);
                    final String _commentDate =
                        TimeOfDay.fromDateTime(DateTime.now()).format(context);
                    FocusScope.of(context).requestFocus(FocusNode());
                    Navigator.pop(context);
                    if (_commentMedia.isNotEmpty) {
                      _media = await StorageService.uploadMediaFile(
                        [File(_commentMedia)],
                        'comments/media',
                      );
                    }
                    final Comment _comment = Comment(
                      author: _userName,
                      authorId: _userId,
                      authorImage: _userImage,
                      media: _media.first,
                      type: 1,
                      timestamp: _commentDate,
                    );
                    DatabaseService.addComment(
                      'comedy',
                      _comedy.id,
                      _comment,
                    );
                    NotificationsService.sendNotification(
                      'New comment',
                      '$_userName commented on your joke',
                      _comedy.authorId,
                      'comedy',
                      _comedy.id,
                    );
                    NotificationsService.sendNotificationToFollowers(
                      'New comment',
                      '$_userName commented on a joke',
                      _comedy.authorId,
                      'comedy',
                      _comedy.id,
                    );
                    setState(() {
                      _commentCounter++;
                    });
                  }
                },
                title: Text('Get from Gallery'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void openCommentSection() {
    showModalBottomSheet(
        backgroundColor: Colors.transparent,
        context: context,
        isScrollControlled: true,
        builder: (context) {
          return Container(
            width: MediaQuery.of(context).size.width,
            height: MediaQuery.of(context).size.height / 1.5,
            padding: MediaQuery.of(context).viewInsets,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: <Widget>[
                Padding(
                  padding: EdgeInsets.symmetric(vertical: 5),
                  child: Text(
                    _comedy.commentCount.toString() + ' Comments',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 24,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                Divider(),
                Expanded(
                  child: StreamBuilder(
                    stream: FirebaseFirestore.instance
                        .collection('comedy')
                        .doc(_comedy.id)
                        .collection('comments')
                        .snapshots(),
                    builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return SpinKitWave(
                          color: Colors.black,
                          size: 27,
                        );
                      } else {
                        return ListView.builder(
                          itemBuilder: (context, int index) {
                            final Comment _comment = Comment.fromDoc(
                              snapshot.data.docs[index],
                            );
                            return Padding(
                              padding: EdgeInsets.symmetric(
                                vertical: 10,
                                horizontal: 10,
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: <Widget>[
                                  GestureDetector(
                                    onTap: () {
                                      Navigator.of(context).push(
                                        MaterialPageRoute(
                                          builder: (context) => ProfilePage(
                                            userId: _comment.authorId,
                                          ),
                                        ),
                                      );
                                    },
                                    child: CircleAvatar(
                                      radius: 20,
                                      backgroundColor: Colors.white,
                                      backgroundImage:
                                          CachedNetworkImageProvider(
                                        _comment.authorImage,
                                      ),
                                    ),
                                  ),
                                  SizedBox(width: _comment.type == 1 ? 10 : 5),
                                  _comment.type == 1
                                      ? Stack(
                                          children: <Widget>[
                                            ClipRRect(
                                              borderRadius:
                                                  BorderRadius.circular(20),
                                              child: CachedNetworkImage(
                                                imageUrl: _comment.media,
                                                fit: BoxFit.cover,
                                                height: MediaQuery.of(context)
                                                        .size
                                                        .height /
                                                    3,
                                                width: MediaQuery.of(context)
                                                        .size
                                                        .height /
                                                    3,
                                              ),
                                            ),
                                            Positioned(
                                              right: 10,
                                              bottom: 10,
                                              child: Text(
                                                _comment.timestamp,
                                                style: TextStyle(
                                                  color: Colors.white,
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ),
                                          ],
                                        )
                                      : Container(
                                          width: MediaQuery.of(context)
                                                  .size
                                                  .width /
                                              3,
                                          padding: EdgeInsets.all(8),
                                          decoration: BoxDecoration(
                                            color: _comment.author == _userName
                                                ? Colors.blue.withOpacity(0.1)
                                                : Colors.grey[200],
                                            borderRadius:
                                                BorderRadius.circular(30),
                                          ),
                                          child: Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.spaceBetween,
                                            children: <Widget>[
                                              Flexible(
                                                child: Padding(
                                                  padding: EdgeInsets.all(8.0),
                                                  child: Text(_comment.content),
                                                ),
                                              ),
                                              SizedBox(width: 5),
                                              Text(
                                                _comment.timestamp,
                                                style: TextStyle(
                                                  color: Colors.grey,
                                                  fontSize: 12,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                  SizedBox(
                                    width: _comment.type == 1 ? 10 : 5,
                                  ),
                                  _comment.type == 1
                                      ? Column(
                                          children: [
                                            Column(
                                              children: <Widget>[
                                                Bounce(
                                                  onPressed: () {
                                                    if (!_comment.likedPeople
                                                        .contains(_userId)) {
                                                      DatabaseService
                                                          .likeComment(
                                                        _comedy.id,
                                                        'comedy',
                                                        _comment.id,
                                                        _userId,
                                                      );
                                                      PersonalityService
                                                          .setImageInput(
                                                        _comment.media,
                                                      );
                                                    } else {
                                                      DatabaseService
                                                          .unLikeComment(
                                                        _comedy.id,
                                                        'comedy',
                                                        _comment.id,
                                                        _userId,
                                                      );
                                                    }
                                                  },
                                                  duration: Duration(
                                                      milliseconds: 100),
                                                  child: Icon(
                                                    Icons.favorite,
                                                    size: 16,
                                                    color: _comment.likedPeople
                                                            .contains(_userId)
                                                        ? Colors.red
                                                        : Colors.black,
                                                  ),
                                                ),
                                                SizedBox(height: 2),
                                                Text(_comment.likes.toString()),
                                              ],
                                            ),
                                            SizedBox(height: 5),
                                            Column(
                                              children: <Widget>[
                                                Bounce(
                                                  onPressed: () {
                                                    Navigator.of(context).push(
                                                      MaterialPageRoute(
                                                        builder: (context) =>
                                                            ReplyPage(
                                                          userId: _userId,
                                                          commentId:
                                                              _comment.id,
                                                          objectId: _comedy.id,
                                                          userName: _userName,
                                                          userImage: _userImage,
                                                        ),
                                                      ),
                                                    );
                                                  },
                                                  duration: Duration(
                                                      milliseconds: 100),
                                                  child: Icon(
                                                    Icons.reply,
                                                    size: 16,
                                                    color: Colors.black,
                                                  ),
                                                ),
                                                SizedBox(height: 2),
                                                Text(_comment.replies
                                                    .toString()),
                                              ],
                                            ),
                                          ],
                                        )
                                      : Row(
                                          children: <Widget>[
                                            Bounce(
                                              onPressed: () {
                                                if (!_comment.likedPeople
                                                    .contains(_userId)) {
                                                  DatabaseService.likeComment(
                                                    _comedy.id,
                                                    'comedy',
                                                    _comment.id,
                                                    _userId,
                                                  );
                                                  PersonalityService
                                                      .setTextInput(
                                                    _comment.content,
                                                  );
                                                } else {
                                                  DatabaseService.unLikeComment(
                                                    _comedy.id,
                                                    'comedy',
                                                    _comment.id,
                                                    _userId,
                                                  );
                                                }
                                              },
                                              duration:
                                                  Duration(milliseconds: 100),
                                              child: Icon(
                                                Icons.favorite,
                                                size: 16,
                                                color: _comment.likedPeople
                                                        .contains(_userId)
                                                    ? Colors.red
                                                    : Colors.black,
                                              ),
                                            ),
                                            SizedBox(width: 2),
                                            Text(_comment.likes.toString()),
                                          ],
                                        ),
                                  SizedBox(width: 5),
                                  _comment.type == 1
                                      ? SizedBox.shrink()
                                      : Row(
                                          children: <Widget>[
                                            Bounce(
                                              onPressed: () {
                                                Navigator.of(context).push(
                                                  MaterialPageRoute(
                                                    builder: (context) =>
                                                        ReplyPage(
                                                      commentId: _comment.id,
                                                      comment: _comment.content,
                                                      objectId: _comedy.id,
                                                      userName: _userName,
                                                      userImage: _userImage,
                                                      userId: _userId,
                                                    ),
                                                  ),
                                                );
                                              },
                                              duration:
                                                  Duration(milliseconds: 100),
                                              child: Icon(
                                                Icons.reply,
                                                size: 16,
                                                color: Colors.black,
                                              ),
                                            ),
                                            SizedBox(width: 2),
                                            Text(_comment.replies.toString()),
                                          ],
                                        ),
                                ],
                              ),
                            );
                          },
                          itemCount: snapshot.data.docs.length,
                        );
                      }
                    },
                  ),
                ),
                Row(
                  children: <Widget>[
                    Padding(
                      padding: EdgeInsets.all(8.0),
                      child: Bounce(
                        child: Icon(Icons.camera_alt),
                        onPressed: () async {
                          _showMediaPicker(context);
                        },
                        duration: Duration(milliseconds: 100),
                      ),
                    ),
                    Expanded(
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.9),
                          borderRadius: BorderRadius.circular(20.0),
                        ),
                        child: TextField(
                          controller: _textEditingController,
                          textInputAction: TextInputAction.none,
                          decoration: InputDecoration(
                            contentPadding: EdgeInsets.all(10.0),
                            border: InputBorder.none,
                            hintText: 'Type a comment',
                          ),
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () async {
                        final String _commentDate =
                            TimeOfDay.fromDateTime(DateTime.now())
                                .format(context);
                        FocusScope.of(context).requestFocus(FocusNode());
                        final Comment _comment = Comment(
                          author: _userName,
                          authorId: _userId,
                          authorImage: _userImage,
                          content: _textEditingController.text,
                          type: 0,
                          timestamp: _commentDate,
                        );
                        await PersonalityService.setTextInput(
                          _comment.content,
                        );
                        DatabaseService.addComment(
                          'comedy',
                          _comedy.id,
                          _comment,
                        );
                        NotificationsService.sendNotification(
                          'New comment',
                          '$_userName commented on your joke',
                          _comedy.authorId,
                          'comedy',
                          _comedy.id,
                        );
                        NotificationsService.sendNotificationToFollowers(
                          'New comment',
                          '$_userName commented on a joke',
                          _comedy.authorId,
                          'comedy',
                          _comedy.id,
                        );
                        _textEditingController.clear();
                        setState(() {
                          _commentCounter++;
                        });
                      },
                      icon: Icon(Icons.send),
                    ),
                  ],
                ),
              ],
            ),
          );
        });
  }

  @override
  void didUpdateWidget(ComedyJoke oldWidget) {
    if (_comedy != Comedy.fromDoc(widget.data)) {
      setState(() {
        _comedy = Comedy.fromDoc(widget.data);
      });
    }
    super.didUpdateWidget(oldWidget);
  }

  Widget _buildMediaContent() {
    return Column(
      children: <Widget>[
        _comedy.caption != ''
            ? Text(
                _comedy.caption,
                style: TextStyle(
                  fontSize: 18,
                ),
              )
            : Container(),
        _comedy.type == '1' ? SizedBox(height: 7) : Container(),
        _comedy.mediaUrl.contains('.mp4')
            ? VideoWidget(videoUrl: _comedy.mediaUrl)
            : Container(
                child: CachedNetworkImage(
                  imageUrl: _comedy.mediaUrl,
                  progressIndicatorBuilder: (context, url, progress) => Padding(
                    padding: EdgeInsets.all(8.0),
                    child: Center(
                      child: SizedBox(
                        height: 40,
                        width: 40,
                        child: CircularProgressIndicator(
                            backgroundColor: Colors.grey,
                            valueColor: AlwaysStoppedAnimation(Colors.black),
                            value: progress.progress),
                      ),
                    ),
                  ),
                ),
              ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_comedy != null) {
      return StreamBuilder(
          stream: _blockedUsers,
          builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return SizedBox.shrink();
            }
            if (snapshot.data == null) {
              return SizedBox.shrink();
            }
            final List<String> blockedUsers =
                snapshot.data.docs.map((e) => e.id).toList();
            if (blockedUsers.contains(_comedy.authorId)) {
              print('yes');
              return Container();
            }
            return VisibilityDetector(
              key: Key(_comedy.id),
              onVisibilityChanged: (VisibilityInfo info) {
                double _visibilePercentage = info.visibleFraction * 100;
                Timer(
                  Duration(milliseconds: 2300),
                  () {
                    if (!_comedy.viewedPeople.contains(_userId)) {
                      if (_visibilePercentage == 100) {
                        DatabaseService.addView(
                          'comedy',
                          _comedy.id,
                          _userId,
                        );
                      }
                    }
                  },
                );
              },
              child: Container(
                padding: EdgeInsets.only(top: 10),
                child: IntrinsicHeight(
                    child: Column(
                  children: <Widget>[
                    Row(
                      children: <Widget>[
                        Padding(
                          padding: EdgeInsets.symmetric(horizontal: 10),
                          child: GestureDetector(
                            onTap: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (context) => ProfilePage(
                                    userId: _comedy.authorId,
                                  ),
                                ),
                              );
                            },
                            child: CircleAvatar(
                              radius: 25,
                              backgroundColor: Colors.grey[400],
                              backgroundImage: CachedNetworkImageProvider(
                                  _comedy.authorImage),
                            ),
                          ),
                        ),
                        Text(
                          _comedy.authorName,
                          style: TextStyle(
                            color: Colors.blue,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    _comedy.type == '0'
                        ? Padding(
                            padding: const EdgeInsets.only(top: 20, bottom: 5),
                            child: Text(
                              _comedy.content,
                              maxLines: 10,
                              style: TextStyle(fontSize: 18),
                            ),
                          )
                        : Container(),
                    SizedBox(height: _comedy.type == '1' ? 0 : 20),
                    _comedy.type == '1' ? _buildMediaContent() : Container(),
                    _comedy.type == '1' ? SizedBox(height: 10) : Container(),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: <Widget>[
                        Bounce(
                          onPressed: openCommentSection,
                          duration: Duration(milliseconds: 100),
                          child: Row(
                            children: <Widget>[
                              Icon(Icons.comment, color: Colors.grey),
                              SizedBox(width: 5),
                              Text(
                                '$_commentCounter comments',
                                style: TextStyle(color: Colors.grey),
                              ),
                            ],
                          ),
                        ),
                        Row(
                          children: <Widget>[
                            Icon(Icons.remove_red_eye, color: Colors.grey),
                            SizedBox(width: 5),
                            Text(
                              '${_comedy.viewsCount} views',
                              style: TextStyle(color: Colors.grey),
                            ),
                          ],
                        ),
                        Bounce(
                          duration: Duration(milliseconds: 100),
                          onPressed: () {
                            setState(() {
                              if (!_isLaugh) {
                                _isLaugh = true;
                                _laughCounter++;
                                DatabaseService.laugh(
                                  _comedy.id,
                                  _userId,
                                );
                                NotificationsService.sendNotification(
                                  'New Laugh 🤣',
                                  '$_userName laughes to  your joke',
                                  _comedy.authorId,
                                  'comedy',
                                  _comedy.id,
                                );
                                NotificationsService
                                    .sendNotificationToFollowers(
                                  'New Laugh 🤣',
                                  '$_userName laughes to  a joke',
                                  _comedy.authorId,
                                  'comedy',
                                  _comedy.id,
                                );
                                if (_comedy.content.isNotEmpty) {
                                  PersonalityService.setTextInput(
                                    '😂 I really like: \'${_comedy.content}\'',
                                  );
                                }
                                if (_comedy.mediaUrl.isNotEmpty) {
                                  if (_comedy.type == '0') {
                                    if (_comedy.caption.isNotEmpty) {
                                      PersonalityService.setTextInput(
                                        '😂 I really like: \'${_comedy.caption}\' plus i like that funny image:',
                                      );
                                    }
                                    PersonalityService.setImageInput(
                                        _comedy.mediaUrl);
                                  } else {
                                    if (_comedy.caption.isNotEmpty) {
                                      PersonalityService.setTextInput(
                                        '😂 I really like: \'${_comedy.caption}\' plus i like that funny video:',
                                      );
                                    }
                                    PersonalityService.setVideoInput(
                                        _comedy.mediaUrl);
                                  }
                                }
                              } else {
                                _isLaugh = false;
                                _laughCounter--;
                                DatabaseService.unLaugh(
                                  _comedy.id,
                                  _userId,
                                );
                              }
                            });
                          },
                          child: Row(
                            children: <Widget>[
                              Icon(
                                Icons.tag_faces,
                                color:
                                    _isLaugh ? Colors.yellow[700] : Colors.grey,
                              ),
                              SizedBox(width: 5),
                              Text(
                                '$_laughCounter laughs',
                                style: TextStyle(
                                  color: _isLaugh
                                      ? Colors.yellow[700]
                                      : Colors.grey,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    Divider(),
                  ],
                )),
              ),
            );
          });
    } else {
      return SizedBox.shrink();
    }
  }
}

class VideoWidget extends StatefulWidget {
  final String videoUrl;
  VideoWidget({Key key, this.videoUrl}) : super(key: key);

  @override
  _VideoWidgetState createState() => _VideoWidgetState();
}

class _VideoWidgetState extends State<VideoWidget> {
  VideoPlayerController _controller;
  @override
  void initState() {
    super.initState();
    _controller = VideoPlayerController.network(widget.videoUrl);
    _controller.initialize().then((value) => setState(() {}));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.width / 1.2,
      width: MediaQuery.of(context).size.width / 1.2,
      child: !_controller.value.initialized
          ? Container(color: Colors.grey[400])
          : Stack(
              children: <Widget>[
                OverflowBox(
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
                Center(
                  child: IconButton(
                    icon: FaIcon(
                      FontAwesomeIcons.play,
                      color: Colors.white,
                    ),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => VideoPlayerWidget(
                            videoPath: widget.videoUrl,
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
    );
  }
}

class ReplyPage extends StatefulWidget {
  final String userId;
  final String objectId;
  final String commentId;
  final String comment;
  final String userName;
  final String userImage;
  ReplyPage(
      {Key key,
      this.userId,
      this.objectId,
      this.commentId,
      this.comment,
      this.userName,
      this.userImage})
      : super(key: key);

  @override
  _ReplyPageState createState() => _ReplyPageState();
}

class _ReplyPageState extends State<ReplyPage> {
  TextEditingController _textEditingController;

  @override
  void initState() {
    super.initState();
    _textEditingController = TextEditingController();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.white,
          title: Text(
            widget.userName + ' Comment',
            style: TextStyle(color: Colors.black),
          ),
          iconTheme: IconThemeData.fallback(),
        ),
        body: Column(
          children: <Widget>[
            Expanded(
              child: StreamBuilder(
                stream: FirebaseFirestore.instance
                    .collection('comedy')
                    .doc(widget.objectId)
                    .collection('comments')
                    .doc(widget.commentId)
                    .collection('replies')
                    .snapshots(),
                builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return SpinKitWave(
                      color: Colors.black,
                      size: 27,
                    );
                  } else {
                    return ListView.builder(
                      itemBuilder: (context, int index) {
                        final Comment _comment = Comment.fromDoc(
                          snapshot.data.docs[index],
                        );
                        return Padding(
                          padding: EdgeInsets.symmetric(
                            vertical: 10,
                            horizontal: 10,
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: <Widget>[
                              CircleAvatar(
                                radius: 20,
                                backgroundColor: Colors.grey[400],
                                backgroundImage: CachedNetworkImageProvider(
                                  _comment.authorImage,
                                ),
                              ),
                              SizedBox(width: 5),
                              Container(
                                padding: EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: _comment.author == widget.userName
                                      ? Colors.blue.withOpacity(0.1)
                                      : Colors.grey[200],
                                  borderRadius: BorderRadius.circular(30),
                                ),
                                child: IntrinsicHeight(
                                  child: Row(
                                    children: <Widget>[
                                      Text(_comment.content),
                                      SizedBox(width: 5),
                                      Text(
                                        _comment.timestamp,
                                        style: TextStyle(
                                          color: Colors.grey,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              SizedBox(
                                width: 5,
                              ),
                              Row(
                                children: <Widget>[
                                  Bounce(
                                    onPressed: () {
                                      if (!_comment.likedPeople
                                          .contains(widget.userId)) {
                                        DatabaseService.likeReply(
                                          widget.objectId,
                                          'comedy',
                                          widget.commentId,
                                          widget.userId,
                                          _comment.id,
                                        );
                                        PersonalityService.setTextInput(
                                          _comment.content,
                                        );
                                      } else {
                                        DatabaseService.unLikeReply(
                                          widget.objectId,
                                          'comedy',
                                          widget.commentId,
                                          widget.userId,
                                          _comment.id,
                                        );
                                      }
                                    },
                                    duration: Duration(milliseconds: 100),
                                    child: Icon(
                                      Icons.favorite,
                                      size: 16,
                                      color: _comment.likedPeople
                                              .contains(widget.userId)
                                          ? Colors.red
                                          : Colors.black,
                                    ),
                                  ),
                                  SizedBox(width: 2),
                                  Text(_comment.likes.toString()),
                                ],
                              ),
                            ],
                          ),
                        );
                      },
                      itemCount: snapshot.data.docs.length,
                    );
                  }
                },
              ),
            ),
            Row(
              children: <Widget>[
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.9),
                      borderRadius: BorderRadius.circular(20.0),
                    ),
                    child: TextField(
                      controller: _textEditingController,
                      textInputAction: TextInputAction.none,
                      decoration: InputDecoration(
                        contentPadding: EdgeInsets.all(10.0),
                        border: InputBorder.none,
                        hintText: 'Reply to ${widget.userName}',
                      ),
                    ),
                  ),
                ),
                IconButton(
                  onPressed: () {
                    final String _commentDate =
                        TimeOfDay.fromDateTime(DateTime.now()).format(context);
                    FocusScope.of(context).requestFocus(FocusNode());
                    final Comment _comment = Comment(
                      author: widget.userName,
                      authorImage: widget.userImage,
                      content: _textEditingController.text,
                      type: 0,
                      timestamp: _commentDate,
                    );
                    PersonalityService.setTextInput(
                      'I\'ll reply for this comment \"${widget.comment}\" by saying ${_comment.content}',
                    );
                    DatabaseService.replyToComment(
                      widget.objectId,
                      'comedy',
                      widget.commentId,
                      _comment,
                    );
                    _textEditingController.clear();
                  },
                  icon: Icon(Icons.send),
                ),
              ],
            ),
          ],
        ));
  }
}

class VideoPlayerWidget extends StatefulWidget {
  final String videoPath;
  VideoPlayerWidget({Key key, this.videoPath}) : super(key: key);

  @override
  _VideoPlayerWidgetState createState() => _VideoPlayerWidgetState();
}

class _VideoPlayerWidgetState extends State<VideoPlayerWidget> {
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
