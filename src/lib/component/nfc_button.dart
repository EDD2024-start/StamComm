import 'package:flutter/material.dart';
import 'package:nfc_manager/nfc_manager.dart';

class NFCButton extends StatelessWidget {
  const NFCButton({super.key});

  @override
  Widget build(BuildContext context) {
    return FloatingActionButton(
      onPressed: () async {
        // NFCがサポートされているか確認
        bool isAvailable = await NfcManager.instance.isAvailable();
        if (isAvailable) {
          // NFC読み取り処理を開始
          _startNfcSession(context);
        } else {
          // NFCが利用できない場合
          _showMessage(context, 'このデバイスではNFCがサポートされていません。');
        }
      },
      backgroundColor: Colors.green,
      child: const Icon(Icons.nfc),
    );
  }

  void _startNfcSession(BuildContext context) async {
    NfcManager.instance.startSession(
      onDiscovered: (NfcTag tag) async {
        // NFCタグの内容を取得
        var nfcData = tag.data;

        // NFC読み取り後にセッションを終了
        NfcManager.instance.stopSession();

        // タグ情報をモーダルウィンドウに表示
        _showMessage(context, 'NFCタグが読み取られました: $nfcData');
      },
      onError: (error) async {
        // エラー処理
        NfcManager.instance.stopSession();
        _showMessage(context, 'NFC読み取り中にエラーが発生しました: $error');
      },
    );
  }

  void _showMessage(BuildContext context, String message) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('NFC読み取り'),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // モーダルを閉じる
              },
              child: const Text('閉じる'),
            ),
          ],
        );
      },
    );
  }
}
