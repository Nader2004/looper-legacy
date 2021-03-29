import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:looper/services/database.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:looper/Pages/home-Pages/global/profile.dart';

class SearchPage extends StatefulWidget {
  const SearchPage({Key key}) : super(key: key);

  @override
  _SearchPageState createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  List<Map<String, dynamic>> queryResultSet = [];
  List<Map<String, dynamic>> tempSearchStore = [];

  initiateSearch(value) {
    if (value.length == 0) {
      setState(() {
        queryResultSet = [];
        tempSearchStore = [];
      });
    }

    var capitalizedValue = value.substring(0, 1) + value.substring(1);

    if (queryResultSet.length == 0 && value.length == 1) {
      DatabaseService.searchByName(value).then((QuerySnapshot docs) {
        for (int i = 0; i < docs.docs.length; ++i) {
          queryResultSet.add(docs.docs[i].data());
        }
      });
    } else {
      tempSearchStore = [];
      queryResultSet.forEach((element) {
        if (element['username'].startsWith(capitalizedValue)) {
          setState(() {
            tempSearchStore.add(element);
          });
        }
      });
    }
  }

  Widget _buildSearchBar() {
    final double _deviceWidth = MediaQuery.of(context).size.width;
    return Container(
      margin: EdgeInsets.only(
        top: 15,
        left: 2,
        bottom: 20,
      ),
      width: _deviceWidth - 5,
      height: 55,
      child: Card(
        elevation: 10,
        child: TextField(
          autofocus: true,
          onChanged: (val) {
            initiateSearch(val);
          },
          decoration: InputDecoration(
            contentPadding: EdgeInsets.only(top: 16),
            hintText: 'Search for people',
            hintStyle: TextStyle(
              fontFamily: 'Montserrat',
            ),
            border: InputBorder.none,
            prefixIcon: Icon(
              MdiIcons.accountSearch,
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        children: <Widget>[
          _buildSearchBar(),
          Expanded(
            child: ListView.builder(
              itemCount: tempSearchStore.length,
              itemBuilder: (BuildContext context, int index) {
                return ListTile(
                  leading: ClipRRect(
                    borderRadius: BorderRadius.circular(50),
                    child: CachedNetworkImage(
                      imageUrl: tempSearchStore[index]['profilePictureUrl'],
                      fit: BoxFit.cover,
                      height: 50,
                      width: 50,
                    ),
                  ),
                  title: Text(tempSearchStore[index]['username']),
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => ProfilePage(
                          userId: tempSearchStore[index]['id'],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
