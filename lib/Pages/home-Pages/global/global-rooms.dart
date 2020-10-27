import 'package:flutter/material.dart';

import 'package:google_fonts/google_fonts.dart';

import '../../rooms/talents.dart';
import '../../rooms/love.dart';
import '../../rooms/sports.dart';
import '../../rooms/challenge.dart';
import '../../rooms/comedy.dart';

class GlobalRoomsPage extends StatefulWidget {
  const GlobalRoomsPage({Key key}) : super(key: key);

  @override
  _GlobalRoomsPageState createState() => _GlobalRoomsPageState();
}

class _GlobalRoomsPageState extends State<GlobalRoomsPage> {
  AppBar _buildAppBar() {
    return AppBar(
      brightness: Brightness.light,
      backgroundColor: Colors.white,
      elevation: 1,
      centerTitle: true,
      title: Text(
        'Global rooms',
        style: TextStyle(
          color: Colors.black,
        ),
      ),
    );
  }

  Widget _buildRoomWidget(
      {LinearGradient gradient,
      String text,
      String image,
      VoidCallback callBack}) {
    final double _deviceWidth = MediaQuery.of(context).size.width;
    return GestureDetector(
      onTap: callBack,
      child: Container(
        alignment: Alignment.center,
        margin: EdgeInsets.symmetric(
          horizontal: 5,
          vertical: 15,
        ),
        width: _deviceWidth,
        height: _deviceWidth / 3,
        decoration: BoxDecoration(
          gradient: gradient,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Stack(
          children: <Widget>[
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.asset(
                image,
                fit: BoxFit.cover,
                height: _deviceWidth / 3,
                width: _deviceWidth,
              ),
            ),
            Opacity(
              opacity: 0.6,
              child: Container(
                width: _deviceWidth,
                height: _deviceWidth / 3,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  gradient: gradient,
                ),
              ),
            ),
            Center(
              child: Text(
                text,
                style: GoogleFonts.raleway(
                  textStyle: TextStyle(
                    color: Colors.white,
                    fontSize: 30,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGlobalRooms() {
    return Column(
      children: <Widget>[
        _buildRoomWidget(
          callBack: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => LoveRoom(),
              ),
            );
          },
          gradient: LinearGradient(
            List: [
              Colors.red[800],
              Colors.red[900],
            ],
          ),
          text: 'Love',
          image: 'assets/love.png',
        ),
        _buildRoomWidget(
          callBack: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => SportsRoom(),
            ),
          ),
          gradient: LinearGradient(
            colors: [
              Colors.blue[800],
              Colors.blue[900],
            ],
          ),
          text: 'Sports',
          image: 'assets/sport.jpg',
        ),
        _buildRoomWidget(
          callBack: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => TalentRoom(),
              ),
            );
          },
          gradient: LinearGradient(
            colors: [
              Colors.purple[800],
              Colors.purple[900],
            ],
          ),
          text: 'Talents',
          image: 'assets/talents.jpg',
        ),
        _buildRoomWidget(
          callBack: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ChallengeRoom(),
            ),
          ),
          gradient: LinearGradient(
            colors: [
              Colors.black54,
              Colors.black87,
            ],
          ),
          text: 'Challenges',
          image: 'assets/challenges.jpg',
        ),
        _buildRoomWidget(
          callBack: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ComedyRoom(),
            ),
          ),
          gradient: LinearGradient(
            colors: [
              Colors.deepPurple[400],
              Colors.deepPurple[900],
            ],
          ),
          text: 'Comedy',
          image: 'assets/comedy.jpg',
        ),
      ],
    );
  }

  Widget _buildBodyWidget() {
    return SingleChildScrollView(
      child: Column(
        children: <Widget>[
          _buildGlobalRooms(),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _buildAppBar(),
      body: _buildBodyWidget(),
    );
  }
}
