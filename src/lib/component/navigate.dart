import 'package:flutter/material.dart';
import 'package:StamComm/view/home.dart';
import 'package:StamComm/view/display_map.dart';
import 'package:StamComm/view/search.dart';
import 'package:StamComm/view/setting.dart';

class NavigateApp extends StatelessWidget {
  static const String _title = 'Flutter Code Sample';

  static Route<void> route() {
    return MaterialPageRoute<void>(builder: (_) => const NavigateApp());
  }

  const NavigateApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: _title,
      home: Navigate(),
    );
  }
}

class Navigate extends StatefulWidget {
  @override
  _NavigateState createState() => _NavigateState();
}

class _NavigateState extends State<Navigate> {
  int pageIndex = 0;

  final List<Widget> pages = [
    HomePage(),
    DisplayMap(),
    SearchPage(),
    SettingPage()
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("App"),
      ),
      body: IndexedStack(
        index: pageIndex,
        children: pages,
      ),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: pageIndex,
        selectedIconTheme: const IconThemeData(color: Colors.blue),
        onTap: (index) {
          setState(() {
            pageIndex = index;
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
