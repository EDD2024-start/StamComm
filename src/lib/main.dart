import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:StamComm/component/navigate.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    // TODO: ここにSupabaseのURLとAnon Keyを入力
    url: 'https://wfvnalpxvymbpqhkgbpy.supabase.co',
    anonKey:
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Indmdm5hbHB4dnltYnBxaGtnYnB5Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3MjczNDY1NDYsImV4cCI6MjA0MjkyMjU0Nn0.bxWuhkPmRDLmF7ikQkzEc0vEVxbpH3QZ-xL1C0uslvo',
  );
  runApp(const LoginSample());
}

class LoginSample extends StatelessWidget {
  const LoginSample({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      title: 'Login Sample',
      home: NavigateApp(),
    );
  }
}
