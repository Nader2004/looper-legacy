import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:looper/services/database.dart';
import 'package:looper/services/notifications.dart';
import 'package:looper/Pages/home-Pages/global/profile.dart';
import '../models/userModel.dart';
import '../models/loveCardModel.dart' as card;

class LoveCard extends StatefulWidget {
  final DocumentSnapshot data;
  final User user;
  LoveCard({Key key, this.data, this.user}) : super(key: key);

  @override
  _LoveCardState createState() => _LoveCardState();
}

class _LoveCardState extends State<LoveCard> {
  card.LoveCard _loveCard;
  bool _isIntersted = false;

  @override
  void initState() {
    super.initState();
    _loveCard = card.LoveCard.fromDoc(widget.data);
    _isIntersted = widget.user.interestedPeople.contains(
      _loveCard.authorId,
    );
  }

  @override
  void didUpdateWidget(LoveCard oldWidget) {
    if (_loveCard != card.LoveCard.fromDoc(widget.data)) {
      setState(() {
        _loveCard = card.LoveCard.fromDoc(widget.data);
      });
    }
    super.didUpdateWidget(oldWidget);
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: <Widget>[
          Stack(
            overflow: Overflow.visible,
            children: <Widget>[
              ClipRRect(
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
                ),
                child: CachedNetworkImage(
                  imageUrl: _loveCard.imageUrl,
                  height: MediaQuery.of(context).size.height / 2.2,
                  width: MediaQuery.of(context).size.width / 1.2,
                  progressIndicatorBuilder: (context, url, downloadProgress) =>
                      Center(
                    child: Padding(
                      padding: EdgeInsets.all(8.0),
                      child: SizedBox(
                        height: 40,
                        width: 40,
                        child: CircularProgressIndicator(
                            backgroundColor: Colors.grey,
                            valueColor: AlwaysStoppedAnimation(Colors.black),
                            strokeWidth: 1.5,
                            value: downloadProgress.progress),
                      ),
                    ),
                  ),
                  fit: BoxFit.cover,
                ),
              ),
              Positioned.fill(
                child: Align(
                  alignment: Alignment.topLeft,
                  child: Container(
                    width: 45,
                    height: 45,
                    margin: EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 1.5),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(30),
                      child: GestureDetector(
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (context) => ProfilePage(
                                userId: _loveCard.authorId,
                              ),
                            ),
                          );
                        },
                        child: CachedNetworkImage(
                          imageUrl: _loveCard.authorImage,
                          placeholder: (context, url) =>
                              Container(color: Colors.grey[400]),
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              Positioned.fill(
                child: Align(
                  alignment: Alignment(0.0, 0.75),
                  child: Text(
                    '${_loveCard.authorName}, ${_loveCard.authorAge.toString()}',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 25,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
          Padding(
            padding: EdgeInsets.only(top: 30),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                Icon(
                  Icons.location_on,
                  size: 20,
                  color: Colors.blueGrey,
                ),
                SizedBox(width: 5),
                Text(
                  _loveCard.location,
                  style: TextStyle(
                    color: Colors.blueGrey,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: 10),
          Column(
            children: <Widget>[
              Container(
                height: 35,
                width: double.infinity,
                margin: EdgeInsets.symmetric(horizontal: 10),
                child: FlatButton(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(5),
                  ),
                  color: Colors.deepPurple,
                  onPressed: () {
                    if (!_isIntersted) {
                      setState(() {
                        _isIntersted = true;
                      });
                      DatabaseService.intrestedInPerson(_loveCard.authorId);
                      NotificationsService.sendNotification(
                        'New Interest 💖',
                        '${widget.user.username}  is interested to you',
                        _loveCard.authorId,
                      );
                    } else {
                      setState(() {
                        _isIntersted = false;
                      });
                      DatabaseService.notIntrestedInPerson(_loveCard.authorId);
                    }
                  },
                  textColor: Colors.white,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: <Widget>[
                      Icon(
                        _isIntersted ? Icons.check : Icons.favorite,
                        color: Colors.white,
                        size: 16,
                      ),
                      SizedBox(width: 5),
                      Text(
                        _isIntersted ? 'Interested' : 'I\'m interested',
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
