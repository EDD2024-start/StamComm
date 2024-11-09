import 'dart:io';
import 'dart:math';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import 'package:geolocator/geolocator.dart'; // 追加
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

// 位置情報の許可を確認し、必要に応じて要求する関数を追加
Future<bool> _handleLocationPermission(BuildContext? context) async {
  bool serviceEnabled;
  LocationPermission permission;

  serviceEnabled = await Geolocator.isLocationServiceEnabled();
  if (!serviceEnabled) {
    if (context != null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('位置情報サービスが無効になっています。有効にしてください。')));
    }
    return false;
  }

  permission = await Geolocator.checkPermission();
  if (permission == LocationPermission.denied) {
    permission = await Geolocator.requestPermission();
    if (permission == LocationPermission.denied) {
      if (context != null) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('位置情報の許可が必要です')));
      }
      return false;
    }
  }

  if (permission == LocationPermission.deniedForever) {
    if (context != null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('位置情報の許可が永続的に拒否されています。設定から許可してください。')));
    }
    return false;
  }

  return true;
}

// 位置情報の検証を行う共通関数
Future<bool> validateLocation(double latitude, double longitude) async {
  try {
    if (!await _handleLocationPermission(null)) {
      return false;
    }

    Position currentPosition = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );

    double distance = calculateDistance(
      currentPosition.latitude,
      currentPosition.longitude,
      latitude,
      longitude,
    );

    return distance <= 30;
  } catch (e) {
    print("Error validating location: $e");
    return false;
  }
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

enum StampSaveError {
  duplicate,
  other
}

// ユーザーのスタンプを保存
Future<StampSaveError?> saveUserStamp(String stampId, String imageUrl) async {
  try {
    final userId = supabase.auth.currentUser?.id;
    if (userId == null) {
      print("User is not logged in");
      return StampSaveError.other;
    }

    final currentTime = DateTime.now().toUtc().toIso8601String();
    final uuid = Uuid();
    await supabase.from('user_stamps').insert({
      'id': uuid.v4(),
      'user_id': userId,
      'stamp_id': stampId,
      'image_url': imageUrl, // パブリックURLを保存
      'created_at': currentTime,
    });
    return null;  // 成功時はnull
  } on PostgrestException catch (e) {
    if (e.code == "23505") { // 重複エラーのコード
      print("Duplicate stamp error: $e");
      return StampSaveError.duplicate;
    }
    print("Error saving user stamp: $e");
    return StampSaveError.other;
  } catch (e) {
    print("Error saving user stamp: $e");
    return StampSaveError.other;
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

    String fileName = photo.path.split('/').last;
    File file = File(photo.path);
    String? publicUrl;

    try {
      if (supabase.auth.currentUser != null) {
        final filePath = "${supabase.auth.currentUser!.id}/$fileName";
        // ストレージにアップロード
        await supabase.storage.from('user_stamp_images').upload(filePath, file);
        publicUrl = supabase.storage.from('user_stamp_images').getPublicUrl(filePath);

        if (publicUrl != null) {
          final error = await saveUserStamp(id, publicUrl);
          
          // ローディングダイアログを閉じる
          if (context.mounted) {
            Navigator.of(context, rootNavigator: true).pop();
          }

          if (error == StampSaveError.duplicate) {
            if (context.mounted) {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('取得済みのスタンプ'),
                  content: const Text('このスタンプは既に取得済みです。'),
                  actions: [
                    TextButton(
                      onPressed: () {
                        Navigator.pushAndRemoveUntil(
                          context,
                          MaterialPageRoute(builder: (context) => DisplayMap()),
                          (route) => false,
                        );
                      },
                      child: const Text('マップに戻る'),
                    ),
                  ],
                ),
              );
            }
            return;
          } else if (error == null) {
            // 成功時の処理
            if (context.mounted) {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => StampSuccessScreen(
                    name: event['name'] ?? '名前がありません',
                    id: id,
                    descriptionImageUrl: event['description_image_url'] ?? '',
                    descriptionText: event['description_text'] ?? '説明がありません',
                    userPhotoUrl: publicUrl ?? '',
                  ),
                ),
              );
              onSnapComplete?.call();
            }
            return;
          }
        }
      }
    } catch (e) {
      print('Error during stamp process: $e');
    }

    // エラー時の処理
    if (context.mounted) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('エラー'),
          content: const Text('スタンプの取得に失敗しました。'),
          actions: [
            TextButton(
              onPressed: () {
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
  } catch (e) {
    print("Error during scan handling: $e");
    if (context.mounted) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => DisplayMap()),
        (route) => false,
      );
    }
  }
}
