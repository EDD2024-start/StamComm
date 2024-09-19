import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../component/display_user_profile.dart'; // 新しいファイルをインポート

class UsersEdits extends StatefulWidget {
  UsersEdits({Key? key}) : super(key: key);

  @override
  State<UsersEdits> createState() => _UsersEditsState();
}

class _UsersEditsState extends State<UsersEdits> {
  final TextEditingController _textContName = TextEditingController();
  final TextEditingController _textContProf = TextEditingController();
  String _editTextName = '';
  String _editTextProf = '';

  @override
  void initState() {
    super.initState();
    _checkUserProfile();
  }

  Future<void> _checkUserProfile() async {
    // Firestoreからユーザーデータを取得する処理
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      DocumentSnapshot userProfile = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      if (userProfile.exists) {
        // ユーザーデータが存在する場合、DisplayUserProfileに遷移
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => DisplayUserProfile()),
        );
      }
    }
  }

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
                foregroundColor: Colors.white, backgroundColor: Colors.blue, // ボタンのテキスト色
              ),
              child: const Text('保存'),
              onPressed: () async {
                User? user = FirebaseAuth.instance.currentUser;
                Map<String, dynamic> insertObj = {
                  'id': user!.uid,
                  'name': _textContName.text,
                  'note': _textContProf.text,
                  'vaild': true,
                  'created_at': FieldValue.serverTimestamp(),
                  'modified_at': FieldValue.serverTimestamp()
                };
                try {
                  var doc = await FirebaseFirestore.instance
                      .collection('users')
                      .doc(user.uid);
                  await doc.set(insertObj);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => DisplayUserProfile()), // 登録後に遷移
                  );
                } catch (e) {
                  print('-----insert error----');
                  print(e);
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
                          if (val != null && val != '') {
                            _editTextName = val;
                          }
                        },
                      ),
                      const SizedBox(height: 16.0),
                      _buildTextField(
                        label:'ひとこと',
                        controller: _textContProf,
                        maxLines: 2,
                        onChanged: (val) {
                          if (val != null && val != '') {
                            _editTextProf = val;
                          }
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
    required Function(String?) onChanged,
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
