import 'dart:io';
import 'dart:convert';

import 'package:export_video_frame/export_video_frame.dart';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_ml_vision/firebase_ml_vision.dart';
import 'package:looper/models/personality.dart';
import 'package:path_provider/path_provider.dart';
import 'package:stringprocess/stringprocess.dart';
import 'package:http/http.dart' as http;

class PersonalityService {
  static const String PERSONALITY_API_KEY =
      '7pItiQmR35dM6w-3UKoaEc2I66dltLtRp2_n0axi0HWH';
  static const String SPEECH_API_KEY =
      'n_6_z-yVPiN9AB4cR4RvQbYtQfYeJYM75umE1EZ-vFXc';
  static const String SPEECH_URL =
      'https://api.us-east.speech-to-text.watson.cloud.ibm.com/instances/9465b5f3-75b9-4d58-af15-c81f45870aa8';
  static const String PERSONALITY_URL =
      'https://api.us-east.personality-insights.watson.cloud.ibm.com/instances/60c6c815-0861-4f90-97fe-2a1945809b26';

  static Future<String> get _localPath async {
    final directory = await getApplicationDocumentsDirectory();
    return directory.path;
  }

  static Future<File> get _localPersonalityFile async {
    final path = await _localPath;
    return File('$path/personality.txt');
  }

  static Future<void> analyzePersonality() async {
    final String path = await _localPath;
    if (File('$path/personality.txt').existsSync()) {
      final File _persFile = await _localPersonalityFile;
      final String _persFileText = await _persFile.readAsString();
      final StringProcessor _tps = StringProcessor();
      print(_persFileText);
      if ((_tps.getWordCount(_persFileText) % 1500) == 0 &&
          _persFileText.isNotEmpty) {
        final http.Response _response = await http.post(
          Uri.encodeFull(
            '$PERSONALITY_URL/v3/profile?version=2017-10-13&consumption_preferences=true&raw_scores=true',
          ),
          body: _persFileText,
          headers: {
            HttpHeaders.authorizationHeader: basicAuthorizationHeader(
              'apikey',
              PERSONALITY_API_KEY,
            ),
            HttpHeaders.contentTypeHeader: 'text/plain',
            HttpHeaders.acceptHeader: 'application/json',
          },
        );

        final Map<String, dynamic> _personalityData =
            json.decode(_response.body);
        final PersonalityType _personality =
            PersonalityType.fromJson(_personalityData);
        final int _openness = (_personality.openness.value * 100).round();
        final int _conscientiousness =
            (_personality.conscientiousness.value * 100).round();
        final int _extroversion =
            (_personality.introversionToExtraversion.value * 100).round();
        final int _agrreableness =
            (_personality.agreeableness.value * 100).round();
        final int _neuroticism =
            (_personality.emotionalRange.value * 100).round();

        FirebaseFirestore.instance
            .collection('users')
            .doc('K8nu4eqn18RMy2YlM3nhzPYdXKX2')
            .update({
          'personality-type': {
            'opennes': _openness,
            'agrreableness': _agrreableness,
            'conscientiousness': _conscientiousness,
            'neuroticism': _neuroticism,
            'extroversion': _extroversion,
          },
        });
      }
    }
  }

