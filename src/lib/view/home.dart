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
        : PageView.builder(
            itemCount: data.length,
            itemBuilder: (context, index) {
              final item = data[index];
              final isCompleted = completedEventIds.contains(item['id']);
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(
                      width: MediaQuery.of(context).size.width * 0.8,
                      height: MediaQuery.of(context).size.height * 0.7,
                      child: ElevatedButton(
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
                          backgroundColor: const Color.fromARGB(255, 255, 255, 255),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(5), // 角の丸さを設定
                          ),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.start,
                          children: [
                            Padding(
                              padding: const EdgeInsets.fromLTRB(0, 10, 0, 5),
                              child: Image.network(
                                item['description_image_url'], // Supabaseから取得した画像URL
                                width: MediaQuery.of(context).size.width * 0.3,
                                height: MediaQuery.of(context).size.height * 0.3,
                              ),
                            ),
                            Text(
                              item['name'],
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              item['description_text'],
                              textAlign: TextAlign.center,
                              style: const TextStyle(fontSize: 14),
                            ),
                            if (isCompleted) ...[
                              const SizedBox(height: 20),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Image.asset(
                                    'assets/images/complete.png', // 完了画像のパス
                                    width: 80,
                                    height: 80,
                                  ),
                                  const SizedBox(width: 10),
                                  const Expanded(
                                    child: Text(
                                      'あなたはこのイベントのスタンプを全て集めました！',
                                      textAlign: TextAlign.left,
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
  );
}
}
