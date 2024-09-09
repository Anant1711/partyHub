import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';
import 'package:shared_preferences/shared_preferences.dart';

class UserService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<Map<String, String>> getAllUsernames(List<String> userIds) async {
    final Map<String, String> usernames = {};

    try {
      final userDocs = await Future.wait(userIds
          .map((userId) => _firestore.collection('users').doc(userId).get()));

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

  Future<String?> getUserId() async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? userId = prefs.getString('userId');
      return userId;
    } catch (e) {
      print("Error retrieving username: $e");
      return null;
    }
  }

  Future<String?> getUserNameByID(String userID) async {
    // Fetch the documents where 'userID' matches the provided userID
    QuerySnapshot querySnapshot = await _firestore
        .collection("users")
        .where('userID', isEqualTo: userID)
        .get();

    // Check if any documents were returned
    if (querySnapshot.docs.isNotEmpty) {
      // Get the first document from the query snapshot
      DocumentSnapshot documentSnapshot = querySnapshot.docs.first;

      // Extract the 'name' field from the document data
      String? name = documentSnapshot.get('name');

      // Return the extracted name
      return name;
    } else {
      // Return null if no documents were found
      return null;
    }
  }

}
