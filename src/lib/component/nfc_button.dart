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
  void readNfc() async {
    final bool isNfcAvailable = await NfcManager.instance.isAvailable();
    print('NFC availability: $isNfcAvailable');
    if (!isNfcAvailable) {
      _showErrorDialog('NFC is not available on this device');
      return;
    } else {
      NfcManager.instance.startSession(
        onDiscovered: (NfcTag tag) async {
          Ndef? ndef = Ndef.from(tag);
          if (ndef == null) {
            print('Tag is not NDEF compatible');
            return;
          }
          try {
            NdefMessage message = await ndef.read();
            List<NdefRecord> records = message.records;
            print('Records: $records');

            String id = '';
            double latitude = 0;
            double longitude = 0;

            for (NdefRecord record in records) {
              Uint8List payload = record.payload;

              // テキストレコード（名前）
              if (record.typeNameFormat == NdefTypeNameFormat.nfcWellknown &&
                  record.type.isNotEmpty &&
                  record.type[0] == 0x54) { // 'T' == 0x54 (Text record)
                String recordId = utf8.decode(payload.sublist(3));
                print('id Payload: $recordId');
                id = recordId;
              }
            }

            // assets/data/sample_data.jsonからイベント情報を読み込む
            final eventData = await _loadStampData();
            final event = eventData.firstWhere((element) => element['id'] == id, orElse: () => null);
            print('Event: $event');
            if (event != null) {
              latitude = event['latitude'];
              longitude = event['longitude'];
            } else {
              _showErrorDialog('対応するイベントが見つかりません');
              return;
            }

            // 現在の位置情報を取得
            Position currentPosition = await Geolocator.getCurrentPosition(
              desiredAccuracy: LocationAccuracy.high,
            );

            // 距離を計算（メートル単位）
            double distance = _calculateDistance(
              currentPosition.latitude,
              currentPosition.longitude,
              latitude,
              longitude,
            );

            print('Distance to NFC tag: $distance meters');

            bool checkPassed = distance <= 30;

            if (checkPassed) {
              setState(() {
                _id = id;
                _name = event['name']; // イベント名を取得
                _descriptionImageUrl = event['description_image_url']; // イメージURLを取得
                _descriptionText = event['description_text']; // 説明文を取得
                _checkPassed = true;
              });

              // IDをローカルストレージに保存
              await _saveUserStamp(id);

              // 新しい画面に遷移してデータを表示
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => StampSuccessScreen(
                    name: _name, 
                    id: _id, 
                    descriptionImageUrl: _descriptionImageUrl, // 修正: 画像URLの変数名を一致させる
                    descriptionText: _descriptionText,
                  ),
                ),
              );
            } else {
              _showErrorDialog('現在位置とイベントの位置が遠すぎます');
            }

          } catch (e) {
            print('Error reading NFC: $e');
            _showErrorDialog('Error reading NFC: $e');
          } finally {
            NfcManager.instance.stopSession();
          }
        },
        onError: (dynamic error) {
          print('NFC Error: ${error.message}');
          _showErrorDialog('NFC Error: ${error.message}');
          NfcManager.instance.stopSession();
          return Future.value();
        },
      );
    }
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
    // final prefs = await SharedPreferences.getInstance();
    // await prefs.setString('id', id);
    // print('ID saved to local storage: $id');
    // print(prefs.getString('id')); 
    try{
      final userId = supabase.auth.currentUser?.id;
      if (userId == null) {
        print("User is not logged in");
        return;
      }

      final currentTime = DateTime.now().toUtc().toIso8601String();
      final uuid = Uuid();
      final response = await supabase.from('user_stamps').insert({
        'id':uuid.v4(),
        'user_id': userId,
        'stamp_id': stampId,
        'created_at': currentTime,
      });
    } catch (e) {
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
