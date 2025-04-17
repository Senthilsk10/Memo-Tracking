import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:syncfusion_flutter_charts/charts.dart';
import 'package:intl/intl.dart';

class VisualizationTab extends StatefulWidget {
  const VisualizationTab({Key? key}) : super(key: key);

  @override
  _VisualizationTabState createState() => _VisualizationTabState();
}

class _VisualizationTabState extends State<VisualizationTab> {
  // Filtering options
  String _filterType = 'Month'; // Default filter
  DateTime? _selectedDate;

  // Chart type selection
  String _chartType = 'Pie'; // Default chart type
  final List<String> _chartTypes = ['Pie', 'Doughnut', 'Bar', 'Line'];

  // Memo Status filter options
  String _statusFilter = 'Total Memos';
  final List<String> _statusFilters = [
    'Total Memos',
    'Carpenter',
    'Plumber',
    'Electrician',
    'Housekeeping Supervisor',
    'Biomedical Engineer',
    'Civil',
  ];

  // Visualization types
  final List<String> _visualizationTypes = [
    'Memo Status',
    'Worker Types',
    'Department Breakdown',
    'Block Breakdown',
    'Approver Distribution',
  ];

  int _currentVisualizationIndex = 0;

  // Existing methods like _fetchMemoData, _filterDataByTimePeriod, etc. remain the same
  // Fetch and process memo data
  Future<List<Map<String, dynamic>>> _fetchMemoData() async {
    try {
      QuerySnapshot querySnapshot = await FirebaseFirestore.instance
          .collection('memo')
          .where('memoId', isNotEqualTo: '')
          .get();

      return querySnapshot.docs
          .map((doc) => {...?doc.data() as Map<String, dynamic>, 'id': doc.id})
          .toList();
    } catch (e) {
      print('Error fetching memo data: $e');
      return [];
    }
  }

  // Filter data based on selected time period
  List<Map<String, dynamic>> _filterDataByTimePeriod(
      List<Map<String, dynamic>> data,
      String filterType,
      DateTime? selectedDate) {
    if (selectedDate == null) return data;

    return data.where((memo) {
      // Handle various timestamp formats
      DateTime? memoDate;
      try {
        if (memo['timestamp'] is Timestamp) {
          memoDate = (memo['timestamp'] as Timestamp).toDate();
        } else if (memo['timestamp'] is String) {
          // Try multiple parsing formats
          try {
            memoDate = DateTime.parse(memo['timestamp']);
          } catch (e) {
            try {
              // Custom format parsing if needed
              memoDate = DateFormat('yyyy-MM-dd').parse(memo['timestamp']);
            } catch (e) {
              return false;
            }
          }
        } else {
          return false;
        }

        switch (filterType) {
          case 'Day':
            return isSameDay(memoDate, selectedDate);
          case 'Month':
            return memoDate.year == selectedDate.year &&
                memoDate.month == selectedDate.month;
          case 'Year':
            return memoDate.year == selectedDate.year;
          default:
            return true;
        }
      } catch (e) {
        print('Date parsing error: $e');
        return false;
      }
    }).toList();
  }

  // Check if two dates are on the same day
  bool isSameDay(DateTime date1, DateTime date2) {
    return date1.year == date2.year &&
        date1.month == date2.month &&
        date1.day == date2.day;
  }

  // Calculate approval data
  List<_ChartData> _calculateApprovalData(List<Map<String, dynamic>> memos) {
    Map<String, int> approvalCounts = {};

    for (var memo in memos) {
      if (memo['approvedBy'] is List) {
        for (var approval in memo['approvedBy']) {
          String userType = approval['userType'] ?? 'Unknown';
          approvalCounts[userType] = (approvalCounts[userType] ?? 0) + 1;
        }
      }
    }

    return approvalCounts.entries
        .map((entry) => _ChartData(entry.key, entry.value))
        .toList();
  }

  // Calculate department breakdown
  List<_ChartData> _calculateDepartmentData(List<Map<String, dynamic>> memos) {
    Map<String, int> departmentCounts = {};

    for (var memo in memos) {
      String department = memo['department'] ?? 'Unspecified';
      departmentCounts[department] = (departmentCounts[department] ?? 0) + 1;
    }

    return departmentCounts.entries
        .map((entry) => _ChartData(entry.key, entry.value))
        .toList();
  }

