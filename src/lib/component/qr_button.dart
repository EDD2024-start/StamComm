// qr_button.dart
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:qr_code_scanner/qr_code_scanner.dart';
import 'package:geolocator/geolocator.dart';
import 'package:StamComm/component/stamp_success_screen.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:StamComm/utils/stamp_utils.dart';

class QRButton extends StatefulWidget {
  final VoidCallback onSnapComplete;

  const QRButton({super.key, required this.onSnapComplete});

  @override
  State<QRButton> createState() => _QRButtonState();
}

class _QRButtonState extends State<QRButton> {
  final supabase = Supabase.instance.client;
  final GlobalKey qrKey = GlobalKey(debugLabel: 'QR');
  QRViewController? controller;
  bool _isProcessing = false;

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

  // QRスキャニングセッションを初期化
  void _onQRViewCreated(QRViewController controller) {
    this.controller = controller;
    controller.scannedDataStream.listen((scanData) {
      if (!_isProcessing) {
        _isProcessing = true;
        _processQRCode(scanData.code).then((_) {});
      }
    });
  }

  // スキャンされたQRコードを処理
  Future<void> _processQRCode(String? code) async {
    if (code == null) {
      await _showErrorDialog('QRコードの読み取りに失敗しました');
      return;
    }

    String id = code.trim();
    print('Scanned ID: $id');

    try {
      final event = await fetchStampInfo(id);

      if (event != null) {
        print('Event: $event');
        double latitude = event['latitude'];
        double longitude = event['longitude'];

        // 現在の位置情報を取得
        Position currentPosition = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high,
        );

        // 距離を計算
        double distance = calculateDistance(
          currentPosition.latitude,
          currentPosition.longitude,
          latitude,
          longitude,
        );

        print('Distance to event: $distance meters');

        bool checkPassed = distance <= 30;

        if (checkPassed) {
          await _handleSuccessfulScan(event, id);
        } else {
          await controller?.pauseCamera();
          await _showErrorDialog('現在位置とイベントの位置が遠すぎます');
        }
      } else {
        await _showErrorDialog('対応するイベントが見つかりません');
      }
    } catch (e) {
      print('Error processing QR code: $e');
      await controller?.pauseCamera();
      await _showErrorDialog('QRコードの処理中にエラーが発生しました: $e');
    } finally {
      _isProcessing = false;
    }
  }

  // スキャンが成功した際の処理
  Future<void> _handleSuccessfulScan(
      Map<String, dynamic> event, String id) async {
    await handleSuccessfulScan(context, event, id,
        onSnapComplete: widget.onSnapComplete);
  }

  // エラーダイアログを表示
  Future<void> _showErrorDialog(String message) async {
    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('エラー'),
        content: Text(message),
        actions: <Widget>[
          TextButton(
            onPressed: () async {
              Navigator.of(context, rootNavigator: true).pop();
              await controller?.resumeCamera();
            },
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  // 緯度・経度から距離を計算（メートル単位）
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

  // 度をラジアンに変換
  double _degreesToRadians(double degrees) {
    return degrees * pi / 180;
  }

  @override
  void dispose() {
    controller?.dispose();
    super.dispose();
  }

  // QRスキャンセッションを開始
  void _startQRScan() {
    showDialog(
      context: context,
      barrierDismissible: false, // スキャン中にダイアログを閉じないようにする
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
              Navigator.of(context, rootNavigator: true).pop();
              setState(() {
                _isProcessing = false;
              });
            },
            child: const Text('キャンセル'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return FloatingActionButton(
      onPressed: _startQRScan,
      child: const Icon(Icons.qr_code),
    );
  }
}
