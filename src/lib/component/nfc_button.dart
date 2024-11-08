import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:nfc_manager/nfc_manager.dart';
import 'package:geolocator/geolocator.dart';
import 'package:StamComm/component/stamp_success_screen.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:StamComm/utils/stamp_utils.dart';

class NFCButton extends StatefulWidget {
  const NFCButton({super.key});

  @override
  State<NFCButton> createState() => _NFCButtonState();
}

class _NFCButtonState extends State<NFCButton> {
  String _name = ''; // 取得した名前を保存する変数
  String _descriptionImageUrl = ''; // 取得した画像URLを保存する変数
  String _descriptionText= ''; // 取得した説明文を保存する変数
  String _id = ''; // 取得したIDを保存する変数
  bool _checkPassed = false; // チェック結果のフラグ
  final supabase = Supabase.instance.client;

  // NFCの読み取り
  Future<void> readNfc() async {
    final bool isNfcAvailable = await NfcManager.instance.isAvailable();
    if (!isNfcAvailable) {
      _showErrorDialog('NFC is not available on this device');
      return;
    }

    NfcManager.instance.startSession(
      onDiscovered: (NfcTag tag) async {
        Ndef? ndef = Ndef.from(tag);
        if (ndef == null) {
          _showErrorDialog('Tag is not NDEF compatible');
          return;
        }

        try {
          NdefMessage message = await ndef.read();
          List<NdefRecord> records = message.records;

          String id = '';

          for (NdefRecord record in records) {
            Uint8List payload = record.payload;

            // テキストレコードからIDを取得
            if (record.typeNameFormat == NdefTypeNameFormat.nfcWellknown &&
                record.type.isNotEmpty &&
                record.type[0] == 0x54) {
              id = utf8.decode(payload.sublist(3));
              break;
            }
          }

          // Supabaseから該当のIDのデータを取得
          final event = await fetchStampInfo(id);

          if (event == null) {
            _showErrorDialog('対応するイベントが見つかりません');
            return;
          }

          // 取得したイベントデータを保存
          final latitude = event['latitude'];
          final longitude = event['longitude'];

          Position currentPosition = await Geolocator.getCurrentPosition(
            desiredAccuracy: LocationAccuracy.high,
          );

          double distance = calculateDistance(
            currentPosition.latitude,
            currentPosition.longitude,
            latitude,
            longitude,
          );

          bool checkPassed = distance <= 30;

          if (checkPassed) {
            setState(() {
              _id = id;
              _name = event['name'];
              _descriptionImageUrl = event['description_image_url'];
              _descriptionText = event['description_text'];
              _checkPassed = true;
            });

            await handleSuccessfulScan(context, event, id);
          } else {
            _showErrorDialog('現在位置とイベントの位置が遠すぎます');
          }
        } catch (e) {
          if (!mounted) return; // ウィジェットがアンマウントされている場合は処理を中断
          _showErrorDialog('Error reading NFC: $e');
        } finally {
          NfcManager.instance.stopSession();
        }
      },
    );
  }

  Future<List<dynamic>> _loadStampData() async {
    final response = await supabase
        .from('stamps') // データベーステーブル名
        .select();
    // データ取得成功時
    final data = json.encode(response);
    print("Supabase data: $data");
    return json.decode(data);
  }

  // エラーダイアログを表示するメソッド
  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('エラー'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
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
