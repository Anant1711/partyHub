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

  //Get party by ID
  Future<Party?> getPartyByID(String partyID) async {
    QuerySnapshot snapshot = await _firestore.collection(PREF_NAME)
        .where('id', isEqualTo: partyID)
        .get();

    if (snapshot.docs.isNotEmpty) {
      // Get the first document from the query snapshot
      DocumentSnapshot documentSnapshot = snapshot.docs.first;

      // Convert the document snapshot into a Party object
      return Party.fromDocument(documentSnapshot);
    } else {
      // Return null if no documents were found
      return null;
    }
  }

  //Add function for getting party Name by ID
  Future<String?> getPartyNamebyId(String partyId)async{

    QuerySnapshot querySnapshot = await _firestore
        .collection(PREF_NAME)
        .where('id', isEqualTo: partyId)
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

  Future<void> deleteFromPendingReq(String partyId,String userId)async{
    try {
      // Reference to the Firestore collection (assuming you have a 'parties' collection)
      CollectionReference parties = FirebaseFirestore.instance.collection(PREF_NAME);

      // Fetch the party document by ID
      DocumentReference partyDoc = parties.doc(partyId);

      // Update the pendingRequests field (add the userId to the array)
      await partyDoc.update({
        'pendingRequests': FieldValue.arrayRemove([userId]),
      });

      print("Pending request remove successfully.");
    } catch (e) {
      print("Error removing pending requests: $e");
    }
  }

  Future<void> updatePendingRequests(String partyId, String userId) async {
    try {
      // Reference to the Firestore collection (assuming you have a 'parties' collection)
      CollectionReference parties = FirebaseFirestore.instance.collection(PREF_NAME);

      // Fetch the party document by ID
      DocumentReference partyDoc = parties.doc(partyId);

      // Update the pendingRequests field (add the userId to the array)
      await partyDoc.update({
        'pendingRequests': FieldValue.arrayUnion([userId]),
      });

      print("Pending request updated successfully.");
    } catch (e) {
      print("Error updating pending requests: $e");
    }
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


  //For Host
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
          tags: List.from(partyData.tags),
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

  /////////////////////////////// Pending Request //////////////////////////////////////

  //get Pending Request
  Future<List<Map<String, dynamic>>> getPendingRequests(String userId) async {
    try {
      final querySnapshot = await _firestore
          .collection(REQUEST_COLLECTION)
          .where('status', isEqualTo: "Pending")
          .where('userId',isEqualTo: userId)
          .get();

      return querySnapshot.docs.map((doc) {
        final data = doc.data();
        data['DocId'] = doc.id; // Add the document ID to the data
        return data;
      }).toList();
    } catch (e) {
      throw Exception('Error fetching pending requests: $e');
    }
  }

}