  static Future<QuerySnapshot> getCompatibleContentStream(
    Map<String, dynamic> _personalityType,
    FirebaseFirestore _firestore,
    String collectionName,
    String fieldName,
  ) {
    if (_personalityType.isNotEmpty) {
      bool returnFiltered = true;
      bool doneListening = false;
      if (collectionName != 'lover-cards' || collectionName != 'love-cards') {
        _firestore
            .collection(collectionName)
            .where(
              fieldName,
              whereIn: [
                {
                  'opennes':
                      _getComaptibleValue(_personalityType['opennes']) - 3,
                  'agrreableness':
                      _getComaptibleValue(_personalityType['agrreableness']) -
                          3,
                  'conscientiousness': _getComaptibleValue(
                          _personalityType['conscientiousness']) -
                      3,
                  'neuroticism':
                      _getComaptibleValue(_personalityType['neuroticism']) - 3,
                  'extroversion':
                      _getComaptibleValue(_personalityType['extroversion']) - 3,
                },
                {
                  'opennes':
                      _getComaptibleValue(_personalityType['opennes']) + 3,
                  'agrreableness':
                      _getComaptibleValue(_personalityType['agrreableness']) +
                          3,
                  'conscientiousness': _getComaptibleValue(
                          _personalityType['conscientiousness']) +
                      3,
                  'neuroticism':
                      _getComaptibleValue(_personalityType['neuroticism']) + 3,
                  'extroversion':
                      _getComaptibleValue(_personalityType['extroversion']) + 3,
                },
                {
                  'opennes':
                      _getComaptibleValue(_personalityType['opennes']) + 2,
                  'agrreableness':
                      _getComaptibleValue(_personalityType['agrreableness']) +
                          2,
                  'conscientiousness': _getComaptibleValue(
                          _personalityType['conscientiousness']) +
                      2,
                  'neuroticism':
                      _getComaptibleValue(_personalityType['neuroticism']) + 2,
                  'extroversion':
                      _getComaptibleValue(_personalityType['extroversion']) + 2,
                },
                {
                  'opennes':
                      _getComaptibleValue(_personalityType['opennes']) - 2,
                  'agrreableness':
                      _getComaptibleValue(_personalityType['agrreableness']) -
                          2,
                  'conscientiousness': _getComaptibleValue(
                          _personalityType['conscientiousness']) -
                      2,
                  'neuroticism':
                      _getComaptibleValue(_personalityType['neuroticism']) - 2,
                  'extroversion':
                      _getComaptibleValue(_personalityType['extroversion']) - 2,
                },
                {
                  'opennes':
                      _getComaptibleValue(_personalityType['opennes']) + 1,
                  'agrreableness':
                      _getComaptibleValue(_personalityType['agrreableness']) +
                          1,
                  'conscientiousness': _getComaptibleValue(
                          _personalityType['conscientiousness']) +
                      1,
                  'neuroticism':
                      _getComaptibleValue(_personalityType['neuroticism']) + 1,
                  'extroversion':
                      _getComaptibleValue(_personalityType['extroversion']) + 1,
                },
                {
                  'opennes':
                      _getComaptibleValue(_personalityType['opennes']) - 1,
                  'agrreableness':
                      _getComaptibleValue(_personalityType['agrreableness']) -
                          1,
                  'conscientiousness': _getComaptibleValue(
                          _personalityType['conscientiousness']) -
                      1,
                  'neuroticism':
                      _getComaptibleValue(_personalityType['neuroticism']) - 1,
                  'extroversion':
                      _getComaptibleValue(_personalityType['extroversion']) - 1,
                },
              ],
            )
            .orderBy('timestamp', descending: true)
            .snapshots()
            .listen((event) {
              print('listen ran');
              if (event.docs.isEmpty) {
                returnFiltered = false;
                doneListening = true;
              } else {
                returnFiltered = true;
                doneListening = true;
              }
              print(returnFiltered);
            });
        if (returnFiltered == true && doneListening == true) {
          return _firestore
              .collection(collectionName)
              .where(
                fieldName,
                whereIn: [
                  {
                    'opennes':
                        _getComaptibleValue(_personalityType['opennes']) - 3,
                    'agrreableness':
                        _getComaptibleValue(_personalityType['agrreableness']) -
                            3,
                    'conscientiousness': _getComaptibleValue(
                            _personalityType['conscientiousness']) -
                        3,
                    'neuroticism':
                        _getComaptibleValue(_personalityType['neuroticism']) -
                            3,
                    'extroversion':
                        _getComaptibleValue(_personalityType['extroversion']) -
                            3,
                  },
                  {
                    'opennes':
                        _getComaptibleValue(_personalityType['opennes']) + 3,
                    'agrreableness':
                        _getComaptibleValue(_personalityType['agrreableness']) +
                            3,
                    'conscientiousness': _getComaptibleValue(
                            _personalityType['conscientiousness']) +
                        3,
                    'neuroticism':
                        _getComaptibleValue(_personalityType['neuroticism']) +
                            3,
                    'extroversion':
                        _getComaptibleValue(_personalityType['extroversion']) +
                            3,
                  },
                  {
                    'opennes':
                        _getComaptibleValue(_personalityType['opennes']) + 2,
                    'agrreableness':
                        _getComaptibleValue(_personalityType['agrreableness']) +
                            2,
                    'conscientiousness': _getComaptibleValue(
                            _personalityType['conscientiousness']) +
                        2,
                    'neuroticism':
                        _getComaptibleValue(_personalityType['neuroticism']) +
                            2,
                    'extroversion':
                        _getComaptibleValue(_personalityType['extroversion']) +
                            2,
                  },
                  {
                    'opennes':
                        _getComaptibleValue(_personalityType['opennes']) - 2,
                    'agrreableness':
                        _getComaptibleValue(_personalityType['agrreableness']) -
                            2,
                    'conscientiousness': _getComaptibleValue(
                            _personalityType['conscientiousness']) -
                        2,
                    'neuroticism':
                        _getComaptibleValue(_personalityType['neuroticism']) -
                            2,
                    'extroversion':
                        _getComaptibleValue(_personalityType['extroversion']) -
                            2,
                  },
                  {
                    'opennes':
                        _getComaptibleValue(_personalityType['opennes']) + 1,
                    'agrreableness':
                        _getComaptibleValue(_personalityType['agrreableness']) +
                            1,
                    'conscientiousness': _getComaptibleValue(
                            _personalityType['conscientiousness']) +
                        1,
                    'neuroticism':
                        _getComaptibleValue(_personalityType['neuroticism']) +
                            1,
                    'extroversion':
                        _getComaptibleValue(_personalityType['extroversion']) +
                            1,
                  },
                  {
                    'opennes':
                        _getComaptibleValue(_personalityType['opennes']) - 1,
                    'agrreableness':
                        _getComaptibleValue(_personalityType['agrreableness']) -
                            1,
                    'conscientiousness': _getComaptibleValue(
                            _personalityType['conscientiousness']) -
                        1,
                    'neuroticism':
                        _getComaptibleValue(_personalityType['neuroticism']) -
                            1,
                    'extroversion':
                        _getComaptibleValue(_personalityType['extroversion']) -
                            1,
                  },
                ],
              )
              .orderBy(
                collectionName == 'talents'
                    ? 'yesCount'
                    : collectionName == 'comedy' ? 'laughs' : 'likes',
                descending: true,
              )
              .orderBy('commentCount', descending: true)
              .orderBy(
                  collectionName == 'talents'
                      ? 'noCount'
                      : collectionName == 'challenge'
                          ? 'disLikes'
                          : collectionName == 'comedy' ||
                                  collectionName == 'sports'
                              ? 'creatorId'
                              : 'shareCount',
                  descending:
                      collectionName == 'comedy' || collectionName == 'sports'
                          ? false
                          : true)
              .orderBy('viewsCount', descending: true)
              .orderBy('timestamp', descending: true)
              .get();
        } else {
          return _firestore
              .collection(collectionName)
              .orderBy(
                collectionName == 'talents'
                    ? 'yesCount'
                    : collectionName == 'comedy' ? 'laughs' : 'likes',
                descending: true,
              )
              .orderBy('commentCount', descending: true)
              .orderBy(
                  collectionName == 'talents'
                      ? 'noCount'
                      : collectionName == 'challenge'
                          ? 'disLikes'
                          : collectionName == 'comedy' ||
                                  collectionName == 'sports'
                              ? 'creatorId'
                              : 'shareCount',
                  descending:
                      collectionName == 'comedy' || collectionName == 'sports'
                          ? false
                          : true)
              .orderBy('viewsCount', descending: true)
              .orderBy('timestamp', descending: true)
              .get();
        }
      } else {
        _firestore
            .collection(collectionName)
            .where(
              fieldName,
              whereIn: [
                {
                  'opennes':
                      _getComaptibleValue(_personalityType['opennes']) - 3,
                  'agrreableness':
                      _getComaptibleValue(_personalityType['agrreableness']) -
                          3,
                  'conscientiousness': _getComaptibleValue(
                          _personalityType['conscientiousness']) -
                      3,
                  'neuroticism':
                      _getComaptibleValue(_personalityType['neuroticism']) - 3,
                  'extroversion':
                      _getComaptibleValue(_personalityType['extroversion']) - 3,
                },
                {
                  'opennes':
                      _getComaptibleValue(_personalityType['opennes']) + 3,
                  'agrreableness':
                      _getComaptibleValue(_personalityType['agrreableness']) +
                          3,
                  'conscientiousness': _getComaptibleValue(
                          _personalityType['conscientiousness']) +
                      3,
                  'neuroticism':
                      _getComaptibleValue(_personalityType['neuroticism']) + 3,
                  'extroversion':
                      _getComaptibleValue(_personalityType['extroversion']) + 3,
                },
                {
                  'opennes':
                      _getComaptibleValue(_personalityType['opennes']) + 2,
                  'agrreableness':
                      _getComaptibleValue(_personalityType['agrreableness']) +
                          2,
                  'conscientiousness': _getComaptibleValue(
                          _personalityType['conscientiousness']) +
                      2,
                  'neuroticism':
                      _getComaptibleValue(_personalityType['neuroticism']) + 2,
                  'extroversion':
                      _getComaptibleValue(_personalityType['extroversion']) + 2,
                },
                {
                  'opennes':
                      _getComaptibleValue(_personalityType['opennes']) - 2,
                  'agrreableness':
                      _getComaptibleValue(_personalityType['agrreableness']) -
                          2,
                  'conscientiousness': _getComaptibleValue(
                          _personalityType['conscientiousness']) -
                      2,
                  'neuroticism':
                      _getComaptibleValue(_personalityType['neuroticism']) - 2,
                  'extroversion':
                      _getComaptibleValue(_personalityType['extroversion']) - 2,
                },
                {
                  'opennes':
                      _getComaptibleValue(_personalityType['opennes']) + 1,
                  'agrreableness':
                      _getComaptibleValue(_personalityType['agrreableness']) +
                          1,
                  'conscientiousness': _getComaptibleValue(
                          _personalityType['conscientiousness']) +
                      1,
                  'neuroticism':
                      _getComaptibleValue(_personalityType['neuroticism']) + 1,
                  'extroversion':
                      _getComaptibleValue(_personalityType['extroversion']) + 1,
                },
                {
                  'opennes':
                      _getComaptibleValue(_personalityType['opennes']) - 1,
                  'agrreableness':
                      _getComaptibleValue(_personalityType['agrreableness']) -
                          1,
                  'conscientiousness': _getComaptibleValue(
                          _personalityType['conscientiousness']) -
                      1,
                  'neuroticism':
                      _getComaptibleValue(_personalityType['neuroticism']) - 1,
                  'extroversion':
                      _getComaptibleValue(_personalityType['extroversion']) - 1,
                },
              ],
            )
            .orderBy('timestamp', descending: true)
            .snapshots()
            .listen((event) {
              print('listen ran');
              if (event.docs.isEmpty) {
                returnFiltered = false;
                doneListening = true;
              } else {
                returnFiltered = true;
                doneListening = true;
              }
              print(returnFiltered);
            });
        if (returnFiltered == true && doneListening == true) {
          return _firestore
              .collection(collectionName)
              .where(
                fieldName,
                whereIn: [
                  {
                    'opennes':
                        _getComaptibleValue(_personalityType['opennes']) - 3,
                    'agrreableness':
                        _getComaptibleValue(_personalityType['agrreableness']) -
                            3,
                    'conscientiousness': _getComaptibleValue(
                            _personalityType['conscientiousness']) -
                        3,
                    'neuroticism':
                        _getComaptibleValue(_personalityType['neuroticism']) -
                            3,
                    'extroversion':
                        _getComaptibleValue(_personalityType['extroversion']) -
                            3,
                  },
                  {
                    'opennes':
                        _getComaptibleValue(_personalityType['opennes']) + 3,
                    'agrreableness':
                        _getComaptibleValue(_personalityType['agrreableness']) +
                            3,
                    'conscientiousness': _getComaptibleValue(
                            _personalityType['conscientiousness']) +
                        3,
                    'neuroticism':
                        _getComaptibleValue(_personalityType['neuroticism']) +
                            3,
                    'extroversion':
                        _getComaptibleValue(_personalityType['extroversion']) +
                            3,
                  },
                  {
                    'opennes':
                        _getComaptibleValue(_personalityType['opennes']) + 2,
                    'agrreableness':
                        _getComaptibleValue(_personalityType['agrreableness']) +
                            2,
                    'conscientiousness': _getComaptibleValue(
                            _personalityType['conscientiousness']) +
                        2,
                    'neuroticism':
                        _getComaptibleValue(_personalityType['neuroticism']) +
                            2,
                    'extroversion':
                        _getComaptibleValue(_personalityType['extroversion']) +
                            2,
                  },
                  {
                    'opennes':
                        _getComaptibleValue(_personalityType['opennes']) - 2,
                    'agrreableness':
                        _getComaptibleValue(_personalityType['agrreableness']) -
                            2,
                    'conscientiousness': _getComaptibleValue(
                            _personalityType['conscientiousness']) -
                        2,
                    'neuroticism':
                        _getComaptibleValue(_personalityType['neuroticism']) -
                            2,
                    'extroversion':
                        _getComaptibleValue(_personalityType['extroversion']) -
                            2,
                  },
                  {
                    'opennes':
                        _getComaptibleValue(_personalityType['opennes']) + 1,
                    'agrreableness':
                        _getComaptibleValue(_personalityType['agrreableness']) +
                            1,
                    'conscientiousness': _getComaptibleValue(
                            _personalityType['conscientiousness']) +
                        1,
                    'neuroticism':
                        _getComaptibleValue(_personalityType['neuroticism']) +
                            1,
                    'extroversion':
                        _getComaptibleValue(_personalityType['extroversion']) +
                            1,
                  },
                  {
                    'opennes':
                        _getComaptibleValue(_personalityType['opennes']) - 1,
                    'agrreableness':
                        _getComaptibleValue(_personalityType['agrreableness']) -
                            1,
                    'conscientiousness': _getComaptibleValue(
                            _personalityType['conscientiousness']) -
                        1,
                    'neuroticism':
                        _getComaptibleValue(_personalityType['neuroticism']) -
                            1,
                    'extroversion':
                        _getComaptibleValue(_personalityType['extroversion']) -
                            1,
                  },
                ],
              )
              .orderBy('timestamp', descending: true)
              .get();
        } else {
          return _firestore
              .collection(collectionName)
              .orderBy('timestamp', descending: true)
              .get();
        }
      }
    } else {
      if (collectionName == 'love-cards' || collectionName == 'lover-cards') {
        return _firestore
            .collection(collectionName)
            .orderBy('timestamp', descending: true)
            .get();
      }
      return _firestore
          .collection(collectionName)
          .orderBy(
            collectionName == 'talents'
                ? 'yesCount'
                : collectionName == 'comedy' ? 'laughs' : 'likes',
            descending: true,
          )
          .orderBy('commentCount', descending: true)
          .orderBy(
              collectionName == 'talents'
                  ? 'noCount'
                  : collectionName == 'challenge'
                      ? 'disLikes'
                      : collectionName == 'comedy' || collectionName == 'sports'
                          ? 'creatorId'
                          : 'shareCount',
              descending:
                  collectionName == 'comedy' || collectionName == 'sports'
                      ? false
                      : true)
          .orderBy('viewsCount', descending: true)
          .orderBy('timestamp', descending: true)
          .get();
    }
  }

