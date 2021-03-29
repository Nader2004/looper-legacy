import 'dart:async';
import 'dart:ui';
import 'dart:io';
import 'dart:typed_data';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:esys_flutter_share/esys_flutter_share.dart';
import 'package:flutter_linkify/flutter_linkify.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:image_picker/image_picker.dart';
import 'package:looper/models/commentModel.dart';
import 'package:looper/services/notifications.dart';
import 'package:looper/services/personality.dart';
import 'package:looper/services/storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:visibility_detector/visibility_detector.dart';
import 'package:flutter_bounce/flutter_bounce.dart';
import '../services/database.dart';
import 'package:video_player/video_player.dart';
import 'package:looper/Pages/home-Pages/global/profile.dart';
import '../models/challengeModel.dart' as challenge;

class Challenge extends StatefulWidget {
  final DocumentSnapshot data;
  Challenge({Key key, this.data}) : super(key: key);

  @override
  _ChallengeState createState() => _ChallengeState();
}

class _ChallengeState extends State<Challenge> {
  String _userId = '';
  String _userName;
  String _userImage;
  String _commentMedia;
  bool _isLike = false;
  bool _isDisLike = false;
  bool _isNormal = false;
  int _likeCounter = 0;
  int _disLikeCounter = 0;
  int _normalCounter = 0;
  int _commentCounter = 0;
  challenge.Challenge _challenge;
  Stream<QuerySnapshot> _blockedUsers;
  VideoPlayerController _controller;
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
      _challenge = challenge.Challenge.fromDoc(widget.data);
      _isLike = _challenge.likedPeople.contains(_userId);
      _isDisLike = _challenge.disLikedPeople.contains(_userId);
      _isNormal = _challenge.neutralPeople.contains(_userId);
      _likeCounter = _challenge.likes;
      _disLikeCounter = _challenge.disLikes;
      _normalCounter = _challenge.neutral;
      _commentCounter = _challenge.comments;
      _textEditingController = TextEditingController();
      _controller = VideoPlayerController.network(_challenge.videoUrl);
      _controller.initialize().then((value) => setState(() {}));
      _controller.setLooping(true);
      _controller.play();
    });
    final FirebaseFirestore _firestore = FirebaseFirestore.instance;
    final DocumentSnapshot _snapshot =
        await _firestore.collection('users').doc(_userId).get();
    _userName = _snapshot?.data()['username'];
    _userImage = _snapshot?.data()['profilePictureUrl'];
  }

  void _showMediaPicker() {
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
                      authorImage: _userImage,
                      authorId: _userId,
                      media: _media.first,
                      type: 1,
                      timestamp: _commentDate,
                    );
                    DatabaseService.addComment(
                      'challenge',
                      _challenge.id,
                      _comment,
                    );
                    NotificationsService.sendNotification(
                      'New comment',
                      '$_userName commented on your challenge',
                      _challenge.creatorId,
                      'challenge',
                      _challenge.creatorId,
                    );
                    NotificationsService.sendNotificationToFollowers(
                      'New comment',
                      '$_userName commented on a challenge',
                      _challenge.creatorId,
                      'challenge',
                      _challenge.creatorId,
                    );
                  }
                  setState(() {
                    _commentCounter++;
                  });
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
                      'challenge',
                      _challenge.id,
                      _comment,
                    );
                    NotificationsService.sendNotification(
                      'New comment',
                      '$_userName commented on your challenge',
                      _challenge.creatorId,
                      'challenge',
                      _challenge.creatorId,
                    );
                    NotificationsService.sendNotificationToFollowers(
                      'New comment',
                      '$_userName commented on a challenge',
                      _challenge.creatorId,
                      'challenge',
                      _challenge.creatorId,
                    );
                  }
                  setState(() {
                    _commentCounter++;
                  });
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
                    _commentCounter.toString() + ' Comments',
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
                        .collection('challenge')
                        .doc(_challenge.id)
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
                                  CircleAvatar(
                                    radius: 20,
                                    backgroundColor: Colors.grey[400],
                                    backgroundImage: CachedNetworkImageProvider(
                                      _comment.authorImage,
                                    ),
                                  ),
                                  SizedBox(width: _comment.type == 1 ? 10 : 5),
                                  _comment.type == 1
                                      ? Stack(
                                          children: <Widget>[
                                            ClipRRect(
                                              borderRadius:
                                                  BorderRadius.circular(20),
                                              child: GestureDetector(
                                                onTap: () {
                                                  Navigator.of(context).push(
                                                    MaterialPageRoute(
                                                      builder: (context) =>
                                                          ProfilePage(
                                                        userId:
                                                            _comment.authorId,
                                                      ),
                                                    ),
                                                  );
                                                },
                                                child: CachedNetworkImage(
                                                  imageUrl: _comment.media,
                                                  fit: BoxFit.cover,
                                                  progressIndicatorBuilder:
                                                      (context, url,
                                                              progress) =>
                                                          Padding(
                                                    padding:
                                                        EdgeInsets.all(8.0),
                                                    child: Center(
                                                      child: SizedBox(
                                                        height: 40,
                                                        width: 40,
                                                        child: CircularProgressIndicator(
                                                            backgroundColor:
                                                                Colors.grey,
                                                            valueColor:
                                                                AlwaysStoppedAnimation(
                                                                    Colors
                                                                        .black),
                                                            value: progress
                                                                .progress),
                                                      ),
                                                    ),
                                                  ),
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
                                                  child: SelectableLinkify(
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
                                                    text: _comment.content,
                                                  ),
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
                                                        _challenge.id,
                                                        'challenge',
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
                                                        _challenge.id,
                                                        'challenge',
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
                                                          comment:
                                                              _comment.content,
                                                          objectId:
                                                              _challenge.id,
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
                                                    _challenge.id,
                                                    'challenge',
                                                    _comment.id,
                                                    _userId,
                                                  );
                                                  PersonalityService
                                                      .setTextInput(
                                                    _comment.content,
                                                  );
                                                } else {
                                                  DatabaseService.unLikeComment(
                                                    _challenge.id,
                                                    'challenge',
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
                                                      objectId: _challenge.id,
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
                          _showMediaPicker();
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
                          'challenge',
                          _challenge.id,
                          _comment,
                        );
                        NotificationsService.sendNotification(
                          'New comment',
                          '$_userName commented on your challenge',
                          _challenge.creatorId,
                          'challenge',
                          _challenge.creatorId,
                        );
                        NotificationsService.sendNotificationToFollowers(
                          'New comment',
                          '$_userName commented on a challenge',
                          _challenge.creatorId,
                          'challenge',
                          _challenge.creatorId,
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
  void didUpdateWidget(Challenge oldWidget) {
    if (_challenge != challenge.Challenge.fromDoc(widget.data)) {
      setState(() {
        _challenge = challenge.Challenge.fromDoc(widget.data);
      });
    }
    super.didUpdateWidget(oldWidget);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_challenge != null) {
      return StreamBuilder(
          stream: _blockedUsers,
          builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return SizedBox.shrink();
            }

            final List<String> blockedUsers =
                snapshot.data.docs.map((e) => e.id).toList();
            if (blockedUsers.contains(_challenge.creatorId)) {
              return Container();
            }
            return VisibilityDetector(
              key: Key(_challenge.id),
              onVisibilityChanged: (VisibilityInfo info) {
                double _visibilePercentage = info.visibleFraction * 100;
                Timer(
                  Duration(milliseconds: 2300),
                  () {
                    if (!_challenge.viewedPeople.contains(_userId)) {
                      if (_visibilePercentage == 100) {
                        DatabaseService.addView(
                          'challenge',
                          _challenge.id,
                          _userId,
                        );
                      }
                    }
                  },
                );
              },
              child: Stack(
                children: <Widget>[
                  !_controller.value.initialized
                      ? Center(
                          child: CircularProgressIndicator(
                            strokeWidth: 1.2,
                            valueColor: AlwaysStoppedAnimation(Colors.white),
                          ),
                        )
                      : SizedBox.expand(
                          child: FittedBox(
                            fit: BoxFit.cover,
                            child: SizedBox(
                              width: _controller.value.size?.width ?? 0,
                              height: _controller.value.size?.height ?? 0,
                              child: VideoPlayer(_controller),
                            ),
                          ),
                        ),
                  !_controller.value.initialized
                      ? Container()
                      : Positioned.fill(
                          child: BackdropFilter(
                            filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                            child: Container(
                              color: Colors.black.withOpacity(0),
                            ),
                          ),
                        ),
                  Align(
                    alignment: Alignment.topCenter,
                    child: Padding(
                      padding: EdgeInsets.all(30),
                      child: IntrinsicWidth(
                        child: Row(
                          children: <Widget>[
                            Padding(
                              padding: EdgeInsets.symmetric(horizontal: 30),
                              child: Bounce(
                                duration: Duration(milliseconds: 100),
                                onPressed: () {
                                  DatabaseService.saveContent(
                                    'saved-challenges',
                                    _challenge.id,
                                  );
                                },
                                child: Container(
                                  padding: EdgeInsets.all(7),
                                  child: Icon(
                                    Icons.bookmark,
                                    color: Colors.white,
                                    size: 28,
                                  ),
                                ),
                              ),
                            ),
                            IntrinsicHeight(
                              child: Column(
                                children: <Widget>[
                                  GestureDetector(
                                    onTap: () {
                                      Navigator.of(context).push(
                                        MaterialPageRoute(
                                          builder: (context) => ProfilePage(
                                            userId: _challenge.creatorId,
                                          ),
                                        ),
                                      );
                                    },
                                    child: CircleAvatar(
                                      backgroundColor: Colors.grey[400],
                                      backgroundImage:
                                          CachedNetworkImageProvider(
                                        _challenge.creatorProfileImage,
                                      ),
                                      radius: 40,
                                    ),
                                  ),
                                  SizedBox(height: 5),
                                  Text(
                                    _challenge.creatorName,
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 25,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  _challenge.category != ''
                                      ? SizedBox(height: 5)
                                      : SizedBox.shrink(),
                                  _challenge.category != ''
                                      ? Text(
                                          _challenge.category,
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 20,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        )
                                      : SizedBox.shrink()
                                ],
                              ),
                            ),
                            Padding(
                              padding: EdgeInsets.symmetric(horizontal: 30),
                              child: Bounce(
                                duration: Duration(milliseconds: 100),
                                onPressed: () async {
                                  var request = await HttpClient()
                                      .getUrl(Uri.parse(_challenge.videoUrl));
                                  var response = await request.close();
                                  Uint8List bytes =
                                      await consolidateHttpClientResponseBytes(
                                          response);
                                  Share.file(
                                    'from ${_challenge.creatorName}',
                                    'media',
                                    bytes,
                                    'video/mp4',
                                  );
                                  PersonalityService.setVideoInput(
                                      _challenge.videoUrl);
                                },
                                child: Container(
                                  padding: EdgeInsets.all(7),
                                  child: Icon(
                                    Icons.share,
                                    color: Colors.white,
                                    size: 28,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  Align(
                    alignment: Alignment(0.0, 0.8),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: <Widget>[
                        IntrinsicHeight(
                          child: Bounce(
                            duration: Duration(milliseconds: 100),
                            onPressed: () {
                              setState(() {
                                if (!_isDisLike) {
                                  if (_isLike) {
                                    _isLike = false;
                                    _likeCounter--;
                                    DatabaseService.unLike(
                                      'challenge',
                                      _challenge.id,
                                      _userId,
                                    );
                                    PersonalityService.setTextInput(
                                        'I dislike');
                                    PersonalityService.setVideoInput(
                                      _challenge.videoUrl,
                                    );
                                  }
                                  if (_isNormal) {
                                    _isNormal = false;
                                    _normalCounter--;
                                    DatabaseService.removeNeutral(
                                      _challenge.id,
                                      _userId,
                                    );
                                  }
                                  _isDisLike = true;
                                  _disLikeCounter++;
                                  DatabaseService.disLike(
                                    'challenge',
                                    _challenge.id,
                                    _userId,
                                  );
                                } else {
                                  _isDisLike = false;
                                  _disLikeCounter--;
                                  DatabaseService.undisLike(
                                    'challenge',
                                    _challenge.id,
                                    _userId,
                                  );
                                }
                              });
                            },
                            child: Column(
                              children: <Widget>[
                                Container(
                                  padding: EdgeInsets.all(12),
                                  child: Icon(
                                    Icons.thumb_down,
                                    color: _isDisLike
                                        ? Colors.black
                                        : Colors.white,
                                  ),
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: _isDisLike
                                        ? Colors.white
                                        : Colors.transparent,
                                    border: Border.all(color: Colors.white),
                                  ),
                                ),
                                SizedBox(height: 7),
                                Text(
                                  _disLikeCounter.toString(),
                                  style: TextStyle(color: Colors.white),
                                ),
                              ],
                            ),
                          ),
                        ),
                        IntrinsicHeight(
                          child: Bounce(
                            duration: Duration(milliseconds: 100),
                            onPressed: () {
                              setState(() {
                                if (!_isNormal) {
                                  if (_isLike) {
                                    _isLike = false;
                                    _likeCounter--;
                                    DatabaseService.unLike(
                                      'challenge',
                                      _challenge.id,
                                      _userId,
                                    );
                                  }
                                  if (_isDisLike) {
                                    _isDisLike = false;
                                    _disLikeCounter--;
                                    DatabaseService.undisLike(
                                      'challenge',
                                      _challenge.id,
                                      _userId,
                                    );
                                  }
                                  _isNormal = true;
                                  _normalCounter++;
                                  DatabaseService.addNeutral(
                                    _challenge.id,
                                    _userId,
                                  );
                                  NotificationsService.sendNotification(
                                    'New Reaction 👀',
                                    '$_userName reacted normal to  your challenge',
                                    _challenge.creatorId,
                                    'challenge',
                                    _challenge.id,
                                  );
                                  NotificationsService
                                      .sendNotificationToFollowers(
                                    'New Reaction 👀',
                                    '$_userName reacted normal to  a challenge',
                                    _challenge.creatorId,
                                    'challenge',
                                    _challenge.id,
                                  );
                                  PersonalityService.setTextInput(
                                      'I feel ok with');
                                  PersonalityService.setVideoInput(
                                    _challenge.videoUrl,
                                  );
                                } else {
                                  _isNormal = false;
                                  _normalCounter--;
                                  DatabaseService.removeNeutral(
                                    _challenge.id,
                                    _userId,
                                  );
                                }
                              });
                            },
                            child: Column(
                              children: <Widget>[
                                Container(
                                  padding: EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: _isNormal
                                        ? Colors.white
                                        : Colors.transparent,
                                    border: Border.all(color: Colors.white),
                                  ),
                                  child: Icon(
                                    Icons.thumbs_up_down,
                                    color:
                                        _isNormal ? Colors.black : Colors.white,
                                  ),
                                ),
                                SizedBox(height: 7),
                                Text(
                                  _normalCounter.toString(),
                                  style: TextStyle(color: Colors.white),
                                ),
                              ],
                            ),
                          ),
                        ),
                        Bounce(
                          duration: Duration(milliseconds: 100),
                          onPressed: () {
                            setState(() {
                              if (!_isLike) {
                                if (_isDisLike) {
                                  _isDisLike = false;
                                  _disLikeCounter--;
                                  DatabaseService.undisLike(
                                    'challenge',
                                    _challenge.id,
                                    _userId,
                                  );
                                }
                                if (_isNormal) {
                                  _isNormal = false;
                                  _normalCounter--;
                                  DatabaseService.removeNeutral(
                                    _challenge.id,
                                    _userId,
                                  );
                                }
                                _isLike = true;
                                _likeCounter++;
                                DatabaseService.like(
                                  'challenge',
                                  _challenge.id,
                                  _userId,
                                );
                                NotificationsService.sendNotification(
                                  'New Like 👍',
                                  '$_userName liked  your challenge',
                                  _challenge.creatorId,
                                  'challenge',
                                  _challenge.id,
                                );
                                NotificationsService
                                    .sendNotificationToFollowers(
                                  'New Like 👍',
                                  '$_userName liked  a challenge',
                                  _challenge.creatorId,
                                  'challenge',
                                  _challenge.id,
                                );
                                PersonalityService.setTextInput('I like');
                                PersonalityService.setVideoInput(
                                  _challenge.videoUrl,
                                );
                              } else {
                                _isLike = false;
                                _likeCounter--;
                                DatabaseService.unLike(
                                  'challenge',
                                  _challenge.id,
                                  _userId,
                                );
                              }
                            });
                          },
                          child: IntrinsicHeight(
                            child: Column(
                              children: <Widget>[
                                Container(
                                  padding: EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: _isLike
                                        ? Colors.white
                                        : Colors.transparent,
                                    border: Border.all(color: Colors.white),
                                  ),
                                  child: Icon(
                                    Icons.thumb_up,
                                    color:
                                        _isLike ? Colors.black : Colors.white,
                                  ),
                                ),
                                SizedBox(height: 7),
                                Text(
                                  _likeCounter.toString(),
                                  style: TextStyle(color: Colors.white),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Align(
                    alignment: Alignment.bottomCenter,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: <Widget>[
                        Container(
                          width: MediaQuery.of(context).size.width / 5,
                          height: 30,
                          margin: EdgeInsets.all(8),
                          padding: EdgeInsets.all(5),
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(30),
                            border: Border.all(
                              color: Colors.white,
                              width: 1.5,
                            ),
                          ),
                          child: Text(
                            '${_challenge.viewsCount} VIEWS',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        SizedBox(width: 10),
                        Bounce(
                          onPressed: openCommentSection,
                          duration: Duration(milliseconds: 100),
                          child: Container(
                            width: MediaQuery.of(context).size.width / 4,
                            height: 30,
                            margin: EdgeInsets.all(8),
                            padding: EdgeInsets.all(5),
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(30),
                              border: Border.all(
                                color: Colors.white,
                                width: 1.5,
                              ),
                            ),
                            child: Text(
                              '$_commentCounter COMMENTS',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  !_controller.value.initialized
                      ? Container()
                      : Center(
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: Container(
                              width: MediaQuery.of(context).size.width - 20,
                              height: MediaQuery.of(context).size.height / 1.8,
                              child: OverflowBox(
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
                        ),
                ],
              ),
            );
          });
    } else {
      return SizedBox.shrink();
    }
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
                    .collection('challenge')
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
                                      SelectableLinkify(
                                        onOpen: (link) async {
                                          if (await canLaunch(link.url)) {
                                            await launch(link.url);
                                          } else {
                                            Fluttertoast.showToast(
                                              msg: 'can not launch this link',
                                            );
                                          }
                                        },
                                        text: _comment.content,
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
                                          'challenge',
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
                                          'challenge',
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
                      'challenge',
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
