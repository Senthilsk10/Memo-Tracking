import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../User_authentication/login.dart';
import 'package:memo4/user_types.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

Future<void> unsubscribeFromWorkerTypeTopic() async {
  final prefs = await SharedPreferences.getInstance();
  final userType = prefs.getString('userType');
  if (userType != null) {
    final topic = UserTypes.userTypeMapping[userType];
    if (topic != null) {
      await FirebaseMessaging.instance.unsubscribeFromTopic(topic);
    }
  }
  // Clear session
  await prefs.clear();
}

class ProfilePage extends StatefulWidget {
  @override
  _ProfilePageState createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  // Define Google AppSheet colors
  final Color primaryColor = Color(0xFF4285F4); // Google Blue
  final Color secondaryColor = Color(0xFF34A853); // Google Green
  final Color backgroundColor = Colors.white; // Changed to white

  File? _profileImage;
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _loadProfileImage();
  }

  Future<void> _loadProfileImage() async {
    final prefs = await SharedPreferences.getInstance();
    final imagePath = prefs.getString('profileImagePath');
    if (imagePath != null) {
      setState(() {
        _profileImage = File(imagePath);
      });
    }
  }

  Future<void> _takePhoto() async {
    final pickedFile = await _picker.pickImage(
      source: ImageSource.camera,
      maxWidth: 600,
      maxHeight: 600,
      imageQuality: 80,
    );

    if (pickedFile != null) {
      final File image = File(pickedFile.path);
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('profileImagePath', image.path);

      setState(() {
        _profileImage = image;
      });
    }
  }

  Future<void> _uploadPhoto() async {
    final pickedFile = await _picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 600,
      maxHeight: 600,
      imageQuality: 80,
    );

    if (pickedFile != null) {
      final File image = File(pickedFile.path);
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('profileImagePath', image.path);

      setState(() {
        _profileImage = image;
      });
    }
  }

  Future<Map<String, String>> _getUserData() async {
    final prefs = await SharedPreferences.getInstance();
    final institutionalId = prefs.getString('institutionalId') ?? 'N/A';

    return {
      'institutionalId': institutionalId,
      'userType': prefs.getString('userType') ?? 'N/A',
    };
  }

  void _showLogoutDialog(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Logout', style: TextStyle(color: primaryColor)),
          content: Text('Do you want to logout?'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context); // Close the dialog
              },
              child: Text('No', style: TextStyle(color: primaryColor)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryColor,
                foregroundColor: Colors.white,
              ),
              onPressed: () async {
                unsubscribeFromWorkerTypeTopic();
                await prefs.clear();
                Fluttertoast.showToast(
                  msg: "Logged out successfully!",
                  backgroundColor: primaryColor,
                  textColor: Colors.white,
                );
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (context) => LoginPage()),
                  (route) => false,
                );
              },
              child: Text('Yes'),
            ),
          ],
        );
      },
    );
  }

  void _showPhotoOptionsDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Choose Photo Option',
              style: TextStyle(color: primaryColor)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: Icon(Icons.camera_alt, color: primaryColor),
                title: Text('Take Photo'),
                onTap: () {
                  Navigator.pop(context);
                  _takePhoto();
                },
              ),
              ListTile(
                leading: Icon(Icons.photo_library, color: primaryColor),
                title: Text('Upload from Gallery'),
                onTap: () {
                  Navigator.pop(context);
                  _uploadPhoto();
                },
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        title: Text('Profile'),
        backgroundColor: primaryColor,
        actions: [
          IconButton(
            icon: Icon(Icons.logout),
            onPressed: () => _showLogoutDialog(context),
          ),
        ],
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          return FutureBuilder<Map<String, String>>(
            future: _getUserData(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return Center(
                    child: CircularProgressIndicator(color: primaryColor));
              }
              final userData = snapshot.data!;
              return Center(
                child: SingleChildScrollView(
                  child: Container(
                    width: constraints.maxWidth > 600
                        ? 600
                        : constraints.maxWidth * 0.9,
                    child: Card(
                      margin: EdgeInsets.symmetric(
                          vertical: 16.0, horizontal: 16.0),
                      elevation: 4,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            GestureDetector(
                              onTap: _showPhotoOptionsDialog,
                              child: Stack(
                                children: [
                                  CircleAvatar(
                                    radius: 60,
                                    backgroundColor: primaryColor,
                                    backgroundImage: _profileImage != null
                                        ? FileImage(_profileImage!)
                                        : null,
                                    child: _profileImage == null
                                        ? Icon(Icons.person,
                                            size: 60, color: Colors.white)
                                        : null,
                                  ),
                                  Positioned(
                                    bottom: 0,
                                    right: 0,
                                    child: Container(
                                      decoration: BoxDecoration(
                                        color: Colors.black,
                                        shape: BoxShape.circle,
                                      ),
                                      child: Icon(
                                        Icons.camera_alt,
                                        color: Colors.white,
                                        size: 24,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            SizedBox(height: 16),
                            Wrap(
                              alignment: WrapAlignment.center,
                              spacing: 10.0,
                              runSpacing: 10.0,
                              children: [
                                Chip(
                                  avatar: Icon(Icons.perm_identity,
                                      color: primaryColor),
                                  label: Text(
                                    'Institutional ID: ${userData['institutionalId']}',
                                    style: TextStyle(
                                        fontSize: 14, color: Colors.black87),
                                  ),
                                  backgroundColor: Colors.grey.shade100,
                                ),
                                Chip(
                                  avatar: Icon(Icons.account_circle,
                                      color: secondaryColor),
                                  label: Text(
                                    'User Type: ${userData['userType']}',
                                    style: TextStyle(
                                        fontSize: 14, color: Colors.black87),
                                  ),
                                  backgroundColor: Colors.grey.shade100,
                                ),
                              ],
                            ),
                            SizedBox(height: 24),
                            ElevatedButton.icon(
                              onPressed: () => _showLogoutDialog(context),
                              icon: Icon(Icons.logout),
                              label: Text('Logout'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: primaryColor,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
