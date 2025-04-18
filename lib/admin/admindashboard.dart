import 'package:flutter/material.dart';
import 'raw_data_tab.dart'; // Raw Data class
import 'visualization_tab.dart'; // Visualization class

class Dashboard extends StatefulWidget {
  @override
  _DashboardState createState() => _DashboardState();
}

class _DashboardState extends State<Dashboard> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(text: 'Raw Data'),
            Tab(text: 'Visualization'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          RawDataTab(), // Raw Data content class
          VisualizationTab(), // Visualization content class
        ],
      ),
    );
  }
}
