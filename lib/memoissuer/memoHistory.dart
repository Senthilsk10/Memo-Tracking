import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:memo4/user_types.dart';

class HistoryPage extends StatefulWidget {
  const HistoryPage({Key? key}) : super(key: key);

  @override
  _HistoryPageState createState() => _HistoryPageState();
}

class _HistoryPageState extends State<HistoryPage> {
  // Color Palette inspired by Google AppSheet
  final Color _primaryColor = const Color(0xFF4285F4); // Google Blue
  final Color _completedColor =
      const Color(0xffffffff); // Light Blue for Completed
  final Color _pendingColor =
      const Color(0xffffffff); // Light Orange for Pending
  final Color _approvedColor =
      const Color(0xffffffff); // Light Green for Approved

  // Filter controllers
  final TextEditingController _blockNameController = TextEditingController();
  final TextEditingController _floorNoController = TextEditingController();
  final TextEditingController _wardNoController = TextEditingController();
  final TextEditingController _departmentController = TextEditingController();
  final TextEditingController _shiftController = TextEditingController();

  // Dropdown for worker type
  String? _selectedWorkerType;
  final List<String> _workerTypes = UserTypes.workertype;

  final TextEditingController _nurseNameController = TextEditingController();
  final TextEditingController _nurseIdController = TextEditingController();

  DateTime? _fromDate;
  DateTime? _toDate;
  TimeOfDay? _fromTime;
  TimeOfDay? _toTime;

  List<Map<String, dynamic>> _filteredMemos = [];

  void _selectFromDate(BuildContext context) async {
    final DateTime? pickedFromDate = await showDatePicker(
      context: context,
      initialDate: _fromDate ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );

    if (pickedFromDate != null) {
      setState(() {
        _fromDate = pickedFromDate;
      });
    }
  }

  void _selectFromTime(BuildContext context) async {
    final TimeOfDay? pickedFromTime = await showTimePicker(
      context: context,
      initialTime: _fromTime ?? TimeOfDay.now(),
    );

    if (pickedFromTime != null) {
      setState(() {
        _fromTime = pickedFromTime;
      });
    }
  }

  void _selectToDate(BuildContext context) async {
    final DateTime? pickedToDate = await showDatePicker(
      context: context,
      initialDate: _toDate ?? DateTime.now(),
      firstDate: _fromDate ?? DateTime(2000),
      lastDate: DateTime(2101),
    );

    if (pickedToDate != null) {
      setState(() {
        _toDate = pickedToDate;
      });
    }
  }

  void _selectToTime(BuildContext context) async {
    final TimeOfDay? pickedToTime = await showTimePicker(
      context: context,
      initialTime: _toTime ?? TimeOfDay.now(),
    );

    if (pickedToTime != null) {
      setState(() {
        _toTime = pickedToTime;
      });
    }
  }

