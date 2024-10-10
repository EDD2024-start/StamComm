import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:nfc_manager/nfc_manager.dart';
import 'package:geolocator/geolocator.dart';
import 'package:StamComm/component/stamp_success_screen.dart';
import 'dart:math';

class NFCButton extends StatefulWidget {
  const NFCButton({super.key});

  @override
  State<NFCButton> createState() => _NFCButtonState();
}

class _NFCButtonState extends State<NFCButton> {
  String _name = ''; // 取得した名前を保存する変数
  bool _checkPassed = false; // チェック結果のフラグ

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

            // 各レコードの処理
            String name = '';
            double latitude = 0;
            double longitude = 0;

            for (NdefRecord record in records) {
              Uint8List payload = record.payload;

              // テキストレコード（名前）
              if (record.typeNameFormat == NdefTypeNameFormat.nfcWellknown &&
                  record.type.isNotEmpty &&
                  record.type[0] == 0x54) { // 'T' == 0x54 (Text record)
                String text = utf8.decode(payload.sublist(3));
                print('Text Payload: $text');
                name = text;
              }

              // URIレコード（緯度経度）
              else if (record.typeNameFormat == NdefTypeNameFormat.nfcWellknown &&
                  record.type.isNotEmpty &&
                  record.type[0] == 0x55) { // 'U' == 0x55 (URI record)
                String geoUri = utf8.decode(payload.sublist(1)); // URIは最初のバイトをスキップ
                print('Geo Payload: $geoUri');

                if (geoUri.startsWith('geo:')) {
                  // "geo:" 以降の部分を分割して緯度経度を取得
                  List<String> latLon = geoUri.substring(4).split(',');
                  latitude = double.tryParse(latLon[0]) ?? 0.0;
                  longitude = double.tryParse(latLon[1]) ?? 0.0;
                }
              }
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

            // 許容範囲内（例えば50メートル以内）であればチェック成功
            bool checkPassed = distance <= 50; // 許容範囲50m

            if (checkPassed) {
              setState(() {
                _name = name;
                _checkPassed = true;
              });

              // 新しい画面に遷移してデータを表示
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => StampSuccessScreen(name: _name),
                ),
              );
            } else {
              _showErrorDialog('現在位置とNFCタグの位置が遠すぎます');
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

  // 緯度・経度から距離を計算するメソッド（ハバースの公式を使用）
  double _calculateDistance(double lat1, double lon1, double lat2, double lon2) {
    const double radiusOfEarth = 6371000; // 地球の半径（メートル）
    double dLat = _degreesToRadians(lat2 - lat1);
    double dLon = _degreesToRadians(lon2 - lon1);

    double a = 
        sin(dLat / 2) * sin(dLat / 2) +
        cos(_degreesToRadians(lat1)) * cos(_degreesToRadians(lat2)) *
        sin(dLon / 2) * sin(dLon / 2);
    double c = 2 * atan2(sqrt(a), sqrt(1 - a));

    return radiusOfEarth * c; // 距離（メートル）
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
