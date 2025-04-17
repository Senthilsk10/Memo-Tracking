import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:memo4/user_types.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'assigned_memos_tab.dart';
import 'tagged_memos_tab.dart';
import '../User_authentication/profile.dart';
import 'responderHistory.dart'; // Import the HistoryPage

class ResponderPage extends StatefulWidget {
  final String institutionalId;
  final String userType;

  const ResponderPage({
    Key? key,
    required this.userType,
    required this.institutionalId,
  }) : super(key: key);

  @override
  _ResponderPageState createState() => _ResponderPageState();
}

class _ResponderPageState extends State<ResponderPage> {
  // Google-inspired color palette
  final Color primaryColor = Color(0xFF4285F4); // Google Blue
  final Color secondaryColor = Color(0xFF34A853); // Google Green
  final Color backgroundColor = Color(0xFFF1F3F4); // Light grey background
  final Color textColor = Colors.black87;

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  String _institutionalId = "";
  String _userType = '';
  int _selectedIndex = 0;

  List<String> _responderTypes = UserTypes.responders;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _institutionalId = prefs.getString('institutionalId') ?? 'N/A';
      _userType = prefs.getString('userType') ?? 'N/A';
    });
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });

    // Navigate to HistoryPage when "Tracking" is selected
    if (index == 1) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => HistoryPage(
            institutionalId: _institutionalId,
            userType: _userType,
          ),
        ),
      );
    }
  }

  // Show toast message instead of SnackBar
  void _showToast(String message) {
    Fluttertoast.showToast(
      msg: message,
      toastLength: Toast.LENGTH_SHORT,
      gravity: ToastGravity.BOTTOM,
      backgroundColor: primaryColor,
      textColor: Colors.white,
      fontSize: 16.0,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      body: Column(
        children: [
          Expanded(
            child: DefaultTabController(
              length: 2,
              child: Scaffold(
                appBar: AppBar(
                  title: Text(
                    'Responder Memos',
                    style: TextStyle(color: Colors.white),
                  ),
                  automaticallyImplyLeading: false,
                  backgroundColor: primaryColor,
                  actions: [
                    IconButton(
                      icon: Icon(Icons.account_circle, color: Colors.white),
                      onPressed: () async {
                        final prefs = await SharedPreferences.getInstance();
                        final institutionalId =
                            prefs.getString('institutionalId');
                        final userType = prefs.getString('userType');

                        if (institutionalId != null && userType != null) {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => ProfilePage(),
                            ),
                          );
                        } else {
                          // Replace SnackBar with Toast
                          _showToast('User data not found!');
                        }
                      },
                    ),
                  ],
                  bottom: TabBar(
                    indicatorColor: Colors.white,
                    tabs: [
                      Tab(text: 'Assigned Memos'),
                      Tab(text: 'Tagged Memos'),
                    ],
                    labelColor: Colors.white,
                    unselectedLabelColor: Colors.white70,
                  ),
                ),
                body: TabBarView(
                  children: [
                    AssignedMemoTab(
                      userType: _userType,
                      institutionalId: _institutionalId,
                      firestore: _firestore,
                      responderTypes: _responderTypes,
                    ),
                    TaggedMemoTab(
                      userType: _userType,
                      institutionalId: _institutionalId,
                      firestore: _firestore,
                      responderTypes: _responderTypes,
                    ),
                  ],
                ),
              ),
            ),
          ),
          BottomNavigationBar(
            currentIndex: _selectedIndex,
            onTap: _onItemTapped,
            backgroundColor: backgroundColor,
            selectedItemColor: primaryColor,
            unselectedItemColor: Colors.grey,
            items: [
              BottomNavigationBarItem(
                icon: Icon(Icons.assignment),
                label: 'Responder',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.track_changes),
                label: 'Tracking',
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// Helper methods remain the same as in the previous implementation
extension ResponderPageHelpers on _ResponderPageState {
  Future<void> saveMemoUpdate({
    required String memoId,
    required Map<String, dynamic> updates,
  }) async {
    try {
      await _firestore.collection('memo').doc(memoId).update(updates);
    } catch (e) {
      print('Error updating memo: $e');
    }
  }

  bool canAccessMemo(Map<String, dynamic> memoData) {
    if (memoData['workerType'] == widget.userType.split(' - ').last) {
      return true;
    }
    if (memoData['tagUser'] == widget.userType) {
      return true;
    }
    return false;
  }

  String formatDateTime(DateTime dateTime) {
    return '${dateTime.year}-${dateTime.month.toString().padLeft(2, '0')}-${dateTime.day.toString().padLeft(2, '0')} '
        '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }

  Map<String, dynamic> createStatusUpdate({
    required String status,
    required String workStatus,
    required String tagUser,
    required String remarks,
  }) {
    return {
      'status': status,
      'workStatus': workStatus,
      'tagUser': tagUser,
      'remarks': remarks,
      'timestamp': DateTime.now().toIso8601String(),
      'institutionalId': _institutionalId,
      'userType': _userType,
    };
  }

  Future<void> updateUserPreferences({
    required String key,
    required String value,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(key, value);
  }

  void showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Error'),
          content: Text(message),
          actions: [
            TextButton(
              style: ElevatedButton.styleFrom(
                foregroundColor: Colors.blue, // Set the text color to blue
              ),
              onPressed: () => Navigator.of(context).pop(),
              child: Text('OK'),
            ),
          ],
        );
      },
    );
  }

  void showSuccessDialog(String message) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Success'),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('OK'),
            ),
          ],
        );
      },
    );
  }
}