  static int _getComaptibleValue(int value) {
    final int _percent = value ~/ 100;
    final int _twentyPercent = _percent * 20;
    if (value > 50) {
      print(value - _twentyPercent);
      return (value - _twentyPercent).round();
    } else if (value <= 50) {
      print(value + _twentyPercent);
      return (value + _twentyPercent).round();
    } else {
      return 0;
    }
  }

  static Stream<QuerySnapshot> setUserPersonalityStream(
      Map<String, dynamic> _personalityType, FirebaseFirestore _firestore,
      [bool use100Limit = false]) {
    if (_personalityType.isNotEmpty) {
      return _firestore
          .collection('users')
          .where(
            'personality-type',
            whereIn: [
              {
                'opennes': _getComaptibleValue(_personalityType['opennes']) - 3,
                'agrreableness':
                    _getComaptibleValue(_personalityType['agrreableness']) - 3,
                'conscientiousness':
                    _getComaptibleValue(_personalityType['conscientiousness']) -
                        3,
                'neuroticism':
                    _getComaptibleValue(_personalityType['neuroticism']) - 3,
                'extroversion':
                    _getComaptibleValue(_personalityType['extroversion']) - 3,
              },
              {
                'opennes': _getComaptibleValue(_personalityType['opennes']) + 3,
                'agrreableness':
                    _getComaptibleValue(_personalityType['agrreableness']) + 3,
                'conscientiousness':
                    _getComaptibleValue(_personalityType['conscientiousness']) +
                        3,
                'neuroticism':
                    _getComaptibleValue(_personalityType['neuroticism']) + 3,
                'extroversion':
                    _getComaptibleValue(_personalityType['extroversion']) + 3,
              },
              {
                'opennes': _getComaptibleValue(_personalityType['opennes']) + 2,
                'agrreableness':
                    _getComaptibleValue(_personalityType['agrreableness']) + 2,
                'conscientiousness':
                    _getComaptibleValue(_personalityType['conscientiousness']) +
                        2,
                'neuroticism':
                    _getComaptibleValue(_personalityType['neuroticism']) + 2,
                'extroversion':
                    _getComaptibleValue(_personalityType['extroversion']) + 2,
              },
              {
                'opennes': _getComaptibleValue(_personalityType['opennes']) - 2,
                'agrreableness':
                    _getComaptibleValue(_personalityType['agrreableness']) - 2,
                'conscientiousness':
                    _getComaptibleValue(_personalityType['conscientiousness']) -
                        2,
                'neuroticism':
                    _getComaptibleValue(_personalityType['neuroticism']) - 2,
                'extroversion':
                    _getComaptibleValue(_personalityType['extroversion']) - 2,
              },
              {
                'opennes': _getComaptibleValue(_personalityType['opennes']) + 1,
                'agrreableness':
                    _getComaptibleValue(_personalityType['agrreableness']) + 1,
                'conscientiousness':
                    _getComaptibleValue(_personalityType['conscientiousness']) +
                        1,
                'neuroticism':
                    _getComaptibleValue(_personalityType['neuroticism']) + 1,
                'extroversion':
                    _getComaptibleValue(_personalityType['extroversion']) + 1,
              },
              {
                'opennes': _getComaptibleValue(_personalityType['opennes']) - 1,
                'agrreableness':
                    _getComaptibleValue(_personalityType['agrreableness']) - 1,
                'conscientiousness':
                    _getComaptibleValue(_personalityType['conscientiousness']) -
                        1,
                'neuroticism':
                    _getComaptibleValue(_personalityType['neuroticism']) - 1,
                'extroversion':
                    _getComaptibleValue(_personalityType['extroversion']) - 1,
              },
            ],
          )
          .limit(use100Limit == true ? 100 : 10)
          .snapshots();
    } else {
      return Stream.empty();
    }
  }

