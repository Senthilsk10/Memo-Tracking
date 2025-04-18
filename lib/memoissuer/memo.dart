import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:memo4/user_types.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import 'package:fluttertoast/fluttertoast.dart';
import '../User_authentication/profile.dart';
import 'memoHistory.dart';
import 'memo_update_delete.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

class MemoPage extends StatefulWidget {
  @override
  _MemoPageState createState() => _MemoPageState();
}

class _MemoPageState extends State<MemoPage> {
  // AppSheet-inspired color palette
  final Color primaryColor = Color(0xFF4285F4); // Google Blue
  final Color secondaryColor = Color(0xFF34A853); // Google Green
  final Color backgroundColor = Color(0xFFF1F3F4); // Light grey background

  String _institutionalId = "";
  String _userType = '';
  final _formKey = GlobalKey<FormState>();
  String _blockName = '';
  String _floorNo = '';
  String _wardNo = '';
  String _department = '';
  String _shift = '';
  String _complaints = '';
  String? _workerType;
  String _nurseName = '';
  String _nurseId = '';
  int _currentIndex = 0;

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

  final List<String> _workerTypes = UserTypes.workertype;

  void _submitMemo() async {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();

      try {
        int newMemoId = await FirebaseFirestore.instance
            .runTransaction((transaction) async {
          final counterDocRef =
              FirebaseFirestore.instance.collection('memo').doc('counter');
          final counterSnapshot = await transaction.get(counterDocRef);

          int currentCounter = 0;

          if (counterSnapshot.exists) {
            currentCounter = counterSnapshot.data()?['currentCounter'] ?? 0;
          }

          int newMemoId = currentCounter + 1;

          transaction.set(
            counterDocRef,
            {'currentCounter': newMemoId},
            SetOptions(merge: true),
          );

          final memoData = {
            'memoId': newMemoId,
            'blockName': _blockName,
            'floorNo': _floorNo,
            'wardNo': _wardNo,
            'department': _department,
            'shift': _shift,
            'complaints': _complaints,
            'workerType': _workerType,
            'nurseName': _nurseName,
            'nurseId': _nurseId,
            'timestamp': FieldValue.serverTimestamp(),
            'status': 'approved',
          };

          final newMemoDocRef =
              FirebaseFirestore.instance.collection('memo').doc();
          transaction.set(newMemoDocRef, memoData);

          return newMemoId;
        });

        // Check if worker type exists in mapping before sending notification
        if (_workerType != null) {
          String? userType = UserTypes.getUserTypeFromWorkerType(_workerType!);

          if (userType != null) {
            String? topic = UserTypes.getNotificationTopic(userType);

            if (topic != null) {
              print(
                  "Sending notification to topic: $topic for memo ID: $newMemoId");

              try {
                final response = await http.post(
                  Uri.parse(
                      'https://senthil1803.pythonanywhere.com/send_notification'),
                  headers: {'Content-Type': 'application/json'},
                  body: jsonEncode({
                    'topic': topic,
                    'title': 'New Memo Assigned',
                    'body':
                        'Memo ID $newMemoId has been created for $_workerType',
                  }),
                );

                print("Notification response status: ${response.statusCode}");
                print("Notification response body: ${response.body}");

                if (response.statusCode != 200) {
                  print(
                      "Warning: Notification might not have been sent properly");
                }
              } catch (notificationError) {
                print("Error sending notification: $notificationError");
              }
            } else {
              print(
                  "Warning: Topic could not be derived from userType: $userType");
            }
          } else {
            print(
                "Warning: Cannot derive userType from workerType: $_workerType");
          }
        }

        // Toast message for successful submission
        Fluttertoast.showToast(
          msg: 'Memo submitted successfully',
          toastLength: Toast.LENGTH_SHORT,
          gravity: ToastGravity.BOTTOM,
          backgroundColor: secondaryColor,
          textColor: Colors.white,
          fontSize: 16.0,
        );

        // Reset form after successful submission
        _formKey.currentState?.reset();
        setState(() {
          _workerType = null;
        });
      } catch (e) {
        // Toast message for error
        print("Error submitting memo: $e");
        Fluttertoast.showToast(
          msg: 'Error submitting memo: ${e.toString()}',
          toastLength: Toast.LENGTH_SHORT,
          gravity: ToastGravity.BOTTOM,
          backgroundColor: Colors.red,
          textColor: Colors.white,
          fontSize: 16.0,
        );
      }
    }
  }

  Widget _buildMemoForm() {
    return LayoutBuilder(
      builder: (context, constraints) {
        return Card(
          color: Colors.white,
          elevation: 4.0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Padding(
            padding: EdgeInsets.all(constraints.maxWidth > 600 ? 24.0 : 16.0),
            child: Form(
              key: _formKey,
              child: Column(
                children: [
                  _buildTextField(
                      'Block Name', (value) => _blockName = value ?? ''),
                  SizedBox(height: 10),
                  _buildTextField(
                      'Floor No', (value) => _floorNo = value ?? ''),
                  SizedBox(height: 10),
                  _buildTextField('Ward No', (value) => _wardNo = value ?? ''),
                  SizedBox(height: 10),
                  _buildTextField(
                      'Department', (value) => _department = value ?? ''),
                  SizedBox(height: 10),
                  _buildTextField('Shift', (value) => _shift = value ?? ''),
                  SizedBox(height: 10),
                  _buildMultilineTextField(
                      'Complaints', (value) => _complaints = value ?? ''),
                  SizedBox(height: 10),
                  _buildDropdownField(),
                  SizedBox(height: 10),
                  _buildTextField('Sent By (Nurse Name)',
                      (value) => _nurseName = value ?? ''),
                  SizedBox(height: 10),
                  _buildTextField(
                      'Nurse ID', (value) => _nurseId = value ?? ''),
                  SizedBox(height: 16.0),
                  _buildActionButtons(constraints),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildTextField(String label, Function(String?) onSaved) {
    return TextFormField(
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: primaryColor),
        filled: true,
        fillColor: backgroundColor,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: primaryColor, width: 2),
        ),
      ),
      onSaved: onSaved,
      validator: (value) =>
          value == null || value.isEmpty ? 'Enter $label' : null,
    );
  }

  Widget _buildMultilineTextField(String label, Function(String?) onSaved) {
    return TextFormField(
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: primaryColor),
        filled: true,
        fillColor: backgroundColor,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: primaryColor, width: 2),
        ),
      ),
      maxLines: 3,
      onSaved: onSaved,
      validator: (value) =>
          value == null || value.isEmpty ? 'Enter $label' : null,
    );
  }

  Widget _buildDropdownField() {
    return Theme(
        data: ThemeData(
          canvasColor: Colors
              .white, // Forces the dropdown menu background color to white
        ),
        child: DropdownButtonFormField<String>(
          decoration: InputDecoration(
            labelText: 'Worker Type',
            labelStyle: TextStyle(color: primaryColor),
            filled: true,
            fillColor: backgroundColor,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: backgroundColor, width: 2),
            ),
          ),
          hint: Text('Select Worker Type'),
          value: _workerType,
          onChanged: (value) {
            setState(() {
              _workerType = value;
            });
          },
          items: _workerTypes.map((type) {
            return DropdownMenuItem(
              value: type,
              child: Text(type),
            );
          }).toList(),
          validator: (value) => value == null ? 'Select Worker Type' : null,
        ));
  }

  Widget _buildActionButtons(BoxConstraints constraints) {
    return constraints.maxWidth > 600
        ? Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildElevatedButton('Submit Memo', _submitMemo),
              _buildElevatedButton('Clear Form', _clearForm),
            ],
          )
        : Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildElevatedButton('Submit Memo', _submitMemo),
              SizedBox(height: 10),
              _buildElevatedButton('Clear Form', _clearForm),
            ],
          );
  }

  Widget _buildElevatedButton(String label, VoidCallback onPressed) {
    return ElevatedButton(
      onPressed: onPressed,
      child: Text(label),
      style: ElevatedButton.styleFrom(
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        padding: EdgeInsets.symmetric(horizontal: 20, vertical: 15),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        elevation: 2,
      ),
    );
  }

  void _clearForm() {
    _formKey.currentState?.reset();
    setState(() {
      _workerType = null;
    });
  }

  Widget _buildRecentMemos() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('memo')
          .orderBy('timestamp', descending: true)
          .limit(5)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Text('Error: ${snapshot.error}');
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        }

        final memos = snapshot.data?.docs ?? [];

        if (memos.isEmpty) {
          return SizedBox();
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Recent Memos',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: primaryColor,
              ),
            ),
            SizedBox(height: 10),
            ...memos.map((doc) {
              final memo = doc.data() as Map<String, dynamic>;

              final timestamp = memo['timestamp'] as Timestamp?;
              String formattedDate = '';
              String formattedTime = '';
              if (timestamp != null) {
                final dateTime = timestamp.toDate();
                formattedDate =
                    '${dateTime.day}/${dateTime.month}/${dateTime.year}';
                formattedTime = DateFormat('hh:mm a').format(dateTime);
              }

              return Card(
                color: Colors.white,
                elevation: 3.0,
                margin: EdgeInsets.symmetric(vertical: 8.0),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                child: ListTile(
                  title: Text(
                    'Memo ID: ${memo['memoId']}',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: primaryColor,
                    ),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'To: ${memo['workerType']} - Status: ${memo['status']}',
                        style: TextStyle(color: secondaryColor),
                      ),
                      Text(
                        'From: Block ${memo['blockName']}, Floor ${memo['floorNo']}, Ward ${memo['wardNo']}',
                        style: TextStyle(color: Colors.grey[700]),
                      ),
                      Text(
                        'Department: ${memo['department']}',
                        style: TextStyle(color: Colors.grey[700]),
                      ),
                      Text(
                        'Shift: ${memo['shift']}',
                        style: TextStyle(color: Colors.grey[700]),
                      ),
                      Text(
                        'Complaints: ${memo['complaints']}',
                        style: TextStyle(color: Colors.grey[700]),
                      ),
                      Text(
                        'Sent by: ${memo['nurseName']} (ID: ${memo['nurseId']})',
                        style: TextStyle(color: Colors.grey[700]),
                      ),
                      Text(
                        'Date: $formattedDate, Time: $formattedTime',
                        style: TextStyle(color: Colors.grey[700]),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: primaryColor,
        title: Text(
          _currentIndex == 0
              ? 'Memo Submission'
              : _currentIndex == 1
                  ? 'Memo Tracking'
                  : 'Editing Section',
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.account_circle),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => ProfilePage()),
              );
            },
          ),
        ],
      ),
      body: _currentIndex == 0
          ? SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    _buildMemoForm(),
                    SizedBox(height: 20),
                    _buildRecentMemos(),
                  ],
                ),
              ),
            )
          : _currentIndex == 1
              ? HistoryPage()
              : MemoListScreen(),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        items: [
          BottomNavigationBarItem(
            icon: Icon(Icons.edit_note),
            label: 'Memo',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.track_changes),
            label: 'Memo Tracking',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.edit),
            label: 'Edit',
          ),
        ],
        selectedItemColor: primaryColor,
        unselectedItemColor: Colors.grey,
        backgroundColor: Colors.white,
      ),
    );
  }
}
