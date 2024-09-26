import 'package:clique/models/joinRequestModel.dart';
import 'package:clique/screens/publicUserProfile.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';
import '../models/createParty.dart';
import '../services/party_service.dart';

class ManageJoinRequestsScreen extends StatefulWidget {
  final String hostId;

  const ManageJoinRequestsScreen({super.key, required this.hostId});

  @override
  _ManageJoinRequestsScreenState createState() => _ManageJoinRequestsScreenState();
}

class _ManageJoinRequestsScreenState extends State<ManageJoinRequestsScreen> {
  late Future<List<Map<String, dynamic>>> _requestsFuture;
  PartyService partyService = PartyService();

  @override
  void initState() {
    super.initState();
    debugPrint("HostId in ManageJoinRequestsScreen: ${widget.hostId}");
    _requestsFuture = partyService.getJoinRequests(widget.hostId);
  }

  Future<void> _handleRequest(String requestId, String partyId, String userId, String action) async {
    debugPrint("In Handle request for $action id: $requestId");
    await partyService.updateJoinRequest(requestId, partyId, action);

    if (action == 'approved') {
      await partyService.addUserToParty(partyId, userId);
      await partyService.deleteFromPendingReq(partyId,userId);
      partyService.deleteRequest(requestId);
    }else if(action == 'rejected'){
      debugPrint("Rejected: $requestId");
      partyService.deleteRequest(requestId);
    }

    setState(() {
      _requestsFuture = partyService.getJoinRequests(widget.hostId); // Refresh the join requests list
    });
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xffffffff),
      appBar: AppBar(
        surfaceTintColor: Colors.white,
        backgroundColor: const Color(0xffffffff),
        title: const Text('Manage Join Requests',style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _requestsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return  Center(child: LoadingAnimationWidget.fallingDot(color: const Color(0xff2226BA), size: 50));
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('No join requests'));
          } else {
            final requests = snapshot.data!;

            return ListView.builder(
              itemCount: requests.length,
              itemBuilder: (context, index) {
                final request = requests[index];
                final userName = request['userName'] ?? 'Unknown User';
                final status = request['status'] ?? 'Unknown Status';
                final DocId = request['DocId'];
                final message = request['message'];
                final partyID = request['partyId'];
                final requestID = request['requestId'];
                final userId = request['userId'];

                return Card(
                  color: Colors.grey[200],
                  margin: const EdgeInsets.fromLTRB(
                      17.0, 8.0, 17.0, 8.0),
                  child: ListTile(
                    onTap: (){
                      fetchAndShowParty(userId, requestID, partyID, status, message);
                    },
                    title: Text('Request from $userName',style: TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text('Status: $status'),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        TextButton(
                          onPressed: () {
                            if (DocId != null) {
                              _handleRequest(DocId, request['partyId'],request['userId'],'approved');
                            } else {
                              debugPrint('Request ID is null');
                            }
                          },
                          child: const Text('Approve',style: TextStyle(color: Color(0xff2226BA),fontWeight: FontWeight.bold),),
                        ),
                        TextButton(
                          onPressed: () {
                            if (DocId != null) {
                              _handleRequest(DocId, request['partyId'],request['userId'], 'rejected');
                            } else {
                              debugPrint('Request ID is null');
                            }
                          },
                          child: const Text('Reject',style: TextStyle(color: Colors.red)),
                        ),
                      ],
                    ),
                  ),
                );
              },
            );

          }
        },
      ),
    );
  }
  Future<void> fetchAndShowParty(String userId,String requestID,String partyID, String status,String message) async {
    try {
      // Await the result of the asynchronous method
      Party? party = await partyService.getPartyByID(partyID);
      JoinRequest? joinRequest = await partyService.getRequestById(requestID);
      DateTime parsedDateTime = DateTime.parse(party!.dateTime);
      showBottomSheetForParty(userId,requestID,joinRequest!,party, status, parsedDateTime,message);
    } catch (e) {
      // Handle any errors that occur during the fetch
      print('Error fetching party: $e');
    }
  }
  void showBottomSheetForParty(String userId, String requestId, JoinRequest request,Party party, String status, DateTime parsedDateTime,String message) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      builder: (BuildContext context) {
        return Padding(
          padding: const EdgeInsets.all(16.0),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Center(
                  child: Text(
                    party.name,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 30,
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                _buildDetailRowWithButton('Attendee Name: ', request),
                _buildDetailRow('Date:', DateFormat('yyyy-MM-dd').format(parsedDateTime)),
                _buildDetailRow('Time:', DateFormat('hh:mm a').format(parsedDateTime)),
                _buildDetailRow('Location: ', party.location),
                _buildDetailRow('Description: ', party.description),
                _buildDetailRow("Other Attendees: ", party.attendees.join(", ")),
                _buildDetailRow('Tags: ', party.tags.join(", ")),
                _buildDetailRow('Status:', status),
                _buildDetailRow('Attendee message:', message ?? 'No Message'),
                const SizedBox(height: 50),
                Row(
                  children: [
                    const SizedBox(width: 50,),
                    ElevatedButton(
                      onPressed: () {
                        // deleteRequest(requestId, party.id, userId);
                        _handleRequest(request.requestId, request.partyId,request.userId,'rejected');
                        Navigator.pop(context, true);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red[400],
                        padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 35),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8.0),
                        ),
                      ),
                      child: const Text(
                        'Reject',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(width: 50,),
                    ElevatedButton(
                      onPressed: () {
                        _handleRequest(request.requestId, request.partyId,request.userId,'approved');
                        Navigator.pop(context, true);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xff2226BA),
                        padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 35),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8.0),
                        ),
                      ),
                      child: const Text(
                        'Approve',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20,)
              ],
            ),
          ),
        );
      },
    );
  }
  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Text(
              label,
              style: TextStyle(fontWeight: FontWeight.bold,fontSize: 17),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                  fontSize: 17,
                  color: value == 'Pending' ? Colors.orange : Colors.black,
                  fontWeight:
                  value == 'Pending' ? FontWeight.bold : FontWeight.normal),
            ),
          ),
        ],
      ),
    );
  }
  Widget _buildDetailRowWithButton(String label, JoinRequest request) {
    print("Request: ${request.userName}");
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center, // Aligns widgets vertically in the center
        children: [
          SizedBox(
            width: 100, // Fixed width to ensure alignment
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.bold,fontSize: 17),
              overflow: TextOverflow.ellipsis, // Handles text overflow
            ),
          ),
          Expanded(
            child: TextButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => publicUserProfile(
                      userId: request.userId,
                    ),
                  ),
                );
              },
              style: TextButton.styleFrom(
                padding: EdgeInsets.zero, // Remove extra padding
              ),
              child: Text(
                request.userName,
                style: const TextStyle(
                  fontSize: 17,
                  color: Colors.blue, // Adjust as needed
                  fontWeight: FontWeight.normal,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
