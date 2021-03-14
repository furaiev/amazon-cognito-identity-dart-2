import 'package:amazon_cognito_identity_dart_2/cognito.dart';
import 'package:flutter/material.dart';
import 'package:secure_counter/screens/login_screen.dart';
import 'package:secure_counter/secrets.dart';
import 'package:secure_counter/user.dart';
import 'package:secure_counter/user_service.dart';

class ConfirmationScreen extends StatefulWidget {
  ConfirmationScreen({Key? key, this.email}) : super(key: key);

  final String? email;

  @override
  _ConfirmationScreenState createState() => _ConfirmationScreenState();
}

class _ConfirmationScreenState extends State<ConfirmationScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  late String confirmationCode;
  final User _user = User();
  final _userService = UserService(userPool);

  Future _submit(BuildContext context) async {
    _formKey.currentState?.save();
    var accountConfirmed = false;
    String message;
    try {
      if (_user.email != null) {
        accountConfirmed = await _userService.confirmAccount(_user.email!, confirmationCode);
        message = 'Account successfully confirmed!';
      } else {
        message = 'Unknown client error occurred';
      }
    } on CognitoClientException catch (e) {
      if (e.code == 'InvalidParameterException' ||
          e.code == 'CodeMismatchException' ||
          e.code == 'NotAuthorizedException' ||
          e.code == 'UserNotFoundException' ||
          e.code == 'ResourceNotFoundException') {
        message = e.message ?? e.code ?? e.toString();
      } else {
        message = 'Unknown client error occurred';
      }
    } catch (e) {
      message = 'Unknown error occurred';
    }

    final snackBar = SnackBar(
      content: Text(message),
      action: SnackBarAction(
        label: 'OK',
        onPressed: () {
          if (accountConfirmed) {
            Navigator.pop(context);
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => LoginScreen(email: _user.email)),
            );
          }
        },
      ),
      duration: Duration(seconds: 30),
    );

    ScaffoldMessenger.of(context).showSnackBar(snackBar);
  }

  Future _resendConfirmation(BuildContext context) async {
    _formKey.currentState?.save();
    String message;
    try {
      if (_user.email != null) {
        await _userService.resendConfirmationCode(_user.email!);
        message = 'Confirmation code sent to ${_user.email!}!';
      } else {
        message = 'Unknown client error occurred';
      }
    } on CognitoClientException catch (e) {
      if (e.code == 'LimitExceededException' || e.code == 'InvalidParameterException' || e.code == 'ResourceNotFoundException') {
        message = e.message ?? e.code ?? e.toString();
      } else {
        message = 'Unknown client error occurred';
      }
    } catch (e) {
      message = 'Unknown error occurred';
    }

    final snackBar = SnackBar(
      content: Text(message),
      action: SnackBarAction(
        label: 'OK',
        onPressed: () {},
      ),
      duration: Duration(seconds: 30),
    );

    ScaffoldMessenger.of(context).showSnackBar(snackBar);
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    return Scaffold(
      appBar: AppBar(
        title: Text('Confirm Account'),
      ),
      body: Builder(
          builder: (BuildContext context) => Container(
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
                          onSaved: (n) => _user.email = n ?? '',
                        ),
                      ),
                      ListTile(
                        leading: const Icon(Icons.lock),
                        title: TextFormField(
                          decoration: InputDecoration(labelText: 'Confirmation Code'),
                          onSaved: (c) => confirmationCode = c ?? '',
                        ),
                      ),
                      Container(
                        padding: EdgeInsets.all(20.0),
                        width: screenSize.width,
                        margin: EdgeInsets.only(
                          top: 10.0,
                        ),
                        child: ElevatedButton(
                          onPressed: () {
                            _submit(context);
                          },
                          child: Text(
                            'Submit',
                            style: TextStyle(color: Colors.white),
                          ),
                        ),
                      ),
                      Center(
                        child: InkWell(
                          onTap: () {
                            _resendConfirmation(context);
                          },
                          child: Text(
                            'Resend Confirmation Code',
                            style: TextStyle(color: Colors.blueAccent),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              )),
    );
  }
}
