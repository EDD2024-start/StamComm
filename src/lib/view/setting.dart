import 'package:flutter/material.dart';

class SettingPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Setting Page'),
      ),
      body: Center(
        child: Text(
          'Welcome to Setting Page!',
          style: TextStyle(fontSize: 24),
        ),
      ),
    );
  }
}