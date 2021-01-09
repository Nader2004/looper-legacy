import 'package:flutter/material.dart';
import '../Pages/log_in.dart';
import '../Pages/sign_up.dart';

class WelcomePage extends StatelessWidget {
  static const String id = 'welcome';
  const WelcomePage({Key key}) : super(key: key);

  Widget _buildButtons(BuildContext context, double deviceWidth) {
    return Container(
      margin: EdgeInsets.only(
        right: 10,
        top: MediaQuery.of(context).size.height / 5.5,
      ),
      child: ButtonBar(
        children: <Widget>[
          ButtonTheme(
            minWidth: deviceWidth / 2.4,
            height: deviceWidth / 7,
            child: OutlineButton(
              borderSide: BorderSide(width: 1.2),
              onPressed: () {
                Navigator.of(context).pushNamed(LogInPage.id);
              },
              child: Text('LOG IN'),
            ),
          ),
          SizedBox(width: 3),
          ButtonTheme(
            minWidth: deviceWidth / 2.4,
            height: deviceWidth / 7,
            child: FlatButton(
              color: Colors.black,
              onPressed: () {
                Navigator.of(context).pushNamed(SignUpPage.id);
              },
              child: Text(
                'SIGN UP',
                style: TextStyle(
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final double _deviceWidth = MediaQuery.of(context).size.width;
    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: <Widget>[
          Image.asset(
            'assets/social-media (2).jpg',
            height: MediaQuery.of(context).size.height / 2,
            width: MediaQuery.of(context).size.width,
          ),
          Container(
            margin: EdgeInsets.only(top: 10),
            child: Text(
              'Welcome to Looper !',
              style: TextStyle(
                fontSize: 25,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          Container(
            margin: EdgeInsets.only(top: 30),
            child: Text(
              'Discover the world around you along with new moments',
              style: TextStyle(fontSize: 15.5, color: Colors.grey),
            ),
          ),
          Container(
            margin: EdgeInsets.only(top: 10),
            child: Text(
              'Build new Relationships with amazing people',
              style: TextStyle(fontSize: 15.5, color: Colors.grey),
            ),
          ),
          Container(
            margin: EdgeInsets.only(top: 10),
            child: Text(
              'Change the way you see your life !',
              style: TextStyle(fontSize: 15.5, color: Colors.grey),
            ),
          ),
          _buildButtons(context, _deviceWidth),
        ],
      ),
    );
  }
}
