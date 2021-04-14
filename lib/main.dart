import 'package:firebase_core/firebase_core.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

/// Copyright 2020
/// Developer : Nader Khaled
/// App Name : Looper
/// App Category : Social Network
/// Company Owner : Looper INC
/// Development Time : 2019 >> 2020
/// Author: Nader Khaled
/// IBM Cloud Account Password : *UyAdgQ$KY82&w#
/// Giphy API Key : UhvOlgZPcbRwN490PThaYgBlNy7N5rIx
/// Google Maps API Key : AIzaSyAk6x-mEiibVC7NamZ0owHRzQthVDhXRuA
import 'package:flutter/material.dart';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/services.dart';

import './Pages/welcome_page.dart';
import './Pages/home.dart';

import './Pages/splash_screen.dart';
import './Pages/errorPage.dart';
import './Pages/personal_data.dart';
import './Pages/sign_up.dart';
import './Pages/log_in.dart';
import './creation/post-create.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  MobileAds.instance.initialize();
  await Firebase.initializeApp();
  await SentryFlutter.init(
    (options) {
      options.dsn =
          'https://7c2f92fe888d48af974782b181060e2b@o479859.ingest.sentry.io/5700694';
    },
    appRunner: () => runApp(Looper()),
  );
}

class Looper extends StatelessWidget {
  const Looper({Key key}) : super(key: key);

  Widget _screenId() {
    return StreamBuilder<User>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (BuildContext context, snapshot) {
        if (snapshot.hasData) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return SplashScreen();
          }
          final User _user = snapshot.data;
          return HomePage(userId: _user.uid);
        } else {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return SplashScreen();
          }
          return WelcomePage();
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      routes: {
        '/': (BuildContext context) => _screenId(),
        HomePage.id: (BuildContext context) => HomePage(),
        PersonalPage.id: (BuildContext context) => PersonalPage(),
        SignUpPage.id: (BuildContext context) => SignUpPage(),
        LogInPage.id: (BuildContext context) => LogInPage(),
        WelcomePage.id: (BuildContext context) => WelcomePage(),
        PostCreationPage.pageId: (BuildContext context) => PostCreationPage(),
      },
      onUnknownRoute: (RouteSettings settings) =>
          MaterialPageRoute(builder: (context) {
        return ErrorPage();
      }),
    );
  }
}
