import 'package:flutter/material.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';

class SplashScreen extends StatelessWidget {
  const SplashScreen({Key key}) : super(key: key);
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Icon(
          MdiIcons.infinity,
          size: 77,
          color: Colors.black,
        ),
      ),
    );
  }
}
