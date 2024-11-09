import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:nfc_manager/nfc_manager.dart';
import 'package:StamComm/utils/stamp_utils.dart';
import 'package:StamComm/view/display_map.dart';  // 追加

class NFCButton extends StatefulWidget {
  final VoidCallback? onSnapComplete;

  const NFCButton({super.key, this.onSnapComplete});
  @override
  State<NFCButton> createState() => _NFCButtonState();
}

class _NFCButtonState extends State<NFCButton> {
  bool _isProcessing = false;
  bool _isSessionActive = false;

  @override
  void dispose() {
    if (_isSessionActive) {
      NfcManager.instance.stopSession();
    }
    super.dispose();
  }

  // NFCの読み取り
  Future<void> readNfc() async {
    if (_isProcessing || !mounted) return;

    final bool isNfcAvailable = await NfcManager.instance.isAvailable();
    if (!isNfcAvailable) {
      if (mounted) _showErrorDialog('NFCはこのデバイスで利用できません');
      return;
    }

    if (mounted) {
      setState(() => _isProcessing = true);
    }

    // NFCスキャンダイアログを表示
    if (mounted) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          title: const Text('NFCをスキャン'),
          content: const Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('NFCタグをスキャンしてください'),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () async {
                await NfcManager.instance.stopSession();
                _isSessionActive = false;
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (context) => DisplayMap()),
                  (route) => false,
                );
                setState(() => _isProcessing = false);
              },
              child: const Text('キャンセル'),
            ),
          ],
        ),
      );
    }

    _isSessionActive = true;
    NfcManager.instance.startSession(
      onDiscovered: (NfcTag tag) async {
        try {
          Ndef? ndef = Ndef.from(tag);
          if (ndef == null) {
            if (mounted) {
              await _handleError('このタグはNDEF非対応です');
            }
            return;
          }

          NdefMessage message = await ndef.read();
          String? id = _extractIdFromNdefMessage(message);

          if (id == null) {
            if (mounted) {
              await _handleError('有効なIDが見つかりません');
            }
            return;
          }

          final event = await fetchStampInfo(id);
          if (event == null) {
            if (mounted) {
              await _handleError('対応するイベントが見つかりません');
            }
            return;
          }

          bool locationValid =
              await validateLocation(event['latitude'], event['longitude']);
          if (!locationValid) {
            if (mounted) {
              await _handleError('現在位置とイベントの位置が遠すぎます');
            }
            return;
          }

          // 成功時の処理
          if (mounted) {
            Navigator.pop(context); // スキャン中のダイアログを閉じる
            await handleSuccessfulScan(context, event, id,
                onSnapComplete: widget.onSnapComplete);
          }
        } catch (e) {
          if (mounted) {
            await _handleError('エラーが発生しました');
          }
        } finally {
          if (mounted) {
            setState(() => _isProcessing = false);
          }
        }
      },
    );
  }

  Future<void> _handleError(String message) async {
    if (!mounted) return;
    
    // スキャン中のダイアログを閉じる
    Navigator.pop(context);
    
    // セッションを停止
    try {
      await NfcManager.instance.stopSession();
    } catch (e) {
      print("セッションの停止に失敗しました: $e");
    }
    _isSessionActive = false;
    
    // エラーダイアログを表示
    await _showErrorDialog(message);
  }

  String? _extractIdFromNdefMessage(NdefMessage message) {
    for (NdefRecord record in message.records) {
      if (record.typeNameFormat == NdefTypeNameFormat.nfcWellknown &&
          record.type.isNotEmpty &&
          record.type[0] == 0x54) {
        return utf8.decode(record.payload.sublist(3));
      }
    }
    return null;
  }

  Future<void> _showErrorDialog(String message) async {
    if (!mounted) return;
    
    await showDialog(
      context: context,
      barrierDismissible: false,  // 追加：ダイアログ外タップでの閉じを防止
      builder: (context) => AlertDialog(
        title: const Text('エラー'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context); // エラーダイアログを閉じる
              
              // マップ画面に戻る
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (context) => DisplayMap()),
                (route) => false,
              );
            },
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return FloatingActionButton(
      onPressed: readNfc,
      child: const Icon(Icons.nfc),
    );
  }
}
