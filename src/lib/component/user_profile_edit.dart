import 'package:StamComm/utils/constants.dart';
import 'package:flutter/material.dart';
import '../component/display_user_profile.dart';

class UsersEdits extends StatefulWidget {
  UsersEdits({Key? key}) : super(key: key);

  @override
  State<UsersEdits> createState() => _UsersEditsState();
}

class _UsersEditsState extends State<UsersEdits> {
  final TextEditingController _textContName = TextEditingController();
  final TextEditingController _textContProf = TextEditingController();

  late final String myUserId;

  @override
  void initState() {
    super.initState();
    myUserId = supabase.auth.currentUser!.id;
    _loadUserProfile();
  }

  Future<void> _loadUserProfile() async {
    try {
      final response =
          await supabase.from('profiles').select().eq('id', myUserId).single();

      if (response != null) {
        // 必要に応じてエラーメッセージをユーザーに表示
      } else {
        final data = response;
        if (data != null) {
          _textContName.text = data['username'] ?? '';
          _textContProf.text = data['user_comment'] ?? '';
        }
      }
    } catch (e) {
      // 必要に応じてエラーメッセージをユーザーに表示
    }
  }

  @override
  void dispose() {
    _textContName.dispose();
    _textContProf.dispose();
    super.dispose();
  }

  /// ユーザープロフィール編集画面を表示するウィジェット。
  @override
  Widget build(BuildContext context) {
    final bottomSpace = MediaQuery.of(context).viewInsets.bottom;
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        centerTitle: true,
        title: const Text('プロフィール編集'),
        actions: [
          Padding(
            padding:
                const EdgeInsets.symmetric(vertical: 15.0, horizontal: 10.0),
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                foregroundColor: Colors.white,
                backgroundColor: Colors.blue, // ボタンのテキスト色
              ),
              child: const Text('保存'),
              onPressed: () async {
                final user = supabase.auth.currentUser;
                if (user == null) {
                  // 必要に応じてエラーメッセージをユーザーに表示
                  return;
                }

                Map<String, dynamic> upsertObj = {
                  'id': user.id,
                  'username': _textContName.text,
                  'user_comment':
                      _textContProf.text.isNotEmpty ? _textContProf.text : null,
                  'updated_at': DateTime.now().toIso8601String(),
                };

                try {
                  // ユーザーデータをSupabaseにupsert
                  await supabase.from('profiles').upsert(upsertObj);
                  // 保存完了後、プロフィール表示ページに戻る
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                        builder: (context) => DisplayUserProfile()),
                  );
                } catch (e) {
                  // 必要に応じてエラーメッセージをユーザーに表示
                }
              },
            ),
          )
        ],
      ),
      resizeToAvoidBottomInset: false,
      body: SafeArea(
        child: SingleChildScrollView(
          reverse: true,
          child: Padding(
            padding: EdgeInsets.only(bottom: bottomSpace),
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      _buildTextField(
                        label: '名前',
                        controller: _textContName,
                        onChanged: (val) {
                          // 必要に応じて処理を追加
                        },
                      ),
                      const SizedBox(height: 16.0),
                      _buildTextField(
                        label: 'ひとこと',
                        controller: _textContProf,
                        maxLines: 2,
                        onChanged: (val) {
                          // 必要に応じて処理を追加
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required String label,
    required TextEditingController controller,
    int maxLines = 1,
    required Function(String) onChanged,
  }) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(),
      ),
      onChanged: onChanged,
    );
  }
}
