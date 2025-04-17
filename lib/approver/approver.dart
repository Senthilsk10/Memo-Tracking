import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../User_authentication/profile.dart';
import 'approverHistory.dart';
import 'package:another_flushbar/flushbar.dart';
import 'package:memo4/user_types.dart';

class ApproverPage extends StatefulWidget {
  final String userRole;
  ApproverPage({required this.userRole});

  @override
  _ApproverPageState createState() => _ApproverPageState();
}

class _ApproverPageState extends State<ApproverPage> {
  // Define Google-inspired color palette
  final Color primaryColor = Color(0xFF4285F4); // Google Blue
  final Color secondaryColor = Color(0xFF34A853); // Google Green
  final Color backgroundColor = Color(0xFFF1F3F4); // Light grey background

  List<Map<String, dynamic>> _memos = [];
  int _selectedIndex = 0;
  static const List<String> _approvalHierarchy = UserTypes.approvers;
  String _institutionalId = "";
  String _userType = '';
  int? _selectedMemoIndex;
  bool _showDetails = false;

  // Required approvers for a memo to be considered approved
  static const List<String> _requiredApprovers = [
    "Approvers - Ward Incharge",
    "Approvers - Nursing Superintendent",
    "Approvers - RMO (Resident Medical Officer)"
  ];

  @override
  void initState() {
    super.initState();
    _loadUserData();
    _fetchMemos();
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
  }

  bool _canApprove(Map<String, dynamic> memo) {
    // Skip if memoId is null
    if (memo['memoId'] == null) return false;

    final currentRoleIndex = _approvalHierarchy.indexOf(widget.userRole);
    if (currentRoleIndex == -1) return false;

    // Get the last approved role's index
    int lastApprovedIndex = -1;
    for (var approval in memo['approvedBy']) {
      int approvalIndex = _approvalHierarchy.indexOf(approval['userType']);
      if (approvalIndex > lastApprovedIndex) {
        lastApprovedIndex = approvalIndex;
      }
    }

    // Current role can approve if they're next in hierarchy
    return currentRoleIndex == lastApprovedIndex + 1;
  }

  void _fetchMemos() async {
    FirebaseFirestore.instance
        .collection('memo')
        .snapshots()
        .listen((snapshot) {
      setState(() {
        _memos = snapshot.docs
            .map((doc) {
              final data = doc.data() as Map<String, dynamic>;
              final approvedBy = (data['approvedBy'] ?? []).map((entry) {
                return {
                  'institutionalId': entry['institutionalId'],
                  'userType': entry['userType'].toString(),
                  'timestamp': entry['timestamp'],
                };
              }).toList();

              return {
                'id': doc.id,
                ...data,
                'approvedBy': approvedBy,
              };
            })
            .where((memo) =>
                memo['memoId'] != null &&
                !memo['approvedBy']
                    .any((e) => e['userType'] == widget.userRole) &&
                _canApprove(memo))
            .toList()
          // Sort memos by timestamp in ascending order
          ..sort((a, b) {
            // Use the first approval timestamp or creation timestamp
            DateTime getEarliestTimestamp(Map<String, dynamic> memo) {
              if (memo['approvedBy'] != null && memo['approvedBy'].isNotEmpty) {
                return DateTime.parse(memo['approvedBy'].first['timestamp']);
              }
              return DateTime.parse(
                  memo['createdAt'] ?? DateTime.now().toIso8601String());
            }

            return getEarliestTimestamp(a).compareTo(getEarliestTimestamp(b));
          });
      });
    });
  }

  void _showToast(String message) {
    Flushbar(
      message: message,
      duration: Duration(milliseconds: 1000),
      backgroundColor: secondaryColor, // Use Google Blue
      messageColor: Colors.white,
      flushbarPosition: FlushbarPosition.TOP,
    )..show(context);
  }

  // Check if all required approvers have approved
  bool _checkRequiredApprovals(Map<String, dynamic> approvers) {
    for (String requiredApprover in _requiredApprovers) {
      if (approvers[requiredApprover] != true) {
        return false;
      }
    }
    return true;
  }

  void _approveMemo(int index) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      String institutionalId = prefs.getString('institutionalId') ?? '';

      var memo = _memos[index];

      // Initialize or fetch the `approvers` map
      Map<String, dynamic> updatedApprovers =
          Map<String, dynamic>.from(memo['approvers'] ??
              {
                "Approvers - Ward Incharge": false,
                "Approvers - Nursing Superintendent": false,
                "Approvers - RMO (Resident Medical Officer)": false,
                "Approvers - Medical Superintendent (MS)": false,
                "Approvers - Dean": false
              });

      // Update the specific role to true
      updatedApprovers[widget.userRole] = true;

      // Add entry to `approvedBy`
      memo['approvedBy'].add({
        'institutionalId': institutionalId,
        'userType': widget.userRole,
        'timestamp': DateTime.now().toIso8601String(),
      });

      // Check if all REQUIRED roles have approved (Ward Incharge, Nursing Superintendent, RMO)
      bool requiredApprovalsComplete =
          _checkRequiredApprovals(updatedApprovers);

      // Update Firestore with both `approvedBy` and `approvers`
      await FirebaseFirestore.instance
          .collection('memo')
          .doc(memo['id'])
          .update({
        'approvedBy': memo['approvedBy'],
        'approvers': updatedApprovers, // Ensure `approvers` is saved
        'status': requiredApprovalsComplete ? 'approved' : 'pending',
      });

