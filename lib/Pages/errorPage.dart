import 'package:flutter/material.dart';

class ErrorPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.red,
        centerTitle: true,
        title: Text(
          'Error',
          style: TextStyle(
            color: Colors.white,
            fontSize: 30.5,
          ),
        ),
      ),
      body: Center(
        child: Text(
          'PAGE NOT FOUND',
          style: TextStyle(
            color: Colors.red,
            letterSpacing: 1.5,
            fontSize: 28.5,
          ),
        ),
      ),
    );
  }
}
