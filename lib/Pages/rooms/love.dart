import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flashy_tab_bar/flashy_tab_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:flutter_swiper/flutter_swiper.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:looper/Pages/home-Pages/global/profile.dart';
import 'package:looper/creation/love-create.dart';
import 'package:looper/services/database.dart';
import 'package:looper/services/personality.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../widgets/love-card.dart';
import '../../widgets/lover-card.dart';
import '../../models/userModel.dart';

class LoveRoom extends StatefulWidget {
  LoveRoom({Key key}) : super(key: key);

  @override
  _LoveRoomState createState() => _LoveRoomState();
}

class _LoveRoomState extends State<LoveRoom> {
  String _userId = 'empty';
  int _selectedIndex = 0;
  FirebaseFirestore _firestore;
  User _user;

  @override
  void initState() {
    super.initState();
    _firestore = FirebaseFirestore.instance;
    PersonalityService.analyzePersonality();
    setPrefs();
  }

  void setPrefs() async {
    final SharedPreferences _prefs = await SharedPreferences.getInstance();
    setState(() {
      _userId = _prefs.get('id');
    });
  }

  Future<List<DocumentSnapshot>> getLoveFeed() async {
    if (_selectedIndex == 0) {
      final QuerySnapshot _snapshot =
          await PersonalityService.getCompatibleContentStream(
        _user?.personalityType ?? '',
        _firestore,
        'love-cards',
        'author-personality',
      );
      if (_user.gender == 'Male') {
        return _snapshot.docs
            .where((element) => element.data()['authorGender'] == 'Female')
            .toList();
      } else {
        return _snapshot.docs
            .where((element) => element.data()['authorGender'] == 'Male')
            .toList();
      }
    } else {
      final QuerySnapshot _snapshot =
          await PersonalityService.getCompatibleContentStream(
        _user?.personalityType ?? '',
        _firestore,
        'lover-cards',
        'author-personality',
      );
      if (_user.gender == 'Male') {
        return _snapshot.docs
            .where((element) => element.data()['gender'] == 'Female')
            .toList();
      } else {
        return _snapshot.docs
            .where((element) => element.data()['gender'] == 'Male')
            .toList();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _userId == 'empty'
          ? SizedBox.shrink()
          : FutureBuilder(
              future: FirebaseFirestore.instance
                  .collection('users')
                  .doc(_userId)
                  .get(),
              builder: (context, AsyncSnapshot<DocumentSnapshot> snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(
                    child: SpinKitWanderingCubes(
                      color: Colors.black,
                    ),
                  );
                }
                _user = User.fromDoc(snapshot.data);
                return Center(
                  child: FutureBuilder(
                      future: getLoveFeed(),
                      builder: (context,
                          AsyncSnapshot<List<DocumentSnapshot>> snapshot) {
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return SpinKitPumpingHeart(
                            color: Colors.pink,
                            size: 40,
                          );
                        } else {
                          if (snapshot.data.length == 0) {
                            return Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    _selectedIndex == 1
                                        ? MdiIcons.handHeart
                                        : MdiIcons.heartFlash,
                                    color: Colors.black,
                                    size: 60,
                                  ),
                                  SizedBox(
                                      height: _selectedIndex == 1 ? 12 : 8),
                                  Text(
                                    _selectedIndex == 2
                                        ? 'No Lover Cards uploaded yet'
                                        : _selectedIndex == 1
                                            ? 'Favorite List is empty'
                                            : 'No Love Cards uploaded yet',
                                    style: GoogleFonts.aBeeZee(
                                      textStyle: TextStyle(
                                        color: Colors.black,
                                        fontSize: 20,
                                      ),
                                    ),
                                  ),
                                  SizedBox(height: 10),
                                  _selectedIndex == 1
                                      ? SizedBox.shrink()
                                      : FlatButton(
                                          shape: RoundedRectangleBorder(
                                            borderRadius:
                                                BorderRadius.circular(10),
                                          ),
                                          color: Colors.red[400],
                                          onPressed: () {
                                            Navigator.of(context).push(
                                              MaterialPageRoute(
                                                builder: (context) =>
                                                    LoveCreation(),
                                              ),
                                            );
                                          },
                                          textColor: Colors.white,
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Icon(
                                                Icons.favorite,
                                                color: Colors.white,
                                              ),
                                              SizedBox(width: 10),
                                              Text('create one now'),
                                            ],
                                          ),
                                        ),
                                ],
                              ),
                            );
                          }
                          return Column(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: <Widget>[
                              
                              _selectedIndex == 1
                                  ? SizedBox.shrink()
                                  : Padding(
                                      padding: EdgeInsets.only(top: 25),
                                      child: Text(
                                        'Swipe Right, Left',
                                        style: GoogleFonts.catamaran(
                                          fontSize: 30,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                              _selectedIndex == 1
                                  ? SizedBox(height: 20)
                                  : Container(),
                              snapshot.data.length == 0
                                  ? Container()
                                  : _selectedIndex == 1
                                      ? Expanded(
                                          child: ListView.separated(
                                            separatorBuilder:
                                                (context, int index) =>
                                                    Divider(),
                                            itemCount:
                                                _user.interestedPeople.length,
                                            itemBuilder: (context, int index) =>
                                                FutureBuilder<DocumentSnapshot>(
                                                    future: _firestore
                                                        .collection('users')
                                                        .doc(
                                                          _user.interestedPeople[
                                                              index],
                                                        )
                                                        .get(),
                                                    builder: (
                                                      context,
                                                      AsyncSnapshot<
                                                              DocumentSnapshot>
                                                          snapshot,
                                                    ) {
                                                      if (!snapshot.hasData) {
                                                        return SizedBox
                                                            .shrink();
                                                      }
                                                      User _favorUser =
                                                          User.fromDoc(
                                                              snapshot.data);
                                                      return ListTile(
                                                        leading: ClipRRect(
                                                          borderRadius:
                                                              BorderRadius
                                                                  .circular(
                                                            40,
                                                          ),
                                                          child:
                                                              CachedNetworkImage(
                                                            imageUrl: _favorUser
                                                                .profileImageUrl,
                                                            fit: BoxFit.cover,
                                                            height: 55,
                                                            width: 55,
                                                          ),
                                                        ),
                                                        title: Text(
                                                          '${_favorUser.username}',
                                                          style: TextStyle(
                                                            fontWeight:
                                                                FontWeight.bold,
                                                            fontSize: 20,
                                                          ),
                                                        ),
                                                        trailing: FlatButton(
                                                          shape:
                                                              RoundedRectangleBorder(
                                                            borderRadius:
                                                                BorderRadius
                                                                    .circular(
                                                                        5),
                                                          ),
                                                          onPressed: () {
                                                            setState(() {
                                                              _user
                                                                  .interestedPeople
                                                                  .removeAt(
                                                                      index);
                                                            });
                                                            DatabaseService
                                                                .notIntrestedInPerson(
                                                              _favorUser.id,
                                                            );
                                                          },
                                                          color: Colors.purple,
                                                          textColor:
                                                              Colors.white,
                                                          child: Text('Remove'),
                                                        ),
                                                        onTap: () {
                                                          Navigator.of(context)
                                                              .push(
                                                            MaterialPageRoute(
                                                              builder:
                                                                  (context) =>
                                                                      ProfilePage(
                                                                userId:
                                                                    _user.id,
                                                              ),
                                                            ),
                                                          );
                                                        },
                                                      );
                                                    }),
                                          ),
                                        )
                                      : Swiper(
                                          layout: SwiperLayout.STACK,
                                          itemWidth: _selectedIndex == 2
                                              ? MediaQuery.of(context)
                                                      .size
                                                      .width /
                                                  1.2
                                              : MediaQuery.of(context)
                                                      .size
                                                      .width /
                                                  1.6,
                                          itemHeight: _selectedIndex == 2
                                              ? MediaQuery.of(context)
                                                      .size
                                                      .height /
                                                  1.35
                                              : MediaQuery.of(context)
                                                      .size
                                                      .height /
                                                  1.5,
                                          itemBuilder: (context, index) {
                                            if (_selectedIndex == 2) {
                                              return LoverCard(
                                                data: snapshot.data[index],
                                                user: _user,
                                              );
                                            } else {
                                              return LoveCard(
                                                data: snapshot.data[index],
                                                user: _user,
                                              );
                                            }
                                          },
                                          itemCount: snapshot.data.length,
                                        ),
                            ],
                          );
                        }
                      }),
                );
              }),
      bottomNavigationBar: ClipRRect(
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(30),
          topRight: Radius.circular(30),
        ),
        child: FlashyTabBar(
          animationCurve: Curves.linear,
          selectedIndex: _selectedIndex,
          onItemSelected: (index) => setState(() => _selectedIndex = index),
          items: [
            FlashyTabBarItem(
              icon: Icon(Icons.favorite),
              title: Text('For you'),
            ),
            FlashyTabBarItem(
              icon: Icon(Icons.star),
              title: Text('Favorite'),
            ),
            FlashyTabBarItem(
              icon: Icon(MdiIcons.accountHeart),
              title: Text('Wishes'),
            ),
          ],
        ),
      ),
    );
  }
}
