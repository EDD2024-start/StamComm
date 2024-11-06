import 'package:flutter/material.dart';
import 'package:StamComm/view/home.dart';
import 'package:StamComm/view/display_map.dart';
import 'package:StamComm/view/search.dart';
import 'package:StamComm/view/setting.dart';
import 'package:StamComm/view/register_page.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class NavigateApp extends StatelessWidget {
  static const String _title = 'Flutter Code Sample';
  final int initialPageIndex; // 追加
  final String? eventId; // 追加

  const NavigateApp({super.key, this.initialPageIndex = 0, this.eventId}); // 変更

  static Route<void> route() {
    return MaterialPageRoute<void>(builder: (_) => const NavigateApp());
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: _title,
      home:
          Navigate(initialPageIndex: initialPageIndex, eventId: eventId), // 変更
    );
  }
}

class Navigate extends StatefulWidget {
  final int initialPageIndex; // 追加
  final String? eventId; // 追加

  const Navigate({super.key, this.initialPageIndex = 0, this.eventId}); // 変更

  @override
  _NavigateState createState() => _NavigateState();
}

class _NavigateState extends State<Navigate> {
  late int pageIndex;
  String? selectedEventId;

  @override
  void initState() {
    super.initState();
    pageIndex = widget.initialPageIndex; // 追加
    selectedEventId = widget.eventId; // 追加
  }

  final List<Widget> pages = [
    HomePage(),
    DisplayMap(), // 変更
    SearchPage(),
    SettingPage()
  ];

  @override
  Widget build(BuildContext context) {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) {
      // ログインしていない場合はRegisterPageに遷移
      return const RegisterPage();
    }

    return Scaffold(
      body: IndexedStack(
        index: pageIndex,
        children: pages.map((page) {
          if (page is DisplayMap) {
            return DisplayMap(eventId: selectedEventId); // 変更
          }
          return page;
        }).toList(),
      ),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: pageIndex,
        selectedIconTheme: const IconThemeData(color: Colors.blue),
        onTap: (index) {
          setState(() {
            pageIndex = index;
            if (index == 1) {
              selectedEventId = null; // マップを選択した場合はeventIdをリセット
            }
          });
        },
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: "Home"),
          BottomNavigationBarItem(icon: Icon(Icons.location_on), label: "マップ"),
          BottomNavigationBarItem(icon: Icon(Icons.search), label: "検索"),
          BottomNavigationBarItem(icon: Icon(Icons.settings), label: "設定"),
        ],
      ),
    );
  }
}
