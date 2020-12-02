import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/postModel.dart';
import '../models/talentModel.dart';
import '../models/sportModel.dart';
import '../models/comedyModel.dart';
import '../models/challengeModel.dart';
import '../models/loveCardModel.dart';
import '../models/loverCardModel.dart';
import '../models/messageModel.dart';
import '../models/commentModel.dart';

class DatabaseService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final CollectionReference _userRef = _firestore.collection('users');
  static final CollectionReference _postsDocRef =
      _firestore.collection('posts');
  static final CollectionReference _talentsDocRef =
      _firestore.collection('talents');
  static final CollectionReference _sportsDocRef =
      _firestore.collection('sports');
  static final CollectionReference _comedyDocRef =
      _firestore.collection('comedy');
  static final CollectionReference _challengesDocRef =
      _firestore.collection('challenge');
  static final CollectionReference _loveCardsDocRef =
      _firestore.collection('love-cards');
  static final CollectionReference _loverCardsDocRef =
      _firestore.collection('lover-cards');

  static void addPost(
    Post post,
    bool sharePost,
    String shareAuthorName,
    String postAction,
  ) {
    final DocumentReference _postdocRef = _postsDocRef.doc();
    try {
      _firestore.runTransaction((Transaction transaction) async {
        transaction.set(_postdocRef, {
          'author': post.authorId,
          'author-name': post.authorName,
          'author-personality': post.authorPersonality,
          'author-image': post.authorImage,
          'share-author-name': shareAuthorName,
          'text': post.text,
          'gif': post.gif,
          'caption': post.caption,
          'location': post.location,
          'question': post.question,
          'mediaUrl': post.mediaUrl,
          'audio': post.audioUrl,
          'audioImage': post.audioImage,
          'audioDescribtion': post.audioDescribtion,
          'timestamp': post.timestamp,
          'type': post.type,
          'isShared': sharePost,
          'viewsCount': 0,
          'likes': 0,
          'viewed-people': [],
          'liked-people': [],
          'option1-people': [],
          'option2-people': [],
          'option1Count': 0,
          'option2Count': 0,
          'commentCount': 0,
          'shareCount': 0,
        });
      });
      Fluttertoast.showToast(msg: 'Post $postAction');
    } catch (_) {
      _showError();
    }
  }

  static void sharePost(String postId, Post post, String userName) {
    final DocumentReference _postDocRef = _postsDocRef.doc(postId);
    try {
      _firestore.runTransaction((Transaction transaction) async {
        transaction.update(_postDocRef, {
          'shareCount': FieldValue.increment(1),
        });
      });
      DatabaseService.addPost(post, true, userName, 'shared');
    } catch (_) {
      _showError();
    }
  }

  static void deletePost(String postId) {
    final DocumentReference _postDocRef = _postsDocRef.doc(postId);
    try {
      _firestore.runTransaction((Transaction transaction) async {
        transaction.delete(_postDocRef);
      });
    } catch (_) {
      _showError();
    }
  }

  static void addTalent(Talent talent) {
    final DocumentReference _talentDocRef = _talentsDocRef.doc();
    try {
      _firestore.runTransaction((Transaction transaction) async {
        transaction.set(_talentDocRef, {
          'creatorId': talent.creatorId,
          'creator-name': talent.creatorName,
          'creator-personality': talent.creatorPersonality,
          'creator-image': talent.creatorProfileImage,
          'videoUrl': talent.videoUrl,
          'category': talent.category,
          'caption': talent.caption,
          'talent-Name': talent.talentName,
          'movieFilter': talent.movieFilter,
          'golden-stared-people': [],
          'yes-counted-people': [],
          'no-counted-people': [],
          'claped-people': [],
          'viewed-people': [],
          'goldenstars': 0,
          'viewsCount': 0,
          'commentCount': 0,
          'claps': 0,
          'yesCount': 0,
          'noCount': 0,
          'timestamp': talent.timestamp,
        });
      });
    } catch (_) {
      _showError();
    }
  }

  static void clapToTalent(String talentId, String userId) {
    final DocumentReference _talentDocRef = _talentsDocRef.doc(talentId);
    try {
      _firestore.runTransaction((Transaction transaction) async {
        transaction.update(_talentDocRef, {
          'claps': FieldValue.increment(2),
          'claped-people': FieldValue.arrayUnion([userId]),
        });
      });
    } catch (_) {
      _showError();
    }
  }

  static void addGoldenStar(String talentId, String userId) {
    final DocumentReference _talentDocRef = _talentsDocRef.doc(talentId);
    try {
      _firestore.runTransaction((Transaction transaction) async {
        transaction.update(_talentDocRef, {
          'goldenstars': FieldValue.increment(1),
          'golden-stared-people': FieldValue.arrayUnion([userId]),
        });
      });
    } catch (_) {
      _showError();
    }
  }

  static void removeGoldenStar(String talentId, String userId) {
    final DocumentReference _talentDocRef = _talentsDocRef.doc(talentId);
    try {
      _firestore.runTransaction((Transaction transaction) async {
        transaction.update(_talentDocRef, {
          'goldenstars': FieldValue.increment(-1),
          'golden-stared-people': FieldValue.arrayRemove([userId]),
        });
      });
    } catch (_) {
      _showError();
    }
  }

  static void addYes(String talentId, String userId) {
    final DocumentReference _talentDocRef = _talentsDocRef.doc(talentId);
    try {
      _firestore.runTransaction((Transaction transaction) async {
        transaction.update(_talentDocRef, {
          'yesCount': FieldValue.increment(1),
          'yes-counted-people': FieldValue.arrayUnion([userId]),
        });
      });
    } catch (_) {
      _showError();
    }
  }

  static void addNo(String talentId, String userId) {
    final DocumentReference _talentDocRef = _talentsDocRef.doc(talentId);
    try {
      _firestore.runTransaction((Transaction transaction) async {
        transaction.update(_talentDocRef, {
          'noCount': FieldValue.increment(1),
          'no-counted-people': FieldValue.arrayUnion([userId]),
        });
      });
    } catch (_) {
      _showError();
    }
  }

  static void removeYes(String talentId, String userId) {
    final DocumentReference _talentDocRef = _talentsDocRef.doc(talentId);
    try {
      _firestore.runTransaction((Transaction transaction) async {
        transaction.update(_talentDocRef, {
          'yesCount': FieldValue.increment(-1),
          'yes-counted-people': FieldValue.arrayRemove([userId]),
        });
      });
    } catch (_) {
      _showError();
    }
  }

  static void removeNo(String talentId, String userId) {
    final DocumentReference _talentDocRef = _talentsDocRef.doc(talentId);
    try {
      _firestore.runTransaction((Transaction transaction) async {
        transaction.update(_talentDocRef, {
          'noCount': FieldValue.increment(-1),
          'no-counted-people': FieldValue.arrayRemove([userId]),
        });
      });
    } catch (_) {
      _showError();
    }
  }

  static void addSport(Sport sport) {
    final DocumentReference _sportDocRef = _sportsDocRef.doc();
    try {
      _firestore.runTransaction((Transaction transaction) async {
        transaction.set(_sportDocRef, {
          'creatorId': sport.creatorId,
          'creator-name': sport.creatorName,
          'creator-personality': sport.creatorPersonality,
          'creator-image': sport.creatorProfileImage,
          'videoUrl': sport.videoUrl,
          'category': sport.sportCategory,
          'liked-people': [],
          'viewed-people': [],
          'viewsCount': 0,
          'likes': 0,
          'commentCount': 0,
          'timestamp': sport.timestamp,
        });
      });
    } catch (_) {
      _showError();
    }
  }

  static void addComedy(Comedy comedy) {
    try {
      final DocumentReference _comedieDocRef = _comedyDocRef.doc();
      _firestore.runTransaction((Transaction transaction) async {
        transaction.set(_comedieDocRef, {
          'creatorId': comedy.authorId,
          'creator-name': comedy.authorName,
          'creator-personality': comedy.authorPersonality,
          'creator-image': comedy.authorImage,
          'mediaUrl': comedy.mediaUrl,
          'caption': comedy.caption,
          'content': comedy.content,
          'type': comedy.type,
          'laughed-people': [],
          'viewed-people': [],
          'viewsCount': 0,
          'visitCount': 0,
          'laughs': 0,
          'commentCount': 0,
          'timestamp': comedy.timestamp,
        });
      });
    } catch (_) {
      _showError();
    }
  }

  static void addChallenge(Challenge challenge) {
    final DocumentReference _challengeDocRef = _challengesDocRef.doc();
    try {
      _firestore.runTransaction((Transaction transaction) async {
        transaction.set(_challengeDocRef, {
          'creatorId': challenge.creatorId,
          'creator-name': challenge.creatorName,
          'creator-personality': challenge.creatorPersonality,
          'creator-image': challenge.creatorProfileImage,
          'videoUrl': challenge.videoUrl,
          'type': challenge.category,
          'liked-people': [],
          'neutral-people': [],
          'disliked-people': [],
          'viewed-people': [],
          'viewsCount': 0,
          'likes': 0,
          'neutral': 0,
          'disLikes': 0,
          'commentCount': 0,
          'timestamp': challenge.timestamp,
        });
      });
    } catch (_) {
      _showError();
    }
  }

  static void addNeutral(String challengeId, String userId) {
    final DocumentReference _docRef = _challengesDocRef.doc(challengeId);
    try {
      _firestore.runTransaction((Transaction transaction) async {
        transaction.update(_docRef, {
          'neutral': FieldValue.increment(1),
          'neutral-people': FieldValue.arrayUnion([userId]),
        });
      });
    } catch (_) {
      _showError();
    }
  }

  static void removeNeutral(String challengeId, String userId) {
    final DocumentReference _docRef = _challengesDocRef.doc(challengeId);
    try {
      _firestore.runTransaction((Transaction transaction) async {
        transaction.update(_docRef, {
          'neutral': FieldValue.increment(-1),
          'neutral-people': FieldValue.arrayRemove([userId]),
        });
      });
    } catch (_) {
      _showError();
    }
  }

  static void addLoveCard(LoveCard loveCard) {
    final DocumentReference _loveCardDocRef = _loveCardsDocRef.doc();
    try {
      _firestore.runTransaction((Transaction transaction) async {
        transaction.set(_loveCardDocRef, {
          'authorId': loveCard.authorId,
          'authorName': loveCard.authorName,
          'author-personality': loveCard.authorPersonality,
          'authorImage': loveCard.authorImage,
          'authorAge': loveCard.authorAge,
          'imageUrl': loveCard.imageUrl,
          'location': loveCard.location,
          'timestamp': loveCard.timestamp,
        });
      });
    } catch (_) {
      _showError();
    }
  }

  static void addLoverCard(LoverCard loverCard) {
    final DocumentReference _loverCardDocRef = _loverCardsDocRef.doc();
    try {
      _firestore.runTransaction((Transaction transaction) async {
        transaction.set(_loverCardDocRef, {
          'authorId': loverCard.authorId,
          'author-name': loverCard.authorName,
          'author-personality': loverCard.authorPersonality,
          'author-image': loverCard.authorImage,
          'age-range': loverCard.ageRange,
          'gender': loverCard.gender,
          'author-age': loverCard.authorAge,
          'qualities': loverCard.qualities,
          'lookQualities': loverCard.lookQualities,
          'timestamp': loverCard.timestamp,
        });
      });
    } catch (_) {
      _showError();
    }
  }

  static void intrestedInPerson(String loveCardAuthorId) async {
    final SharedPreferences _prefs = await SharedPreferences.getInstance();
    final id = _prefs.get('id');
    final DocumentReference _docRef = _userRef.doc(id);
    try {
      _firestore.runTransaction((Transaction transaction) async {
        transaction.update(_docRef, {
          'interested-people': FieldValue.arrayUnion([loveCardAuthorId]),
        });
      });
    } catch (_) {
      _showError();
    }
  }

  static void notIntrestedInPerson(String loveCardAuthorId) async {
    final SharedPreferences _prefs = await SharedPreferences.getInstance();
    final id = _prefs.get('id');
    final DocumentReference _docRef = _userRef.doc(id);
    try {
      _firestore.runTransaction((Transaction transaction) async {
        transaction.update(_docRef, {
          'interested-people': FieldValue.arrayRemove([loveCardAuthorId]),
        });
      });
    } catch (_) {
      _showError();
    }
  }

  static void laugh(String comedyId, String userId) {
    final DocumentReference _docRef = _comedyDocRef.doc(comedyId);
    try {
      _firestore.runTransaction((Transaction transaction) async {
        transaction.update(_docRef, {
          'laughs': FieldValue.increment(1),
          'laughed-people': FieldValue.arrayUnion([userId]),
        });
      });
    } catch (_) {
      _showError();
    }
  }

  static void unLaugh(String comedyId, String userId) {
    final DocumentReference _docRef = _comedyDocRef.doc(comedyId);
    try {
      _firestore.runTransaction((Transaction transaction) async {
        transaction.update(_docRef, {
          'laughs': FieldValue.increment(-1),
          'laughed-people': FieldValue.arrayRemove([userId]),
        });
      });
    } catch (_) {
      _showError();
    }
  }

  static void addVisit(String comedyId) {
    final DocumentReference _docRef = _comedyDocRef.doc(comedyId);
    try {
      _firestore.runTransaction((Transaction transaction) async {
        transaction.update(_docRef, {
          'visitCount': FieldValue.increment(1),
        });
      });
    } catch (_) {
      _showError();
    }
  }

  static void removeVisit(String comedyId) {
    final DocumentReference _docRef = _comedyDocRef.doc(comedyId);
    try {
      _firestore.runTransaction((Transaction transaction) async {
        transaction.update(_docRef, {
          'visitCount': FieldValue.increment(-1),
        });
      });
    } catch (_) {
      _showError();
    }
  }

  static void saveContent(String collection, String contentId) async {
    final SharedPreferences _prefs = await SharedPreferences.getInstance();
    final id = _prefs.get('id');
    final DocumentReference _docSavingRef = _firestore
        .collection('users')
        .doc(id)
        .collection(collection)
        .doc(contentId);
    try {
      _firestore.runTransaction(
        (transaction) async => transaction.set(_docSavingRef, {
          'content-id': contentId,
        }),
      );
      Fluttertoast.showToast(msg: 'Saved to your List');
    } catch (_) {
      _showError();
    }
  }

  static void chooseOption1(String postId, String userId) {
    final DocumentReference _docRef = _postsDocRef.doc(postId);
    try {
      _firestore.runTransaction((Transaction transaction) async {
        transaction.update(_docRef, {
          'option1Count': FieldValue.increment(1),
          'option1-people': FieldValue.arrayUnion([userId]),
        });
      });
    } catch (_) {
      _showError();
    }
  }

  static void chooseOption2(String postId, String userId) {
    final DocumentReference _docRef = _postsDocRef.doc(postId);
    try {
      _firestore.runTransaction((Transaction transaction) async {
        transaction.update(_docRef, {
          'option2Count': FieldValue.increment(1),
          'option2-people': FieldValue.arrayUnion([userId]),
        });
      });
    } catch (_) {
      _showError();
    }
  }

  static void like(String collection, String objectId, String userId) {
    try {
      final DocumentReference _docRef =
          _firestore.collection(collection).doc(objectId);

      _firestore.runTransaction((Transaction transaction) async {
        transaction.update(_docRef, {
          'likes': FieldValue.increment(1),
          'liked-people': FieldValue.arrayUnion([userId]),
        });
      });
    } catch (_) {
      _showError();
    }
  }

  static void unLike(String collection, String objectId, String userId) {
    try {
      final DocumentReference _docRef =
          _firestore.collection(collection).doc(objectId);

      _firestore.runTransaction((Transaction transaction) async {
        transaction.update(_docRef, {
          'likes': FieldValue.increment(-1),
          'liked-people': FieldValue.arrayRemove([userId]),
        });
      });
    } catch (_) {
      _showError();
    }
  }

  static void disLike(String collection, String objectId, String userId) {
    final DocumentReference _docRef =
        _firestore.collection(collection).doc(objectId);
    try {
      _firestore.runTransaction((Transaction transaction) async {
        transaction.update(_docRef, {
          'disLikes': FieldValue.increment(1),
          'disliked-people': FieldValue.arrayUnion([userId]),
        });
      });
    } catch (_) {
      _showError();
    }
  }

  static void undisLike(String collection, String objectId, String userId) {
    final DocumentReference _docRef =
        _firestore.collection(collection).doc(objectId);
    try {
      _firestore.runTransaction((Transaction transaction) async {
        transaction.update(_docRef, {
          'disLikes': FieldValue.increment(-1),
          'disliked-people': FieldValue.arrayRemove([userId]),
        });
      });
    } catch (_) {
      _showError();
    }
  }

  static void addView(String collection, String objectId, String userId) {
    final DocumentReference _docRef =
        _firestore.collection(collection).doc(objectId);
    _firestore.runTransaction((Transaction transaction) async {
      transaction.update(_docRef, {
        'viewsCount': FieldValue.increment(1),
        'viewed-people': FieldValue.arrayUnion([userId]),
      });
    });
  }

  static void addComment(
    String collection,
    String objectId,
    Comment comment,
  ) {
    final DocumentReference _objectDocRef =
        _firestore.collection(collection).doc(objectId);
    final DocumentReference _objectCommentDocRef =
        _objectDocRef.collection('comments').doc();
    try {
      _firestore.runTransaction((Transaction transaction) async {
        transaction.set(_objectCommentDocRef, {
          'author': comment.author,
          'authorId': comment.authorId,
          'author-image': comment.authorImage,
          'content': comment.content,
          'media': comment.media,
          'liked-people': [],
          'likes': 0,
          'replies': 0,
          'timestamp': comment.timestamp,
          'type': comment.type,
        });
        transaction.update(_objectDocRef, {
          'commentCount': FieldValue.increment(1),
        });
      });
    } catch (_) {
      _showError();
    }
  }

  static void deleteComment(
    String objectId,
    String collection,
    String commentId,
  ) {
    final DocumentReference _objectDocRef =
        _firestore.collection(collection).doc(objectId);
    final DocumentReference _objectCommentDocRef =
        _objectDocRef.collection('comments').doc(commentId);
    _firestore.runTransaction((Transaction transaction) async {
      transaction.delete(_objectCommentDocRef);
      transaction.update(_objectDocRef, {
        'commentCount': FieldValue.increment(-1),
      });
    }).catchError(() {
      _showError();
    });
  }

  static void likeComment(
    String objectId,
    String collection,
    String commentId,
    String userId,
  ) {
    final DocumentReference _objectDocRef =
        _firestore.collection(collection).doc(objectId);
    final DocumentReference _objectCommentDocRef =
        _objectDocRef.collection('comments').doc(commentId);
    try {
      _firestore.runTransaction((Transaction transaction) async {
        transaction.update(_objectCommentDocRef, {
          'likes': FieldValue.increment(1),
          'liked-people': FieldValue.arrayUnion([userId]),
        });
      });
    } catch (_) {
      _showError();
    }
  }

  static void unLikeComment(
    String objectId,
    String collection,
    String commentId,
    String userId,
  ) {
    final DocumentReference _objectDocRef =
        _firestore.collection(collection).doc(objectId);
    final DocumentReference _objectCommentDocRef =
        _objectDocRef.collection('comments').doc(commentId);
    try {
      _firestore.runTransaction((Transaction transaction) async {
        transaction.update(_objectCommentDocRef, {
          'likes': FieldValue.increment(-1),
          'liked-people': FieldValue.arrayRemove([userId]),
        });
      });
    } catch (_) {
      _showError();
    }
  }

  static void replyToComment(
    String objectId,
    String collection,
    String commentId,
    Comment reply,
  ) {
    final DocumentReference _objectDocRef =
        _firestore.collection(collection).doc(objectId);
    final DocumentReference _objectCommentDocRef =
        _objectDocRef.collection('comments').doc(commentId);
    final DocumentReference _objectCommentReplyDocRef =
        _objectCommentDocRef.collection('replies').doc();
    try {
      _firestore.runTransaction((Transaction transaction) async {
        transaction.set(_objectCommentReplyDocRef, {
          'author': reply.author,
          'authorId': reply.authorId,
          'author-image': reply.authorImage,
          'content': reply.content,
          'media': reply.media,
          'likes': 0,
          'liked-people': [],
          'timestamp': reply.timestamp,
          'type': reply.type,
        });
        transaction.update(_objectCommentDocRef, {
          'replies': FieldValue.increment(1),
        });
      });
    } catch (_) {
      _showError();
    }
  }

  static void deleteReply(
    String objectId,
    String collection,
    String commentId,
    String replyId,
  ) {
    final DocumentReference _objectDocRef =
        _firestore.collection(collection).doc(objectId);
    final DocumentReference _objectCommentDocRef =
        _objectDocRef.collection('comments').doc(commentId);
    final DocumentReference _objectCommentReplyDocRef =
        _objectCommentDocRef.collection('replies').doc(replyId);
    _firestore.runTransaction((Transaction transaction) async {
      transaction.delete(_objectCommentReplyDocRef);
      transaction.update(_objectCommentReplyDocRef, {
        'replies': FieldValue.increment(-1),
      });
    }).catchError(() {
      _showError();
    });
  }

  static void likeReply(
    String objectId,
    String collection,
    String commentId,
    String userId,
    String replyId,
  ) {
    final DocumentReference __objectDocRef =
        _firestore.collection(collection).doc(objectId);
    final DocumentReference _objectCommentDocRef =
        __objectDocRef.collection('comments').doc(commentId);
    final DocumentReference _objectCommentReplyDocRef =
        _objectCommentDocRef.collection('replies').doc(replyId);
    try {
      _firestore.runTransaction((Transaction transaction) async {
        transaction.update(_objectCommentReplyDocRef, {
          'likes': FieldValue.increment(1),
          'liked-people': FieldValue.arrayUnion([userId]),
        });
      });
    } catch (_) {
      _showError();
    }
  }

  static void unLikeReply(
    String objectId,
    String collection,
    String commentId,
    String userId,
    String replyId,
  ) {
    final DocumentReference __objectDocRef =
        _firestore.collection(collection).doc(objectId);
    final DocumentReference _objectCommentDocRef =
        __objectDocRef.collection('comments').doc(commentId);
    final DocumentReference _objectCommentReplyDocRef =
        _objectCommentDocRef.collection('replies').doc(replyId);
    try {
      _firestore.runTransaction((Transaction transaction) async {
        transaction.update(_objectCommentReplyDocRef, {
          'likes': FieldValue.increment(-1),
          'liked-people': FieldValue.arrayRemove([userId]),
        });
      });
    } catch (_) {
      _showError();
    }
  }

  static void followUser(String userId, String userName) async {
    final SharedPreferences _prefs = await SharedPreferences.getInstance();
    final id = _prefs.get('id');
    final DocumentSnapshot _docSnap =
        await _firestore.collection('users').doc(id).get();
    final String _idName = _docSnap.data()['username'];
    final DocumentReference _docFollowingRef = _firestore
        .collection('users')
        .doc(id)
        .collection('following')
        .doc(userId);
    final DocumentReference _docFollowersRef = _firestore
        .collection('users')
        .doc(userId)
        .collection('followers')
        .doc(id);

    FirebaseFirestore.instance.runTransaction(
      (Transaction transaction) async {
        transaction.set(_docFollowingRef, {
          'id': userId,
          'name': userName,
        });
        transaction.set(_docFollowersRef, {
          'id': id,
          'name': _idName,
        });
      },
    );
  }

  static void unFollowUser(String userId) async {
    final SharedPreferences _prefs = await SharedPreferences.getInstance();
    final id = _prefs.get('id');
    final DocumentReference _docFollowingRef = _firestore
        .collection('users')
        .doc(id)
        .collection('following')
        .doc(userId);
    final DocumentReference _docFollowersRef = _firestore
        .collection('users')
        .doc(userId)
        .collection('followers')
        .doc(id);

    FirebaseFirestore.instance.runTransaction(
      (Transaction transaction) async {
        transaction.delete(_docFollowingRef);
        transaction.delete(_docFollowersRef);
      },
    );
  }

  static Future<bool> checkIsFollowing(String uid) async {
    final SharedPreferences _prefs = await SharedPreferences.getInstance();
    final id = _prefs.get('id');
    bool isFollowing = false;
    QuerySnapshot querySnapshot = await _firestore
        .collection("users")
        .doc(id)
        .collection("following")
        .get();

    for (var i = 0; i < querySnapshot.docs.length; i++) {
      if (querySnapshot.docs[i].id == uid) {
        isFollowing = true;
      }
    }
    return isFollowing;
  }

  static Future<QuerySnapshot> getFollowedContentFeed(
      String collectionName, String fieldName, QuerySnapshot followingList) {
    final List<dynamic> followingIds = [];
    if (followingList != null) {
      if (followingList.docs.isNotEmpty) {
        for (DocumentSnapshot id in followingList.docs) {
          followingIds.add(id.id);
        }
        return _firestore
            .collection(collectionName)
            .where(fieldName, whereIn: followingIds)
            .orderBy('timestamp', descending: true)
            .get();
      } else {
        return _firestore
            .collection(collectionName)
            .orderBy('timestamp', descending: true)
            .get();
      }
    } else {
      return _firestore
          .collection(collectionName)
          .orderBy('timestamp', descending: true)
          .get();
    }
  }

  static void sendMessage(String groupId, Message message, bool isGlobal) {
    final String _timeStamp = DateTime.now().millisecondsSinceEpoch.toString();
    final DocumentReference _documentReference = _firestore
        .collection(
          isGlobal == true ? 'global-chat' : 'chat',
        )
        .doc(groupId)
        .collection('messages')
        .doc(_timeStamp);
    _firestore.runTransaction(
      (Transaction tx) async {
        print('running');
        tx.set(
          _documentReference,
          {
            'id': _timeStamp,
            'from': message.author,
            'to': message.peerId,
            'content': message.content,
            'type': message.type,
            'timestamp': message.timestamp,
          },
        );
      },
    );
  }

  static void deleteMessage(String groupId, String messageId) {
    final DocumentReference _documentReference = _firestore
        .collection('chat')
        .doc(groupId)
        .collection('messages')
        .doc(messageId);
    _firestore.runTransaction((Transaction tx) async {
      tx.delete(_documentReference);
    });
  }

  static String getMessageTiming(String timestamp) {
    String msg = '';
    var dt = DateTime.parse(timestamp).toLocal();

    if (DateTime.now().toLocal().isBefore(dt)) {
      return DateFormat.jm()
          .format(DateTime.parse(timestamp).toLocal())
          .toString();
    }

    var dur = DateTime.now().toLocal().difference(dt);
    if (dur.inDays > 0) {
      msg = '${dur.inDays} d ago';
      return dur.inDays == 1 ? '1d ago' : DateFormat("dd MMM").format(dt);
    } else if (dur.inHours > 0) {
      msg = '${dur.inHours} h ago';
    } else if (dur.inMinutes > 0) {
      msg = '${dur.inMinutes} m ago';
    } else if (dur.inSeconds > 0) {
      msg = '${dur.inSeconds} s ago';
    } else {
      msg = 'now';
    }
    return msg;
  }

  static Future<QuerySnapshot> searchByName(String searchField) {
    return FirebaseFirestore.instance
        .collection('users')
        .where(
          'searchKey',
          isEqualTo: searchField.substring(0, 1),
        )
        .get();
  }

  static void _showError() {
    Fluttertoast.showToast(msg: 'Could not connect to Looper');
  }
}
