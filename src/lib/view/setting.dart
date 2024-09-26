import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../component/display_user_profile.dart'; // DisplayUserProfileをインポート
import '../component/user_profile_edit.dart'; // UsersEditsをインポート

class SettingPage extends StatelessWidget {
  Future<Widget> _getUserProfileWidget() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      DocumentSnapshot userProfile = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      if (userProfile.exists) {
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
