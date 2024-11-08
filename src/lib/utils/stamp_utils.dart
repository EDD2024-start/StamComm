import 'dart:io';
import 'dart:math';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import 'package:StamComm/component/stamp_success_screen.dart';
import 'package:image_picker/image_picker.dart';
import 'package:StamComm/view/display_map.dart';

final supabase = Supabase.instance.client;

double calculateDistance(double lat1, double lon1, double lat2, double lon2) {
  const double radiusOfEarth = 6371000;
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

// 度をラジアンに変換
double degreesToRadians(double degrees) {
  return degrees * pi / 180;
}

// Supabaseからスタンプ情報を取得
Future<Map<String, dynamic>?> fetchStampInfo(String id) async {
  final supabase = Supabase.instance.client;
  final response = await supabase.from('stamps').select().eq('id', id).single();

  if (response != null) {
    return response;
  } else {
    return null;
  }
}

// ユーザーのスタンプを保存
Future<bool> saveUserStamp(String stampId, String imageUrl) async {
  try {
    final userId = supabase.auth.currentUser?.id;
    if (userId == null) {
      print("User is not logged in");
      return false;
    }

    final currentTime = DateTime.now().toUtc().toIso8601String();
    final uuid = Uuid();
    await supabase.from('user_stamps').insert({
      'id': uuid.v4(),
      'user_id': userId,
      'stamp_id': stampId,
      'image_url': imageUrl, // 追加: 撮影した写真のファイル名を設定
      'created_at': currentTime,
    });
    return true; // 保存成功
  } catch (e) {
    print("Error saving user stamp: $e");
    // RLSポリシー関連のエラーの場合の対処を追加
    if (e is StorageException && e.statusCode == 403) {
      print("RLSポリシーに違反しています。Supabaseの設定を確認してください。");
    }
    return false; // 保存失敗
  }
}

// スキャンが成功した際の共通処理
Future<void> handleSuccessfulScan(
    BuildContext context, Map<String, dynamic> event, String id,
    {VoidCallback? onSnapComplete}) async {
  try {
    // QRスキャンダイアログを閉じる
    Navigator.of(context, rootNavigator: true).pop();

    // カメラを直接開く
    final ImagePicker picker = ImagePicker();
    final XFile? photo = await picker.pickImage(source: ImageSource.camera);

    if (photo == null) {
      // 写真撮影がキャンセルされた場合
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => DisplayMap()),
        (route) => false,
      );
      return;
    }

    // 写真撮影後にローディングダイアログを表示
    if (!context.mounted) return;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) => const Center(
        child: CircularProgressIndicator(),
      ),
    );

    // 撮影した写真のファイル名を取得
    String fileName = photo.path.split('/').last;
    print('写真が撮影されました: ${photo.path}');

    File file = File(photo.path);
    bool uploadSuccess = false;
    try {
      if (supabase.auth.currentUser != null) {
        await supabase.storage.from('user_stamp_images').upload(
            "${supabase.auth.currentUser!.id}/$fileName",
            file); // ストレージにアップロ���ド
        uploadSuccess = await saveUserStamp(id, fileName); // ファイル名を保存
      } else {
        print("User is not logged in");
        uploadSuccess = false;
      }
    } catch (e) {
      print('Error uploading image: $e');
    }

    // ローディングダイアログを閉じる
    if (context.mounted) {
      Navigator.of(context, rootNavigator: true).pop();
    }

    if (uploadSuccess) {
      // 保存成功時に成功画面へ遷移
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) {
            if (event['name'] == null ||
                event['description_image_url'] == null ||
                event['description_text'] == null) {
              return Scaffold(
                appBar: AppBar(
                  title: const Text('エラー'),
                ),
                body: Center(
                  child: Text('イベント情報が不完全です。'),
                ),
              );
            } else {
              return StampSuccessScreen(
                name: event['name'] ?? '名前がありません',
                id: id,
                descriptionImageUrl: event['description_image_url'] ?? '',
                descriptionText: event['description_text'] ?? '説明がありません',
              );
            }
          },
        ),
      );
    } else {
      // 保存失敗時にマップ画面へ遷移
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => DisplayMap(),
        ),
      );
    }

    onSnapComplete?.call();
  } catch (e) {
    print("Error during scan handling: $e");
  }
}
