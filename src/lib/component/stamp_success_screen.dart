import 'package:flutter/material.dart';

// スタンプ取得成功画面
class StampSuccessScreen extends StatelessWidget {
  final String name; // 名前を受け取るための変数
  final String id; // IDを受け取るための変数
  final String descriptionImageUrl; // 画像URLを受け取るための変数
  final String descriptionText; // 説明文を受け取るための変数

  const StampSuccessScreen({
    super.key, 
    required this.name, 
    required this.id, 
    required this.descriptionText, // 引数を適切に受け取る
    required this.descriptionImageUrl, // 引数を適切に受け取る
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('スタンプ取得'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pop(context, id); // idを返す
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
                '$name',
                style: const TextStyle(fontSize: 18),
              ),
              const SizedBox(height: 10),
              Text(
                descriptionText,
                style: const TextStyle(fontSize: 16),
              ),
              // 画像URLを表示する部分
              Image.network(
                descriptionImageUrl, 
                fit: BoxFit.cover, // 画像を適切に表示
                errorBuilder: (context, error, stackTrace) {
                  return const Text('画像を読み込めませんでした。'); // エラーハンドリング
                },
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context, id); // idを返す
                },
                child: const Text('戻る'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
