import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class ResetPasswordScreen extends StatefulWidget {
  const ResetPasswordScreen({super.key});

  @override
  State<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends State<ResetPasswordScreen> {
  // メッセージ表示用
  String infoText = '';
  String mailAddress = '';
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      //ここから追加
      appBar: AppBar(
        title: Text(
          'パスワードリセット',
        ),
      ),
      //ここまで追加
      body: Center(
        child: Container(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              // メールアドレス入力
              TextFormField(
                decoration: const InputDecoration(labelText: 'メールアドレス'),
                onChanged: (String value) {
                  mailAddress = value;
                },
              ),

              Container(
                padding: const EdgeInsets.all(8),
                // メッセージ表示
                child: Text(infoText),
              ),
              SizedBox(
                width: double.infinity,
                // ユーザー登録ボタン
                child: ElevatedButton(
                  child: const Text('パスワードリセット'),
                  onPressed: () async {
                    try {
                      final FirebaseAuth auth = FirebaseAuth.instance;
                      await auth.sendPasswordResetEmail(email: mailAddress);
                      setState(() {
                        infoText = "パスワードリセットメールを送信しました。";
                      });
                    } catch (e) {
                      setState(() {
                        infoText = "パスワードリセットメールの送信に失敗しました：${e.toString()}";
                      });
                    }
                  },
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}
