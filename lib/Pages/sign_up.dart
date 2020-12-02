import 'package:flutter/material.dart';
import 'package:looper/Pages/personal_data.dart';

import 'package:string_validator/string_validator.dart';

import 'package:email_validator/email_validator.dart';

import '../Pages/log_in.dart';

class SignUpPage extends StatefulWidget {
  static const String id = 'SignUp';
  const SignUpPage({Key key}) : super(key: key);
  @override
  State<StatefulWidget> createState() => _SignUpPageState();
}

class _SignUpPageState extends State<SignUpPage> {
  String username = '';
  String email = '';
  String password = '';
  GlobalKey<FormState> _usernameFormKey = GlobalKey<FormState>();
  GlobalKey<FormState> _emailFormKey = GlobalKey<FormState>();
  GlobalKey<FormState> _passwordFormKey = GlobalKey<FormState>();
  GlobalKey<FormState> _confirmedPasswordFormKey = GlobalKey<FormState>();
  bool _obscureText = true;
  bool _obscureText2 = true;
  bool _isPressed = false;

  void _togglePassword() {
    setState(() {
      _obscureText = !_obscureText;
    });
  }

  void _toggleConfirmedPassword() {
    setState(() {
      _obscureText2 = !_obscureText2;
    });
  }

  Widget _buildUsernameForm() {
    return Form(
      key: _usernameFormKey,
      child: Container(
        margin: EdgeInsets.only(bottom: 20),
        width: 300,
        child: TextFormField(
          autocorrect: true,
          decoration: InputDecoration(
            labelText: 'username',
            border: OutlineInputBorder(),
            prefixIcon: Icon(
              Icons.person,
              color: Colors.black,
            ),
          ),
          onChanged: (String value) {
            username = value;
            if (_isPressed == true) {
              if (username != null) {
                _usernameFormKey.currentState.validate();
              }
            }
          },
          validator: (String value) {
            if (value.isEmpty || value.length <= 1) {
              return 'invalid username';
            } else {
              return null;
            }
          },
          onEditingComplete: () {
            _usernameFormKey.currentState.validate();
            if (_usernameFormKey.currentState.validate()) {
              FocusScope.of(context).requestFocus(FocusNode());
            }
          },
        ),
      ),
    );
  }

  Widget _buildEmailForm() {
    return Form(
      key: _emailFormKey,
      child: Container(
        margin: EdgeInsets.only(bottom: 20),
        width: 300,
        child: TextFormField(
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
              return 'invalid email address';
            } else {
              return null;
            }
          },
          onEditingComplete: () {
            _emailFormKey.currentState.validate();
            if (_emailFormKey.currentState.validate()) {
              FocusScope.of(context).requestFocus(FocusNode());
            }
          },
          decoration: InputDecoration(
            labelText: 'email address',
            border: OutlineInputBorder(),
            prefixIcon: Icon(
              Icons.email,
              color: Colors.black,
            ),
            labelStyle: TextStyle(
              fontSize: 16,
            ),
          ),
          keyboardType: TextInputType.emailAddress,
        ),
      ),
    );
  }

  Widget _buildPasswordForm() {
    return Form(
      key: _passwordFormKey,
      child: Container(
        margin: EdgeInsets.only(bottom: 20),
        width: 300,
        child: TextFormField(
          autocorrect: true,
          obscureText: _obscureText,
          onChanged: (String value) {
            password = value;
            if (_isPressed == true) {
              if (password != null) {
                _passwordFormKey.currentState.validate();
              }
            }
          },
          validator: (String value) {
            if ((value.isEmpty || value.length <= 5) ||
                !isAlphanumeric(value)) {
              return 'invalid password and should contain numbers';
            } else {
              return null;
            }
          },
          onEditingComplete: () {
            _passwordFormKey.currentState.validate();
            if (_passwordFormKey.currentState.validate()) {
              FocusScope.of(context).requestFocus(FocusNode());
            }
          },
          decoration: InputDecoration(
            labelText: 'password',
            border: OutlineInputBorder(),
            prefixIcon: Icon(
              Icons.lock,
              color: Colors.black,
            ),
            suffixIcon: IconButton(
              icon: Icon(
                _obscureText == false ? Icons.visibility : Icons.visibility_off,
              ),
              onPressed: _togglePassword,
            ),
            labelStyle: TextStyle(
              fontSize: 16,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildConfirmPasswordForm() {
    return Form(
      key: _confirmedPasswordFormKey,
      child: Container(
        margin: EdgeInsets.only(bottom: 35),
        width: 300,
        child: TextFormField(
          autocorrect: true,
          obscureText: _obscureText2,
          validator: (String value) {
            if (password != value || value.isEmpty) {
              return 'incorrect password';
            } else {
              return null;
            }
          },
          onEditingComplete: () {
            _confirmedPasswordFormKey.currentState.validate();
            if (_confirmedPasswordFormKey.currentState.validate()) {
              FocusScope.of(context).requestFocus(FocusNode());
            }
          },
          decoration: InputDecoration(
            labelText: 'confirm password',
            border: OutlineInputBorder(),
            labelStyle: TextStyle(
              fontSize: 16,
            ),
            prefixIcon: Icon(
              Icons.lock_outline,
              color: Colors.black,
            ),
            suffixIcon: IconButton(
              icon: Icon(
                _obscureText2 == false
                    ? Icons.visibility
                    : Icons.visibility_off,
              ),
              onPressed: _toggleConfirmedPassword,
            ),
          ),
        ),
      ),
    );
  }

  void createAccount() {
    setState(() {
      _isPressed = true;
    });
    if (_usernameFormKey.currentState.validate() ||
        _emailFormKey.currentState.validate() ||
        _passwordFormKey.currentState.validate() ||
        _confirmedPasswordFormKey.currentState.validate()) {
      _usernameFormKey.currentState.save();
      _emailFormKey.currentState.save();
      _passwordFormKey.currentState.save();
      _confirmedPasswordFormKey.currentState.save();
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => PersonalPage(
            email: email,
            username: username,
            password: password,
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final double _deviceWidth = MediaQuery.of(context).size.width;
    return SafeArea(
      child: Scaffold(
        body: SingleChildScrollView(
          child: Column(
            children: <Widget>[
              Container(
                margin: EdgeInsets.only(top: 90, right: 140, bottom: 60),
                child: Text(
                  'Sign up',
                  style: TextStyle(
                    fontFamily: 'Montserrat',
                    fontSize: 42,
                  ),
                ),
              ),
              Column(
                children: <Widget>[
                  _buildUsernameForm(),
                  _buildEmailForm(),
                  _buildPasswordForm(),
                  _buildConfirmPasswordForm(),
                ],
              ),
              Center(
                child: ButtonTheme(
                  minWidth: _deviceWidth / 1.2,
                  height: 50.0,
                  child: FlatButton(
                    color: Colors.black,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    onPressed: createAccount,
                    child: Text(
                      'Create Account',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16.5,
                      ),
                    ),
                  ),
                ),
              ),
              Container(
                margin: EdgeInsets.only(top: 30, left: 80),
                child: Row(
                  children: <Widget>[
                    Text('Already have an Account?'),
                    SizedBox(width: 3),
                    GestureDetector(
                      onTap: () {
                        Navigator.of(context).pushNamed(LogInPage.id);
                      },
                      child: Text(
                        'Login here',
                        style: TextStyle(color: Colors.blue),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
