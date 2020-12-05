import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bounce/flutter_bounce.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:image_picker/image_picker.dart';
import 'package:looper/models/commentModel.dart';
import 'package:looper/services/notifications.dart';
import 'package:looper/services/personality.dart';
import 'package:looper/services/storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/database.dart';
import 'package:esys_flutter_share/esys_flutter_share.dart';
import 'package:video_player/video_player.dart';
import 'package:visibility_detector/visibility_detector.dart';
import 'package:looper/Pages/home-Pages/global/profile.dart';
import '../models/talentModel.dart' as tal;

class Talent extends StatefulWidget {
  final DocumentSnapshot data;
  Talent({Key key, this.data}) : super(key: key);

  @override
  _TalentState createState() => _TalentState();
}

class _TalentState extends State<Talent> {
  String _userId = '';
  tal.Talent _talent;
  String _userName;
  String _userImage;
  String _commentMedia;
  bool _isYes = false;
  bool _isNo = false;
  bool _isGoldenStar = false;
  bool _isClapped = false;
  int _yesCounter = 0;
  int _noCounter = 0;
  int _goldenStarCounter = 0;
  int _clapCounter = 0;
  Stream<QuerySnapshot> _blockedUsers;
  TextEditingController _textEditingController;
  VideoPlayerController _playerController;

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
      _talent = tal.Talent.fromDoc(widget.data);
      _isYes = _talent.yesCountedPeople.contains(_userId);
      _isNo = _talent.noCountedPeople.contains(_userId);
      _isGoldenStar = _talent.goldenStaredPeople.contains(_userId);
      _isClapped = _talent.clapedPeople.contains(_userId);
      _yesCounter = _talent.yesCount;
      _noCounter = _talent.noCount;
      _goldenStarCounter = _talent.goldenStars;
      _clapCounter = _talent.claps;
      _textEditingController = TextEditingController();
      _playerController = VideoPlayerController.network(_talent.videoUrl);
      _playerController.initialize().then((_) => setState(() {}));
      _playerController.setLooping(true);
      _playerController.play();
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
                      media: _media.first,
                      type: 1,
                      timestamp: _commentDate,
                    );
                    DatabaseService.addComment(
                      'talents',
                      _talent.id,
                      _comment,
                    );
                    NotificationsService.sendNotification(
                      'New comment',
                      '$_userName commented on your talant',
                      _talent.creatorId,
                      'talent',
                      _talent.id,
                    );
                    NotificationsService.sendNotificationToFollowers(
                      'New comment',
                      '$_userName commented on your talant',
                      _talent.creatorId,
                      'talent',
                      _talent.id,
                    );
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
                    final String _commentDate =
                        TimeOfDay.fromDateTime(DateTime.now()).format(context);
                    FocusScope.of(context).requestFocus(FocusNode());
                    Navigator.pop(context);
                    if (_commentMedia.isNotEmpty) {
                      await PersonalityService.setImageInput(_commentMedia);
                      _media = await StorageService.uploadMediaFile(
                        [File(_commentMedia)],
                        'comments/media',
                      );
                    }
                    final Comment _comment = Comment(
                      author: _userName,
                      authorImage: _userImage,
                      media: _media.first,
                      type: 1,
                      timestamp: _commentDate,
                    );
                    DatabaseService.addComment(
                      'talents',
                      _talent.id,
                      _comment,
                    );
                    NotificationsService.sendNotification(
                      'New comment',
                      '$_userName commented on your talant',
                      _talent.creatorId,
                      'talent',
                      _talent.id,
                    );
                    NotificationsService.sendNotificationToFollowers(
                      'New comment',
                      '$_userName commented on your talant',
                      _talent.creatorId,
                      'talent',
                      _talent.id,
                    );
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
                    _talent.commentCount.toString() + ' Comments',
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
                        .collection('talents')
                        .doc(_talent.id)
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
                                      backgroundColor: Colors.grey[400],
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
                                                progressIndicatorBuilder:
                                                    (context, url, progress) =>
                                                        Padding(
                                                  padding: EdgeInsets.all(8.0),
                                                  child: Center(
                                                    child: SizedBox(
                                                      height: 40,
                                                      width: 40,
                                                      child: CircularProgressIndicator(
                                                          backgroundColor:
                                                              Colors.grey,
                                                          valueColor:
                                                              AlwaysStoppedAnimation(
                                                                  Colors.black),
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
                                                        _talent.id,
                                                        'talents',
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
                                                        _talent.id,
                                                        'talents',
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
                                                          commentId:
                                                              _comment.id,
                                                          objectId: _talent.id,
                                                          userName: _userName,
                                                          userImage: _userImage,
                                                          userId: _userId,
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
                                                    _talent.id,
                                                    'talents',
                                                    _comment.id,
                                                    _userId,
                                                  );
                                                  PersonalityService
                                                      .setTextInput(
                                                    _comment.content,
                                                  );
                                                } else {
                                                  DatabaseService.unLikeComment(
                                                    _talent.id,
                                                    'talents',
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
                                                      userId: _userId,
                                                      commentId: _comment.id,
                                                      comment: _comment.content,
                                                      objectId: _talent.id,
                                                      userName: _userName,
                                                      userImage: _userImage,
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
                          authorImage: _userImage,
                          content: _textEditingController.text,
                          type: 0,
                          timestamp: _commentDate,
                        );
                        await PersonalityService.setTextInput(
                          _comment.content,
                        );
                        DatabaseService.addComment(
                          'talents',
                          _talent.id,
                          _comment,
                        );
                        NotificationsService.sendNotification(
                          'New comment',
                          '$_userName commented on your talant',
                          _talent.creatorId,
                          'talent',
                          _talent.id,
                        );
                        NotificationsService.sendNotificationToFollowers(
                          'New comment',
                          '$_userName commented on your talant',
                          _talent.creatorId,
                          'talent',
                          _talent.id,
                        );
                        _textEditingController.clear();
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
  void didUpdateWidget(Talent oldWidget) {
    if (_talent != tal.Talent.fromDoc(widget.data)) {
      setState(() {
        _talent = tal.Talent.fromDoc(widget.data);
      });
    }
    super.didUpdateWidget(oldWidget);
  }

  @override
  void dispose() {
    _playerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_talent != null) {
      return StreamBuilder(
          stream: _blockedUsers,
          builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return SizedBox.shrink();
            }

            final List<String> blockedUsers =
                snapshot.data.docs.map((e) => e.id).toList();
            if (blockedUsers.contains(_talent.creatorId)) {
              return Container();
            }
            return VisibilityDetector(
              key: Key(_talent.id),
              onVisibilityChanged: (VisibilityInfo info) {
                double _visibilePercentage = info.visibleFraction * 100;
                Timer(
                  Duration(milliseconds: 2300),
                  () {
                    if (!_talent.viewedPeople.contains(_userId)) {
                      if (_visibilePercentage == 100) {
                        DatabaseService.addView(
                          'talents',
                          _talent.id,
                          _userId,
                        );
                      }
                    }
                  },
                );
              },
              child: Stack(
                children: <Widget>[
                  !_playerController.value.initialized
                      ? Center(
                          child: CircularProgressIndicator(
                            strokeWidth: 1.2,
                            valueColor: AlwaysStoppedAnimation(Colors.white),
                          ),
                        )
                      : _talent.category != 'Acting'
                          ? SizedBox.expand(
                              child: FittedBox(
                                fit: BoxFit.cover,
                                child: SizedBox(
                                  width:
                                      _playerController.value.size?.width ?? 0,
                                  height:
                                      _playerController.value.size?.height ?? 0,
                                  child: VideoPlayer(_playerController),
                                ),
                              ),
                            )
                          : SizedBox.expand(
                              child: ShaderMask(
                                blendMode: _talent.movieFilter == 'normal'
                                    ? BlendMode.dst
                                    : _talent.movieFilter == 'black&white'
                                        ? BlendMode.hue
                                        : _talent.movieFilter ==
                                                    'yellow&brown' ||
                                                _talent.movieFilter == 'pinky'
                                            ? BlendMode.color
                                            : _talent.movieFilter == 'red'
                                                ? BlendMode.colorBurn
                                                : _talent.movieFilter == 'x-ray'
                                                    ? BlendMode.difference
                                                    : BlendMode.exclusion,
                                shaderCallback: (bounds) => LinearGradient(
                                  colors: _talent.movieFilter == 'normal'
                                      ? [Colors.white, Colors.white]
                                      : _talent.movieFilter == 'black&white'
                                          ? [Colors.black, Colors.white]
                                          : _talent.movieFilter ==
                                                  'yellow&brown'
                                              ? [
                                                  Color(0xFF704214),
                                                  Colors.brown
                                                ]
                                              : _talent.movieFilter == 'red'
                                                  ? [
                                                      Colors.red,
                                                      Colors.red[700]
                                                    ]
                                                  : _talent.movieFilter ==
                                                          'pinky'
                                                      ? [
                                                          Color(0xFFF8EFB6),
                                                          Color(0xFFD09C8E),
                                                          Color(0xFFD77067),
                                                          Color(0xFF724559),
                                                        ]
                                                      : _talent.movieFilter ==
                                                              'x-ray'
                                                          ? [
                                                              Color(0xFF191a1b),
                                                              Color(0xFFc8dde7),
                                                              Color(0xFFa8d3e3),
                                                              Color(0xFF394346),
                                                              Color(0xFF293135),
                                                            ]
                                                          : [
                                                              Colors.yellow,
                                                              Colors.red,
                                                              Colors
                                                                  .greenAccent,
                                                            ],
                                ).createShader(
                                  bounds,
                                ),
                                child: FittedBox(
                                  fit: BoxFit.cover,
                                  child: SizedBox(
                                    width:
                                        _playerController.value.size?.width ??
                                            0,
                                    height:
                                        _playerController.value.size?.height ??
                                            0,
                                    child: VideoPlayer(_playerController),
                                  ),
                                ),
                              ),
                            ),
                  Align(
                    alignment: Alignment.topCenter,
                    child: Padding(
                      padding: EdgeInsets.only(top: 30, right: 15, left: 15),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: <Widget>[
                          Row(
                            children: <Widget>[
                              ClipRRect(
                                borderRadius: BorderRadius.circular(30),
                                child: GestureDetector(
                                  onTap: () {
                                    Navigator.of(context).push(
                                      MaterialPageRoute(
                                        builder: (context) => ProfilePage(
                                          userId: _talent.creatorId,
                                        ),
                                      ),
                                    );
                                  },
                                  child: CachedNetworkImage(
                                    imageUrl: _talent.creatorProfileImage,
                                    placeholder: (context, url) =>
                                        Container(color: Colors.grey[400]),
                                    fit: BoxFit.cover,
                                    height: 45,
                                    width: 45,
                                  ),
                                ),
                              ),
                              SizedBox(width: 10),
                              IntrinsicHeight(
                                child: Column(
                                  children: <Widget>[
                                    Text(
                                      _talent.creatorName.toString(),
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    SizedBox(height: 3),
                                    _talent.talentName != null
                                        ? Text(
                                            '# ${_talent.talentName.toString()}',
                                            style: TextStyle(
                                                color: Colors.grey[800]),
                                          )
                                        : Container(),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          SizedBox(width: 5),
                          Container(
                            width: MediaQuery.of(context).size.width / 5,
                            height: 30,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(30),
                              border: Border.all(
                                color: Colors.white,
                                width: 1.2,
                              ),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: <Widget>[
                                Icon(
                                  Icons.remove_red_eye,
                                  size: 14,
                                  color: Colors.white,
                                ),
                                SizedBox(width: 5),
                                Text(
                                  _talent.viewsCount.toString(),
                                  style: TextStyle(color: Colors.white),
                                ),
                              ],
                            ),
                          ),
                          Bounce(
                            duration: Duration(milliseconds: 100),
                            onPressed: () {
                              DatabaseService.saveContent(
                                'saved-talents',
                                _talent.id,
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
                          Bounce(
                            duration: Duration(milliseconds: 100),
                            onPressed: () async {
                              var request = await HttpClient()
                                  .getUrl(Uri.parse(_talent.videoUrl));
                              var response = await request.close();
                              Uint8List bytes =
                                  await consolidateHttpClientResponseBytes(
                                      response);
                              Share.file(
                                'from ${_talent.creatorName}',
                                'media',
                                bytes,
                                'video/mp4',
                              );
                              PersonalityService.setVideoInput(
                                _talent.videoUrl,
                              );
                            },
                            child: Padding(
                              padding: const EdgeInsets.all(8.0),
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
                  Padding(
                    padding: EdgeInsets.symmetric(
                      vertical: 10,
                      horizontal: 10,
                    ),
                    child: Align(
                      alignment: Alignment(0.95, 0.5),
                      child: IntrinsicHeight(
                        child: Column(
                          children: <Widget>[
                            Bounce(
                              duration: Duration(milliseconds: 100),
                              onPressed: () {
                                setState(() {
                                  if (!_isGoldenStar) {
                                    setState(() {
                                      _isGoldenStar = true;
                                      _goldenStarCounter++;
                                    });
                                    DatabaseService.addGoldenStar(
                                      _talent.id,
                                      _userId,
                                    );
                                    NotificationsService.sendNotification(
                                      'New Golden Star ✨',
                                      '$_userName gave a golden star to  your talent',
                                      _talent.creatorId,
                                      'talent',
                                      _talent.id,
                                    );
                                    PersonalityService.setTextInput(
                                      'Wow i am pretty impressed by',
                                    );
                                    PersonalityService.setVideoInput(
                                      _talent.videoUrl,
                                    );
                                  } else {
                                    setState(() {
                                      _isGoldenStar = false;
                                      _goldenStarCounter--;
                                    });
                                    DatabaseService.removeGoldenStar(
                                      _talent.id,
                                      _userId,
                                    );
                                  }
                                });
                              },
                              child: Column(
                                children: <Widget>[
                                  Container(
                                    padding: EdgeInsets.all(7),
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: _isGoldenStar
                                          ? Colors.white
                                          : Colors.transparent,
                                      border: Border.all(color: Colors.white),
                                    ),
                                    child: Icon(
                                      _isGoldenStar
                                          ? Icons.star
                                          : Icons.star_border,
                                      color: Colors.yellow[900],
                                      size: 30,
                                    ),
                                  ),
                                  SizedBox(height: 7),
                                  Text(
                                    _goldenStarCounter.toString(),
                                    style: TextStyle(color: Colors.yellow[900]),
                                  ),
                                ],
                              ),
                            ),
                            SizedBox(height: 16),
                            Bounce(
                              duration: Duration(milliseconds: 100),
                              onPressed: () {
                                setState(() {
                                  if (!_isClapped) {
                                    setState(() {
                                      _isClapped = true;
                                      _clapCounter++;
                                    });
                                    DatabaseService.clapToTalent(
                                      _talent.id,
                                      _userId,
                                    );
                                    NotificationsService.sendNotification(
                                      'New Clap 👏',
                                      '$_userName clapped to  your talent',
                                      _talent.creatorId,
                                      'talent',
                                      _talent.id,
                                    );
                                    PersonalityService.setTextInput(
                                        'I really like');
                                    PersonalityService.setVideoInput(
                                      _talent.videoUrl,
                                    );
                                  } else {
                                    return;
                                  }
                                });
                              },
                              child: Column(
                                children: <Widget>[
                                  Container(
                                    padding: EdgeInsets.all(10),
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: !_isClapped
                                          ? Colors.transparent
                                          : Colors.white,
                                      border: Border.all(color: Colors.white),
                                    ),
                                    child: Image.asset(
                                      'assets/clap.png',
                                      color: !_isClapped
                                          ? Colors.white
                                          : Colors.black,
                                      height: 28,
                                      width: 28,
                                    ),
                                  ),
                                  SizedBox(height: 10),
                                  Text(
                                    _clapCounter.toString(),
                                    style: TextStyle(color: Colors.white),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  Padding(
                    padding: EdgeInsets.only(bottom: 10),
                    child: Align(
                      alignment: Alignment.bottomCenter,
                      child: IntrinsicWidth(
                        child: Row(
                          children: <Widget>[
                            Bounce(
                              onPressed: openCommentSection,
                              duration: Duration(milliseconds: 100),
                              child: Container(
                                width: MediaQuery.of(context).size.width / 2,
                                height: 45,
                                alignment: Alignment.centerLeft,
                                margin: EdgeInsets.only(bottom: 16, left: 4),
                                padding: EdgeInsets.only(left: 16),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(30),
                                  border: Border.all(color: Colors.white),
                                ),
                                child: Text(
                                  'Comment...',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                  ),
                                ),
                              ),
                            ),
                            IntrinsicWidth(
                              child: Row(
                                children: <Widget>[
                                  Bounce(
                                    duration: Duration(milliseconds: 100),
                                    onPressed: () {
                                      setState(() {
                                        if (_isYes) {
                                          _isYes = false;
                                          _yesCounter--;

                                          DatabaseService.removeYes(
                                            _talent.id,
                                            _userId,
                                          );
                                        }
                                        if (!_isNo) {
                                          _isNo = true;
                                          _noCounter++;
                                          DatabaseService.addNo(
                                            _talent.id,
                                            _userId,
                                          );

                                          PersonalityService.setTextInput(
                                            'I would give a no for',
                                          );
                                          PersonalityService.setVideoInput(
                                            _talent.videoUrl,
                                          );
                                        } else {
                                          _isNo = false;
                                          _noCounter--;

                                          DatabaseService.removeNo(
                                            _talent.id,
                                            _userId,
                                          );
                                        }
                                      });
                                    },
                                    child: IntrinsicHeight(
                                      child: Column(
                                        children: <Widget>[
                                          Container(
                                            padding: EdgeInsets.all(10),
                                            margin: EdgeInsets.symmetric(
                                                horizontal: 20),
                                            decoration: BoxDecoration(
                                              shape: BoxShape.circle,
                                              color: !_isNo
                                                  ? Colors.transparent
                                                  : Colors.white,
                                              border: Border.all(
                                                  color: Colors.white),
                                            ),
                                            child: Icon(
                                              Icons.thumb_down,
                                              color: !_isNo
                                                  ? Colors.white
                                                  : Colors.black,
                                            ),
                                          ),
                                          SizedBox(height: 7),
                                          Text(
                                            '$_noCounter No',
                                            style:
                                                TextStyle(color: Colors.white),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                  Bounce(
                                    duration: Duration(milliseconds: 100),
                                    onPressed: () {
                                      setState(() {
                                        if (!_isYes) {
                                          if (_isNo) {
                                            _isNo = false;
                                            _noCounter--;

                                            DatabaseService.removeNo(
                                              _talent.id,
                                              _userId,
                                            );
                                          }
                                          _isYes = true;
                                          _yesCounter++;

                                          DatabaseService.addYes(
                                            _talent.id,
                                            _userId,
                                          );
                                          NotificationsService.sendNotification(
                                            'New YES 👍',
                                            '$_userName gave you a YES to  your talent',
                                            _talent.creatorId,
                                            'talent',
                                            _talent.id,
                                          );
                                          NotificationsService
                                              .sendNotificationToFollowers(
                                            'New YES 👍',
                                            '$_userName gave you a YES to  a talent',
                                            _talent.creatorId,
                                            'talent',
                                            _talent.id,
                                          );
                                        } else {
                                          _isYes = false;
                                          _yesCounter--;
                                          DatabaseService.removeYes(
                                            _talent.id,
                                            _userId,
                                          );
                                        }
                                      });
                                    },
                                    child: IntrinsicHeight(
                                      child: Column(
                                        children: <Widget>[
                                          Container(
                                            padding: EdgeInsets.all(10),
                                            margin: EdgeInsets.symmetric(
                                                horizontal: 20),
                                            decoration: BoxDecoration(
                                              shape: BoxShape.circle,
                                              color: !_isYes
                                                  ? Colors.transparent
                                                  : Colors.white,
                                              border: Border.all(
                                                  color: Colors.white),
                                            ),
                                            child: Icon(
                                              Icons.thumb_up,
                                              color: !_isYes
                                                  ? Colors.white
                                                  : Colors.black,
                                            ),
                                          ),
                                          SizedBox(height: 7),
                                          Text(
                                            '$_yesCounter Yes',
                                            style:
                                                TextStyle(color: Colors.white),
                                          )
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
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
                    .collection('talents')
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
                                          'talents',
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
                                          'talents',
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
                      'talents',
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
