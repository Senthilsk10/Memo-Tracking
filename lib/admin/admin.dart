/*import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import 'package:open_file/open_file.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:io';
import 'profile.dart';

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

class Memo {
  final String id;
  final int ward;
  final String shift;
  final String department;
  final String complaint;
  final String status;
  final String issuedBy;
  final DateTime issuedDate;
  final List<String> approvedBy;
  final DateTime? approvedDate;
  final String? attendedBy;
  final DateTime? attendedDate;
  final String completionStatus;
  final DateTime? completionDate;
  final String? remarks;
  final String? reasonForPending;

  Memo({
    required this.id,
    required this.ward,
    required this.shift,
    required this.department,
    required this.complaint,
    required this.status,
    required this.issuedBy,
    required this.issuedDate,
    required this.approvedBy,
    this.approvedDate,
    this.attendedBy,
    this.attendedDate,
    required this.completionStatus,
    this.completionDate,
    this.remarks,
    this.reasonForPending,
  });
}

class AdminDashboardPage extends StatefulWidget {
  @override
  _AdminDashboardPageState createState() => _AdminDashboardPageState();
}

class _AdminDashboardPageState extends State<AdminDashboardPage> {
  int _selectedIndex = 0;
  final _formKey = GlobalKey<FormState>();
  final _institutionalIdController = TextEditingController();
  final _nameController = TextEditingController();
  final _mobileNumberController = TextEditingController();
  String _selectedUserType = 'Ward Staff Nurse';
  List<Memo> _memoList = [];
  Map<String, Map<String, int>> _departmentStats = {};
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  final List<String> userTypes = [
    'Ward Staff Nurse',
    'Approvers - Ward Incharge',
    'Approvers - Nursing Superintendent',
    'Approvers - RMO (Resident Medical Officer)',
    'Approvers - Medical Superintendent (MS)',
    'Approvers - Dean',
    'Responder - Carpenter',
    'Responder - Plumber',
    'Responder - Housekeeping Supervisor',
    'Responder - Biomedical Engineer',
    'Responder - Civil',
    'Admin'
  ];

  final List<String> departments = [
    'Carpentry',
    'Plumbing',
    'Electrical',
    'House Keeping',
    'Biomedical Engineer'
  ];

  @override
  void initState() {
    super.initState();
    _loadMockData();
    _initializeDepartmentStats();
  }

  Future<void> _registerUser(User user) async {
    try {
      // Reference to the registerUser collection
      CollectionReference users = _firestore.collection('registerUser');
      
      // Check if user with same institutional ID already exists
      QuerySnapshot existingUser = await users
          .where('institutionalId', isEqualTo: user.institutionalId)
          .get();
      
      if (existingUser.docs.isNotEmpty) {
        throw 'User with this Institutional ID already exists';
      }

      // Add user to Firestore
      await users.add(user.toMap());
      
      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('User added successfully'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      // Show error message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error adding user: $e'),
          backgroundColor: Colors.red,
        ),
      );
      rethrow;
    }
  }

  void _initializeDepartmentStats() {
    for (var department in departments) {
      _departmentStats[department] = {
        'Issued': 0,
        'Approved': 0,
        'Attended': 0,
        'Pending': 0,
      };
    }
    _updateDepartmentStats();
  }

  void _loadMockData() {
    _memoList = [
      Memo(
        id: '1',
        ward: 2,
        shift: 'morning',
        department: 'Plumbing',
        complaint: 'Water leakage in ward 3',
        status: 'Approved',
        issuedBy: 'Nurse John',
        issuedDate: DateTime.now().subtract(Duration(days: 2)),
        approvedBy: ['Ward Incharge', 'Nursing Superintendent','RMO','Medical Superintendent','Dean'],
        approvedDate: DateTime.now().subtract(Duration(days: 1)),
        attendedBy: 'Plumber Mike',
        attendedDate: DateTime.now(),
        completionStatus: 'Completed',
        completionDate: DateTime.now(),
        remarks: 'Fixed the pipe leak',
      ),
    ];
  }

  void _updateDepartmentStats() {
    for (var memo in _memoList) {
      if (_departmentStats.containsKey(memo.department)) {
        _departmentStats[memo.department]![memo.status] =
            (_departmentStats[memo.department]![memo.status] ?? 0) + 1;
      }
    }
  }

  void _showAddUserDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Add New User'),
          content: SingleChildScrollView(
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: _institutionalIdController,
                    decoration: InputDecoration(labelText: 'Institutional ID'),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter Institutional ID';
                      }
                      return null;
                    },
                  ),
                  TextFormField(
                    controller: _nameController,
                    decoration: InputDecoration(labelText: 'Name'),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter Name';
                      }
                      return null;
                    },
                  ),
                  TextFormField(
                    controller: _mobileNumberController,
                    decoration: InputDecoration(labelText: 'Mobile Number'),
                    keyboardType: TextInputType.phone,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter Mobile Number';
                      }
                      if (!RegExp(r'^\d{10}$').hasMatch(value)) {
                        return 'Please enter a valid 10-digit mobile number';
                      }
                      return null;
                    },
                  ),
                  DropdownButtonFormField<String>(
                    value: _selectedUserType,
                    decoration: InputDecoration(labelText: 'User Type'),
                    items: userTypes.map((String type) {
                      return DropdownMenuItem(
                        value: type,
                        child: Text(type),
                      );
                    }).toList(),
                    onChanged: (String? newValue) {
                      if (newValue != null) {
                        setState(() {
                          _selectedUserType = newValue;
                        });
                      }
                    },
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (_formKey.currentState!.validate()) {
                  // Create new user
                  final newUser = User(
                    institutionalId: _institutionalIdController.text,
                    name: _nameController.text,
                    mobileNumber: _mobileNumberController.text,
                    userType: _selectedUserType,
                  );
                  
                  try {
                    await _registerUser(newUser);
                    Navigator.pop(context);
                    _resetForm();
                  } catch (e) {
                    // Error is already handled in _registerUser
                  }
                }
              },
              child: Text('Add User'),
            ),
          ],
        );
      },
    );
  }

  void _resetForm() {
    _institutionalIdController.clear();
    _nameController.clear();
    _mobileNumberController.clear();
    setState(() {
      _selectedUserType = 'Ward Staff Nurse';
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Admin Dashboard'),
        actions: [
          IconButton(
            icon: Icon(Icons.person_add),
            onPressed: _showAddUserDialog,
            tooltip: 'Manage User',
          ),
          IconButton(
            icon: Icon(Icons.account_circle),
            onPressed: () {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => ProfilePage()),
              );
            }
          ),
        ],
      ),
      body: IndexedStack(
        index: _selectedIndex,
        children: [
          _buildDashboardView(),
          _buildMemoTrackingView(),
          _buildHistoryView(),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) => setState(() => _selectedIndex = index),
        items: [
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
      ),
    );
  }

  Widget _buildDashboardView() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(16.0),
      child: Column(
        children: departments
            .map((department) => _buildDepartmentCard(department))
            .toList(),
      ),
    );
  }

  Widget _buildDepartmentCard(String department) {
    final stats = _departmentStats[department]!;
    return Card(
      margin: EdgeInsets.only(bottom: 16.0),
      child: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  department,
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                TextButton(
                  onPressed: () => _navigateToMemoList(department),
                  child: Text('View Details'),
                ),
              ],
            ),
            SizedBox(height: 8),
            _buildStatsGrid(stats),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsGrid(Map<String, int> stats) {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      childAspectRatio: 1,
      children: stats.entries.map((entry) {
        return Card(
          color: _getStatusColor(entry.key),
          child: Padding(
            padding: EdgeInsets.all(4.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  entry.key,
                  style: TextStyle(color: Colors.white),
                ),
                Text(
                  '${entry.value}',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'Issued':
        return Colors.blue;
      case 'Approved':
        return Colors.green;
      case 'Attended':
        return Colors.orange;
      case 'Pending':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  void _navigateToMemoList(String department) {
    final departmentMemos = _memoList
        .where((memo) => memo.department == department)
        .toList();
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => MemoListPage(memos: departmentMemos),
      ),
    );
  }

  Widget _buildMemoTrackingView() {
    return ListView.builder(
      itemCount: _memoList.length,
      itemBuilder: (context, index) {
        final memo = _memoList[index];
        return Card(
          margin: EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: ListTile(
            title: Text('Memo #${memo.id}'),
            subtitle: Text(
              'Status: ${memo.status}\nDepartment: ${memo.department}',
            ),
            trailing: IconButton(
              icon: Icon(Icons.download),
              onPressed: () => _generateAndDownloadPDF(memo),
            ),
            onTap: () => _showMemoDetailsDialog(memo),
          ),
        );
      },
    );
  }

  Widget _buildHistoryView() {
    final completedMemos = _memoList
        .where((memo) => memo.completionStatus == 'Completed')
        .toList();
    return ListView.builder(
      itemCount: completedMemos.length,
      itemBuilder: (context, index) {
        final memo = completedMemos[index];
        return Card(
          margin: EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: ListTile(
            title: Text('Memo #${memo.id}'),
            subtitle: Text(
              'Completed on: ${DateFormat('dd/MM/yyyy').format(memo.completionDate!)}',
            ),
            trailing: IconButton(
              icon: Icon(Icons.download),
              onPressed: () => _generateAndDownloadPDF(memo),
            ),
            onTap: () => _showMemoDetailsDialog(memo),
          ),
        );
      },
    );
  }

  void _showMemoDetailsDialog(Memo memo) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Memo Details'),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildMemoDetailItem('Memo ID', memo.id),
                _buildMemoDetailItem('Department', memo.department),
                _buildMemoDetailItem('Status', memo.status),
                _buildMemoDetailItem('Ward', memo.ward.toString()),
                _buildMemoDetailItem('Shift', memo.shift),
                _buildMemoDetailItem('Complaint', memo.complaint),
                _buildMemoDetailItem('Issued By', memo.issuedBy),
                _buildMemoDetailItem('Issued Date',
                    DateFormat('dd/MM/yyyy').format(memo.issuedDate)),
                if (memo.approvedBy.isNotEmpty)
                  _buildMemoDetailItem('Approved By', memo.approvedBy.join(', ')),
                if (memo.approvedDate != null)
                  _buildMemoDetailItem('Approved Date',
                      DateFormat('dd/MM/yyyy').format(memo.approvedDate!)),
                
                if (memo.attendedDate != null)
                  _buildMemoDetailItem('Attended Date',
                      DateFormat('dd/MM/yyyy').format(memo.attendedDate!)),
                if (memo.completionStatus == 'Completed')
                  _buildMemoDetailItem('Completion Date',
                      DateFormat('dd/MM/yyyy').format(memo.completionDate!)),
                if (memo.remarks != null)
                  _buildMemoDetailItem('Remarks', memo.remarks!),
                if (memo.reasonForPending != null)
                  _buildMemoDetailItem('Reason for Pending', memo.reasonForPending!),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Close'),
            ),
            ElevatedButton(
              onPressed: () => _generateAndDownloadPDF(memo),
              child: Text('Download PDF'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildMemoDetailItem(String label, String value) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(
            child: Text(value),
          ),
        ],
      ),
    );
  }

  Future<void> _generateAndDownloadPDF(Memo memo) async {
    final pdf = pw.Document();
    
    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Header(
                level: 0,
                child: pw.Text('Memo Details',
                    style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold)),
              ),
              pw.SizedBox(height: 20),
              _buildPDFDetailRow('Memo ID', memo.id),
              _buildPDFDetailRow('Department', memo.department),
              _buildPDFDetailRow('Status', memo.status),
              _buildPDFDetailRow('Ward', memo.ward.toString()),
              _buildPDFDetailRow('Shift', memo.shift),
              _buildPDFDetailRow('Complaint', memo.complaint),
              _buildPDFDetailRow('Issued By', memo.issuedBy),
              _buildPDFDetailRow('Issued Date',
                  DateFormat('dd/MM/yyyy').format(memo.issuedDate)),
              if (memo.approvedBy.isNotEmpty)
                _buildPDFDetailRow('Approved By', memo.approvedBy.join(', ')),
              if (memo.approvedDate != null)
                _buildPDFDetailRow('Approved Date',
                    DateFormat('dd/MM/yyyy').format(memo.approvedDate!)),
              if (memo.attendedBy != null)
                _buildPDFDetailRow('Attended By', memo.attendedBy!),
              if (memo.attendedDate != null)
                _buildPDFDetailRow('Attended Date',
                    DateFormat('dd/MM/yyyy').format(memo.attendedDate!)),
              if (memo.completionStatus == 'Completed')
                _buildPDFDetailRow('Completion Date',
                    DateFormat('dd/MM/yyyy').format(memo.completionDate!)),
              if (memo.remarks != null)
                _buildPDFDetailRow('Remarks', memo.remarks!),
              if (memo.reasonForPending != null)
                _buildPDFDetailRow('Reason for Pending', memo.reasonForPending!),
            ],
          );
        },
      ),
    );

    try {
      final dir = await getApplicationDocumentsDirectory();
      final file = File('${dir.path}/memo_${memo.id}.pdf');
      await file.writeAsBytes(await pdf.save());
      await OpenFile.open(file.path);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error generating PDF: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  pw.Widget _buildPDFDetailRow(String label, String value) {
    return pw.Container(
      margin: pw.EdgeInsets.symmetric(vertical: 4),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Container(
            width: 120,
            child: pw.Text(
              '$label:',
              style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
            ),
          ),
          pw.Expanded(
            child: pw.Text(value),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _institutionalIdController.dispose();
    _nameController.dispose();
    _mobileNumberController.dispose();
    super.dispose();
  }
}

class MemoListPage extends StatelessWidget {
  final List<Memo> memos;

  MemoListPage({required this.memos});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Memo List'),
      ),
      body: memos.isEmpty
          ? Center(
              child: Text('No memos found'),
            )
          : ListView.builder(
              itemCount: memos.length,
              itemBuilder: (context, index) {
                final memo = memos[index];
                return Card(
                  margin: EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                  child: ListTile(
                    title: Text('Memo #${memo.id}'),
                    subtitle: Text(
                      'Status: ${memo.status}\nDepartment: ${memo.department}',
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: Icon(Icons.visibility),
                          onPressed: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => MemoDetailPage(memo: memo),
                            ),
                          ),
                        ),
                        IconButton(
                          icon: Icon(Icons.download),
                          onPressed: () => _generateAndDownloadPDF(context, memo),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }

  Future<void> _generateAndDownloadPDF(BuildContext context, Memo memo) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text('Memo ID: ${memo.id}',
                  style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
              pw.Text('Department: ${memo.department}'),
              pw.Text('Complaint: ${memo.complaint}'),
              pw.Text('Status: ${memo.status}'),
              pw.Text('Ward No: ${memo.ward}'),
              pw.Text('Shift: ${memo.shift}'),
              pw.Text('Issued By: ${memo.issuedBy}'),
              pw.Text('Issued Date: ${DateFormat('dd/MM/yyyy').format(memo.issuedDate)}'),
              if (memo.approvedBy.isNotEmpty)
                pw.Text('Approved By: ${memo.approvedBy.join(', ')}'),
              if (memo.approvedDate != null)
                pw.Text('Approved Date: ${DateFormat('dd/MM/yyyy').format(memo.approvedDate!)}'),
              if (memo.attendedBy != null)
                pw.Text('Attended By: ${memo.attendedBy}'),
              if (memo.attendedDate != null)
                pw.Text('Attended Date: ${DateFormat('dd/MM/yyyy').format(memo.attendedDate!)}'),
              if (memo.completionStatus == 'Completed')
                pw.Text('Completion Date: ${DateFormat('dd/MM/yyyy').format(memo.completionDate!)}'),
              if (memo.remarks != null)
                pw.Text('Remarks: ${memo.remarks}'),
            ],
          );
        },
      ),
    );

    try {
      final dir = await getApplicationDocumentsDirectory();
      final file = File('${dir.path}/memo_${memo.id}.pdf');
      await file.writeAsBytes(await pdf.save());
      await OpenFile.open(file.path);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error generating PDF: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}

class MemoDetailPage extends StatelessWidget {
  final Memo memo;

  MemoDetailPage({required this.memo});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Memo Details'),
        actions: [
          IconButton(
            icon: Icon(Icons.download),
            onPressed: () => _generateAndDownloadPDF(context),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildDetailCard(
              title: 'Basic Information',
              children: [
                _buildDetailItem('Memo ID', memo.id),
                _buildDetailItem('Department', memo.department),
                _buildDetailItem('Ward', memo.ward.toString()),
                _buildDetailItem('Shift', memo.shift),
              ],
            ),
            SizedBox(height: 16),
            _buildDetailCard(
              title: 'Complaint Details',
              children: [
                _buildDetailItem('Complaint', memo.complaint),
                _buildDetailItem('Status', memo.status),
                if (memo.reasonForPending != null)
                  _buildDetailItem('Reason for Pending', memo.reasonForPending!),
              ],
            ),
            SizedBox(height: 16),
            _buildDetailCard(
              title: 'Timeline',
              children: [
                _buildDetailItem('Issued By', memo.issuedBy),
                _buildDetailItem('Issued Date',
                    DateFormat('dd/MM/yyyy').format(memo.issuedDate)),
                if (memo.approvedBy.isNotEmpty)
                  _buildDetailItem('Approved By', memo.approvedBy.join(', ')),
                if (memo.approvedDate != null)
                  _buildDetailItem('Approved Date',
                      DateFormat('dd/MM/yyyy').format(memo.approvedDate!)),
                if (memo.attendedBy != null)
                  _buildDetailItem('Attended By', memo.attendedBy!),
                if (memo.attendedDate != null)
                  _buildDetailItem('Attended Date',
                      DateFormat('dd/MM/yyyy').format(memo.attendedDate!)),
                if (memo.completionStatus == 'Completed')
                  _buildDetailItem('Completion Date',
                      DateFormat('dd/MM/yyyy').format(memo.completionDate!)),
              ],
            ),
            if (memo.remarks != null) ...[
              SizedBox(height: 16),
              _buildDetailCard(
                title: 'Additional Information',
                children: [
                  _buildDetailItem('Remarks', memo.remarks!),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildDetailCard({
    required String title,
    required List<Widget> children,
  }) {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 8),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildDetailItem(String label, String value) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(
            child: Text(value),
          ),
        ],
      ),
    );
  }

  Future<void> _generateAndDownloadPDF(BuildContext context) async {
    // Reuse the PDF generation code from MemoListPage
    final pdf = pw.Document();

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text('Memo ID: ${memo.id}',
                  style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
              pw.Text('Department: ${memo.department}'),
              pw.Text('Complaint: ${memo.complaint}'),
              pw.Text('Status: ${memo.status}'),
              pw.Text('Ward No: ${memo.ward}'),
              pw.Text('Shift: ${memo.shift}'),
              pw.Text('Issued By: ${memo.issuedBy}'),
              pw.Text('Issued Date: ${DateFormat('dd/MM/yyyy').format(memo.issuedDate)}'),
              if (memo.approvedBy.isNotEmpty)
                pw.Text('Approved By: ${memo.approvedBy.join(', ')}'),
              if (memo.approvedDate != null)
                pw.Text('Approved Date: ${DateFormat('dd/MM/yyyy').format(memo.approvedDate!)}'),
              if (memo.attendedBy != null)
                pw.Text('Attended By: ${memo.attendedBy}'),
              if (memo.attendedDate != null)
                pw.Text('Attended Date: ${DateFormat('dd/MM/yyyy').format(memo.attendedDate!)}'),
              if (memo.completionStatus == 'Completed')
                pw.Text('Completion Date: ${DateFormat('dd/MM/yyyy').format(memo.completionDate!)}'),
              if (memo.remarks != null)
                pw.Text('Remarks: ${memo.remarks}'),
            ],
          );
        },
      ),
    );

    try {
      final dir = await getApplicationDocumentsDirectory();
      final file = File('${dir.path}/memo_${memo.id}.pdf');
      await file.writeAsBytes(await pdf.save());
      await OpenFile.open(file.path);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error generating PDF: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
} */
