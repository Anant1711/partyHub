import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:clique/models/createParty.dart';
import 'package:uuid/uuid.dart';

import '../models/joinRequestModel.dart';

class PartyService {
  Uuid uid = Uuid();
  // Collection name for join requests
  final String REQUEST_COLLECTION = "joinRequests";

  //Collection name for partyDetails
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

  //////////////////////////////////////////////////////////////////////////

  Future<void> createJoinRequest(JoinRequest joinRequest) async {
    await _firestore
        .collection(REQUEST_COLLECTION)
        .doc(uid.v4())  // Using `partyId` as the requestID
        .set(joinRequest.toMap());  // Directly setting the content of the request

  }


  Future<List<Map<String, dynamic>>> getJoinRequests(String hostId) async {
    try {
      final querySnapshot = await _firestore
          .collection(REQUEST_COLLECTION)
          .where('hostId', isEqualTo: hostId)
          .get();

      return querySnapshot.docs.map((doc) {
        final data = doc.data();
        data['DocId'] = doc.id; // Add the document ID to the data
        return data;
      }).toList();
    } catch (e) {
      throw Exception('Error fetching join requests: $e');
    }
  }


  // Update the join request status
  Future<void> updateJoinRequest(String DocId, String partyId, String status) async {
    await _firestore.collection(REQUEST_COLLECTION)
        .doc(DocId)
    .update({
      'status': status,
    });
  }

  // Add user to the party if request is accepted (For Approved Requests)
  Future<void> addUserToParty(String partyId, String userId) async {
    final party = await _firestore.collection(PREF_NAME).doc(partyId).get();
    if (party.exists) {
      final partyData = Party.fromMap(party.data() as Map<String, dynamic>);
      if (partyData.attendees.length < partyData.maxAttendees &&
          !partyData.attendees.contains(userId)) {
        final updatedParty = Party(
          id: partyData.id,
          name: partyData.name,
          description: partyData.description,
          dateTime: partyData.dateTime,
          location: partyData.location,
          maxAttendees: partyData.maxAttendees,
          attendees: List.from(partyData.attendees)..add(userId),
          hostName: partyData.hostName,
          hostID: partyData.hostID,
          pendingRequests: partyData.pendingRequests,
        );
        await _firestore.collection(PREF_NAME).doc(partyId).update(updatedParty.toMap());
      }
    }
  }

  //Delete Request
  Future<void> deleteRequest(String requestId) async {
    debugPrint("Deleting a Request");
    await _firestore.collection(REQUEST_COLLECTION).doc(requestId).delete();
  }

}
