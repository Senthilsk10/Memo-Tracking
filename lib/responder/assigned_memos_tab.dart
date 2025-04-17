import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'memo_dialog.dart';

class AssignedMemoTab extends StatefulWidget {
  final String userType;
  final String institutionalId;
  final FirebaseFirestore firestore;
  final List<String> responderTypes;

  const AssignedMemoTab({
    Key? key,
    required this.userType,
    required this.institutionalId,
    required this.firestore,
    required this.responderTypes,
  }) : super(key: key);

  @override
  _AssignedMemoTabState createState() => _AssignedMemoTabState();
}

class _AssignedMemoTabState extends State<AssignedMemoTab> {
  String _searchQuery = '';
  List<String> _searchFields = [
    'memoId',
    'blockName',
    'wardNo',
    'department',
    'floorNo',
  ];
  String _selectedSearchField = 'memoId';

  // Date and Time Range Filters
  /*DateTime? _fromDate;
  DateTime? _toDate;
  TimeOfDay? _fromTime;
  TimeOfDay? _toTime;*/
  // Google-inspired color scheme
  final Color primaryColor = Color(0xFF4285F4); // Google Blue
  final Color secondaryColor = Color(0xFF34A853); // Google Green
  final Color backgroundColor = Color(0xFFF1F3F4); // Light grey background

  // Filter visibility toggle
  bool _isFilterExpanded = false;

