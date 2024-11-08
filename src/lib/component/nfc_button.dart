import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:nfc_manager/nfc_manager.dart';
import 'package:geolocator/geolocator.dart';
import 'package:StamComm/component/stamp_success_screen.dart';
import 'dart:math';
import 'package:flutter/services.dart' show rootBundle;
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';


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
          final response = await supabase
              .from('stamps')
              .select()
              .eq('id', id)
              .single();  // 単一レコードを取得

          if (response == null) {
            _showErrorDialog('対応するイベントが見つかりません');
            return;
          }

          // 取得したイベントデータを保存
          final event = response;
          final latitude = event['latitude'];
          final longitude = event['longitude'];

          Position currentPosition = await Geolocator.getCurrentPosition(
            desiredAccuracy: LocationAccuracy.high,
          );

          double distance = _calculateDistance(
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

            await _saveUserStamp(id);

            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => StampSuccessScreen(
                  name: _name,
                  id: _id,
                  descriptionImageUrl: _descriptionImageUrl,
                  descriptionText: _descriptionText,
                ),
              ),
            );
          } else {
            _showErrorDialog('現在位置とイベントの位置が遠すぎます');
          }
        } catch (e) {
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

  // 取得済みスタンプとしてuser_stampsにデータを挿入するメソッド
  Future<void> _saveUserStamp(String stampId) async {
    try {
      final userId = supabase.auth.currentUser?.id;
      if (userId == null) {
        print("User is not logged in");
        return;
      }

      final currentTime = DateTime.now().toUtc().toIso8601String();
      final uuid = Uuid();
      await supabase.from('user_stamps').insert({
        'id': uuid.v4(),
        'user_id': userId,
        'stamp_id': stampId,
        'created_at': currentTime,
      });
    } on PostgrestException catch (error) {
      if (error.code == "23505") { // "23505" は重複エラーのコード

        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            content: Text("このスタンプは取得済みです。"),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text("OK"),
              ),
            ],
          ),
        );
      }
    }catch (e) {
      print("Error: $e");
    }
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

  // 緯度・経度から距離を計算するメソッド
  double _calculateDistance(double lat1, double lon1, double lat2, double lon2) {
    const double radiusOfEarth = 6371000;
    double dLat = _degreesToRadians(lat2 - lat1);
    double dLon = _degreesToRadians(lon2 - lon1);

    double a = 
        sin(dLat / 2) * sin(dLat / 2) +
        cos(_degreesToRadians(lat1)) * cos(_degreesToRadians(lat2)) *
        sin(dLon / 2) * sin(dLon / 2);
    double c = 2 * atan2(sqrt(a), sqrt(1 - a));

    return radiusOfEarth * c;
  }

  double _degreesToRadians(double degrees) {
    return degrees * pi / 180;
  }

  @override
  Widget build(BuildContext context) {
    return FloatingActionButton(
      onPressed: readNfc,
      child: const Icon(Icons.nfc),
    );
  }
}
