import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:flutter/services.dart' show rootBundle;

class History extends StatelessWidget {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: _firestore
          .collection('memo')
          .where('status', whereIn: ['completed']).snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Center(child: Text("No memos found."));
        }

        final memos = snapshot.data!.docs;

        return ListView.builder(
          itemCount: memos.length,
          itemBuilder: (context, index) {
            final memo = memos[index];
            final memoData = memo.data() as Map<String, dynamic>;
            return Card(
              margin: EdgeInsets.all(8.0),
              child: ListTile(
                title: Text(
                  "Worker: ${memoData['workerType'] ?? 'N/A'}                                   Status: ${memoData['status']}",
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: Text("Memo ID: ${memoData['memoId'] ?? 'N/A'}"),
                trailing: IconButton(
                  icon: Icon(Icons.download, color: Colors.green),
                  onPressed: () => _showDownloadConfirmation(context, memoData),
                ),
                onTap: () => _showMemoDetails(context, memoData),
              ),
            );
          },
        );
      },
    );
  }

  void _showMemoDetails(BuildContext context, Map<String, dynamic> memoData) {
    showDialog(
      context: context,
      builder: (context) {
        final dialogWidth = MediaQuery.of(context).size.width * 0.9;
        return Theme(
            data: ThemeData(
              canvasColor: Colors
                  .white, // Forces the dropdown menu background color to white
            ),
            child: AlertDialog(
              title: Text("Memo Details"),
              contentPadding: EdgeInsets.zero,
              content: Container(
                width: dialogWidth,
                padding: EdgeInsets.all(16.0),
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildKeyValueRow("Memo ID", memoData['memoId']),
                      _buildKeyValueRow("Worker Type", memoData['workerType']),
                      _buildKeyValueRow("Complaint", memoData['complaints']),
                      _buildKeyValueRow("Department", memoData['department']),
                      _buildKeyValueRow("Block", memoData['blockName']),
                      _buildKeyValueRow("Floor", memoData['floorNo']),
                      _buildKeyValueRow("Ward No", memoData['wardNo']),
                      _buildKeyValueRow("Nurse Name", memoData['nurseName']),
                      _buildKeyValueRow("Shift", memoData['shift']),
                      _buildKeyValueRow("Status", memoData['status']),
                      _buildKeyValueRow(
                          "Timestamp", _formatTimestamp(memoData['timestamp'])),
                      if (memoData['approvedBy'] != null)
                        _buildTable(
                          "Approved By",
                          memoData['approvedBy'],
                          ["institutionalId", "userType", "timestamp"],
                          formatTimestamp: true,
                        ),
                      if (memoData['workerStatuses'] != null)
                        _buildTable(
                          "Worker Statuses",
                          memoData['workerStatuses'],
                          [
                            "institutionalId",
                            "userType",
                            "workStatus",
                            "status",
                            "remarks"
                          ],
                        ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  style: ElevatedButton.styleFrom(
                    foregroundColor: Colors.blue, // Set the text color to blue
                  ),
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text("Close"),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    foregroundColor: Colors.blue, // Set the text color to blue
                  ),
                  onPressed: () => _downloadAsPDF(context, memoData),
                  child: Text("Download as PDF"),
                ),
              ],
            ));
      },
    );
  }

  void _showDownloadConfirmation(
      BuildContext context, Map<String, dynamic> memoData) {
    showDialog(
        context: context,
        builder: (context) => Theme(
              data: ThemeData(
                canvasColor: Colors
                    .white, // Forces the dropdown menu background color to white
              ),
              child: AlertDialog(
                title: Text("Download Memo"),
                content: Text("Do you want to download this memo as a PDF?"),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: Text("No"),
                  ),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                      _downloadAsPDF(context, memoData);
                    },
                    child: Text("Yes"),
                  ),
                ],
              ),
            ));
  }

  Future<void> _downloadAsPDF(
      BuildContext context, Map<String, dynamic> memoData) async {
    final pdf = pw.Document();

    // Define elegant color scheme
    final darkBlue = PdfColors.blueGrey800;
    final mediumBlue = PdfColors.blueGrey700;
    final lightBlue = PdfColors.blueGrey200;
    final smokeWhite = PdfColors.grey100;
    final black = PdfColors.black;
    final white = PdfColors.white;

    // Load multiple fonts for better Tamil support
    final fontData =
        await rootBundle.load("assets/fonts/NotoSansTamil-Regular.ttf");

    // Try loading Latha font which has good Tamil support
    pw.Font? tamilFont;
    try {
      final lathaFontData = await rootBundle.load("assets/fonts/Nirmala.ttf");
      tamilFont = pw.Font.ttf(lathaFontData);
    } catch (e) {
      // Fallback to Noto Sans Tamil if Latha is not available
      tamilFont = pw.Font.ttf(fontData);
    }

    // Use default font for non-Tamil text
    final regularFont = pw.Font.helvetica();

    // Create a function to determine which font to use based on text content
    pw.TextStyle getTextStyle({
      required double fontSize,
      pw.FontWeight fontWeight = pw.FontWeight.normal,
      PdfColor color = PdfColors.black,
      pw.FontStyle fontStyle = pw.FontStyle.normal,
    }) {
      return pw.TextStyle(
        font: tamilFont,
        fontSize: fontSize,
        fontWeight: fontWeight,
        color: color,
        fontStyle: fontStyle,
      );
    }

    // Header for each page
    pw.Widget buildHeader() {
      return pw.Container(
        padding: pw.EdgeInsets.only(bottom: 10),
        decoration: pw.BoxDecoration(
          border: pw.Border(bottom: pw.BorderSide(color: darkBlue, width: 1.5)),
        ),
        child: pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Text(
              "Memo Details",
              style: getTextStyle(
                fontSize: 22,
                fontWeight: pw.FontWeight.bold,
                color: darkBlue,
              ),
            ),
            pw.Container(
              padding: pw.EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: pw.BoxDecoration(
                color: darkBlue,
                borderRadius: pw.BorderRadius.circular(4),
              ),
              child: pw.Text(
                "ID: ${memoData['memoId'] ?? 'N/A'}",
                style: getTextStyle(
                  fontSize: 12,
                  color: white,
                ),
              ),
            ),
          ],
        ),
      );
    }

    // Footer for each page
    pw.Widget buildFooter(pw.Context context) {
      return pw.Container(
        decoration: pw.BoxDecoration(
          border: pw.Border(top: pw.BorderSide(color: lightBlue, width: 0.5)),
        ),
        padding: pw.EdgeInsets.only(top: 5),
        child: pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Text(
              'Generated on ${DateTime.now().toString().split('.')[0]}',
              style: getTextStyle(
                fontSize: 8,
                color: mediumBlue,
              ),
            ),
            pw.Text(
              'Page ${context.pageNumber} of ${context.pagesCount}',
              style: getTextStyle(
                fontSize: 9,
                color: mediumBlue,
              ),
            ),
          ],
        ),
      );
    }

    pw.Widget buildTable(
        String title, List<dynamic> data, List<String> columns) {
      return pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Container(
            padding: pw.EdgeInsets.symmetric(vertical: 5, horizontal: 8),
            decoration: pw.BoxDecoration(
              color: darkBlue,
              borderRadius: pw.BorderRadius.only(
                topLeft: pw.Radius.circular(5),
                topRight: pw.Radius.circular(5),
              ),
            ),
            child: pw.Text(
              title,
              style: getTextStyle(
                fontSize: 14,
                fontWeight: pw.FontWeight.bold,
                color: white,
              ),
            ),
          ),
          pw.Table.fromTextArray(
            headers: columns,
            data: data.map((row) {
              return columns
                  .map((column) => row[column]?.toString() ?? "N/A")
                  .toList();
            }).toList(),
            headerStyle: getTextStyle(
              fontSize: 11,
              fontWeight: pw.FontWeight.bold,
              color: white,
            ),
            cellStyle: getTextStyle(
              fontSize: 10,
              color: black,
            ),
            border: pw.TableBorder.symmetric(
              inside: pw.BorderSide(
                color: lightBlue,
                width: 0.5,
              ),
            ),
            headerDecoration: pw.BoxDecoration(
              color: mediumBlue,
            ),
            rowDecoration: pw.BoxDecoration(
              color: smokeWhite,
            ),
            headerAlignment: pw.Alignment.center,
            cellAlignment: pw.Alignment.center,
            cellAlignments: {
              0: pw.Alignment.centerLeft,
              1: pw.Alignment.center,
              2: pw.Alignment.center,
              3: pw.Alignment.center,
            },
          ),
          pw.SizedBox(height: 15),
        ],
      );
    }

    pw.Widget buildInfoSection(String title, Map<String, dynamic> data) {
      final entries = data.entries.toList();

      return pw.Container(
        margin: pw.EdgeInsets.only(bottom: 15),
        decoration: pw.BoxDecoration(
          borderRadius: pw.BorderRadius.circular(5),
          border: pw.Border.all(color: lightBlue, width: 0.5),
        ),
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            // Section header
            pw.Container(
              width: double.infinity,
              padding: pw.EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: pw.BoxDecoration(
                color: mediumBlue,
                borderRadius: pw.BorderRadius.only(
                  topLeft: pw.Radius.circular(4),
                  topRight: pw.Radius.circular(4),
                ),
              ),
              child: pw.Text(
                title,
                style: getTextStyle(
                  fontSize: 14,
                  fontWeight: pw.FontWeight.bold,
                  color: white,
                ),
              ),
            ),
            // Data content
            pw.Container(
              padding: pw.EdgeInsets.all(10),
              color: smokeWhite,
              child: pw.Column(
                children: [
                  for (int i = 0; i < entries.length; i += 2)
                    pw.Padding(
                      padding: pw.EdgeInsets.only(bottom: 6),
                      child: pw.Row(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          // First item in the row
                          pw.Expanded(
                            child: pw.Row(
                              crossAxisAlignment: pw.CrossAxisAlignment.start,
                              children: [
                                pw.Container(
                                  width: 80,
                                  child: pw.Text(
                                    "${entries[i].key}:",
                                    style: getTextStyle(
                                      fontSize: 11,
                                      fontWeight: pw.FontWeight.bold,
                                      color: darkBlue,
                                    ),
                                  ),
                                ),
                                pw.Expanded(
                                  child: pw.Text(
                                    "${entries[i].value ?? 'N/A'}",
                                    style: getTextStyle(
                                      fontSize: 11,
                                      color: black,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          // Second item in the row (if available)
                          if (i + 1 < entries.length)
                            pw.Expanded(
                              child: pw.Row(
                                crossAxisAlignment: pw.CrossAxisAlignment.start,
                                children: [
                                  pw.Container(
                                    width: 80,
                                    child: pw.Text(
                                      "${entries[i + 1].key}:",
                                      style: getTextStyle(
                                        fontSize: 11,
                                        fontWeight: pw.FontWeight.bold,
                                        color: darkBlue,
                                      ),
                                    ),
                                  ),
                                  pw.Expanded(
                                    child: pw.Text(
                                      "${entries[i + 1].value ?? 'N/A'}",
                                      style: getTextStyle(
                                        fontSize: 11,
                                        color: black,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    // Alternative approach for Tamil text: Rendering as images
    Future<pw.Widget> buildTamilTextAsImage(String text,
        {double fontSize = 12, bool isBold = false}) async {
      // This is a fallback method if font rendering fails
      // Would need to implement a native method to render text to image
      // This is a placeholder implementation
      return pw.Text(
        text,
        style: getTextStyle(
          fontSize: fontSize,
          fontWeight: isBold ? pw.FontWeight.bold : pw.FontWeight.normal,
        ),
      );
    }

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: pw.EdgeInsets.all(30),
        header: (pw.Context context) => buildHeader(),
        footer: (pw.Context context) => buildFooter(context),
        build: (pw.Context context) {
          return [
            pw.SizedBox(height: 10),

            // Basic Info Section
            buildInfoSection("Basic Information", {
              "Worker Type": memoData['workerType'] ?? 'N/A',
              "Complaint": memoData['complaints'] ?? 'N/A',
              "Department": memoData['department'] ?? 'N/A',
              "Status": memoData['status'] ?? 'N/A',
              "Timestamp": _formatTimestamp(memoData['timestamp']) ?? 'N/A',
            }),

            // Location Info Section
            buildInfoSection("Location Information", {
              "Block": memoData['blockName'] ?? 'N/A',
              "Floor": memoData['floorNo'] ?? 'N/A',
              "Ward No": memoData['wardNo'] ?? 'N/A',
            }),

            // Staff Info Section
            buildInfoSection("Staff Information", {
              "Nurse Name": memoData['nurseName'] ?? 'N/A',
              "Shift": memoData['shift'] ?? 'N/A',
            }),

            pw.SizedBox(height: 5),

            // Approved By Table
            if (memoData['approvedBy'] != null)
              buildTable(
                "Approved By",
                List<Map<String, dynamic>>.from(memoData['approvedBy']),
                ["institutionalId", "userType", "timestamp"],
              ),

            // Worker Status Table (without Remarks)
            if (memoData['workerStatuses'] != null)
              buildTable(
                "Worker Statuses",
                List<Map<String, dynamic>>.from(memoData['workerStatuses']),
                ["institutionalId", "userType", "workStatus", "status"],
              ),

            // Separate Remarks Section
            if (memoData['workerStatuses'] != null &&
                List<Map<String, dynamic>>.from(memoData['workerStatuses'])
                    .any((row) => row['remarks'] != null))
              pw.Container(
                decoration: pw.BoxDecoration(
                  border: pw.Border.all(color: lightBlue),
                  borderRadius: pw.BorderRadius.circular(5),
                ),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Container(
                      width: double.infinity,
                      padding:
                          pw.EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: pw.BoxDecoration(
                        color: mediumBlue,
                        borderRadius: pw.BorderRadius.only(
                          topLeft: pw.Radius.circular(4),
                          topRight: pw.Radius.circular(4),
                        ),
                      ),
                      child: pw.Text(
                        "Remarks",
                        style: getTextStyle(
                          fontSize: 14,
                          fontWeight: pw.FontWeight.bold,
                          color: white,
                        ),
                      ),
                    ),
                    pw.Container(
                      padding: pw.EdgeInsets.all(10),
                      color: smokeWhite,
                      child: pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: List<Map<String, dynamic>>.from(
                                memoData['workerStatuses'])
                            .where((row) => row['remarks'] != null)
                            .map((row) {
                          return pw.Padding(
                            padding: pw.EdgeInsets.only(bottom: 8),
                            child: pw.Column(
                              crossAxisAlignment: pw.CrossAxisAlignment.start,
                              children: [
                                pw.Container(
                                  padding: pw.EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 3),
                                  decoration: pw.BoxDecoration(
                                    color: darkBlue,
                                    borderRadius: pw.BorderRadius.circular(3),
                                  ),
                                  child: pw.Text(
                                    "ID: ${row['institutionalId']} (${row['userType']})",
                                    style: getTextStyle(
                                      fontSize: 10,
                                      color: white,
                                    ),
                                  ),
                                ),
                                pw.SizedBox(height: 3),
                                pw.Container(
                                  padding: pw.EdgeInsets.all(8),
                                  width: double.infinity,
                                  decoration: pw.BoxDecoration(
                                    color: white,
                                    borderRadius: pw.BorderRadius.circular(3),
                                  ),
                                  child: pw.Text(
                                    "${row['remarks']}",
                                    style: getTextStyle(
                                      fontSize: 10,
                                      color: black,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ],
                ),
              ),
          ];
        },
      ),
    );

    await Printing.sharePdf(
        bytes: await pdf.save(), filename: "Memo_${memoData['memoId']}.pdf");
  }

// Add this alternate implementation for Tamil font handling
  Future<void> generatePdfWithTamilWorkaround(
      BuildContext context, Map<String, dynamic> memoData) async {
    // You can either:

    // 1. Use a different font like Latha or TAM-Tamil that's specifically
    // designed for Tamil text rendering

    // 2. Use a Base64 approach where you first convert Tamil text to images
    // and embed those in the PDF

    // 3. Use a third-party library like flutter_native_pdf_renderer to first
    // generate HTML with proper Tamil support and then convert to PDF

    // 4. Use the syncfusion_flutter_pdf package which has better font support

    await _downloadAsPDF(context, memoData);
  }

  Widget _buildKeyValueRow(String key, dynamic value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Text(
              "$key:",
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(value != null ? value.toString() : "N/A"),
          ),
        ],
      ),
    );
  }

  Widget _buildTable(String title, List<dynamic> items, List<String> columns,
      {bool formatTimestamp = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 16.0, bottom: 8.0),
          child: Text(
            title,
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
        ),
        Table(
          border: TableBorder.all(),
          columnWidths:
              columns.asMap().map((i, _) => MapEntry(i, FlexColumnWidth())),
          children: [
            TableRow(
              children: columns.map((col) {
                return Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Text(
                    col,
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                );
              }).toList(),
            ),
            ...items.map((item) {
              final itemData = item as Map<String, dynamic>;
              return TableRow(
                children: columns.map((col) {
                  var value = itemData[col];
                  if (formatTimestamp && col == "timestamp" && value != null) {
                    value = _formatTimestamp(value);
                  }
                  return Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Text(value?.toString() ?? "N/A"),
                  );
                }).toList(),
              );
            }).toList(),
          ],
        ),
      ],
    );
  }

  String _formatTimestamp(dynamic timestamp) {
    if (timestamp is Timestamp) {
      final dateTime = timestamp.toDate();
      return DateFormat('yyyy-MM-dd HH:mm').format(dateTime);
    } else if (timestamp is String) {
      try {
        final dateTime = DateTime.parse(timestamp);
        return DateFormat('yyyy-MM-dd HH:mm').format(dateTime);
      } catch (e) {
        return "Invalid Date";
      }
    }
    return "N/A";
  }
}
