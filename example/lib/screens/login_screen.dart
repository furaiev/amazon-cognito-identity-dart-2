import 'package:amazon_cognito_identity_dart_2/cognito.dart';
import 'package:flutter/material.dart';
import 'package:secure_counter/screens/confirmation_screen.dart';
import 'package:secure_counter/screens/secure_counter_screen.dart';
import 'package:secure_counter/secrets.dart';
import 'package:secure_counter/user.dart';
import 'package:secure_counter/user_service.dart';

class LoginScreen extends StatefulWidget {
  LoginScreen({Key? key, this.email}) : super(key: key);

  final String? email;

  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final _userService = UserService(userPool);
  User _user = User();
  bool _isAuthenticated = false;

  Future<UserService> _getValues() async {
    await _userService.init();
    _isAuthenticated = await _userService.checkAuthenticated();
    return _userService;
  }

  void submit(BuildContext context) async {
    _formKey.currentState?.save();
    String message;
    if (_user.email != null && _user.password != null) {
      try {
        var u = await _userService.login(_user.email!, _user.password!);
        if (u == null) {
          message = 'Could not login user';
        } else {
          _user = u;
          message = 'User sucessfully logged in!';
          if (!_user.confirmed) {
            message = 'Please confirm user account';
          }
        }
      } on CognitoClientException catch (e) {
        if (e.code == 'InvalidParameterException' ||
            e.code == 'NotAuthorizedException' ||
            e.code == 'UserNotFoundException' ||
            e.code == 'ResourceNotFoundException') {
          message = e.message ?? e.code ?? e.toString();
        } else {
          message = 'An unknown client error occured';
        }
      } catch (e) {
        message = 'An unknown error occurred';
      }
    } else {
      message = 'Missing required attributes on user';
    }
    final snackBar = SnackBar(
      content: Text(message),
      action: SnackBarAction(
        label: 'OK',
        onPressed: () async {
          if (_user.hasAccess) {
            Navigator.pop(context);
            if (!_user.confirmed) {
              await Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => ConfirmationScreen(email: _user.email ?? 'no email found')),
              );
            } else {
              await Navigator.push(context, MaterialPageRoute(builder: (context) => SecureCounterScreen()));
            }
          }
        },
      ),
      duration: Duration(seconds: 30),
    );

    ScaffoldMessenger.of(context).showSnackBar(snackBar);
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
        future: _getValues(),
        builder: (context, AsyncSnapshot<UserService> snapshot) {
          if (snapshot.hasData) {
            if (_isAuthenticated) {
              return SecureCounterScreen();
            }
            final screenSize = MediaQuery.of(context).size;
            return Scaffold(
              appBar: AppBar(
                title: Text('Login'),
              ),
              body: Builder(
                builder: (BuildContext context) {
                  return Container(
                    child: Form(
                      key: _formKey,
                      child: ListView(
                        children: <Widget>[
                          ListTile(
                            leading: const Icon(Icons.email),
                            title: TextFormField(
                              initialValue: widget.email,
                              decoration: InputDecoration(hintText: 'example@inspire.my', labelText: 'Email'),
                              keyboardType: TextInputType.emailAddress,
                              onSaved: (n) => _user.email = n,
                            ),
                          ),
                          ListTile(
                            leading: const Icon(Icons.lock),
                            title: TextFormField(
                              decoration: InputDecoration(labelText: 'Password'),
                              obscureText: true,
                              onSaved: (n) => _user.password = n,
                            ),
                          ),
                          Container(
                            padding: EdgeInsets.all(20.0),
                            width: screenSize.width,
                            margin: EdgeInsets.only(
                              top: 10.0,
                            ),
                            child: ElevatedButton(
                              onPressed: () => submit(context),
                              child: Text(
                                'Login',
                                style: TextStyle(color: Colors.white),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            );
          }
          return Scaffold(appBar: AppBar(title: Text('Loading...')));
        });
  }
}
