import 'package:flutter/material.dart';
import 'package:sliding_up_panel/sliding_up_panel.dart';
import '../component/stamp_detail_panel_component.dart'; // slide_up_content.dartをインポート

class DisplayMap extends StatelessWidget {
  const DisplayMap({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('サンプル'),
      ),
      body: SlidingUpPanel(
        panel: const SlideUpContent(), // SlideUpContentコンポーネントを使用
        body: Center(
          child: const Text('サンプル'),
        ),
         borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(12),
            topRight: Radius.circular(12),
          ),
        minHeight: 100,
        maxHeight: 700,
      ),
    );
  }
}
