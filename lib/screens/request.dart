import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';
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
                final DocId = request['DocId']; // Ensure the ID is fetched correctly

                return Card(
                  color: Colors.grey[200],
                  margin: const EdgeInsets.fromLTRB(
                      17.0, 8.0, 17.0, 8.0),
                  child: ListTile(
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
}