  // Calculate block breakdown
  List<_ChartData> _calculateBlockData(List<Map<String, dynamic>> memos) {
    Map<String, int> blockCounts = {};

    for (var memo in memos) {
      String blockName = memo['blockName'] ??
          'Unspecified'; // Default to 'Unspecified' if missing
      blockCounts[blockName] = (blockCounts[blockName] ?? 0) + 1;
    }

    return blockCounts.entries
        .map((entry) => _ChartData(entry.key, entry.value))
        .toList();
  }

  // Calculate worker breakdown
  List<_ChartData> _calculateworkerData(List<Map<String, dynamic>> memos) {
    Map<String, int> workerCounts = {};

    for (var memo in memos) {
      String workerType = memo['workerType'] ??
          'Unspecified'; // Default to 'Unspecified' if missing
      workerCounts[workerType] = (workerCounts[workerType] ?? 0) + 1;
    }

    return workerCounts.entries
        .map((entry) => _ChartData(entry.key, entry.value))
        .toList();
  }

// Calculate status breakdown
// Calculate status data
  List<_ChartData> _calculatestatusData(List<Map<String, dynamic>> memos) {
    Map<String, int> statusCounts = {};

    for (var memo in memos) {
      String workerType = memo['workerType'] ?? 'Unspecified';
      String status = memo['status'] ?? 'Unspecified';

      if (_statusFilter == 'Total Memos' || _statusFilter == workerType) {
        statusCounts[status] = (statusCounts[status] ?? 0) + 1;
      }
    }

    return statusCounts.entries
        .map((entry) => _ChartData(entry.key, entry.value))
        .toList();
  }

  // Date picker for filtering
  Future<void> _selectDate(BuildContext context) async {
    DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );

