import 'package:StamComm/component/navigate.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final supabase = Supabase.instance.client;
  List<dynamic> data = [];
  List<String> completedEventIds = []; 

  @override
  void initState() {
    super.initState();
    fetchData();
    fetchCompletedEvents();
  }

  void fetchData() async {
    final response = await supabase.from('events').select();
    if (response != null) {
      setState(() {
        data = response;
      });
    } else {
      // エラーハンドリング
      print(response);
    }
  }

  Future<List<String>> getCompletedEvents(String userId) async {
    final response = await supabase.rpc(
      'get_completed_events',
      params: {'user_id': userId},
    );

    if (response != null) {    
      // 取得したデータをイベントIDのリストとして返す
      // final data = response;
      List<dynamic> events = response;
      List<String> completedEventIds = events.map((event) {
        return event['event_id'].toString();
      }).toList();
      print('Completed events:' + completedEventIds.toString());
      return completedEventIds;
    } else {
      print('Error fetching completed events:' + response.toString());
      return [];
    }
  }

  Future<void> fetchCompletedEvents() async {
    final userId = supabase.auth.currentUser?.id;
    if (userId == null) {
      return;
    }
    completedEventIds = await getCompletedEvents(userId);
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('StamComm'),
        centerTitle: true, // タイトルを中央に配置
      ),
      body: data.isEmpty
          ? Center(child: CircularProgressIndicator())
          : ListView.builder(
              itemCount: data.length,
              itemBuilder: (context, index) {
                final item = data[index];
                final isCompleted = completedEventIds.contains(item['id']);
                return Column(
                  children: [
                    SizedBox(
                      width: MediaQuery.of(context).size.width * 0.9,
                      height: 70,
                      child: Stack(
                        children: [
                          // ElevatedButton
                          ElevatedButton(
                            onPressed: () {
                              Navigator.pushReplacement(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => NavigateApp(
                                    initialPageIndex: 1,
                                    eventId: item['id'],
                                  ),
                                ),
                              );
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: isCompleted
                                  ? const Color.fromARGB(255, 170, 170, 170)
                                  : const Color.fromARGB(255, 255, 255, 255),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(5), // 角の丸さを設定
                              ),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.start,
                              children: <Widget>[
                                Padding(
                                  padding: const EdgeInsets.fromLTRB(
                                      0, 0, 0, 0), // 上下左右に同じ余白を設定
                                  child: Image.network(
                                    item['description_image_url'], // Supabaseから取得した画像URL
                                    width: 50,
                                    height: 50,
                                  ),
                                ),
                                Expanded(
                                  child: Text(
                                    item['name'],
                                    textAlign: TextAlign.right,
                                    softWrap: false,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          // 完了状態の場合、completed.pngを重ねる
                          if (isCompleted)
                            Positioned.fill(
                              child: Align(
                                alignment: Alignment.center,
                                child: Image.asset(
                                  'assets/images/complete.png', // 画像のパス
                                  width: 100,
                                  height: 100,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                    SizedBox(height: 10), // ボタン間のスペース
                  ],
                );
              },
            ),
    );
  }
}
