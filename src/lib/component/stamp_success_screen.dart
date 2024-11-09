import 'package:flutter/material.dart';

// スタンプ取得成功画面
class StampSuccessScreen extends StatelessWidget {
  final String name; // 名前を受け取るための変数
  final String id; // IDを受け取るための変数
  final String descriptionImageUrl; // 画像URLを受け取るための変数
  final String descriptionText; // 説明文を受け取るための変数
  final String userPhotoUrl; // 追加：ユーザーが撮影した写真のURL

  const StampSuccessScreen({
    super.key,
    required this.name,
    required this.id,
    required this.descriptionText, // 引数を適切に受け取る
    required this.descriptionImageUrl, // 引数を適切に受け取る
    required this.userPhotoUrl, // 追加
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('スタンプ取得'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pop(context, {'id': id, 'needsRestart': true});
          },
        ),
      ),
      body: Center(
        child: SingleChildScrollView(
          // スクロール可能にする
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
                  name,
                  style: const TextStyle(fontSize: 18),
                ),
                const SizedBox(height: 10),
                Text(
                  descriptionText,
                  style: const TextStyle(fontSize: 16),
                ),
                const SizedBox(height: 20),
                // スタンプの説明画像
                Image.network(
                  descriptionImageUrl,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return const Text('画像を読み込めませんでした。');
                  },
                ),
                const SizedBox(height: 20),
                // ユーザーが撮影した写真を表示
                const Text(
                  '撮影した写真:',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 10),
                Image.network(
                  userPhotoUrl,
                  fit: BoxFit.cover,
                  loadingBuilder: (BuildContext context, Widget child,
                      ImageChunkEvent? loadingProgress) {
                    if (loadingProgress == null) {
                      return child;
                    }
                    return SizedBox(
                      height: 200, // 適切な高さを設定
                      child: Center(
                        child: CircularProgressIndicator(
                          value: loadingProgress.expectedTotalBytes != null
                              ? loadingProgress.cumulativeBytesLoaded /
                                  loadingProgress.expectedTotalBytes!
                              : null,
                        ),
                      ),
                    );
                  },
                  errorBuilder: (context, error, stackTrace) {
                    return const Text('撮影した写真を読み込めませんでした。');
                  },
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context, {'id': id, 'needsRestart': true});
                  },
                  child: const Text('戻る'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