  Stream<List<DocumentSnapshot>> _getFilteredMemos() {
    String workerType = widget.userType.split(' - ').last;
    return widget.firestore
        .collection('memo')
        .where('status', whereIn: ['approved', 'completed'])
        .where('workerType', isEqualTo: workerType)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs.where((doc) {
            final data = doc.data() as Map<String, dynamic>;

            // Worker status filtering logic
            final workerStatuses = data['workerStatuses'] as List<dynamic>?;

            if (workerStatuses == null || workerStatuses.isEmpty) {
              return _filterBySearchQuery(
                  data); // && _filterByDateTimeRange(data);
            }

            final lastStatus = Map<String, dynamic>.from(workerStatuses.last);

            bool isRelevantStatus = lastStatus['userType'] == widget.userType;

            if (isRelevantStatus &&
                lastStatus['status'] == 'attended' &&
                lastStatus['workStatus'] == 'complete' &&
                (lastStatus['tagUser'] == 'no need' ||
                    lastStatus['tagUser'] == widget.institutionalId)) {
              if (data['status'] == 'approved') {
                _updateMemoStatus(doc.reference);
              }
              return false;
            }

            return isRelevantStatus &&
                (lastStatus['tagUser'] == 'no need' ||
                    lastStatus['tagUser'] == widget.institutionalId) &&
                _filterBySearchQuery(data); //&&
            //  _filterByDateTimeRange(data);
          }).toList();
        });
  }

  /* bool _filterByDateTimeRange(Map<String, dynamic> data) {
    // Parse date and time from the memo
    DateTime? memoDate =
        data['date'] != null ? DateTime.tryParse(data['date']) : null;
    TimeOfDay? memoTime =
        data['time'] != null ? _parseTimeOfDay(data['time']) : null;

    // Check date range
    if (_fromDate != null && memoDate != null) {
      if (memoDate.isBefore(_fromDate!)) return false;
    }
    if (_toDate != null && memoDate != null) {
      if (memoDate.isAfter(_toDate!)) return false;
    }

    // Check time range
    if (_fromTime != null && memoTime != null) {
      DateTime memoDateTime = DateTime(
          memoDate?.year ?? DateTime.now().year,
          memoDate?.month ?? DateTime.now().month,
          memoDate?.day ?? DateTime.now().day,
          memoTime.hour,
          memoTime.minute);
      DateTime fromDateTime = DateTime(
          _fromDate?.year ?? DateTime.now().year,
          _fromDate?.month ?? DateTime.now().month,
          _fromDate?.day ?? DateTime.now().day,
          _fromTime!.hour,
          _fromTime!.minute);
      if (memoDateTime.isBefore(fromDateTime)) return false;
    }
    if (_toTime != null && memoTime != null) {
      DateTime memoDateTime = DateTime(
          memoDate?.year ?? DateTime.now().year,
          memoDate?.month ?? DateTime.now().month,
          memoDate?.day ?? DateTime.now().day,
          memoTime.hour,
          memoTime.minute);
      DateTime toDateTime = DateTime(
          _toDate?.year ?? DateTime.now().year,
          _toDate?.month ?? DateTime.now().month,
          _toDate?.day ?? DateTime.now().day,
          _toTime!.hour,
          _toTime!.minute);
      if (memoDateTime.isAfter(toDateTime)) return false;
    }

    return true;
  }

  TimeOfDay _parseTimeOfDay(String timeString) {
    try {
      final parsedTime = DateFormat.Hm().parse(timeString);
      return TimeOfDay(hour: parsedTime.hour, minute: parsedTime.minute);
    } catch (e) {
      return TimeOfDay.now();
    }
  }
*/
  bool _filterBySearchQuery(Map<String, dynamic> data) {
    if (_searchQuery.isEmpty) return true;

    switch (_selectedSearchField) {
      case 'memoId':
        return data['memoId']
            .toString()
            .toLowerCase()
            .contains(_searchQuery.toLowerCase());
      case 'blockName':
        return data['blockName']
            .toString()
            .toLowerCase()
            .contains(_searchQuery.toLowerCase());
      case 'wardNo':
        return data['wardNo']
            .toString()
            .toLowerCase()
            .contains(_searchQuery.toLowerCase());
      case 'department':
        return data['department']
            .toString()
            .toLowerCase()
            .contains(_searchQuery.toLowerCase());
      case 'floorNo':
        return data['floorNo']
            .toString()
            .toLowerCase()
            .contains(_searchQuery.toLowerCase());
      /* case 'date':
        return data['date']
            .toString()
            .toLowerCase()
            .contains(_searchQuery.toLowerCase());
      case 'time':
        return data['time']
            .toString()
            .toLowerCase()
            .contains(_searchQuery.toLowerCase());*/
      default:
        return true;
    }
  }

  Future<void> _updateMemoStatus(DocumentReference memoRef) async {
    try {
      await memoRef.update({'status': 'completed'});
    } catch (e) {
      print('Error updating memo status: $e');
    }
  }

  /* Future<void> _selectDateRange() async {
    DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
      initialDateRange: _fromDate != null && _toDate != null
          ? DateTimeRange(start: _fromDate!, end: _toDate!)
          : null,
    );

    if (picked != null) {
      setState(() {
        _fromDate = picked.start;
        _toDate = picked.end;
      });
    }
  }

  Future<void> _selectTimeRange() async {
    TimeOfDay? fromTime = await showTimePicker(
      context: context,
      initialTime: _fromTime ?? TimeOfDay.now(),
    );

    if (fromTime != null) {
      TimeOfDay? toTime = await showTimePicker(
        context: context,
        initialTime: _toTime ?? TimeOfDay.now(),
      );

      if (toTime != null) {
        setState(() {
          _fromTime = fromTime;
          _toTime = toTime;
        });
      }
    }
  }*/

  void _clearFilters() {
    setState(() {
      _searchQuery = '';
      // _fromDate = null;
      //_toDate = null;
      //_fromTime = null;
      // _toTime = null;
      _selectedSearchField = 'memoId';
    });
  }

  Color _getStatusColor(String status, String workStatus, String tagUser) {
    if (tagUser != 'no need') {
      return Colors.white;
    }
    if (status == 'attended' && workStatus == 'incomplete') {
      return Colors.white;
    }
    if (status == 'attended' && workStatus == 'complete') {
      return Colors.white;
    }
    if (status == 'not attended' && workStatus == 'incomplete') {
      return Colors.white;
    }
    return Colors.white;
  }

  Map<String, dynamic>? _getLastUserTypeWorkerStatus(DocumentSnapshot memo) {
    try {
      final data = memo.data() as Map<String, dynamic>;
      final workerStatuses = data['workerStatuses'] as List<dynamic>?;

      if (workerStatuses != null && workerStatuses.isNotEmpty) {
        // Find the last status for the current user type
        final reversedStatuses = workerStatuses.reversed.toList();
        for (var status in reversedStatuses) {
          final statusMap = Map<String, dynamic>.from(status);
          if (statusMap['userType'] == widget.userType) {
            return statusMap;
          }
        }

        // If no status for current user type, return the last status
        return Map<String, dynamic>.from(workerStatuses.last);
      }
    } catch (e) {
      print('Error getting worker status: $e');
    }
    return null;
  }

  void _showMemoDetailsDialog(BuildContext context, DocumentSnapshot memo) {
    final lastStatus = _getLastUserTypeWorkerStatus(memo);
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Theme(
            data: ThemeData(
              canvasColor: Colors
                  .white, // Forces the dropdown menu background color to white
            ),
            child: MemoDialog(
              memo: memo,
              lastStatus: lastStatus,
              userType: widget.userType,
              institutionalId: widget.institutionalId,
              firestore: widget.firestore,
              responderTypes: widget.responderTypes,
            ));
      },
    );
  }

  // Method to show toast instead of SnackBar
  void _showToast(String message, {bool isError = false}) {
    Fluttertoast.showToast(
      msg: message,
      toastLength: Toast.LENGTH_SHORT,
      gravity: ToastGravity.BOTTOM,
      backgroundColor: isError ? Colors.red : secondaryColor,
      textColor: Colors.white,
      fontSize: 16.0,
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isNarrow = screenWidth < 600;

    return Scaffold(
      backgroundColor: backgroundColor,
      body: Column(
        children: [
          // Filter Card with Icon
          Card(
            margin: EdgeInsets.all(8),
            elevation: 4,
            child: Column(
              children: [
                ListTile(
                  title: Text('Filter Memos',
                      style: TextStyle(color: primaryColor)),
                  trailing: IconButton(
                    icon: Icon(
                        _isFilterExpanded
                            ? Icons.expand_less
                            : Icons.expand_more,
                        color: primaryColor),
                    onPressed: () {
                      setState(() {
                        _isFilterExpanded = !_isFilterExpanded;
                      });
                    },
                  ),
                ),

                // Expandable Filter Section
                if (_isFilterExpanded)
                  Padding(
                    padding: EdgeInsets.all(8.0),
                    child: Column(
                      children: [
                        // Search Field
                        _buildSearchField(),
                        SizedBox(height: 10),

                        // Search Field Dropdown
                        _buildSearchFieldDropdown(),
                        SizedBox(height: 10),

                        // Date Range Button
                        /* _buildDateRangeButton(),
                        SizedBox(height: 10),

                        // Time Range Button
                        _buildTimeRangeButton(),
                        SizedBox(height: 10), */

                        // Clear Filters Button
                        _buildClearFiltersButton(),
                      ],
                    ),
                  ),
              ],
            ),
          ),

          // Memo List remains the same
          Expanded(
            child: StreamBuilder<List<DocumentSnapshot>>(
              stream: _getFilteredMemos(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return Center(
                    child: CircularProgressIndicator(color: primaryColor),
                  );
                }
                final memos = snapshot.data!;

                return screenWidth > 600
                    ? _buildMemoGrid(memos)
                    : _buildMemoList(memos);
              },
            ),
          ),
        ],
      ),
    );
  }

  // Extracted widget methods for better organization
  Widget _buildSearchField() {
    return TextField(
      decoration: InputDecoration(
        hintText: 'Search...',
        prefixIcon: Icon(Icons.search, color: primaryColor),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: primaryColor),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: primaryColor, width: 2),
        ),
        contentPadding: EdgeInsets.symmetric(vertical: 10, horizontal: 10),
      ),
      onChanged: (value) {
        setState(() {
          _searchQuery = value;
        });
      },
    );
  }

  Widget _buildSearchFieldDropdown() {
    return Theme(
        data: ThemeData(
          canvasColor: Colors
              .white, // Forces the dropdown menu background color to white
        ),
        child: DropdownButtonFormField<String>(
          decoration: InputDecoration(
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            contentPadding: EdgeInsets.symmetric(vertical: 10, horizontal: 10),
          ),
          value: _selectedSearchField,
          items: _searchFields.map((field) {
            return DropdownMenuItem(
              value: field,
              child: Text(field, style: TextStyle(fontSize: 14)),
            );
          }).toList(),
          onChanged: (value) {
            setState(() {
              _selectedSearchField = value!;
            });
          },
        ));
  }

  /*Widget _buildDateRangeButton() {
    return ElevatedButton.icon(
      onPressed: _selectDateRange,
      icon: Icon(Icons.calendar_today, size: 18),
      label: Text(
        _fromDate != null && _toDate != null
            ? '${DateFormat('dd/MM/yyyy').format(_fromDate!)} - ${DateFormat('dd/MM/yyyy').format(_toDate!)}'
            : 'Date Range',
        style: TextStyle(fontSize: 12),
      ),
      style: ElevatedButton.styleFrom(
        minimumSize: Size.fromHeight(48),
      ),
    );
  }

  Widget _buildTimeRangeButton() {
    return ElevatedButton.icon(
      onPressed: _selectTimeRange,
      icon: Icon(Icons.access_time, size: 18),
      label: Text(
        _fromTime != null && _toTime != null
            ? '${_fromTime!.format(context)} - ${_toTime!.format(context)}'
            : 'Time Range',
        style: TextStyle(fontSize: 12),
      ),
      style: ElevatedButton.styleFrom(
        minimumSize: Size.fromHeight(48),
      ),
    );
  }*/

  Widget _buildClearFiltersButton() {
    return IconButton(
      icon: Icon(Icons.clear),
      onPressed: _clearFilters,
      tooltip: 'Clear Filters',
    );
  }

  Widget _buildMemoGrid(List<DocumentSnapshot> memos) {
    return GridView.builder(
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 1.5,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
      ),
      itemCount: memos.length,
      itemBuilder: (context, index) {
        return _buildMemoCard(memos[index]);
      },
    );
  }

  Widget _buildMemoList(List<DocumentSnapshot> memos) {
    return ListView.builder(
      itemCount: memos.length,
      itemBuilder: (context, index) {
        return _buildMemoCard(memos[index]);
      },
    );
  }

  Widget _buildMemoCard(DocumentSnapshot memo) {
    final lastStatus = _getLastUserTypeWorkerStatus(memo);
    String status = lastStatus?['status'] ?? 'not attended';
    String workStatus = lastStatus?['workStatus'] ?? 'incomplete';
    String tagUser = lastStatus?['tagUser'] ?? 'no need';

    return Card(
      color: _getStatusColor(status, workStatus, tagUser),
      child: ListTile(
        title:
            Text('Memo ID: ${memo['memoId']}', style: TextStyle(fontSize: 14)),
        subtitle: Text('Complaint: ${memo['complaints']}',
            style: TextStyle(fontSize: 12)),
        onTap: () => _showMemoDetailsDialog(context, memo),
      ),
    );
  }
}
