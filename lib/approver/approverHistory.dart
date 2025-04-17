import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:memo4/user_types.dart';

class HistoryPage extends StatelessWidget {
  final String userRole;
  final List<String> _approvalHierarchy = UserTypes.approvers;

  HistoryPage({required this.userRole});

  String _formatTimestamp(String? timestamp) {
    if (timestamp == null) return '-';
    final dateTime = DateTime.parse(timestamp);
    return '${dateTime.day}/${dateTime.month}/${dateTime.year} ${dateTime.hour}:${dateTime.minute}';
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('memo')
          .where('memoId', isNotEqualTo: '')
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError)
          return Center(child: Text('Error loading memos'));
        if (snapshot.connectionState == ConnectionState.waiting)
          return Center(child: CircularProgressIndicator());

        final memos = snapshot.data?.docs ?? [];
        if (memos.isEmpty) return Center(child: Text('No memos found'));

        return ListView.builder(
          itemCount: memos.length,
          itemBuilder: (context, index) {
            final memo = memos[index].data() as Map<String, dynamic>;
            final approvedBy = (memo['approvedBy'] ?? []) as List;

            return Card(
              margin: EdgeInsets.all(8.0),
              elevation: 5,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
              ),
              child: ListTile(
                contentPadding:
                    EdgeInsets.symmetric(vertical: 12.0, horizontal: 16.0),
                title: Text('Memo ID: ${memo['memoId']}',
                    style: TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Ward No: ${memo['wardNo']}'),
                    Text('Status: ${memo['status'] ?? 'Pending'}'),
                  ],
                ),
                onTap: () {
                  showDialog(
                      context: context,
                      builder: (context) => Theme(
                            data: ThemeData(
                              canvasColor: Colors
                                  .white, // Forces the dropdown menu background color to white
                            ),
                            child: Dialog(
                              child: SingleChildScrollView(
                                child: Container(
                                  padding: EdgeInsets.all(16),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text('Memo Details',
                                          style: TextStyle(
                                              fontSize: 20,
                                              fontWeight: FontWeight.bold,
                                              color: Colors.blue)),
                                      const SizedBox(height: 16),
                                      Text('Memo ID: ${memo['memoId']}'),
                                      Text('Floor No: ${memo['floorNo']}'),
                                      Text('Ward No: ${memo['wardNo']}'),
                                      Text('Department: ${memo['department']}'),
                                      Text('Complaint: ${memo['complaints']}'),
                                      SizedBox(height: 16),
                                      Text('Approval Status:',
                                          style: TextStyle(
                                              fontWeight: FontWeight.bold)),
                                      SizedBox(height: 8),

                                      // Wrapping the Table in SingleChildScrollView for horizontal scrolling
                                      SingleChildScrollView(
                                        scrollDirection: Axis.horizontal,
                                        child: DataTable(
                                          columns: [
                                            DataColumn(
                                                label: Text('Approver Role',
                                                    style: TextStyle(
                                                        fontWeight:
                                                            FontWeight.bold))),
                                            DataColumn(
                                                label: Text('Status',
                                                    style: TextStyle(
                                                        fontWeight:
                                                            FontWeight.bold))),
                                            DataColumn(
                                                label: Text('Timestamp',
                                                    style: TextStyle(
                                                        fontWeight:
                                                            FontWeight.bold))),
                                          ],
                                          rows: _approvalHierarchy.map((role) {
                                            final approval =
                                                approvedBy.firstWhere(
                                                    (e) =>
                                                        e['userType'] == role,
                                                    orElse: () => null);
                                            final isApproved = approval != null;

                                            return DataRow(cells: [
                                              DataCell(Text(role)),
                                              DataCell(
                                                Row(
                                                  children: [
                                                    if (isApproved)
                                                      Icon(Icons.check_circle,
                                                          color: Colors.green,
                                                          size: 20)
                                                    else
                                                      Icon(
                                                          Icons
                                                              .hourglass_bottom,
                                                          color: Colors.orange),
                                                  ],
                                                ),
                                              ),
                                              DataCell(Text(
                                                isApproved
                                                    ? _formatTimestamp(
                                                        approval['timestamp'])
                                                    : '-',
                                              )),
                                            ]);
                                          }).toList(),
                                        ),
                                      ),

                                      SizedBox(height: 16),
                                      Align(
                                        alignment: Alignment.centerRight,
                                        child: TextButton(
                                          style: ElevatedButton.styleFrom(
                                            foregroundColor: Colors
                                                .blue, // Set the text color to blue
                                          ),
                                          onPressed: () =>
                                              Navigator.pop(context),
                                          child: Text('Close'),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ));
                },
              ),
            );
          },
        );
      },
    );
  }
}

class ApproverPageWrapper extends StatelessWidget {
  final String userRole;

  ApproverPageWrapper({required this.userRole});

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        return false; // Prevents going back
      },
      child: HistoryPage(userRole: userRole),
    );
  }
}