  void _applyFilters(List<QueryDocumentSnapshot> memos) {
    _filteredMemos =
        memos.map((doc) => doc.data() as Map<String, dynamic>).where((memo) {
      // Null-safe conversion and type checking
      String blockName = memo['blockName']?.toString() ?? '';
      String floorNo = memo['floorNo']?.toString() ?? '';
      String wardNo = memo['wardNo']?.toString() ?? '';
      String department = memo['department']?.toString() ?? '';
      String shift = memo['shift']?.toString() ?? '';
      String workerType = memo['workerType']?.toString() ?? '';
      String nurseName = memo['nurseName']?.toString() ?? '';
      String nurseId = memo['nurseId']?.toString() ?? '';

      bool matchesBlockName = _blockNameController.text.isEmpty ||
          blockName
              .toLowerCase()
              .contains(_blockNameController.text.toLowerCase().trim());

      bool matchesFloorNo = _floorNoController.text.isEmpty ||
          floorNo == _floorNoController.text.trim();

      bool matchesWardNo = _wardNoController.text.isEmpty ||
          wardNo == _wardNoController.text.trim();

      bool matchesDepartment = _departmentController.text.isEmpty ||
          department
              .toLowerCase()
              .contains(_departmentController.text.toLowerCase().trim());

      bool matchesShift = _shiftController.text.isEmpty ||
          shift
              .toLowerCase()
              .contains(_shiftController.text.toLowerCase().trim());

      bool matchesWorkerType = _selectedWorkerType == null ||
          workerType.toLowerCase() == _selectedWorkerType!.toLowerCase();

      bool matchesNurseName = _nurseNameController.text.isEmpty ||
          nurseName
              .toLowerCase()
              .contains(_nurseNameController.text.toLowerCase().trim());

      bool matchesNurseId = _nurseIdController.text.isEmpty ||
          nurseId == _nurseIdController.text.trim();

      // Date and Time filtering with robust logic
      bool matchesDateRange = true;
      DateTime? memoDate = memo['timestamp'] is Timestamp
          ? (memo['timestamp'] as Timestamp).toDate()
          : null;

      if (memoDate != null) {
        if (_fromDate != null) {
          DateTime fromDateTime = DateTime(_fromDate!.year, _fromDate!.month,
              _fromDate!.day, _fromTime?.hour ?? 0, _fromTime?.minute ?? 0);
          matchesDateRange = memoDate.isAtSameMomentAs(fromDateTime) ||
              memoDate.isAfter(fromDateTime);
        }

        if (_toDate != null) {
          DateTime toDateTime = DateTime(_toDate!.year, _toDate!.month,
              _toDate!.day, _toTime?.hour ?? 23, _toTime?.minute ?? 59);
          matchesDateRange = matchesDateRange &&
              (memoDate.isAtSameMomentAs(toDateTime) ||
                  memoDate.isBefore(toDateTime));
        }
      }

      return matchesBlockName &&
          matchesFloorNo &&
          matchesWardNo &&
          matchesDepartment &&
          matchesShift &&
          matchesWorkerType &&
          matchesNurseName &&
          matchesNurseId &&
          matchesDateRange;
    }).toList();
  }

