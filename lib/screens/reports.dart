import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:fl_chart/fl_chart.dart';
import 'config.dart'; //

class ReportsScreen extends StatefulWidget {
  final String inspectorId;

  const ReportsScreen({super.key, required this.inspectorId});

  @override
  _ReportsScreenState createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  int totalInspections = 0;
  List<Map<String, dynamic>> mostCommonReasons = [];
  int approvedCount = 0;
  int notApprovedCount = 0;
  bool isLoading = true;
  List<Map<String, dynamic>> inspectionsData = [];

  @override
  void initState() {
    super.initState();
    fetchReportsData();
  }

  Future<void> fetchReportsData() async {
  try {
    // Use Config.serverIp for dynamic IP configuration
    final response = await http.get(Uri.parse('http://${Config.serverIp}:3000/reports'));

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      setState(() {
        totalInspections = data['totalInspections'];
        mostCommonReasons = List<Map<String, dynamic>>.from(data['mostCommonReasons']);
        approvedCount = data['approvedCount'] ?? 0;
        notApprovedCount = data['notApprovedCount'] ?? 0;
        isLoading = false;
      });
    } else {
      print('Failed to load report data');
    }
  } catch (error) {
    print('Error fetching report data: $error');
  }
}

Future<void> fetchInspectionsData() async {
  try {
    // Use Config.serverIp for dynamic IP configuration
    final response = await http.get(Uri.parse('http://${Config.serverIp}:3000/inspections'));

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      setState(() {
        inspectionsData = List<Map<String, dynamic>>.from(data['inspections']);
      });
    } else {
      print('Failed to load inspections data');
    }
  } catch (error) {
    print('Error fetching inspections data: $error');
  }
}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Reports'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: isLoading
            ? Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    GestureDetector(
                      onTap: () async {
                        await fetchInspectionsData();
                        _showInspectionsDialog();
                      },
                      child: _buildReportCard(
                        icon: Icons.list_alt_rounded,
                        iconColor: Colors.blue,
                        title: 'Total Inspections',
                        value: totalInspections.toString(),
                      ),
                    ),
                    _buildReportCard(
                      icon: Icons.warning_rounded,
                      iconColor: Colors.redAccent,
                      title: 'Most Common Reasons for Not Approved',
                      value: mostCommonReasons.isEmpty
                          ? 'None'
                          : mostCommonReasons
                              .map((reason) => "${reason['reason']} (${reason['count']})")
                              .join(', '),
                    ),
                    _buildPieChart(),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _buildReportCard({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String value,
  }) {
    return Card(
      elevation: 8,
      shadowColor: Colors.blueAccent.withOpacity(0.3),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15.0),
      ),
      margin: const EdgeInsets.only(bottom: 20),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CircleAvatar(
              radius: 25,
              backgroundColor: iconColor.withOpacity(0.2),
              child: Icon(icon, size: 30, color: iconColor),
            ),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    value,
                    style: const TextStyle(
                      fontSize: 16,
                      color: Colors.blue,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPieChart() {
    return Card(
      elevation: 8,
      shadowColor: Colors.blueAccent.withOpacity(0.3),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15.0)),
      margin: const EdgeInsets.only(bottom: 20),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Approved vs Not Approved',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            approvedCount + notApprovedCount > 0
                ? AspectRatio(
                    aspectRatio: 1.5,
                    child: PieChart(
                      PieChartData(
                        sections: [
                          PieChartSectionData(
                            color: Colors.black,
                            value: approvedCount.toDouble(),
                            title: approvedCount.toString(),
                            radius: 50,
                            titleStyle: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          PieChartSectionData(
                            color: Colors.white,
                            value: notApprovedCount.toDouble(),
                            title: notApprovedCount.toString(),
                            radius: 50,
                            titleStyle: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.black,
                            ),
                          ),
                        ],
                        borderData: FlBorderData(show: false),
                        sectionsSpace: 2,
                      ),
                    ),
                  )
                : Center(
                    child: const Text(
                      'No data available',
                      style: TextStyle(fontSize: 16, color: Colors.grey),
                    ),
                  ),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildLegendItem(Colors.black, 'Approved'),
                _buildLegendItem(Colors.white, 'Not Approved'),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLegendItem(Color color, String text) {
    return Row(
      children: [
        Container(
          width: 16,
          height: 16,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: color,
            border: color == Colors.white
                ? Border.all(color: Colors.black, width: 1)
                : null,
          ),
        ),
        const SizedBox(width: 5),
        Text(text),
      ],
    );
  }

void _showInspectionsDialog() {
  showDialog(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        title: const Text('Total Inspection List'),
        content: SizedBox(
          width: double.maxFinite,
          child: SingleChildScrollView( // This allows the content to scroll vertically
            child: SingleChildScrollView( // This allows the table to scroll horizontally
              scrollDirection: Axis.horizontal, // Scroll direction set to horizontal
              child: DataTable(
                columns: const [
                  DataColumn(label: Text('Applicant Name')),
                  DataColumn(label: Text('Inspection Status')),
                  DataColumn(label: Text('Reason Not Approved')),
                ],
                rows: inspectionsData.map((inspection) {
                  return DataRow(cells: [
                    DataCell(Text(inspection['applicant_name'] ?? '')),
                    DataCell(Text(inspection['inspection_status'] ?? '')),
                    DataCell(Text(inspection['reason_not_approved'] ?? '')),
                  ]);
                }).toList(),
              ),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
            child: const Text('Close'),
          ),
        ],
      );
    },
  );
}
}
