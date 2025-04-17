import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'raw_data_tab.dart'; // Raw Data class
import 'visualization_tab.dart'; // Visualization class
import '../User_authentication/profile.dart'; // Profile page
import 'admin_memo_tracking.dart'; // Memo Tracking class
import 'adminhistory.dart'; // History class
import 'manageuser.dart';

// Models
class User {
  final String institutionalId;
  final String name;
  final String mobileNumber;
  final String userType;

  User({
    required this.institutionalId,
    required this.name,
    required this.mobileNumber,
    required this.userType,
  });

  // Convert user data to a Map for Firestore
  Map<String, dynamic> toMap() {
    return {
      'institutionalId': institutionalId,
      'name': name,
      'mobileNumber': mobileNumber,
      'userType': userType,
      'createdAt': FieldValue.serverTimestamp(),
    };
  }
}

class AdminDashboard extends StatefulWidget {
  @override
  _AdminDashboardState createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard>
    with SingleTickerProviderStateMixin {
  int _selectedIndex = 0;
  String _institutionalId = "";
  String _userType = '';
  final _formKey = GlobalKey<FormState>();
  final _institutionalIdController = TextEditingController();
  final _nameController = TextEditingController();
  final _mobileNumberController = TextEditingController();
  String _selectedUserType = 'Ward Staff Nurse';
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  late TabController _tabController;
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadUserData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadUserData() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _institutionalId = prefs.getString('institutionalId') ?? 'N/A';
      _userType = prefs.getString('userType') ?? 'N/A';
    });
  }

  // Method to handle Bottom Navigation Bar changes
  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text('Admin Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.person_add),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => ManageUserScreen()),
              );
            },
            tooltip: 'Manage User',
          ),
          IconButton(
            icon: const Icon(Icons.account_circle),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => ProfilePage()),
              );
            },
          ),
        ],
        bottom: _selectedIndex == 0
            ? TabBar(
                controller: _tabController,
                // indicatorColor: ,
                labelStyle: TextStyle(color: Colors.white),
                tabs: const [
                  Tab(text: 'Raw Data'),
                  Tab(text: 'Visualization'),
                ],
              )
            : null, // Display TabBar only for the Dashboard
      ),
      body: _selectedIndex == 0
          ? TabBarView(
              controller: _tabController,
              children: [
                RawDataTab(), // Raw Data tab content
                VisualizationTab(), // Visualization tab content
              ],
            )
          : _selectedIndex == 1
              ? MemoTracking() // Memo Tracking Page
              : History(), // History Page
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: Colors.white,
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard),
            label: 'Dashboard',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.track_changes),
            label: 'Memo Tracking',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.history),
            label: 'History',
          ),
        ],
        currentIndex: _selectedIndex,
        onTap: _onItemTapped, // Switch between tabs
      ),
    );
  }
}
