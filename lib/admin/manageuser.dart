import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:memo4/user_types.dart';

class ManageUserScreen extends StatefulWidget {
  @override
  _ManageUserScreenState createState() => _ManageUserScreenState();
}

class _ManageUserScreenState extends State<ManageUserScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  Set<String> expandedUsers = {};
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    // Add debug print to check if we're initializing correctly
    print('ManageUserScreen initialized');
  }

  // Read ALL users with no filters
  Stream<QuerySnapshot> _getUsers() {
    print('Getting users stream'); // Debug log
    // Remove any ordering or filtering to ensure we get ALL records
    return _firestore.collection('registerUser').snapshots();
  }

  // Add user method
  Future<void> _addUser(String institutionalId, String name,
      String mobileNumber, String userType) async {
    try {
      CollectionReference users = _firestore.collection('registerUser');
      print('Adding new user: $name, $institutionalId'); // Debug log

      // Create a new user
      var newUser = {
        'institutionalId': institutionalId,
        'name': name,
        'mobileNumber': mobileNumber,
        'userType': userType,
        'createdAt': FieldValue.serverTimestamp(),
      };

      await users.add(newUser);
      print('User added successfully'); // Debug log

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('User added successfully'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      print('Error adding user: $e'); // Debug log
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error adding user: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // Delete user method
  Future<void> _deleteUser(String docId) async {
    try {
      print('Deleting user with ID: $docId'); // Debug log
      await _firestore.collection('registerUser').doc(docId).delete();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('User deleted successfully'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      print('Error deleting user: $e'); // Debug log
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error deleting user: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // Update user method
  Future<void> _updateUser(
      String docId, String name, String mobileNumber, String userType) async {
    try {
      print('Updating user with ID: $docId'); // Debug log
      await _firestore.collection('registerUser').doc(docId).update({
        'name': name,
        'mobileNumber': mobileNumber,
        'userType': userType,
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('User updated successfully'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      print('Error updating user: $e'); // Debug log
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error updating user: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // Show Add User Dialog
  void _showAddUserDialog() {
    final _institutionalIdController = TextEditingController();
    final _nameController = TextEditingController();
    final _mobileNumberController = TextEditingController();
    String _selectedUserType =
        UserTypes.usertype.isNotEmpty ? UserTypes.usertype.first : '';

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Theme(
          data: ThemeData(
            canvasColor: Colors.white,
          ),
          child: AlertDialog(
            title: Text('Add New User'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: _institutionalIdController,
                    decoration: InputDecoration(
                      labelText: 'Institutional ID*',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  SizedBox(height: 10),
                  TextField(
                    controller: _nameController,
                    decoration: InputDecoration(
                      labelText: 'Name*',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  SizedBox(height: 10),
                  TextField(
                    controller: _mobileNumberController,
                    decoration: InputDecoration(
                      labelText: 'Mobile Number*',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.phone,
                  ),
                  SizedBox(height: 10),
                  Container(
                    width: double.infinity,
                    child: DropdownButtonFormField<String>(
                      decoration: InputDecoration(
                        labelText: 'User Type',
                        border: OutlineInputBorder(),
                      ),
                      value: _selectedUserType,
                      onChanged: (String? newValue) {
                        if (newValue != null) {
                          _selectedUserType = newValue;
                        }
                      },
                      items: UserTypes.usertype
                          .map<DropdownMenuItem<String>>((String value) {
                        return DropdownMenuItem<String>(
                          value: value,
                          child: Text(value),
                        );
                      }).toList(),
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () {
                  _addUser(
                    _institutionalIdController.text.trim(),
                    _nameController.text.trim(),
                    _mobileNumberController.text.trim(),
                    _selectedUserType,
                  );
                  Navigator.pop(context);
                },
                child: Text('Add User'),
              ),
            ],
          ),
        );
      },
    );
  }

  // Show Update User Dialog
  void _showUpdateDialog(
      String docId, String name, String mobileNumber, String userType) {
    final _nameController = TextEditingController(text: name);
    final _mobileNumberController = TextEditingController(text: mobileNumber);
    String _selectedUserType = userType;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Theme(
            data: ThemeData(
              canvasColor: Colors.white,
            ),
            child: AlertDialog(
              title: Text('Update User'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: _nameController,
                      decoration: InputDecoration(labelText: 'Name'),
                    ),
                    TextField(
                      controller: _mobileNumberController,
                      decoration: InputDecoration(labelText: 'Mobile Number'),
                      keyboardType: TextInputType.phone,
                    ),
                    DropdownButton<String>(
                      value: _selectedUserType,
                      isExpanded: true,
                      onChanged: (String? newValue) {
                        if (newValue != null) {
                          _selectedUserType = newValue;
                        }
                      },
                      items: UserTypes.usertype
                          .map<DropdownMenuItem<String>>((String value) {
                        return DropdownMenuItem<String>(
                          value: value,
                          child: Text(value),
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () {
                    _updateUser(
                      docId,
                      _nameController.text,
                      _mobileNumberController.text,
                      _selectedUserType,
                    );
                    Navigator.pop(context);
                  },
                  child: Text('Update User'),
                ),
              ],
            ));
      },
    );
  }

  // Show Delete Confirmation Dialog
  void _showDeleteConfirmationDialog(String docId) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Theme(
            data: ThemeData(
              canvasColor: Colors.white,
            ),
            child: AlertDialog(
              title: Text('Delete User'),
              content: Text('Do you want to delete this user?'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () {
                    _deleteUser(docId);
                    Navigator.pop(context);
                  },
                  child: Text('Delete'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                  ),
                ),
              ],
            ));
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Manage Users'),
        actions: [
          // Add a refresh button
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: () {
              setState(() {
                // Force refresh
                print('Manual refresh requested');
              });
            },
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _getUsers(),
        builder: (context, snapshot) {
          // Print debug information about the connection state
          print('StreamBuilder state: ${snapshot.connectionState}');

          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            print('StreamBuilder error: ${snapshot.error}');
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, color: Colors.red, size: 48),
                  SizedBox(height: 16),
                  Text(
                    'Error loading users',
                    style: TextStyle(fontSize: 18),
                  ),
                  SizedBox(height: 8),
                  Text(
                    '${snapshot.error}',
                    style: TextStyle(color: Colors.red),
                  ),
                  SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      setState(() {
                        // Force refresh
                      });
                    },
                    child: Text('Retry'),
                  ),
                ],
              ),
            );
          }

          if (!snapshot.hasData) {
            print('StreamBuilder: No data available');
            return Center(child: Text('No data available'));
          }

          var users = snapshot.data!.docs;
          print('Users found: ${users.length}');

          if (users.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.people_outline, color: Colors.grey, size: 48),
                  SizedBox(height: 16),
                  Text(
                    'No users found',
                    style: TextStyle(fontSize: 18),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Add your first user with the + button',
                    style: TextStyle(color: Colors.grey),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            itemCount: users.length,
            itemBuilder: (context, index) {
              // Get document ID and data
              var userDoc = users[index];
              String docId = userDoc.id;

              // Print debug information for each document
              print('Processing user $index, ID: $docId');

              // Safely extract data with a try-catch to handle any data format issues
              Map<String, dynamic> userData;
              try {
                userData = userDoc.data() as Map<String, dynamic>;
                print('User data retrieved successfully for $docId');
              } catch (e) {
                print('Error processing user data for $docId: $e');
                // Return a fallback card for corrupted data
                return Card(
                  margin: EdgeInsets.all(8),
                  color: Colors.red.shade50,
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Data Error - ID: $docId',
                            style: TextStyle(fontWeight: FontWeight.bold)),
                        Text('Error: Unable to process user data'),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            IconButton(
                              onPressed: () =>
                                  _showDeleteConfirmationDialog(docId),
                              icon: Icon(Icons.delete, color: Colors.red),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              }

              // Get if this specific user is expanded
              bool isExpanded = expandedUsers.contains(docId);

              // Safely get user properties with fallbacks for missing fields
              String name = userData['name'] ?? 'No Name';
              String institutionalId = userData['institutionalId'] ?? 'No ID';
              String userType = userData['userType'] ?? 'Unknown';
              String mobileNumber = userData['mobileNumber'] ?? 'No Number';

              // Use a ?? operator for all optional fields
              var isRegistered = userData['isRegistered'] ?? false;

              // Handle timestamps carefully
              String createdAtStr = 'N/A';
              if (userData.containsKey('createdAt') &&
                  userData['createdAt'] != null) {
                try {
                  Timestamp createdAtTimestamp =
                      userData['createdAt'] as Timestamp;
                  createdAtStr = createdAtTimestamp.toDate().toString();
                } catch (e) {
                  print('Error formatting createdAt: $e');
                }
              }

              String registrationTimestampStr = 'N/A';
              if (userData.containsKey('registrationTimestamp') &&
                  userData['registrationTimestamp'] != null) {
                try {
                  Timestamp regTimestamp =
                      userData['registrationTimestamp'] as Timestamp;
                  registrationTimestampStr = regTimestamp.toDate().toString();
                } catch (e) {
                  print('Error formatting registrationTimestamp: $e');
                }
              }

              return Card(
                margin: EdgeInsets.all(8),
                elevation: 3,
                child: InkWell(
                  onTap: () {
                    setState(() {
                      // Toggle expansion state for this specific user
                      if (isExpanded) {
                        expandedUsers.remove(docId);
                      } else {
                        expandedUsers.add(docId);
                      }
                    });
                  },
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    name,
                                    style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold),
                                  ),
                                  SizedBox(height: 4),
                                  Text('ID: $institutionalId'),
                                  Text('Type: $userType'),
                                ],
                              ),
                            ),
                            Row(
                              children: [
                                IconButton(
                                  onPressed: () => _showUpdateDialog(
                                      docId, name, mobileNumber, userType),
                                  icon: Icon(Icons.edit, color: Colors.green),
                                ),
                                IconButton(
                                  onPressed: () =>
                                      _showDeleteConfirmationDialog(docId),
                                  icon: Icon(Icons.delete, color: Colors.red),
                                ),
                              ],
                            ),
                          ],
                        ),
                        if (isExpanded) ...[
                          Divider(),
                          SizedBox(height: 8),
                          Text('Mobile: $mobileNumber'),
                          Text('Created At: $createdAtStr'),
                          Text('Is Registered: ${isRegistered ? 'Yes' : 'No'}'),
                          Text('Registration Date: $registrationTimestampStr'),
                        ],
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddUserDialog,
        child: Icon(Icons.add),
        tooltip: 'Add New User',
      ),
    );
  }
}