  static Future<void> setTextInput(String data) async {
    final File _persFile = await _localPersonalityFile;
    _persFile.writeAsString(data, mode: FileMode.append);
  }

  static String basicAuthorizationHeader(String username, String password) {
    return 'Basic ' + base64Encode(utf8.encode('$username:$password'));
  }

  static Future<void> setAudioInput(String data) async {
    if (data.contains('http')) {
      final Directory dir = await getTemporaryDirectory();
      final String filePath = '${dir.path}/analyzed-video';
      final http.Response response = await http.get(data);
      final File videoFile = File(filePath);
      videoFile.writeAsBytesSync(response.bodyBytes);
      final Stream<List<int>> _stream = videoFile.openRead();
      _stream.listen((event) async {
        final http.Response _response = await http.post(
          Uri.encodeFull('$SPEECH_URL/v1/recognize'),
          body: event,
          headers: {
            HttpHeaders.authorizationHeader:
                basicAuthorizationHeader('apikey', SPEECH_API_KEY),
            HttpHeaders.contentTypeHeader: 'audio/mp3',
            HttpHeaders.acceptHeader: 'application/json',
          },
        );
        final Map<String, dynamic> _json = json.decode(_response.body);
        if (_response.statusCode == 200) {
          final List _results = _json['results'];
          if (_results.isNotEmpty) {
            final File _persFile = await _localPersonalityFile;
            String _data = _json['results'][0]['alternatives'][0]['transcript'];
            _persFile.writeAsString(_data, mode: FileMode.append);
          }
        }
      });
    } else {
      final Stream<List<int>> _stream = File(data).openRead();
      _stream.listen((event) async {
        print(data);
        print(event);
        final http.Response _response = await http.post(
          Uri.encodeFull('$SPEECH_URL/v1/recognize'),
          body: event,
          headers: {
            HttpHeaders.authorizationHeader:
                basicAuthorizationHeader('apikey', SPEECH_API_KEY),
            HttpHeaders.contentTypeHeader: 'audio/mp3',
            HttpHeaders.acceptHeader: 'application/json',
          },
        );
        final Map<String, dynamic> _json = json.decode(_response.body);
        if (_response.statusCode == 200) {
          final List _results = _json['results'];
          if (_results.isNotEmpty) {
            final File _persFile = await _localPersonalityFile;
            String _data = _json['results'][0]['alternatives'][0]['transcript'];
            _persFile.writeAsString(_data, mode: FileMode.append);
          }
        }
      });
    }
  }

