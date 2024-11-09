// navigate.dart
import 'package:flutter/material.dart';
import 'package:StamComm/view/home.dart';
import 'package:StamComm/view/display_map.dart';
import 'package:StamComm/view/search.dart';
import 'package:StamComm/view/setting.dart';
import 'package:StamComm/view/register_page.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class NavigateApp extends StatelessWidget {
  static const String _title = 'Flutter Code Sample';
  final int initialPageIndex;
  final String? eventId;

  const NavigateApp({super.key, this.initialPageIndex = 0, this.eventId});

  static Route<void> route() {
    return MaterialPageRoute<void>(builder: (_) => const NavigateApp());
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: _title,
      home: Navigate(initialPageIndex: initialPageIndex, eventId: eventId),
    );
  }
}

class Navigate extends StatefulWidget {
  final int initialPageIndex;
  final String? eventId;

  const Navigate({super.key, this.initialPageIndex = 0, this.eventId});

  @override
  _NavigateState createState() => _NavigateState();
}

class _NavigateState extends State<Navigate> {
  late int pageIndex;
  String? selectedEventId;

  @override
  void initState() {
    super.initState();
    pageIndex = widget.initialPageIndex;
    selectedEventId = widget.eventId;
  }

  @override
  Widget build(BuildContext context) {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) {
      return const RegisterPage();
    }

    final pages = [
      HomePage(refreshCompletedEvents: pageIndex == 0), // 変更
      DisplayMap(eventId: selectedEventId),
      SearchPage(),
      SettingPage(),
    ];

    return Scaffold(
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
            if (index == 1) {
              selectedEventId = null;
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
