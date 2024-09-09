import 'package:clique/models/createParty.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
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
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: const Text('Manage Join Requests'),
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _requestsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
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
                final userId = request['userName'] ?? 'Unknown User';
                final status = request['status'] ?? 'Unknown Status';
                final DocId = request['DocId']; // Ensure the ID is fetched correctly

                return Card(
                  margin: const EdgeInsets.all(8.0),
                  child: ListTile(
                    title: Text('Request from $userId'),
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
                          child: const Text('Approve'),
                        ),
                        TextButton(
                          onPressed: () {
                            if (DocId != null) {
                              _handleRequest(DocId, request['partyId'],request['userId'], 'rejected');
                            } else {
                              debugPrint('Request ID is null');
                            }
                          },
                          child: const Text('Reject'),
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
