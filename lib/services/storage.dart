import 'dart:io';

import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:flutter_video_compress/flutter_video_compress.dart';
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';

class StorageService {
  static String getMediaFormatType(
    String path,
    String mediaPath,
    String mediaId,
  ) {
    if (mediaPath.endsWith('.mp4')) {
      return '$path/videos/$mediaId.mp4';
    } else if (mediaPath.endsWith('.mp3') || mediaPath.endsWith('.m4c')) {
      return '$path/audios/$mediaId.mp3';
    } else {
      return '$path/images/$mediaId.jpg';
    }
  }

  static Future<List<String>> uploadMediaFile(
    List<File> mediaFiles,
    String path,
  ) async {
    if (mediaFiles.length == 1) {
      final String _mediaId = Uuid().v4();
      final String _path =
          getMediaFormatType(path, mediaFiles[0].path, _mediaId);
      final Reference _storageRef = FirebaseStorage.instance.ref().child(_path);
      await _storageRef.putFile(mediaFiles[0]);
      final _downloadUrl = await _storageRef.getDownloadURL();
      return [_downloadUrl];
    } else {
      List<String> mediaUrls = [];
      for (File mediaFile in mediaFiles) {
        final String _mediaId = Uuid().v4();
        final String _path =
            getMediaFormatType(path, mediaFile.path, _mediaId);
        final Reference _storageRef =
            FirebaseStorage.instance.ref().child(_path);
        await _storageRef.putFile(mediaFile);
        final _downloadUrl = await _storageRef.getDownloadURL();
        mediaUrls.add(_downloadUrl);
      }
      return mediaUrls;
    }
  }
}

Future<File> compressImage(String photoId, File image) async {
  final Directory _temp = await getTemporaryDirectory();
  final String _path = _temp.path;
  final File _compressedImage = await FlutterImageCompress.compressAndGetFile(
    image.absolute.path,
    '$_path/img_$photoId.jpg',
  );
  return _compressedImage;
}

Future<File> compressVideo(File video) async {
  final FlutterVideoCompress _videoCompress = FlutterVideoCompress();
  final MediaInfo _compressedVideo = await _videoCompress.compressVideo(
    video.path,
    includeAudio: true,
  );
  return _compressedVideo.file;
}
