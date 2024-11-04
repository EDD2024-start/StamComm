import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:qr_code_scanner/qr_code_scanner.dart';
import 'package:geolocator/geolocator.dart';
import 'package:StamComm/component/stamp_success_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/services.dart' show rootBundle;

class QRButton extends StatefulWidget {
  const QRButton({super.key});

  @override
  State<QRButton> createState() => _QRButtonState();
}

class _QRButtonState extends State<QRButton> {
  String _name = ''; // 取得した名前を保存する変数
  String _descriptionImageUrl = ''; // 取得した画像URLを保存する変数
  String _descriptionText = ''; // 取得した説明文を保存する変数
  String _id = ''; // 取得したIDを保存する変数
  bool _checkPassed = false; // チェック結果のフラグ
  final GlobalKey qrKey = GlobalKey(debugLabel: 'QR');
  QRViewController? controller;
  bool _isProcessing = false; // 処理中かどうかのフラグ

  @override
  void reassemble() {
    super.reassemble();
    if (controller != null) {
      if (Theme.of(context).platform == TargetPlatform.android) {
        controller!.pauseCamera();
      } else if (Theme.of(context).platform == TargetPlatform.iOS) {
        controller!.resumeCamera();
      }
    }
  }

  // QRコードの読み取り
  void _onQRViewCreated(QRViewController controller) {
    this.controller = controller;
    controller.scannedDataStream.listen((scanData) {
      if (!_isProcessing) {
        _isProcessing = true;
        _processQRCode(scanData.code);
      }
    });
  }

  // QRコードを処理するメソッド
  Future<void> _processQRCode(String? code) async {
    if (code == null) {
      _showErrorDialog('QRコードの読み取りに失敗しました');
      _isProcessing = false;
      return;
    }

    String id = code.trim(); // QRコードから取得したID
    print('Scanned ID: $id');

    try {
      // assets/data/sample_data.jsonからイベント情報を読み込む
      final eventData = await _loadEventData();
      final event = eventData.firstWhere(
        (element) => element['id'] == id,
        orElse: () => null,
      );

      print('Event: $event');
      if (event != null) {
        double latitude = event['latitude'];
        double longitude = event['longitude'];

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

        print('Distance to event: $distance meters');

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
          await _saveIdToLocalStorage(id);

          // 新しい画面に遷移してデータを表示
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

          // カメラを停止
          controller?.stopCamera();
        } else {
          _showErrorDialog('現在位置とイベントの位置が遠すぎます');
        }
      } else {
        _showErrorDialog('対応するイベントが見つかりません');
      }
    } catch (e) {
      print('Error processing QR code: $e');
      _showErrorDialog('QRコードの処理中にエラーが発生しました: $e');
    } finally {
      _isProcessing = false;
    }
  }

  // assets/data/sample_data.jsonからイベント情報を読み込む
  Future<List<dynamic>> _loadEventData() async {
    String jsonString =
        await rootBundle.loadString('assets/data/sample_data.json');
    return json.decode(jsonString);
  }

  // ローカルストレージにIDを保存するメソッド
  Future<void> _saveIdToLocalStorage(String id) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('id', id);
    print('ID saved to local storage: $id');
    print(prefs.getString('id'));
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
  double _calculateDistance(
      double lat1, double lon1, double lat2, double lon2) {
    const double radiusOfEarth = 6371000; // メートル
    double dLat = _degreesToRadians(lat2 - lat1);
    double dLon = _degreesToRadians(lon2 - lon1);

    double a = sin(dLat / 2) * sin(dLat / 2) +
        cos(_degreesToRadians(lat1)) *
            cos(_degreesToRadians(lat2)) *
            sin(dLon / 2) *
            sin(dLon / 2);
    double c = 2 * atan2(sqrt(a), sqrt(1 - a));

    return radiusOfEarth * c;
  }

  double _degreesToRadians(double degrees) {
    return degrees * pi / 180;
  }

  @override
  void dispose() {
    controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FloatingActionButton(
      onPressed: () {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('QRコードをスキャン'),
            content: SizedBox(
              width: double.infinity,
              height: 300,
              child: QRView(
                key: qrKey,
                onQRViewCreated: _onQRViewCreated,
                overlay: QrScannerOverlayShape(
                  borderColor: Colors.blue,
                  borderRadius: 10,
                  borderLength: 30,
                  borderWidth: 10,
                  cutOutSize: 250,
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () {
                  controller?.stopCamera();
                  Navigator.pop(context);
                },
                child: const Text('キャンセル'),
              ),
            ],
          ),
        );
      },
      child: const Icon(Icons.qr_code),
    );
  }
}
