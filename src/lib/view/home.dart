import 'package:flutter/material.dart';

class HomePage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Image.asset(
          'lib/images/kumamon.jpg', // 画像のパスを指定
          height: 40, 
        ),
        centerTitle: true, // タイトルを中央に配置
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          children: <Widget>[
            SizedBox(
              width: MediaQuery.of(context).size.width * 0.9,
              height: 70,
              child: ElevatedButton(
                onPressed: () {
                  // ボタン1が押されたときの処理
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color.fromARGB(255, 217, 217, 217),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(5), // 角の丸さを設定
                  ),
                ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.start,
                children: <Widget>[
                  Padding(
                      padding: const EdgeInsets.fromLTRB(0, 0, 0, 0), // 上下左右に同じ余白を設定
                      child: Image.asset(
                        'lib/images/kumamon.jpg', // 画像のパスを指定
                        width: 50,
                        height: 50,
                      ),
                    ),
                  Expanded(
                      child: Text(
                        '宇宙ロック祭inみずほPayPayドーム',
                        textAlign: TextAlign.right,
                        softWrap: false,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  Expanded(
                      child: Text(
                        'Cosmic Chaos',
                        textAlign: TextAlign.end,
                        softWrap: true,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 10,
                        ),
                      ),
                    ),
                ]
                )
              ),
            ),
            SizedBox(height: 10), // ボタン間のスペース
               SizedBox(
              width: MediaQuery.of(context).size.width * 0.9,
              height: 70,
              child: ElevatedButton(
                onPressed: () {
                  // ボタン1が押されたときの処理
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color.fromARGB(255, 217, 217, 217),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(5), // 角の丸さを設定
                  ),
                ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.start,
                children: <Widget>[
                  Padding(
                      padding: const EdgeInsets.fromLTRB(0, 0, 0, 0), // 上下左右に同じ余白を設定
                      child: Image.asset(
                        'lib/images/kumamon.jpg', // 画像のパスを指定
                        width: 50,
                        height: 50,
                      ),
                    ),
                  Expanded(
                      child: Text(
                        '宇宙ロック祭inみずほPayPayドーム',
                        textAlign: TextAlign.right,
                        softWrap: false,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  Expanded(
                      child: Text(
                        'Cosmic Chaos',
                        textAlign: TextAlign.end,
                        softWrap: true,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 10,
                        ),
                      ),
                    ),
                ]
                )
              ),
            ),
            SizedBox(height: 10), // ボタン間のスペース
                        SizedBox(
              width: MediaQuery.of(context).size.width * 0.9,
              height: 70,
              child: ElevatedButton(
                onPressed: () {
                  // ボタン1が押されたときの処理
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color.fromARGB(255, 217, 217, 217),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(5), // 角の丸さを設定
                  ),
                ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.start,
                children: <Widget>[
                  Padding(
                      padding: const EdgeInsets.fromLTRB(0, 0, 0, 0), // 上下左右に同じ余白を設定
                      child: Image.asset(
                        'lib/images/kumamon.jpg', // 画像のパスを指定
                        width: 50,
                        height: 50,
                      ),
                    ),
                  Expanded(
                      child: Text(
                        '宇宙ロック祭inみずほPayPayドーム',
                        textAlign: TextAlign.right,
                        softWrap: false,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  Expanded(
                      child: Text(
                        'Cosmic Chaos',
                        textAlign: TextAlign.end,
                        softWrap: true,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 10,
                        ),
                      ),
                    ),
                ]
                )
              ),
            ),
          ],
        ),
      ),
    );
  }
}