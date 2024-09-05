import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:clique/models/createParty.dart';

class PartyService {
  final String PREF_NAME = "partyDetails";
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Create a new party
  Future<void> createParty(Party party) async {
    debugPrint("Creating Party");
    await _firestore.collection(PREF_NAME).doc(party.id).set(party.toMap());
  }

  // Get all parties
  Future<List<Party>> getParties() async {
    debugPrint("Get all Party");
    QuerySnapshot snapshot = await _firestore.collection(PREF_NAME).get();
    return snapshot.docs.map((doc) => Party.fromMap(doc.data() as Map<String, dynamic>)).toList();
  }

  //Get specific user's parties
  Future<List<Party>> getUserParties(String userId) async {
    debugPrint("Getting Parties created by user: $userId");

    try {
      // Perform the query
      QuerySnapshot snapshot = await _firestore
          .collection(PREF_NAME)
          .where('hostid', isEqualTo: userId)
          .get();

      // Log the number of documents retrieved
      debugPrint("Number of parties found: ${snapshot.docs.length}");

      // Log the data of each document
      for (var doc in snapshot.docs) {
        debugPrint("Document data: ${doc.data()}");
      }

      // Convert documents to Party objects
      return snapshot.docs
          .map((doc) => Party.fromMap(doc.data() as Map<String, dynamic>))
          .toList();
    } catch (e) {
      // Log any errors
      debugPrint("Error retrieving parties: $e");
      return [];
    }
  }


  // Update a party
  Future<void> updateParty(Party party) async {
    debugPrint("Updating Party");
    await _firestore.collection(PREF_NAME).doc(party.id).update(party.toMap());
  }

  // Delete a party
  Future<void> deleteParty(String partyId) async {
    debugPrint("Deleting a Party");
    await _firestore.collection(PREF_NAME).doc(partyId).delete();
  }
}
