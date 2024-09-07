import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';

class UserService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<Map<String, String>> getAllUsernames(List<String> userIds) async {
    final Map<String, String> usernames = {};

    try {
      final userDocs = await Future.wait(userIds.map((userId) =>
          _firestore.collection('users').doc(userId).get()));

      for (var doc in userDocs) {
        if (doc.exists) {
          final username = doc.data()?['name'] ?? 'Unknown';
          usernames[doc.id] = username;
        } else {
          usernames[doc.id] = 'Unknown'; // If document does not exist
        }
      }
    } catch (e) {
      print("Error fetching usernames: $e");
    }

    return usernames;
  }

  Future<String?> getUserName() async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? username = prefs.getString('userName');
      return username;
    } catch (e) {
      print("Error retrieving username: $e");
      return null;
    }
  }
}