  static Future<void> setImageInput(String data) {
    PersonalityService.getImageLabels(data).then(
      (value) async {
        final File _persFile = await _localPersonalityFile;
        final String _labels = value.toString();
        _persFile.writeAsString(_labels, mode: FileMode.append);
      },
    );
    return null;
  }

  static Future<void> setVideoInput(String data) async {
    await PersonalityService.extractVideoFileFramesAndAnalyze(data);
  }

  static Future<void> extractVideoFileFramesAndAnalyze(
      String videoFileName) async {
    FirebaseVisionImage _visionImage;
    if (videoFileName.contains('http')) {
      print(videoFileName);
      final Directory dir = await getTemporaryDirectory();
      final String filePath = '${dir.path}/analyzed-video';
      final http.Response response = await http.get(videoFileName);
      final File videoFile = File(filePath);
      videoFile.writeAsBytesSync(response.bodyBytes);
      final List<File> images = await ExportVideoFrame.exportImage(
        videoFile.path,
        10,
        0,
      );
      for (File image in images) {
        _visionImage = FirebaseVisionImage.fromFile(image);
        final ImageLabeler _labelDetector =
            FirebaseVision.instance.imageLabeler(
          ImageLabelerOptions(
            confidenceThreshold: 0.75,
          ),
        );
        final List<ImageLabel> _labels = await _labelDetector.processImage(
          _visionImage,
        );
        final List<String> _imageLabels = <String>[];
        for (ImageLabel label in _labels) {
          if (label.text.isNotEmpty) {
            final _labelText = label.text;
            _imageLabels.add(_labelText);
          }
        }
        final File _persFile = await _localPersonalityFile;
        _persFile.writeAsString(_imageLabels.toString(), mode: FileMode.append);
      }
    } else {
      final List<File> images = await ExportVideoFrame.exportImage(
        videoFileName,
        1,
        0,
      );
      for (File image in images) {
        _visionImage = FirebaseVisionImage.fromFile(image);
        final ImageLabeler _labelDetector =
            FirebaseVision.instance.imageLabeler(
          ImageLabelerOptions(
            confidenceThreshold: 0.75,
          ),
        );
        final List<ImageLabel> _labels = await _labelDetector.processImage(
          _visionImage,
        );
        final List<String> _imageLabels = <String>[];
        for (ImageLabel label in _labels) {
          if (label.text.isNotEmpty) {
            final _labelText = label.text;
            _imageLabels.add(_labelText);
          }
        }
        print(_imageLabels);
        final File _persFile = await _localPersonalityFile;
        _persFile.writeAsString(_imageLabels.toString(), mode: FileMode.append);
      }
    }
  }

  static Future<List<String>> getImageLabels(String imagePath) async {
    FirebaseVisionImage _visionImage;
    if (imagePath.contains('http')) {
      final Directory dir = await getTemporaryDirectory();
      final String filePath = '${dir.path}/analyzed-image';
      final http.Response response = await http.get(imagePath);
      final File imageFile = File(filePath);
      imageFile.writeAsBytesSync(response.bodyBytes);
      _visionImage = FirebaseVisionImage.fromFile(imageFile);
    } else {
      _visionImage = FirebaseVisionImage.fromFilePath(imagePath);
    }

    final ImageLabeler _labelDetector = FirebaseVision.instance.imageLabeler(
      ImageLabelerOptions(
        confidenceThreshold: 0.75,
      ),
    );
    final List<ImageLabel> _labels = await _labelDetector.processImage(
      _visionImage,
    );
    final List<String> _imageLabels = <String>[];
    for (ImageLabel label in _labels) {
      if (label.text.isNotEmpty) {
        final _labelText = label.text;
        _imageLabels.add(_labelText);
      }
    }
    return _imageLabels;
  }
}