    if (pickedDate != null) {
      setState(() {
        _selectedDate = pickedDate;
      });
    }
  }

  // Navigate to next visualization
  void _nextVisualization() {
    setState(() {
      _currentVisualizationIndex =
          (_currentVisualizationIndex + 1) % _visualizationTypes.length;
    });
  }

  // Navigate to previous visualization
  void _previousVisualization() {
    setState(() {
      _currentVisualizationIndex =
          (_currentVisualizationIndex - 1 + _visualizationTypes.length) %
              _visualizationTypes.length;
    });
  }

  // Updated build method to include chart type selection
  @override
  Widget build(BuildContext context) {
    // Get the screen width and height
    double screenWidth = MediaQuery.of(context).size.width;

    return Column(
      children: [
        // Filter controls row
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Filter type dropdown
            SizedBox(
              width: screenWidth * 0.4, // Adjust width based on screen size
              child: DropdownButton<String>(
                value: _filterType,
                dropdownColor: Colors.white,
                items: ['Day', 'Month', 'Year']
                    .map((type) => DropdownMenuItem(
                          value: type,
                          child: Text(type),
                        ))
                    .toList(),
                onChanged: (String? newValue) {
                  if (newValue != null) {
                    setState(() {
                      _filterType = newValue;
                      _selectedDate = null;
                    });
                  }
                },
              ),
            ),
            // Date selection button
            SizedBox(
              width: screenWidth * 0.4, // Adjust width based on screen size
              child: TextButton(
                onPressed: () => _selectDate(context),
                child: Text(
                  _selectedDate == null
                      ? 'Select Date'
                      : DateFormat('yyyy-MM-dd').format(_selectedDate!),
                  style: TextStyle(
                      fontSize: screenWidth * 0.05), // Adjust font size
                ),
              ),
            ),
          ],
        ),

        // Chart type selection row
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('Chart Type: '),
            SizedBox(
              width: screenWidth * 0.4, // Adjust width based on screen size
              child: DropdownButton<String>(
                value: _chartType,
                dropdownColor: Colors.white,
                items: _chartTypes
                    .map((type) => DropdownMenuItem(
                          value: type,
                          child: Text(type),
                        ))
                    .toList(),
                onChanged: (String? newValue) {
                  if (newValue != null) {
                    setState(() {
                      _chartType = newValue;
                    });
                  }
                },
              ),
            ),
          ],
        ),

        // Memo Status dropdown (only for Memo Status visualization)
        if (_visualizationTypes[_currentVisualizationIndex] == 'Memo Status')
          Padding(
            padding: EdgeInsets.symmetric(vertical: 8.0),
            child: DropdownButton<String>(
              value: _statusFilter,
              dropdownColor: Colors.white,
              items: _statusFilters.map((filter) {
                return DropdownMenuItem<String>(
                  value: filter,
                  child: Text(filter),
                );
              }).toList(),
              onChanged: (String? newValue) {
                if (newValue != null) {
                  setState(() {
                    _statusFilter = newValue;
                  });
                }
              },
            ),
          ),

        // Visualization navigation
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: _previousVisualization,
            ),
            Text(
              _visualizationTypes[_currentVisualizationIndex],
              style:
                  TextStyle(fontSize: screenWidth * 0.05), // Adjust font size
            ),
            IconButton(
              icon: const Icon(Icons.arrow_forward),
              onPressed: _nextVisualization,
            ),
          ],
        ),

        // Visualizations
        Expanded(
          child: FutureBuilder<List<Map<String, dynamic>>>(
            future: _fetchMemoData(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              if (!snapshot.hasData || snapshot.data!.isEmpty) {
                return const Center(
                  child: Text(
                    'No data available',
                    style: TextStyle(fontSize: 18),
                  ),
                );
              }

              // Filter the data
              List<Map<String, dynamic>> filteredMemos =
                  _filterDataByTimePeriod(
                      snapshot.data!, _filterType, _selectedDate);

              // Choose visualization based on current index
              List<_ChartData> chartData;
              String chartTitle;

              switch (_visualizationTypes[_currentVisualizationIndex]) {
                case 'Approver Distribution':
                  chartData = _calculateApprovalData(filteredMemos);
                  chartTitle = 'Approver Distribution';
                  break;
                case 'Department Breakdown':
                  chartData = _calculateDepartmentData(filteredMemos);
                  chartTitle = 'Memos by Department';
                  break;
                case 'Block Breakdown':
                  chartData = _calculateBlockData(filteredMemos);
                  chartTitle = 'Memos by Block';
                  break;
                case 'Worker Types':
                  chartData = _calculateworkerData(filteredMemos);
                  chartTitle = 'Memos to Worker Type';
                  break;
                case 'Memo Status':
                  chartData = _calculatestatusData(filteredMemos);
                  chartTitle = 'Memos Status';
                  break;
                default:
                  chartData = [];
                  chartTitle = 'No Data';
              }

              // Handle empty data
              if (chartData.isEmpty) {
                return Center(
                  child: Text(
                    'No data for ${_visualizationTypes[_currentVisualizationIndex]}',
                    style: const TextStyle(fontSize: 18),
                  ),
                );
              }

              // Render appropriate chart based on selected type
              return _buildChart(chartTitle, chartData, _chartType);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildChart(String title, List<_ChartData> data, String chartType) {
    // Define a palette of light colors
    final List<Color> lightColors = [
      const Color.fromARGB(255, 103, 250, 103), // Light Green
      const Color.fromARGB(255, 247, 90, 90), // Light Red
      const Color.fromARGB(255, 250, 250, 122), // Light Yellow
      const Color.fromARGB(255, 253, 180, 131), // Light Orange
      const Color.fromARGB(255, 136, 195, 255), // Light Blue
      const Color.fromARGB(255, 255, 132, 91), // Light Brown
    ];

    // Get screen width and height for responsive sizing
    double screenWidth = MediaQuery.of(context).size.width;
    double screenHeight = MediaQuery.of(context).size.height;
    double fontSize =
        screenWidth * 0.04; // Adjust font size based on screen width
    double labelFontSize = screenWidth * 0.03; // Smaller font for axis labels

    // Common chart title and legend styles
    ChartTitle chartTitle = ChartTitle(
      text: title,
      textStyle: TextStyle(
        fontSize: fontSize, // Adjust title font size based on screen width
        fontWeight: FontWeight.bold,
        color: Colors.blue,
      ),
    );

    Legend legend = Legend(
      isVisible: true,
      overflowMode: LegendItemOverflowMode.wrap,
      textStyle: TextStyle(fontSize: fontSize), // Adjust legend font size
    );

    // Chart type-specific rendering
    switch (chartType) {
      case 'Pie':
        return SfCircularChart(
          title: chartTitle,
          legend: legend,
          series: <PieSeries<_ChartData, String>>[
            PieSeries<_ChartData, String>(
              dataSource: data,
              xValueMapper: (_ChartData data, _) => data.category,
              yValueMapper: (_ChartData data, _) => data.value,
              pointColorMapper: (_ChartData data, int index) =>
                  lightColors[index % lightColors.length],
              dataLabelSettings: DataLabelSettings(
                isVisible: true,
                textStyle:
                    TextStyle(fontSize: fontSize), // Adjust label font size
              ),
            )
          ],
        );

      case 'Doughnut':
        return SfCircularChart(
          title: chartTitle,
          legend: legend,
          series: <DoughnutSeries<_ChartData, String>>[
            DoughnutSeries<_ChartData, String>(
              dataSource: data,
              xValueMapper: (_ChartData data, _) => data.category,
              yValueMapper: (_ChartData data, _) => data.value,
              pointColorMapper: (_ChartData data, int index) =>
                  lightColors[index % lightColors.length],
              dataLabelSettings: DataLabelSettings(
                isVisible: true,
                textStyle:
                    TextStyle(fontSize: fontSize), // Adjust label font size
              ),
            )
          ],
        );

      case 'Bar':
        return SfCartesianChart(
          title: chartTitle,
          primaryXAxis: CategoryAxis(
            labelIntersectAction: AxisLabelIntersectAction.rotate90,
            labelStyle: TextStyle(
                fontSize: labelFontSize), // Smaller font for axis labels
          ),
          primaryYAxis: NumericAxis(
            labelStyle: TextStyle(
                fontSize: fontSize), // Adjust font size for axis labels
          ),
          legend: legend,
          series: <ColumnSeries<_ChartData, String>>[
            ColumnSeries<_ChartData, String>(
              dataSource: data,
              xValueMapper: (_ChartData data, _) => data.category,
              yValueMapper: (_ChartData data, _) => data.value,
              pointColorMapper: (_ChartData data, int index) =>
                  lightColors[index % lightColors.length],
              dataLabelSettings: DataLabelSettings(
                isVisible: true,
                textStyle:
                    TextStyle(fontSize: fontSize), // Adjust label font size
              ),
            )
          ],
        );

      case 'Line':
        return SfCartesianChart(
          title: chartTitle,
          primaryXAxis: CategoryAxis(
            labelIntersectAction: AxisLabelIntersectAction.rotate90,
            labelStyle: TextStyle(
                fontSize: labelFontSize), // Smaller font for axis labels
          ),
          primaryYAxis: NumericAxis(
            labelStyle: TextStyle(
                fontSize: fontSize), // Adjust font size for axis labels
          ),
          legend: legend,
          series: <LineSeries<_ChartData, String>>[
            LineSeries<_ChartData, String>(
              dataSource: data,
              xValueMapper: (_ChartData data, _) => data.category,
              yValueMapper: (_ChartData data, _) => data.value,
              color: lightColors[0], // Use the first color in the palette
              markerSettings: MarkerSettings(isVisible: true),
              dataLabelSettings: DataLabelSettings(
                isVisible: true,
                textStyle:
                    TextStyle(fontSize: fontSize), // Adjust label font size
              ),
            )
          ],
        );

      case 'Funnel':
        return SfFunnelChart(
          title: chartTitle,
          legend: legend,
          series: FunnelSeries<_ChartData, String>(
            dataSource: data,
            xValueMapper: (_ChartData data, _) => data.category,
            yValueMapper: (_ChartData data, _) => data.value,
            pointColorMapper: (_ChartData data, int index) =>
                lightColors[index % lightColors.length],
            dataLabelSettings: DataLabelSettings(
              isVisible: true,
              textStyle: TextStyle(fontSize: fontSize),
            ),
          ),
        );

      default:
        return const Center(child: Text('Unsupported chart type'));
    }
  }

  /*// Helper method to go to next visualization
  void _nextVisualization() {
    setState(() {
      _currentVisualizationIndex =
          (_currentVisualizationIndex + 1) % _visualizationTypes.length;
    });
  }

  // Helper method to go to previous visualization
  void _previousVisualization() {
    setState(() {
      _currentVisualizationIndex =
          (_currentVisualizationIndex - 1 + _visualizationTypes.length) %
              _visualizationTypes.length;
    });
  }

  // Date picker for filtering
  Future<void> _selectDate(BuildContext context) async {
    DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );

    if (pickedDate != null) {
      setState(() {
        _selectedDate = pickedDate;
      });
    }
  } */

  // Existing data calculation methods remain the same
  // _fetchMemoData(), _filterDataByTimePeriod(), etc.
}

// Helper class for chart data
class _ChartData {
  final String category;
  final int value;

  _ChartData(this.category, this.value);
}