      // Notify user of success
      _showToast('Memo approved successfully');
    } catch (e) {
      print('Error approving memo: $e');
      _showToast('Failed to approve memo. Please try again.');
    }
  }

  void _toggleDetails(int index) {
    setState(() {
      _selectedMemoIndex = index;
      _showDetails = !_showDetails || _selectedMemoIndex != index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: primaryColor, // Google Blue
        title: Text('${widget.userRole} Approval'),
        actions: [
          IconButton(
            icon: Icon(Icons.account_circle),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => ProfilePage(),
              ),
            ),
          ),
        ],
      ),
      body: Container(
        color: backgroundColor, // Light grey background
        child: _selectedIndex == 0
            ? _buildApprovalBody()
            : HistoryPage(userRole: widget.userRole),
      ),
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: Colors.white,
        selectedItemColor: primaryColor,
        unselectedItemColor: Colors.grey,
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.approval),
            label: 'Approvals',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.track_changes),
            label: 'Memo Tracking',
          ),
        ],
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
      ),
    );
  }

  Widget _buildApprovalBody() {
    return _memos.isEmpty
        ? Center(child: Text('No pending memos for approval'))
        : ListView.builder(
            itemCount: _memos.length,
            itemBuilder: (context, index) {
              final memo = _memos[index];
              return Card(
                margin: EdgeInsets.all(8.0),
                elevation: 5.0,
                child: Column(
                  children: [
                    ListTile(
                      title: Text('Memo ID: ${memo['memoId']}'),
                      subtitle: Text('Status: ${_getApprovalStatus(memo)}'),
                      trailing: IconButton(
                        icon: Icon(_selectedMemoIndex == index && _showDetails
                            ? Icons.expand_less
                            : Icons.expand_more),
                        onPressed: () => _toggleDetails(index),
                      ),
                    ),
                    if (_selectedMemoIndex == index && _showDetails)
                      Padding(
                        padding: const EdgeInsets.all(12.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Floor No: ${memo['floorNo']}'),
                            Text('Ward No: ${memo['wardNo']}'),
                            Text('Department: ${memo['department']}'),
                            Text('Complaint: ${memo['complaints']}'),
                            SizedBox(height: 16),
                            Table(
                              border: TableBorder.all(),
                              columnWidths: const {
                                0: FlexColumnWidth(2),
                                1: FlexColumnWidth(1),
                                2: FlexColumnWidth(2),
                              },
                              children: [
                                TableRow(
                                  decoration: BoxDecoration(
                                    color: Colors.grey[200],
                                  ),
                                  children: [
                                    Padding(
                                      padding: EdgeInsets.all(8),
                                      child: Text('Approver',
                                          style: TextStyle(
                                              fontWeight: FontWeight.bold)),
                                    ),
                                    Padding(
                                      padding: EdgeInsets.all(8),
                                      child: Text('Status',
                                          style: TextStyle(
                                              fontWeight: FontWeight.bold)),
                                    ),
                                    Padding(
                                      padding: EdgeInsets.all(8),
                                      child: Text('Timestamp',
                                          style: TextStyle(
                                              fontWeight: FontWeight.bold)),
                                    ),
                                  ],
                                ),
                                ..._approvalHierarchy.map((approver) {
                                  var approval = memo['approvedBy'].firstWhere(
                                      (e) => e['userType'] == approver,
                                      orElse: () => null);
                                  bool isApproved = approval != null;
                                  bool canApprove =
                                      approver == widget.userRole &&
                                          _canApprove(memo);

                                  return TableRow(
                                    children: [
                                      Padding(
                                        padding: EdgeInsets.all(8),
                                        child: Text(approver),
                                      ),
                                      Padding(
                                        padding: EdgeInsets.all(8),
                                        child: canApprove
                                            ? Switch(
                                                value: isApproved,
                                                activeColor: Colors.green,
                                                activeTrackColor: Colors.green
                                                    .withOpacity(0.5),
                                                inactiveThumbColor:
                                                    Colors.white,
                                                inactiveTrackColor:
                                                    Colors.red.withOpacity(0.5),
                                                onChanged: (value) {
                                                  if (value == true)
                                                    _approveMemo(index);
                                                },
                                              )
                                            : isApproved
                                                ? Icon(
                                                    Icons.check_circle,
                                                    color: Colors.green,
                                                    size: 20,
                                                  )
                                                : Icon(
                                                    Icons
                                                        .hourglass_bottom_outlined,
                                                    color: Colors.orange),
                                      ),
                                      Padding(
                                        padding: EdgeInsets.all(8),
                                        child: Text(isApproved
                                            ? _formatTimestamp(
                                                approval['timestamp'])
                                            : '-'),
                                      ),
                                    ],
                                  );
                                }).toList(),
                              ],
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              );
            },
          );
  }

  String _getApprovalStatus(Map<String, dynamic> memo) {
    int approvedCount = memo['approvedBy'].length;
    return '$approvedCount/${_approvalHierarchy.length} Approvals';
  }

  String _formatTimestamp(String timestamp) {
    final dateTime = DateTime.parse(timestamp);
    return '${dateTime.day}/${dateTime.month}/${dateTime.year} ${dateTime.hour}:${dateTime.minute}';
  }
}
