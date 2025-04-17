import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart'; // Import for date formatting

class HistoryPage extends StatelessWidget {
  final String institutionalId;
  final String userType;

  const HistoryPage({
    Key? key,
    required this.institutionalId,
    required this.userType,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Memo History'),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('memo')
            .where('status', isEqualTo: 'completed')
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text('No completed memos found.'));
          }

          final memos = snapshot.data!.docs;

          return ListView.builder(
            itemCount: memos.length,
            itemBuilder: (context, index) {
              final memo = memos[index];
              final memoData = memo.data() as Map<String, dynamic>;

              // Extract and filter workerStatuses
              final workStatuses =
                  memoData['workerStatuses'] as List<dynamic>? ?? [];
              final relevantStatuses = workStatuses.where((status) {
                if (status is Map<String, dynamic>) {
                  return status['institutionalId'] == institutionalId &&
                      status['status'] == 'attended' &&
                      status['workStatus'] == 'complete';
                }
                return false;
              }).toList();

              if (relevantStatuses.isEmpty) {
                return const SizedBox.shrink(); // Skip if no relevant statuses
              }

              return Card(
                margin: const EdgeInsets.all(8.0),
                child: ListTile(
                  title: Text('Memo ID: ${memoData['memoId'] ?? 'N/A'}'),
                  subtitle:
                      Text('Complaint: ${memoData['complaints'] ?? 'N/A'}'),
                  trailing: const Icon(Icons.arrow_forward),
                  onTap: () {
                    showDialog(
                      context: context,
                      builder: (BuildContext context) {
                        return MemoDetailDialog(
                          memoDetails: memoData,
                          workStatuses: relevantStatuses,
                        );
                      },
                    );
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class MemoDetailDialog extends StatelessWidget {
  final Map<String, dynamic> memoDetails;
  final List<dynamic> workStatuses;

  const MemoDetailDialog({
    Key? key,
    required this.memoDetails,
    required this.workStatuses,
  }) : super(key: key);

  String formatTimestamp(dynamic timestamp) {
    try {
      DateTime dateTime;
      if (timestamp is Timestamp) {
        dateTime = timestamp.toDate();
      } else if (timestamp is String) {
        dateTime = DateTime.parse(timestamp);
      } else {
        return 'Invalid timestamp';
      }
      return DateFormat('MMM d, yyyy h:mm a').format(dateTime);
    } catch (e) {
      return 'Invalid timestamp';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Theme(
        data: ThemeData(
          canvasColor: Colors
              .white, // Forces the dropdown menu background color to white
        ),
        child: Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16.0),
          ),
          elevation: 8.0,
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Text(
                      'Memo Details',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        // color: Colors.teal,
                      ),
                    ),
                  ),
                  const Divider(),
                  Text(
                    'Memo ID: ${memoDetails['memoId'] ?? 'N/A'}',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Text('Block: ${memoDetails['blockName'] ?? 'N/A'}'),
                  Text('Floor No: ${memoDetails['floorNo'] ?? 'N/A'}'),
                  Text('Ward No: ${memoDetails['wardNo'] ?? 'N/A'}'),
                  Text('Complaint: ${memoDetails['complaints'] ?? 'N/A'}'),
                  Text('Shift: ${memoDetails['shift'] ?? 'N/A'}'),
                  Text(
                    'Timestamp: ${formatTimestamp(memoDetails['timestamp'])}',
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Work Status History',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      // color: Colors.teal,
                    ),
                  ),
                  const Divider(),
                  if (workStatuses.isEmpty)
                    const Text(
                      'No work statuses found.',
                      style: TextStyle(color: Colors.red),
                    ),
                  if (workStatuses.isNotEmpty)
                    Column(
                      children: workStatuses.map((status) {
                        return Card(
                          margin: const EdgeInsets.symmetric(vertical: 8.0),
                          elevation: 4.0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12.0),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(12.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Status: ${status['status'] ?? 'N/A'}',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.blue,
                                  ),
                                ),
                                Text(
                                  'Work Status: ${status['workStatus'] ?? 'N/A'}',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Color.fromARGB(255, 26, 2, 112),
                                  ),
                                ),
                                Text('Tag User: ${status['tagUser'] ?? 'N/A'}'),
                                Text(
                                    'Remarks: ${status['remarks'] ?? 'No remarks'}'),
                                Text(
                                  'Timestamp: ${formatTimestamp(status['timestamp'])}',
                                  style: const TextStyle(
                                      color: Color.fromARGB(255, 22, 16, 16)),
                                ),
                              ],
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  const SizedBox(height: 16),
                  Align(
                    alignment: Alignment.centerRight,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Color(0xfff6f7f8),
                        foregroundColor: Colors.blue,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8.0),
                        ),
                      ),
                      onPressed: () {
                        Navigator.of(context).pop();
                      },
                      child: const Text('Close'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ));
  }
}

// Function to show the dialog with animation
void showAnimatedDialog(BuildContext context, Map<String, dynamic> memoDetails,
    List<dynamic> workStatuses) {
  showGeneralDialog(
    context: context,
    barrierDismissible: true,
    barrierLabel: '',
    pageBuilder: (context, animation1, animation2) => Container(),
    transitionBuilder: (context, animation1, animation2, child) {
      final curvedAnimation = CurvedAnimation(
        parent: animation1,
        curve: Curves.easeInOut,
      );
      return ScaleTransition(
        scale: curvedAnimation,
        child: MemoDetailDialog(
          memoDetails: memoDetails,
          workStatuses: workStatuses,
        ),
      );
    },
    transitionDuration: const Duration(milliseconds: 300),
  );
}
