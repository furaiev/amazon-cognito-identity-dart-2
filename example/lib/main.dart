import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:amazon_cognito_identity_dart_2/sig_v4.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:secure_counter/screens/home_screen.dart';

class Counter {
  int count;
  Counter(this.count);

  factory Counter.fromJson(json) {
    return Counter(json['count']);
  }
}

class CounterService {
  AwsSigV4Client awsSigV4Client;
  CounterService(this.awsSigV4Client);

  /// Retrieve user's previous count from Lambda + DynamoDB
  Future<Counter> getCounter() async {
    final signedRequest = SigV4Request(awsSigV4Client, method: 'GET', path: '/counter');
    final url = signedRequest.url;

    Map<String, String>? headers;
    if (signedRequest.headers != null) {
      headers = Map.from(signedRequest.headers!);
    }

    if (url != null) {
      final response = await http.get(Uri.parse(url), headers: headers);

      if (response.statusCode != 200 || json.decode(response.body)['count'] == null) {
        throw HttpException('Cannot get counter, statusCode: ${response.statusCode}, body: ${response.body}');
      }

      return Counter.fromJson(json.decode(response.body));
    } else {
      return Counter(-1);
    }
  }

  /// Increment user's count in DynamoDB
  Future<Counter> incrementCounter() async {
    final signedRequest = SigV4Request(awsSigV4Client, method: 'PUT', path: '/counter');
    final url = signedRequest.url;
    Map<String, String>? headers;
    if (signedRequest.headers != null) {
      headers = Map.from(signedRequest.headers!);
    }
    if (url != null) {
      final response = await http.put(Uri.parse(url), headers: headers);
      if (response.statusCode != 200 || json.decode(response.body)['count'] == null) {
        throw HttpException('Cannot get counter, statusCode: ${response.statusCode}, body: ${response.body}');
      }
      return Counter.fromJson(json.decode(response.body));
    } else {
      return Counter(-1);
    }
  }
}

void main() => runApp(SecureCounterApp());

class SecureCounterApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Cognito on Flutter',
      theme: ThemeData(
        primarySwatch: Colors.orange,
      ),
      home: HomePage(title: 'Cognito on Flutter'),
    );
  }
}
