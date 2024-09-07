import 'package:flutter/material.dart';
import 'package:sliding_up_panel/sliding_up_panel.dart';

class DisplayMap extends StatelessWidget {
  const DisplayMap({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('サンプル'),
      ),
      body: SlidingUpPanel(
        panel: Center(
          child: Text('スライドアップパネルの内容'),
        ),
        body: Center(
          child: Text('サンプル'),
        ),
      ),
    );
  }
}
