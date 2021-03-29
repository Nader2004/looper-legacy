import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:looper/models/userModel.dart';
import 'package:looper/services/notifications.dart';
import 'package:looper/Pages/home-Pages/global/profile.dart';
import '../models/loverCardModel.dart' as card;

class LoverCard extends StatefulWidget {
  final DocumentSnapshot data;
  final User user;
  LoverCard({Key key, this.data, this.user}) : super(key: key);

  @override
  _LoverCardState createState() => _LoverCardState();
}

class _LoverCardState extends State<LoverCard> {
  card.LoverCard _loverCard;

  @override
  void initState() {
    super.initState();
    _loverCard = card.LoverCard.fromDoc(widget.data);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height / 90,
      child: Card(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(27),
        ),
        child: Stack(
          children: <Widget>[
            Row(
              children: [
                Align(
                  alignment: Alignment.topCenter,
                  child: Container(
                    height: MediaQuery.of(context).size.width / 5,
                    width: MediaQuery.of(context).size.width / 5,
                    child: Card(
                      elevation: 10,
                      shape: CircleBorder(),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(50),
                        child: GestureDetector(
                          onTap: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (context) => ProfilePage(
                                  userId: _loverCard.authorId,
                                ),
                              ),
                            );
                          },
                          child: CachedNetworkImage(
                            imageUrl: _loverCard.authorImage,
                            placeholder: (context, url) =>
                                Container(color: Colors.grey[400]),
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            Align(
              alignment: Alignment(-0.15, -0.9),
              child: Text(
                '${_loverCard.authorName}, ${_loverCard.authorAge}',
                style: GoogleFonts.catamaran(
                  fontSize: 30,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            Align(
              alignment: Alignment(0.0, -0.55),
              child: Text(
                'I wish someone to be',
                style: TextStyle(
                  color: Colors.grey[400],
                  fontSize: 25,
                ),
              ),
            ),
            Align(
              alignment: Alignment(0.0, -0.3),
              child: Wrap(
                children: List.generate(
                  _loverCard.qualities.length,
                  (index) => Container(
                    width: MediaQuery.of(context).size.width / 5,
                    height: 25,
                    margin: EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(30),
                      border: Border.all(color: Colors.black, width: 1.5),
                    ),
                    child: Text(
                      _loverCard.qualities[index].toString(),
                    ),
                  ),
                ),
              ),
            ),
            Align(
              alignment: Alignment(0.0, -0.05),
              child: Text(
                'And might look',
                style: TextStyle(
                  color: Colors.grey[400],
                  fontSize: 25,
                ),
              ),
            ),
            Align(
              alignment: Alignment(-0.8, 0.35),
              child: IntrinsicWidth(
                child: Row(
                  children: <Widget>[
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 25),
                      child: IntrinsicHeight(
                        child: Column(
                          children: <Widget>[
                            Image.asset(
                              _loverCard.gender == 'Male'
                                  ? 'assets/female-hair (2).png'
                                  : 'assets/male-hair (2).png',
                              color: _loverCard.lookQualities['hairColor'] ==
                                      'Black'
                                  ? Colors.black
                                  : _loverCard.lookQualities['hairColor'] ==
                                          'Brown'
                                      ? Colors.brown
                                      : _loverCard.lookQualities['hairColor'] ==
                                              'Yellow'
                                          ? Colors.yellow
                                          : Colors.red,
                              height: MediaQuery.of(context).size.width / 8,
                              width: MediaQuery.of(context).size.width / 8,
                            ),
                            SizedBox(height: 3),
                            Text(
                              _loverCard.lookQualities['hairColor'],
                              style: GoogleFonts.abel(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 25),
                      child: IntrinsicHeight(
                        child: Column(
                          children: <Widget>[
                            Icon(Icons.face, size: 40),
                            SizedBox(height: 3),
                            Text(
                              _loverCard.lookQualities['faceShape'],
                              style: GoogleFonts.abel(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 25),
                      child: IntrinsicHeight(
                        child: Column(
                          children: <Widget>[
                            Icon(
                              Icons.remove_red_eye,
                              size: 35,
                              color: _loverCard.lookQualities['eyeColor'] ==
                                      'Black'
                                  ? Colors.black
                                  : _loverCard.lookQualities['eyeColor'] ==
                                          'Brown'
                                      ? Colors.brown
                                      : _loverCard.lookQualities['eyeColor'] ==
                                              'Blue'
                                          ? Colors.blue
                                          : Colors.green,
                            ),
                            SizedBox(height: 3),
                            Text(
                              _loverCard.lookQualities['eyeColor'],
                              style: GoogleFonts.abel(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
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
            Align(
              alignment: Alignment(0.0, 0.67),
              child: IntrinsicWidth(
                child: Row(
                  children: <Widget>[
                    Text(
                      'Age at',
                      style: TextStyle(
                        color: Colors.grey[400],
                        fontSize: 25,
                      ),
                    ),
                    SizedBox(width: 7),
                    Text(
                      '${_loverCard.ageRange['min']} - ${_loverCard.ageRange['max']}',
                      style: TextStyle(
                        fontSize: 25,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Align(
              alignment: Alignment.bottomCenter,
              child: RaisedButton(
                padding: EdgeInsets.symmetric(horizontal: 30),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
                color: Colors.pink,
                onPressed: () {
                  NotificationsService.sendNotification(
                    'New Hand Raised 💖',
                    '${widget.user.username} raised hand to your wish',
                    _loverCard.authorId,
                    'profile'
                  );
                },
                textColor: Colors.white,
                child: Text('RAISE MY HAND'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
