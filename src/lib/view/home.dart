import 'package:StamComm/view/display_map.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final supabase = Supabase.instance.client;
  List<dynamic> data = [];

  @override
  void initState() {
    super.initState();
    fetchData();
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Image.asset(
          'lib/images/StamComm.png', // 画像のパスを指定
          height: 40,
        ),
        centerTitle: true, // タイトルを中央に配置
      ),
      body: data.isEmpty
          ? Center(child: CircularProgressIndicator())
          : ListView.builder(
              itemCount: data.length,
              itemBuilder: (context, index) {
                final item = data[index];
                return Column(
                  children: [
                    SizedBox(
                      width: MediaQuery.of(context).size.width * 0.9,
                      height: 70,
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => DisplayMap(eventId: item['id']),
                            ),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor:
                              const Color.fromARGB(255, 217, 217, 217),
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
                                item[
                                    'description_image_url'], // Supabaseから取得した画像URL
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
                    ),
                    SizedBox(height: 10), // ボタン間のスペース
                  ],
                );
              },
            ),
    );
  }
}
