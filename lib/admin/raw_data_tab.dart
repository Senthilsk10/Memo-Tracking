import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:memo4/user_types.dart';

class RawDataTab extends StatelessWidget {
  const RawDataTab({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final workerTypes = UserTypes.workertype;
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('memo')
          .where('memoId', isNotEqualTo: '')
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        // Process data
        final docs = snapshot.data!.docs;
        Map<String, int> totalMemos = {
          'Issued': 0,
          'Pending': 0,
          'Approved': 0,
          'Completed': 0
        };
        Map<String, Map<String, int>> workerStats = {};

        for (var doc in docs) {
          final data = doc.data() as Map<String, dynamic>;
          String? status = data['status'];
          String? workerType = data['workerType'];

          // Update total memos
          totalMemos['Issued'] = totalMemos['Issued']! + 1;
          if (status == 'pending')
            totalMemos['Pending'] = totalMemos['Pending']! + 1;
          if (status == 'approved')
            totalMemos['Approved'] = totalMemos['Approved']! + 1;
          if (status == 'completed')
            totalMemos['Completed'] = totalMemos['Completed']! + 1;

          // Update worker-specific stats
          if (workerType != null) {
            workerStats.putIfAbsent(
                workerType,
                () => {
                      'Issued': 0,
                      'Pending': 0,
                      'Approved': 0,
                      'Completed': 0,
                    });

            workerStats[workerType]!['Issued'] =
                workerStats[workerType]!['Issued']! + 1;
            if (status == 'pending')
              workerStats[workerType]!['Pending'] =
                  workerStats[workerType]!['Pending']! + 1;
            if (status == 'approved')
              workerStats[workerType]!['Approved'] =
                  workerStats[workerType]!['Approved']! + 1;
            if (status == 'completed')
              workerStats[workerType]!['Completed'] =
                  workerStats[workerType]!['Completed']! + 1;
          }
        }

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              // Total Memos Table
              buildResponsiveTable(
                title: "Total Memos",
                data: totalMemos,
                context: context,
              ),
              const SizedBox(height: 16.0),
              // Worker-specific Tables
              ...workerTypes.map((workerType) {
                final stats = workerStats[workerType] ??
                    {
                      'Issued': 0,
                      'Pending': 0,
                      'Approved': 0,
                      'Completed': 0,
                    };
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    buildResponsiveTable(
                      title: workerType,
                      data: stats,
                      context: context,
                    ),
                    const SizedBox(height: 16.0),
                  ],
                );
              }).toList(),
            ],
          ),
        );
      },
    );
  }

  Widget buildResponsiveTable({
    required String title,
    required Map<String, int> data,
    required BuildContext context,
  }) {
    return Card(
      elevation: 4, // Reduced elevation for a subtle shadow
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: TextStyle(
                fontSize: MediaQuery.of(context).size.width > 600 ? 20 : 16,
                fontWeight: FontWeight.bold,
                color: Colors.blue,
              ),
            ),
            const SizedBox(height: 12.0), // Increased space for separation
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                columnSpacing: MediaQuery.of(context).size.width > 600
                    ? 40
                    : 24, // Adjust column spacing for larger screens
                border: TableBorder(
                  top: BorderSide(width: 1, color: Colors.black),
                  bottom: BorderSide(width: 1, color: Colors.black),
                  left: BorderSide(width: 1, color: Colors.black),
                  right: BorderSide(width: 1, color: Colors.black),
                  horizontalInside: BorderSide(width: 1, color: Colors.black),
                  verticalInside: BorderSide(width: 1, color: Colors.black),
                ),
                columns: const [
                  DataColumn(
                      label: Text("Issued",
                          style: TextStyle(fontWeight: FontWeight.bold))),
                  DataColumn(
                      label: Text("Pending",
                          style: TextStyle(fontWeight: FontWeight.bold))),
                  DataColumn(
                      label: Text("Approved",
                          style: TextStyle(fontWeight: FontWeight.bold))),
                  DataColumn(
                      label: Text("Completed",
                          style: TextStyle(fontWeight: FontWeight.bold))),
                ],
                rows: [
                  DataRow(
                    cells: [
                      _buildResponsiveCell(data['Issued']?.toString() ?? '0'),
                      _buildResponsiveCell(data['Pending']?.toString() ?? '0'),
                      _buildResponsiveCell(data['Approved']?.toString() ?? '0'),
                      _buildResponsiveCell(
                          data['Completed']?.toString() ?? '0'),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

// Responsive cell with improved font size and padding
  DataCell _buildResponsiveCell(String value) {
    return DataCell(
      Padding(
        padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 16.0),
        child: Text(
          value,
          textAlign: TextAlign.center, // Center text in the cell
          style: const TextStyle(
            fontSize: 18, // Slightly larger text for readability
            fontWeight:
                FontWeight.w600, // A bit lighter weight for better aesthetics
          ),
        ),
      ),
    );
  }
}