  void _showFilterDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Theme(
          data: ThemeData(
            canvasColor:
                Colors.white, // This changes the dropdown background to white
          ),
          child: AlertDialog(
            title: const Text('Filter Memos'),
            content: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextField(
                    controller: _blockNameController,
                    decoration: const InputDecoration(labelText: 'Block Name'),
                  ),
                  TextField(
                    controller: _floorNoController,
                    decoration: const InputDecoration(labelText: 'Floor No'),
                    keyboardType: TextInputType.number,
                  ),
                  TextField(
                    controller: _wardNoController,
                    decoration: const InputDecoration(labelText: 'Ward No'),
                    keyboardType: TextInputType.number,
                  ),
                  TextField(
                    controller: _departmentController,
                    decoration: const InputDecoration(labelText: 'Department'),
                  ),
                  TextField(
                    controller: _shiftController,
                    decoration: const InputDecoration(labelText: 'Shift'),
                  ),
                  // Worker Type Dropdown
                  DropdownButtonFormField<String>(
                    value: _selectedWorkerType,
                    decoration: const InputDecoration(labelText: 'Worker Type'),
                    hint: const Text('Select Worker Type'),
                    items: _workerTypes.map((String workerType) {
                      return DropdownMenuItem<String>(
                        value: workerType,
                        child: Text(workerType),
                      );
                    }).toList(),
                    onChanged: (String? newValue) {
                      setState(() {
                        _selectedWorkerType = newValue;
                      });
                    },
                  ),
                  TextField(
                    controller: _nurseNameController,
                    decoration: const InputDecoration(labelText: 'Nurse Name'),
                  ),
                  TextField(
                    controller: _nurseIdController,
                    decoration: const InputDecoration(labelText: 'Nurse ID'),
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: 10),
                  const Text('Date Range:',
                      style: TextStyle(fontWeight: FontWeight.bold)),

                  // From Date and Time
                  const Text('From:',
                      style: TextStyle(fontWeight: FontWeight.bold)),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            foregroundColor:
                                Colors.blue, // Set the text color to blue
                          ),
                          onPressed: () => _selectFromDate(context),
                          child: Text(_fromDate == null
                              ? 'Select Date'
                              : DateFormat('dd/MM/yyyy').format(_fromDate!)),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            foregroundColor:
                                Colors.blue, // Set the text color to blue
                          ),
                          onPressed: () => _selectFromTime(context),
                          child: Text(_fromTime == null
                              ? 'Select Time'
                              : _fromTime!.format(context)),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 10),

                  // To Date and Time
                  const Text('To:',
                      style: TextStyle(fontWeight: FontWeight.bold)),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            foregroundColor:
                                Colors.blue, // Set the text color to blue
                          ),
                          onPressed: () => _selectToDate(context),
                          child: Text(_toDate == null
                              ? 'Select Date'
                              : DateFormat('dd/MM/yyyy').format(_toDate!)),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            foregroundColor:
                                Colors.blue, // Set the text color to blue
                          ),
                          onPressed: () => _selectToTime(context),
                          child: Text(_toTime == null
                              ? 'Select Time'
                              : _toTime!.format(context)),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                style: ElevatedButton.styleFrom(
                  foregroundColor: Colors.blue, // Set the text color to blue
                ),
                child: const Text('Clear'),
                onPressed: () {
                  setState(() {
                    // Clear all controllers and date/time values
                    _blockNameController.clear();
                    _floorNoController.clear();
                    _wardNoController.clear();
                    _departmentController.clear();
                    _shiftController.clear();
                    _selectedWorkerType = null;
                    _nurseNameController.clear();
                    _nurseIdController.clear();
                    _fromDate = null;
                    _toDate = null;
                    _fromTime = null;
                    _toTime = null;
                  });
                  Navigator.of(context).pop();
                },
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  foregroundColor: Colors.blue, // Set the text color to blue
                ),
                child: const Text('Apply'),
                onPressed: () {
                  Navigator.of(context).pop();
                  setState(() {});
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _showToast(String message, {bool isError = false}) {
    Fluttertoast.showToast(
      msg: message,
      toastLength: Toast.LENGTH_SHORT,
      gravity: ToastGravity.BOTTOM,
      timeInSecForIosWeb: 1,
      backgroundColor: isError ? Colors.red : _primaryColor,
      textColor: Colors.white,
      fontSize: 16.0,
    );
  }

  void _showMemoDetailsBottomSheet(Map<String, dynamic> memo) {
    // Format timestamp into separate date and time
    final timestamp = memo['timestamp'] as Timestamp?;
    String formattedDate = '';
    String formattedTime = '';
    if (timestamp != null) {
      final dateTime = timestamp.toDate();
      formattedDate = DateFormat('dd/MM/yyyy').format(dateTime);
      formattedTime = DateFormat('hh:mm a').format(dateTime);
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.7,
          minChildSize: 0.3,
          maxChildSize: 0.9,
          expand: false,
          builder: (context, scrollController) {
            return Container(
              padding: const EdgeInsets.all(16),
              child: ListView(
                controller: scrollController,
                children: [
                  Text(
                    'Memo Details',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: _primaryColor,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildDetailRow(
                      'Memo ID', memo['memoId']?.toString() ?? 'N/A'),
                  _buildDetailRow(
                      'Worker Type', memo['workerType']?.toString() ?? 'N/A'),
                  _buildDetailRow('Status',
                      memo['status']?.toString().toUpperCase() ?? 'N/A'),
                  _buildDetailRow('Location',
                      'Block ${memo['blockName'] ?? 'N/A'}, Floor ${memo['floorNo'] ?? 'N/A'}, Ward ${memo['wardNo'] ?? 'N/A'}'),
                  _buildDetailRow(
                      'Department', memo['department']?.toString() ?? 'N/A'),
                  _buildDetailRow('Shift', memo['shift']?.toString() ?? 'N/A'),
                  _buildDetailRow(
                      'Complaints', memo['complaints']?.toString() ?? 'N/A'),
                  _buildDetailRow('Submitted by',
                      '${memo['nurseName'] ?? 'N/A'} (ID: ${memo['nurseId'] ?? 'N/A'})'),
                  _buildDetailRow('Date', formattedDate),
                  _buildDetailRow('Time', formattedTime),
                  if (memo['responder'] != null)
                    _buildDetailRow('Currently with',
                        memo['responder']?.toString() ?? 'N/A'),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: _primaryColor,
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              value,
              style: const TextStyle(color: Colors.black87),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('memo')
          .orderBy('timestamp', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(
            child: Text(
              'Error loading memos',
              style: TextStyle(color: _primaryColor),
            ),
          );
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(
            child: CircularProgressIndicator(
              color: _primaryColor,
            ),
          );
        }

        final memos = snapshot.data?.docs ?? [];
        _applyFilters(memos);

        return Scaffold(
          backgroundColor: Colors.white,
          body: Column(
            children: [
              // AppSheet-like Filter Card
              Container(
                margin: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.2),
                      spreadRadius: 1,
                      blurRadius: 3,
                    ),
                  ],
                ),
                child: ListTile(
                  title: Text(
                    'Filter Memos',
                    style: TextStyle(
                        fontWeight: FontWeight.w600, color: _primaryColor),
                  ),
                  trailing: IconButton(
                    icon: Icon(Icons.filter_list, color: _primaryColor),
                    onPressed: () {
                      _showFilterDialog();
                      _showToast('Filter options opened');
                    },
                  ),
                ),
              ),

              // Memo List
              Expanded(
                child: _filteredMemos.isEmpty
                    ? Center(
                        child: Text(
                          'No Memos Found',
                          style: TextStyle(
                            fontSize: 18,
                            color: _primaryColor.withOpacity(0.7),
                          ),
                        ),
                      )
                    : ListView.builder(
                        itemCount: _filteredMemos.length,
                        itemBuilder: (context, index) {
                          final memo = _filteredMemos[index];

                          // Existing date formatting code
                          final timestamp = memo['timestamp'] as Timestamp?;
                          String formattedDate = '';
                          String formattedTime = '';
                          if (timestamp != null) {
                            final dateTime = timestamp.toDate();
                            formattedDate =
                                DateFormat('dd/MM/yyyy').format(dateTime);
                            formattedTime =
                                DateFormat('hh:mm a').format(dateTime);
                          }

                          return Card(
                            margin: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 6),
                            elevation: 2,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            color: _getStatusColor(
                                memo['status']?.toString() ?? ''),
                            child: ListTile(
                              title: Text(
                                'Memo ID: ${memo['memoId']?.toString() ?? 'N/A'}',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black87,
                                ),
                              ),
                              subtitle: Text(
                                'To: ${memo['workerType']?.toString() ?? 'N/A'} - Status: ${(memo['status']?.toString() ?? '').toUpperCase()}',
                                style: const TextStyle(color: Colors.black54),
                              ),
                              trailing: Icon(
                                Icons.chevron_right,
                                color: _primaryColor,
                              ),
                              onTap: () {
                                // Show bottom sheet with full memo details
                                _showMemoDetailsBottomSheet(memo);
                              },
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
          floatingActionButton: FloatingActionButton(
            backgroundColor: _primaryColor,
            onPressed: () {
              _showFilterDialog();
              _showToast('Filter options opened');
            },
            child: const Icon(Icons.filter_list),
          ),
        );
      },
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'completed':
        return _completedColor;
      case 'approved':
        return _approvedColor;
      case 'pending':
        return _pendingColor;
      default:
        return Colors.grey[100]!;
    }
  }

  @override
  void dispose() {
    // Dispose all controllers
    _blockNameController.dispose();
    _floorNoController.dispose();
    _wardNoController.dispose();
    _departmentController.dispose();
    _shiftController.dispose();
    _nurseNameController.dispose();
    _nurseIdController.dispose();
    super.dispose();
  }
}
