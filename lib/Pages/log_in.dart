import 'package:flutter/material.dart';

import 'package:email_validator/email_validator.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';

import '../services/auth.dart';

import '../Pages/sign_up.dart';

import '../Pages/home.dart';

class LogInPage extends StatefulWidget {
  static const String id = 'logIn';
  const LogInPage({Key key}) : super(key: key);
  @override
  State<StatefulWidget> createState() => _LogInPageState();
}

class _LogInPageState extends State<LogInPage> {
  String email;
  String password;
  GlobalKey<FormState> _emailFormKey = GlobalKey<FormState>();
  GlobalKey<FormState> _passwordFormKey = GlobalKey<FormState>();
  bool _obscureText = true;
  bool _isPressed = false;

  void _togglePassword() {
    setState(() {
      _obscureText = !_obscureText;
    });
  }

  Widget _buildEmailField() {
    return Form(
      key: _emailFormKey,
      child: Container(
        width: 300,
        margin: EdgeInsets.only(bottom: 20),
        child: TextFormField(
          autocorrect: true,
          keyboardType: TextInputType.emailAddress,
          decoration: InputDecoration(
            labelText: 'email address',
            border: OutlineInputBorder(),
            prefixIcon: Icon(
              Icons.email,
              color: Colors.black,
            ),
          ),
          onChanged: (String value) {
            email = value;
            if (_isPressed == true) {
              if (email != null) {
                _emailFormKey.currentState.validate();
              }
            }
          },
          validator: (String value) {
            if (!EmailValidator.validate(value)) {
              return 'incorrect email address';
            } else {
              return null;
            }
          },
        ),
      ),
    );
  }

  Widget _buildPasswordField() {
    return Form(
      key: _passwordFormKey,
      child: Container(
        width: 300,
        margin: EdgeInsets.only(bottom: 20),
        child: TextFormField(
          autocorrect: true,
          obscureText: _obscureText,
          decoration: InputDecoration(
            suffixIcon: IconButton(
              icon: Icon(
                _obscureText == false ? Icons.visibility : Icons.visibility_off,
              ),
              onPressed: _togglePassword,
            ),
            labelText: 'password',
            border: OutlineInputBorder(),
            prefixIcon: Icon(
              Icons.lock,
              color: Colors.black,
            ),
          ),
          onChanged: (String value) {
            password = value;
            if (_isPressed == true) {
              if (password != null) {
                _passwordFormKey.currentState.validate();
              }
            }
          },
          validator: (String value) {
            if ((value.isEmpty || value.length <= 5)) {
              return 'incorrect password and should contain numbers';
            } else {
              return null;
            }
          },
        ),
      ),
    );
  }

  

  @override
  Widget build(BuildContext context) {
    final double _deviceWidth = MediaQuery.of(context).size.width;
    return SafeArea(
      child: Scaffold(
        body: SingleChildScrollView(
          child: Column(
            children: <Widget>[
              Center(
                child: Container(
                  alignment: Alignment.center,
                  margin: EdgeInsets.only(top: 50, bottom: 30),
                  height: 100,
                  width: 100,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.black,
                  ),
                  child: Icon(
                    MdiIcons.infinity,
                    color: Colors.white,
                    size: 60,
                  ),
                ),
              ),
              Center(
                child: Container(
                  margin: EdgeInsets.only(bottom: 30),
                  child: Text(
                    'Welcome back !',
                    style: TextStyle(
                      fontSize: 30,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ),
              ),
              _buildEmailField(),
              _buildPasswordField(),
              SizedBox(height: 10),
              Container(
                margin: EdgeInsets.only(bottom: 20),
                child: ButtonTheme(
                  minWidth: _deviceWidth / 1.3,
                  height: 50,
                  child: RaisedButton(
                    elevation: 5,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    onPressed: () {
                      setState(() {
                        _isPressed = true;
                      });
                      if (_emailFormKey.currentState.validate() ||
                          _passwordFormKey.currentState.validate()) {
                        _emailFormKey.currentState.save();
                        _passwordFormKey.currentState.save();
                        AuthService.logInUser(
                          context,
                          email,
                          password,
                          () => Navigator.pushNamed(context, HomePage.id),
                        );
                      } else {
                        return;
                      }
                    },
                    color: Colors.black,
                    child: Text(
                      'Login',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16.5,
                      ),
                    ),
                  ),
                ),
              ),
              Container(
                margin: EdgeInsets.only(bottom: 20),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    Container(
                      width: 150,
                      height: 1,
                      color: Colors.black,
                    ),
                    SizedBox(width: 5),
                    Text(
                      'or',
                      style:
                          TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
                    ),
                    SizedBox(width: 5),
                    Container(
                      width: 150,
                      height: 1,
                      color: Colors.black,
                    ),
                  ],
                ),
              ),
              ButtonTheme(
                minWidth: _deviceWidth / 1.5,
                height: 45,
                child: OutlineButton(
                  borderSide: BorderSide(color: Colors.black),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (BuildContext context) => SignUpPage(),
                      ),
                    );
                  },
                  color: Colors.green[600],
                  child: Text(
                    'Create an Account',
                    style: TextStyle(
                      fontSize: 16.5,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
