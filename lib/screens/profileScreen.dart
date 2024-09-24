import 'package:clique/screens/PendingRequest.dart';
import 'package:clique/utility/CommonUtility.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io'; // for File
import 'package:loading_animation_widget/loading_animation_widget.dart';
import 'package:path/path.dart';
import '../services/UserService.dart';
import '../services/AuthService.dart';
import 'package:clique/screens/MyPartiesScreen.dart';
import 'package:clique/screens/request.dart';
import 'package:clique/screens/joinedParties.dart';
import '../main.dart';
import 'EditProfileScreen.dart';
import 'package:path/path.dart' as path;

class ProfileScreen extends StatefulWidget {
  @override
  _ProfileScreen createState() => _ProfileScreen();
}

class _ProfileScreen extends State<ProfileScreen> {
  UserService userService = UserService();
  final commonUtility = CommonUtility();
  late Future<List<String?>> _userInfoFuture;
  final _storage = FirebaseStorage.instance;

  // File variable to store the selected image
  File? _image;
  final ImagePicker _picker = ImagePicker();
  String profilePicUrl = "";

  @override
  void initState() {
    super.initState();
    _userInfoFuture = _fetchUserInfo();
    _fetchProfileImage();
  }

  // Refresh User info on ProfileScreen
  void _refreshUserInfo() {
    setState(() {
      _userInfoFuture = _fetchUserInfo(); // This will trigger a rebuild
    });
  }

  // Fetching UserInfo
  Future<List<String?>> _fetchUserInfo() {
    return Future.wait([
      userService.getUserNamee(),
      userService.getUserId(),
    ]);
  }

  // Function to pick image from gallery
  Future<void> _pickImage(String uid) async {
    final pickedFile = await _picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      setState(() {
        if (pickedFile != null) {
          _image = File(pickedFile.path);
          uploadFile(uid);
        } else {
          print('No image selected.');
        }
      });
    }
  }

  Future uploadFile(String uid) async {
    if (_image == null) return;

    final fileName = basename(_image!.path);
    var destination = uid;

    try {
      final ref = FirebaseStorage.instance
          .ref('$destination/ProfilePic')
          .child("profilePhoto.jpg");
      await ref.putFile(_image!);

      String url = await ref.getDownloadURL();
      print("Uploaded $url");
    } catch (e) {
      String error = "$e";
      print(error);
    }
  }

  //Fetch Profile Pic
  Future<void> _fetchProfileImage() async {
    try {
      // Get the image URL from Firestore or use a default location if needed
      String userId = FirebaseAuth.instance.currentUser?.uid ?? '';

      final ref = FirebaseStorage.instance
          .ref('$userId/ProfilePic')
          .child("profilePhoto.jpg");

      // Fetch the user's profile picture from storage
      String url = await ref.getDownloadURL();
      print("Fetched URL: $url");
      setState(() {
        profilePicUrl = url;
      });
    } catch (e) {
      print('Error fetching profile image: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xffffffff),
      body: FutureBuilder<List<String?>>(
        future: _userInfoFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(
              child: LoadingAnimationWidget.fallingDot(
                color: const Color(0xff2226BA),
                size: 50,
              ),
            );
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else if (snapshot.hasData && snapshot.data != null) {
            final data = snapshot.data!;
            var userName = data[0];
            var userId = data[1];
            return Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                SizedBox(height: 60),
                GestureDetector(
                  onTap: () {
                    _pickImage(userId!); // Pass userId or appropriate parameter
                  },
                  child: CircleAvatar(
                    radius: 70,
                    backgroundColor: Colors.grey[300],
                    child: ClipOval(
                      child: profilePicUrl != null
                          ? Image.network(
                              profilePicUrl!,
                              fit: BoxFit.cover,
                              width: 130,
                              height: 130,
                              // Show a placeholder while the image is loading
                              loadingBuilder: (BuildContext context,
                                  Widget child,
                                  ImageChunkEvent? loadingProgress) {
                                if (loadingProgress == null) {
                                  return child; // Image has loaded successfully
                                }
                                return Center(
                                  child: LoadingAnimationWidget.fallingDot(
                                    color: const Color(0xff2226BA),
                                    size: 50,
                                  ),
                                ); // Show a loader while image is loading
                              },
                              // Show an error widget if there is a loading error
                              errorBuilder: (BuildContext context, Object error,
                                  StackTrace? stackTrace) {
                                return Icon(Icons.person,size: 60,);
                              },
                            )
                          : LoadingAnimationWidget.fallingDot(
                              color: const Color(0xff2226BA),
                              size: 50,
                            ), // Default placeholder
                    ),
                  ),
                ),
                SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      userName ?? 'No username found',
                      style:
                          TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                    SizedBox(width: 10),
                    GestureDetector(
                      onTap: () async {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) => EditProfileScreen()),
                        ).then((isUpdated) {
                          if (isUpdated == true) {
                            _refreshUserInfo();
                          }
                        });
                      },
                      child: const Icon(
                        Icons.edit,
                        size: 20,
                        color: Colors.blue,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 30),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20.0),
                  child: Column(
                    children: [
                      ListTile(
                        leading: Icon(Icons.event, color: Colors.blue),
                        title: Text('My Parties'),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) => MyPartiesScreen()),
                          );
                        },
                        trailing: Icon(Icons.arrow_forward_ios),
                      ),
                      Divider(),
                      ListTile(
                        leading: Icon(Icons.upcoming_sharp, color: Colors.blue),
                        title: const Text('Upcoming Parties'),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) => JoinedPartiesScreen()),
                          );
                        },
                        trailing: Icon(Icons.arrow_forward_ios),
                      ),
                      Divider(),
                      ListTile(
                        leading: Icon(Icons.watch_later_outlined,
                            color: Colors.blue),
                        title: const Text('Pending Requests'),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  PendingRequestsScreen(userId: userId ?? ""),
                            ),
                          );
                        },
                        trailing: Icon(Icons.arrow_forward_ios),
                      ),
                      Divider(),
                      ListTile(
                        leading: Icon(Icons.request_page, color: Colors.blue),
                        title: const Text('Request'),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => ManageJoinRequestsScreen(
                                  hostId: userId ?? ""),
                            ),
                          );
                        },
                        trailing: Icon(Icons.arrow_forward_ios),
                      ),
                      Divider(),
                      ListTile(
                        leading: Icon(Icons.logout, color: Colors.red),
                        title: Text('Logout'),
                        onTap: () async {
                          bool? confirmation = await _showConfirmationDialog(
                              context, "Log Out?", "Are you sure?");
                          if (confirmation == true) {

                            await AuthService().signOut();
                            await AuthService().signOutGoogle();
                            Navigator.pushAndRemoveUntil(
                              context,
                              MaterialPageRoute(
                                  builder: (context) =>
                                      AuthenticationWrapper()),
                              (Route<dynamic> route) => false,
                            );
                          }
                        },
                        trailing: Icon(Icons.arrow_forward_ios),
                      ),
                      Divider(),
                    ],
                  ),
                ),
              ],
            );
          } else {
            return Center(child: Text('No data found'));
          }
        },
      ),
    );
  }

  Future<bool?> _showConfirmationDialog(
      BuildContext context, String title, String content) async {
    return showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Colors.white,
          title: Text(title, style: TextStyle(fontWeight: FontWeight.bold)),
          content: Text(content),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text(
                'Cancel',
                style: TextStyle(color: Color(0xff4C46EB)),
              ),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xff4C46EB)),
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text(
                'Confirm',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        );
      },
    );
  }

}
