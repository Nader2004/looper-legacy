import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bounce/flutter_bounce.dart';
import 'package:flutter_linkify/flutter_linkify.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:image_picker/image_picker.dart';
import 'package:looper/models/commentModel.dart';
import 'package:looper/services/notifications.dart';
import 'package:looper/services/personality.dart';
import 'package:looper/services/storage.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:video_player/video_player.dart';
import 'package:visibility_detector/visibility_detector.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:looper/Pages/home-Pages/global/profile.dart';
import '../models/sportModel.dart' as modl;
import '../services/database.dart';

class Sport extends StatefulWidget {
  final DocumentSnapshot data;
  Sport({Key key, this.data}) : super(key: key);

  @override
  _SportState createState() => _SportState();
}

class _SportState extends State<Sport> {
  modl.Sport _sport;
  String _commentMedia;
  String _userName;
  String _userImage;
  String _userId = '';
  bool _isLike = false;
  int _likeCounter = 0;
  int _commentCounter = 0;
  Stream<QuerySnapshot> _blockedUsers;
  VideoPlayerController _videoController;
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
      _sport = modl.Sport.fromDoc(widget.data);
      _isLike = _sport.likedPeople.contains(_userId);
      _likeCounter = _sport.likes;
      _commentCounter = _sport.commentCount;
      _videoController = VideoPlayerController.network(_sport.videoUrl);
      _videoController.initialize()..then((_) => setState(() {}));
      _videoController.play();
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
                      authorId: _userId,
                      authorImage: _userImage,
                      media: _media.first,
                      type: 1,
                      timestamp: _commentDate,
                    );
                    DatabaseService.addComment(
                      'sports',
                      _sport.id,
                      _comment,
                    );
                    NotificationsService.sendNotification(
                      'New comment',
                      '$_userName commented on your sport',
                      _sport.creatorId,
                      'sport',
                      _sport.id,
                    );
                    NotificationsService.sendNotificationToFollowers(
                      'New comment',
                      '$_userName commented on a sport',
                      _sport.creatorId,
                      'sport',
                      _sport.id,
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
                      'sports',
                      _sport.id,
                      _comment,
                    );
                    NotificationsService.sendNotification(
                      'New comment',
                      '$_userName commented on your talant',
                      _sport.creatorId,
                      'sport',
                      _sport.id,
                    );
                    NotificationsService.sendNotificationToFollowers(
                      'New comment',
                      '$_userName commented on a talant',
                      _sport.creatorId,
                      'sport',
                      _sport.id,
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
                        .collection('sports')
                        .doc(_sport.id)
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
                                      backgroundColor: Colors.grey,
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
                                                        _sport.id,
                                                        'sports',
                                                        _comment.id,
                                                        _userId,
                                                      );
                                                      NotificationsService
                                                          .sendNotificationToFollowers(
                                                        'New Like ❤',
                                                        '$_userName liked your sport',
                                                        _sport.creatorId,
                                                        'sport',
                                                        _sport.id,
                                                      );
                                                      NotificationsService
                                                          .sendNotificationToFollowers(
                                                        'New Like ❤',
                                                        '$_userName liked a sport',
                                                        _sport.creatorId,
                                                        'sport',
                                                        _sport.id,
                                                      );
                                                      PersonalityService
                                                          .setImageInput(
                                                        _comment.media,
                                                      );
                                                    } else {
                                                      DatabaseService
                                                          .unLikeComment(
                                                        _sport.id,
                                                        'sports',
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
                                                          objectId: _sport.id,
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
                                                    _sport.id,
                                                    'sports',
                                                    _comment.id,
                                                    _userId,
                                                  );
                                                  PersonalityService
                                                      .setTextInput(
                                                    _comment.content,
                                                  );
                                                } else {
                                                  DatabaseService.unLikeComment(
                                                    _sport.id,
                                                    'sports',
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
                                                      objectId: _sport.id,
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
                          'sports',
                          _sport.id,
                          _comment,
                        );
                        NotificationsService.sendNotification(
                          'New comment',
                          '$_userName commented on your sport',
                          _sport.creatorId,
                          'sport',
                          _sport.id,
                        );
                        NotificationsService.sendNotificationToFollowers(
                          'New comment',
                          '$_userName commented on a sport',
                          _sport.creatorId,
                          'sport',
                          _sport.id,
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
  void didUpdateWidget(Sport oldWidget) {
    if (_sport != modl.Sport.fromDoc(widget.data)) {
      setState(() {
        _sport = modl.Sport.fromDoc(widget.data);
      });
    }
    super.didUpdateWidget(oldWidget);
  }

  @override
  void dispose() {
    _videoController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_sport != null) {
      return StreamBuilder(
          stream: _blockedUsers,
          builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return SizedBox.shrink();
            }

            final List<String> blockedUsers =
                snapshot.data.docs.map((e) => e.id).toList();
            if (blockedUsers.contains(_sport.creatorId)) {
              return Container();
            }
            return VisibilityDetector(
              key: Key(_sport.id),
              onVisibilityChanged: (VisibilityInfo info) {
                double _visibilePercentage = info.visibleFraction * 100;
                Timer(
                  Duration(milliseconds: 2300),
                  () {
                    if (!_sport.viewedPeople.contains(_userId)) {
                      if (_visibilePercentage == 100) {
                        DatabaseService.addView(
                          'sports',
                          _sport.id,
                          _userId,
                        );
                      }
                    }
                  },
                );
              },
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: Container(
                    color: !_videoController.value.initialized
                        ? Colors.black
                        : Colors.transparent,
                    child: Stack(
                      children: <Widget>[
                        !_videoController.value.initialized
                            ? Center(
                                child: Padding(
                                  padding: EdgeInsets.symmetric(
                                    vertical:
                                        MediaQuery.of(context).size.width / 2,
                                  ),
                                  child: CircularProgressIndicator(
                                    strokeWidth: 1.2,
                                    valueColor:
                                        AlwaysStoppedAnimation(Colors.white),
                                  ),
                                ),
                              )
                            : Container(
                                height: MediaQuery.of(context).size.width * 1.2,
                                width: MediaQuery.of(context).size.width,
                                child: OverflowBox(
                                  alignment: Alignment.center,
                                  child: FittedBox(
                                    fit: BoxFit.cover,
                                    child: Container(
                                      width: MediaQuery.of(context).size.width,
                                      height: MediaQuery.of(context)
                                              .size
                                              .width /
                                          _videoController.value.aspectRatio,
                                      child: VideoPlayer(_videoController),
                                    ),
                                  ),
                                ),
                              ),
                        Positioned(
                          top: 10,
                          left: 10,
                          child: Row(
                            children: <Widget>[
                              Container(
                                width: 50,
                                height: 50,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border:
                                      Border.all(color: Colors.white, width: 2),
                                ),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(50),
                                  child: GestureDetector(
                                    onTap: () {
                                      Navigator.of(context).push(
                                        MaterialPageRoute(
                                          builder: (context) => ProfilePage(
                                            userId: _sport.creatorId,
                                          ),
                                        ),
                                      );
                                    },
                                    child: CachedNetworkImage(
                                      imageUrl: _sport.creatorProfileImage,
                                      placeholder: (context, url) =>
                                          Container(color: Colors.grey[400]),
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                ),
                              ),
                              SizedBox(width: 10),
                              Text(
                                _sport.creatorName,
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 20,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Positioned(
                          top: 10,
                          right: 5,
                          child: Row(
                            children: <Widget>[
                              Text(
                                _commentCounter.toString(),
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              IconButton(
                                icon: Icon(Icons.add_comment),
                                color: Colors.white,
                                onPressed: openCommentSection,
                              ),
                            ],
                          ),
                        ),
                        Positioned(
                          bottom: 5,
                          child: Bounce(
                            duration: Duration(milliseconds: 100),
                            onPressed: () {
                              setState(() {
                                if (!_isLike) {
                                  _isLike = true;
                                  _likeCounter++;
                                  DatabaseService.like(
                                    'sports',
                                    _sport.id,
                                    _userId,
                                  );
                                  PersonalityService.setTextInput('I like');
                                  PersonalityService.setVideoInput(
                                    _sport.videoUrl,
                                  );
                                } else {
                                  _isLike = false;
                                  _likeCounter--;
                                  DatabaseService.unLike(
                                    'sports',
                                    _sport.id,
                                    _userId,
                                  );
                                }
                              });
                            },
                            child: Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Column(
                                children: <Widget>[
                                  Container(
                                    padding: EdgeInsets.all(7),
                                    child: Icon(
                                      _isLike
                                          ? Icons.favorite
                                          : Icons.favorite_border,
                                      color:
                                          _isLike ? Colors.red : Colors.white,
                                    ),
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: _isLike
                                          ? Colors.white
                                          : Colors.transparent,
                                      border: Border.all(color: Colors.white),
                                    ),
                                  ),
                                  SizedBox(height: 4),
                                  Text(
                                    '$_likeCounter likes',
                                    style: TextStyle(color: Colors.white),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        Positioned(
                          top: MediaQuery.of(context).size.height / 2.5,
                          child: Bounce(
                            duration: Duration(milliseconds: 100),
                            onPressed: () {
                              DatabaseService.saveContent(
                                'saved-sports',
                                _sport.id,
                              );
                            },
                            child: Padding(
                              padding: const EdgeInsets.all(8.0),
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
                        ),
                        Positioned(
                          top: MediaQuery.of(context).size.height / 2.1,
                          child: Bounce(
                            duration: Duration(milliseconds: 100),
                            onPressed: () async {
                             var request = await HttpClient()
                                      .getUrl(Uri.parse(_sport.videoUrl));
                                  var response = await request.close();
                                  Uint8List bytes =
                                      await consolidateHttpClientResponseBytes(
                                          response);
                                  var buffer = bytes.buffer;
                                  ByteData byteData = ByteData.view(buffer);
                                  var tempDir = await getTemporaryDirectory();
                                  File file = await File('${tempDir.path}/img')
                                      .writeAsBytes(buffer.asUint8List(
                                          byteData.offsetInBytes,
                                          byteData.lengthInBytes));

                                  Share.shareFiles(
                                    [file.path],
                                    text: 'from ${_sport.creatorName}',
                                  );
                              PersonalityService.setVideoInput(
                                _sport.videoUrl,
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
                        ),
                        Positioned(
                          bottom: 5,
                          right: 5,
                          child: Container(
                            width: MediaQuery.of(context).size.width / 5,
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
                              '${_sport.viewsCount} VIEWS',
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
                ),
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
                    .collection('sports')
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
                                  backgroundImage: CachedNetworkImageProvider(
                                    _comment.authorImage,
                                  ),
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
                                          'sports',
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
                                          'sports',
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
                      authorId: widget.userId,
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
                      'sports',
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
