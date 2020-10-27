import 'package:flutter/material.dart';
import 'package:enhanced_future_builder/enhanced_future_builder.dart';

import 'package:photo_manager/photo_manager.dart';

import 'package:path/path.dart';

import 'package:shimmer/shimmer.dart';

class AudioPicker extends StatefulWidget {
  AudioPicker({Key key}) : super(key: key);

  @override
  _AudioPickerState createState() => _AudioPickerState();
}

class _AudioPickerState extends State<AudioPicker>
    with TickerProviderStateMixin {
  int currentPage = 0;
  int lastPage;
  int _selectedIndex = 0;
  List<Audio> _audios = [];
  String _audioUrl = '';
  AnimationController _scaleAnimationController;
  Animation<double> _scaleAnimation;
  @override
  void initState() {
    super.initState();
    getAudioFiles();
    setUpAnimations();
  }

  void setUpAnimations() {
    _scaleAnimationController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 200),
    );

    _scaleAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _scaleAnimationController,
        curve: Curves.easeInToLinear,
      ),
    );
    _scaleAnimationController.forward();
  }

  void getAudioFiles() async {
    lastPage = currentPage;
    bool result = await PhotoManager.requestPermission();
    if (result) {
      List<AssetPathEntity> albums = await PhotoManager.getAssetPathList(
        onlyAll: true,
        type: RequestType.audio,
      );
      List<AssetEntity> media =
          await albums[0].getAssetListPaged(currentPage, 60);
      _audios = media
          .map(
            (AssetEntity entity) => Audio(entity),
          )
          .toList();

      setState(() {
        currentPage++;
      });
    } else {
      PhotoManager.openSetting();
    }
  }

  Widget _buildLoadingListItem() {
    return Shimmer.fromColors(
      baseColor: Colors.grey[300],
      highlightColor: Colors.grey[100],
      child: Container(
        width: double.infinity,
        height: 50,
        color: Colors.white,
      ),
    );
  }

  _onSelected(int index) {
    setState(() => _selectedIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.deepOrangeAccent,
        title: Text('Pick your Audio'),
      ),
      floatingActionButton: ScaleTransition(
        scale: _scaleAnimation,
        child: FloatingActionButton(
          onPressed: () {
            Navigator.pop(context, _audioUrl);
          },
          backgroundColor: Colors.deepOrangeAccent,
          child: Icon(Icons.check),
        ),
      ),
      body: ListView.separated(
        itemCount: _audios.length,
        separatorBuilder: (context, index) => Divider(),
        itemBuilder: (context, index) => EnhancedFutureBuilder(
          rememberFutureResult: true,
          whenNotDone: Container(),
          future: _audios[index].entity.file,
          whenWaiting: _buildLoadingListItem(),
          whenDone: (snapshot) => Container(
            color: _selectedIndex != null && _selectedIndex == index
                ? Colors.deepOrange.withOpacity(0.3)
                : Colors.transparent,
            child: ListTile(
              onTap: () {
                _onSelected(index);
                _audioUrl = snapshot.path;
              },
              leading: Container(
                width: 40,
                height: 40,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(5),
                  color: Colors.deepOrange,
                ),
                child: Icon(
                  Icons.mic,
                  color: Colors.white,
                ),
              ),
              title: Text(
                basename(snapshot.path),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class Audio {
  final AssetEntity entity;
  bool selected = false;
  Audio(this.entity);
}
