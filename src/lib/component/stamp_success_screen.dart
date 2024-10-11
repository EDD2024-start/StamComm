import 'package:flutter/material.dart';

// スタンプ取得成功画面
class StampSuccessScreen extends StatelessWidget {
  final String name;
  final String id;  // IDを受け取るための変数を追加

  const StampSuccessScreen({
    super.key, 
    required this.name, 
    required this.id,  // コンストラクタにもIDを追加
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('スタンプ取得'),
        leading: IconButton(
        icon: const Icon(Icons.arrow_back),
        onPressed: () {
          Navigator.pop(context, id);  // idを返す
        },
      ),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const Text(
                'おめでとうございます！！\nスタンプを取得しました！！',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              Text(
                '名前：$name',
                style: const TextStyle(fontSize: 18),
              ),
              const SizedBox(height: 10),
              Text(
                'ID：$id',  // IDを表示する部分を追加
                style: const TextStyle(fontSize: 18),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
