import 'package:StamComm/utils/constants.dart';
import 'package:flutter/material.dart';
import '../component/display_user_profile.dart'; // DisplayUserProfileをインポート
import '../component/user_profile_edit.dart'; // UsersEditsをインポート

class SettingPage extends StatelessWidget {
  Future<Widget> _getUserProfileWidget() async {
    final user = supabase.auth.currentUser;
    if (user != null) {
      final userProfile =
          await supabase.from('profiles').select().eq('id', user!.id).limit(1);

      if (userProfile != null) {
        return DisplayUserProfile();
      }
    }
    return UsersEdits();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: FutureBuilder<Widget>(
        future: _getUserProfileWidget(),
        builder: (BuildContext context, AsyncSnapshot<Widget> snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else {
            return snapshot.data ?? Center(child: Text('Error: No data'));
          }
        },
      ),
    );
  }
}
