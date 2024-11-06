import 'package:StamComm/models/profile.dart';
import 'package:StamComm/utils/constants.dart';
import 'package:flutter/material.dart';
import 'user_profile_edit.dart';

class DisplayUserProfile extends StatefulWidget {
  @override
  _DisplayUserProfileState createState() => _DisplayUserProfileState();
}

class _DisplayUserProfileState extends State<DisplayUserProfile> {
  late final Stream<List<Profile>> stream;
  late final String myUserId;

  @override
  void initState() {
    super.initState();
    myUserId = supabase.auth.currentUser!.id;

    // クエリを直接実行
    supabase.from('profiles').select().eq('id', myUserId).then((response) {
      if (response != null) {
        // エラーチェックを修正
      } else {
        if ((response as List).isEmpty) {
          // データが見つからなかった場合の処理
        } else {
          for (var map in response) {
            try {
              Profile profile = Profile.fromMap(map: map, myUserId: myUserId);
            } catch (e) {
              // マップからProfileへの変換エラー処理
            }
          }
        }
      }
    }).catchError((error) {
      // 予期しないエラー処理
    });

    // Streamをローカル変数として保持
    stream = supabase
        .from('profiles')
        .stream(primaryKey: ['id'])
        .eq('id', myUserId)
        .map((maps) {
          if (maps.isEmpty) {
            // データが見つからなかった場合の処理
          } else {
            // データが見つかった場合の処理
          }
          return maps
              .map((map) {
                try {
                  return Profile.fromMap(map: map, myUserId: myUserId);
                } catch (e) {
                  // マップからProfileへの変換エラー処理
                  return null;
                }
              })
              .where((profile) => profile != null)
              .cast<Profile>()
              .toList();
        })
        .handleError((error) {
          // データ取得エラー処理
        });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('プロフィール'),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            tooltip: 'プロフィールを編集',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => UsersEdits()),
              );
            },
          ),
        ],
      ),
      body: StreamBuilder<List<Profile>>(
        stream: stream,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('No data found'));
          } else {
            final profiles = snapshot.data!;
            final profile = profiles.first; // 最初のプロフィールを使用
            return Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Card(
                    child: ListTile(
                      leading: Icon(Icons.person, size: 50),
                      title: Text(
                        '名前',
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      subtitle: Text(
                        profile.username,
                        style: TextStyle(fontSize: 16),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Card(
                    child: ListTile(
                      leading: Icon(Icons.chat_bubble_outline, size: 50),
                      title: Text(
                        'ひとこと',
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      subtitle: Text(
                        profile.userComment ?? 'コメントはありません',
                        style: TextStyle(fontSize: 16),
                      ),
                    ),
                  ),
                ],
              ),
            );
          }
        },
      ),
    );
  }
}
