import 'package:amazon_cognito_identity_dart_2/cognito.dart';
import 'package:amazon_cognito_identity_dart_2/sig_v4.dart';
import 'package:flutter/material.dart';
import 'package:secure_counter/main.dart';
import 'package:secure_counter/screens/login_screen.dart';
import 'package:secure_counter/secrets.dart';
import 'package:secure_counter/user.dart';
import 'package:secure_counter/user_service.dart';

class SecureCounterScreen extends StatefulWidget {
  SecureCounterScreen({Key? key}) : super(key: key);

  @override
  _SecureCounterScreenState createState() => _SecureCounterScreenState();
}

class _SecureCounterScreenState extends State<SecureCounterScreen> {
  final _userService = UserService(userPool);
  late CounterService _counterService;
  late AwsSigV4Client _awsSigV4Client;
  User? _user = User();
  Counter _counter = Counter(0);
  bool _isAuthenticated = false;

  void _incrementCounter() async {
    final counter = await _counterService.incrementCounter();
    setState(() {
      _counter = counter;
    });
  }

  Future<UserService> _getValues(BuildContext context) async {
    try {
      await _userService.init();
      _isAuthenticated = await _userService.checkAuthenticated();
      if (_isAuthenticated) {
        // get user attributes from cognito
        _user = await _userService.getCurrentUser();

        // get session credentials
        final credentials = await _userService.getCredentials();
        if (credentials != null &&
            credentials.accessKeyId != null &&
            credentials.secretAccessKey != null) {
          _awsSigV4Client = AwsSigV4Client(
            credentials.accessKeyId!,
            credentials.secretAccessKey!,
            apiEndpoint,
            region: awsRegion,
            sessionToken: credentials.sessionToken,
          );

          // get previous count
          _counterService = CounterService(_awsSigV4Client);
          try {
            _counter = await _counterService.getCounter();
          } catch (e) {
            ScaffoldMessenger.of(context)
                .showSnackBar(SnackBar(content: Text(e.toString())));
          }
        }
      }
      return _userService;
    } on CognitoClientException catch (e) {
      if (e.code == 'NotAuthorizedException') {
        await _userService.signOut();
        Navigator.pop(context);
      }
      rethrow;
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
        future: _getValues(context),
        builder: (context, AsyncSnapshot<UserService> snapshot) {
          if (snapshot.hasData) {
            if (!_isAuthenticated) {
              return LoginScreen();
            }

            return Scaffold(
              appBar: AppBar(
                title: Text('Secure Counter'),
              ),
              body: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    Text(
                      'Welcome ${_user?.name}!',
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
                    Divider(),
                    Text(
                      'You have pushed the button this many times:',
                    ),
                    Text(
                      '${_counter.count}',
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
                    Divider(),
                    Center(
                      child: InkWell(
                        onTap: () {
                          _userService.signOut();
                          Navigator.pop(context);
                        },
                        child: Text(
                          'Logout',
                          style: TextStyle(color: Colors.blueAccent),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              floatingActionButton: FloatingActionButton(
                onPressed: () {
                  if (snapshot.hasData) {
                    _incrementCounter();
                  }
                },
                tooltip: 'Increment',
                child: Icon(Icons.add),
              ),
            );
          }
          return Scaffold(appBar: AppBar(title: Text('Loading...')));
        });
  }
}
