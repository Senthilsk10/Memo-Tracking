import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

// Memo Model

class Memo {
  final String blockName;
  final String complaints;
  final String department;
  final String floorNo;
  final int memoId;
  final String nurseId;
  final String nurseName;
  final String shift;
  final String status;
  final String timestamp; // Timestamp should be String here
  final String wardNo;
  final String workerType;

  Memo({
    required this.blockName,
    required this.complaints,
    required this.department,
    required this.floorNo,
    required this.memoId,
    required this.nurseId,
    required this.nurseName,
    required this.shift,
    required this.status,
    required this.timestamp,
    required this.wardNo,
    required this.workerType,
  });

  factory Memo.fromFirestore(DocumentSnapshot doc) {
    Map data = doc.data() as Map<String, dynamic>;

    // Convert Timestamp to String
    String timestamp = '';
    if (data['timestamp'] is Timestamp) {
      timestamp = (data['timestamp'] as Timestamp).toDate().toString();
    }

    return Memo(
      blockName: data['blockName'] ?? '',
      complaints: data['complaints'] ?? '',
      department: data['department'] ?? '',
      floorNo: data['floorNo'] ?? '',
      memoId: data['memoId'] ?? 0,
      nurseId: data['nurseId'] ?? '',
      nurseName: data['nurseName'] ?? '',
      shift: data['shift'] ?? '',
      status: data['status'] ?? '',
      timestamp: timestamp,
      wardNo: data['wardNo'] ?? '',
      workerType: data['workerType'] ?? '',
    );
  }
}

// Memo List Screen
class MemoListScreen extends StatelessWidget {
  const MemoListScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('memo')
          .where('status', isEqualTo: 'pending')
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Center(child: Text('No pending memos'));
        }

        return ListView.builder(
          itemCount: snapshot.data!.docs.length,
          itemBuilder: (context, index) {
            Memo memo = Memo.fromFirestore(snapshot.data!.docs[index]);
            return _buildMemoCard(
                context, memo, snapshot.data!.docs[index].reference);
          },
        );
      },
    );
  }

  Widget _buildMemoCard(
      BuildContext context, Memo memo, DocumentReference docRef) {
    return Card(
      margin: EdgeInsets.all(8),
      child: ListTile(
        title: Text('Memo ID: ${memo.memoId}'),
        subtitle: Text('Worker Type: ${memo.workerType}'),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: Icon(Icons.edit, color: Colors.blue),
              onPressed: () {
                _showEditMemoDialog(context, memo, docRef);
              },
            ),
            IconButton(
              icon: Icon(Icons.delete, color: Colors.red),
              onPressed: () {
                _deleteMemo(docRef);
              },
            ),
          ],
        ),
        onTap: () {
          _showMemoDetailsDialog(context, memo);
        },
      ),
    );
  }

  void _showMemoDetailsDialog(BuildContext context, Memo memo) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Theme(
            data: ThemeData(
              canvasColor: Colors
                  .white, // Forces the dropdown menu background color to white
            ),
            child: AlertDialog(
              title: Text('Memo Details'),
              content: SingleChildScrollView(
                child: ListBody(
                  children: <Widget>[
                    _buildDetailRow('Block Name', memo.blockName),
                    _buildDetailRow('Complaints', memo.complaints),
                    _buildDetailRow('Department', memo.department),
                    _buildDetailRow('Floor No', memo.floorNo),
                    _buildDetailRow('Nurse ID', memo.nurseId),
                    _buildDetailRow('Nurse Name', memo.nurseName),
                    _buildDetailRow('Shift', memo.shift),
                    _buildDetailRow('Ward No', memo.wardNo),
                    _buildDetailRow('Worker Type', memo.workerType),
                    _buildDetailRow('Timestamp', memo.timestamp),
                  ],
                ),
              ),
              actions: <Widget>[
                TextButton(
                  child: Text('Close'),
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                ),
              ],
            ));
      },
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$label: ',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }

  void _showEditMemoDialog(
      BuildContext context, Memo memo, DocumentReference docRef) {
    // Create controllers for each editable field
    final blockNameController = TextEditingController(text: memo.blockName);
    final complaintsController = TextEditingController(text: memo.complaints);
    final departmentController = TextEditingController(text: memo.department);
    final floorNoController = TextEditingController(text: memo.floorNo);
    final nurseIdController = TextEditingController(text: memo.nurseId);
    final nurseNameController = TextEditingController(text: memo.nurseName);
    final shiftController = TextEditingController(text: memo.shift);
    final wardNoController = TextEditingController(text: memo.wardNo);
    final workerTypeController = TextEditingController(text: memo.workerType);

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Theme(
            data: ThemeData(
              canvasColor: Colors
                  .white, // Forces the dropdown menu background color to white
            ),
            child: AlertDialog(
              title: Text('Edit Memo'),
              content: SingleChildScrollView(
                child: Column(
                  children: [
                    _buildEditTextField('Block Name', blockNameController),
                    _buildEditTextField('Complaints', complaintsController),
                    _buildEditTextField('Department', departmentController),
                    _buildEditTextField('Floor No', floorNoController),
                    _buildEditTextField('Nurse ID', nurseIdController),
                    _buildEditTextField('Nurse Name', nurseNameController),
                    _buildEditTextField('Shift', shiftController),
                    _buildEditTextField('Ward No', wardNoController),
                    _buildEditTextField('Worker Type', workerTypeController),
                  ],
                ),
              ),
              actions: <Widget>[
                TextButton(
                  child: Text('Cancel'),
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                ),
                TextButton(
                  child: Text('Save'),
                  onPressed: () {
                    // Update Firestore document
                    docRef.update({
                      'blockName': blockNameController.text,
                      'complaints': complaintsController.text,
                      'department': departmentController.text,
                      'floorNo': floorNoController.text,
                      'nurseId': nurseIdController.text,
                      'nurseName': nurseNameController.text,
                      'shift': shiftController.text,
                      'wardNo': wardNoController.text,
                      'workerType': workerTypeController.text,
                      // Note: status and timestamp remain unchanged
                    });
                    Navigator.of(context).pop();
                  },
                ),
              ],
            ));
      },
    );
  }

  Widget _buildEditTextField(String label, TextEditingController controller) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: TextField(
        controller: controller,
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(),
        ),
      ),
    );
  }

  void _deleteMemo(DocumentReference docRef) {
    // Implement delete confirmation dialog
    docRef.delete().then(
      (value) {
        // Optional: Show a snackbar or toast to confirm deletion
        print('Memo deleted successfully');
      },
      onError: (error) {
        // Handle any errors during deletion
        print('Error deleting memo: $error');
      },
    );
  }
}
