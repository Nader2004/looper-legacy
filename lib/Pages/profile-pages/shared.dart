import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:looper/widgets/post.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SharedListPage extends StatefulWidget {
  SharedListPage({Key key}) : super(key: key);

  @override
  _SharedListPageState createState() => _SharedListPageState();
}

class _SharedListPageState extends State<SharedListPage> {
  String _id = 'empty';

  @override
  void initState() {
    super.initState();
    setPrefs();
  }

  void setPrefs() async {
    final SharedPreferences _prefs = await SharedPreferences.getInstance();
    setState(() {
      _id = _prefs.get('id');
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        elevation: 0.5,
        backgroundColor: Colors.white,
        iconTheme: IconThemeData.fallback(),
        centerTitle: true,
        title: Text(
          'Shared Posts',
          style: TextStyle(color: Colors.black),
        ),
      ),
      body: _id == 'empty'
          ? SizedBox.shrink()
          : FutureBuilder(
              future:
                  FirebaseFirestore.instance.collection('users').doc(_id).get(),
              builder: (context, AsyncSnapshot<DocumentSnapshot> snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return SizedBox.shrink();
                } else {
                  return StreamBuilder(
                    stream: FirebaseFirestore.instance
                        .collection('posts')
                        .where(
                          'share-author-name',
                          isEqualTo: snapshot.data.data()['username'],
                        )
                        .snapshots(),
                    builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return Center(
                          child: CircularProgressIndicator(
                            strokeWidth: 1.2,
                            valueColor: AlwaysStoppedAnimation(Colors.black),
                          ),
                        );
                      } else {
                        if (snapshot.data.docs.isEmpty) {
                          return Center(
                            child: Text(
                              'You didn\'t share anything yet',
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 20,
                              ),
                            ),
                          );
                        }
                        return ListView.builder(
                          itemCount: snapshot.data.docs.length,
                          itemBuilder: (context, index) => PostWidget(
                            snapshot: snapshot.data.docs[index],
                          ),
                        );
                      }
                    },
                  );
                }
              },
            ),
    );
  }
}
