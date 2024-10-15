import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:fl_chart/fl_chart.dart';

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

  @override
  void initState() {
    super.initState();
    fetchReportsData();
  }

  Future<void> fetchReportsData() async {
    try {
      final response = await http.get(Uri.parse('http://192.168.1.2:3000/reports'));

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
            : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildReportCard(
                    title: 'Total Inspections',
                    value: totalInspections.toString(),
                  ),
                  _buildReportCard(
                    title: 'Most Common Reasons for Not Approved',
                    value: mostCommonReasons.isEmpty
                        ? 'None'
                        : mostCommonReasons.map((reason) => "${reason['reason']} (${reason['count']})").join(', '),
                  ),
                  _buildPieChart(),
                ],
              ),
      ),
    );
  }

  Widget _buildReportCard({required String title, required String value}) {
    return Card(
      elevation: 5,
      shadowColor: Colors.blueAccent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15.0)),
      margin: const EdgeInsets.only(bottom: 20),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            Text(
              value,
              style: const TextStyle(fontSize: 16, color: Colors.blue),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPieChart() {
    return Card(
      elevation: 5,
      shadowColor: Colors.blueAccent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15.0)),
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
                            color: Colors.green,
                            value: approvedCount.toDouble(),
                            title: approvedCount.toString(),
                            radius: 50,
                            titleStyle: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          PieChartSectionData(
                            color: Colors.red,
                            value: notApprovedCount.toDouble(),
                            title: notApprovedCount.toString(),
                            radius: 50,
                            titleStyle: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ],
                        borderData: FlBorderData(show: false),
                        sectionsSpace: 2,
                      ),
                    ),
                  )
                : Center(
                    child: Text(
                      'No data available',
                      style: TextStyle(fontSize: 16, color: Colors.grey),
                    ),
                  ),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildLegendItem(Colors.green, 'Approved'),
                _buildLegendItem(Colors.red, 'Not Approved'),
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
          ),
        ),
        const SizedBox(width: 5),
        Text(text),
      ],
    );
  }
}
