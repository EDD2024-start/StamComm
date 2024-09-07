import 'package:flutter/material.dart';

class SlideUpContent extends StatelessWidget {
  const SlideUpContent({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        'スライドアップ',
        style: TextStyle(fontSize: 24),
      ),
    );
  }
}