import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

class ReportsScreen extends StatefulWidget {
  final String inspectorId;

  const ReportsScreen({super.key, required this.inspectorId});

  @override
  _ReportsScreenState createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  int totalInspections = 0;
  String commonReasonNotApproved = '';

  @override
  void initState() {
    super.initState();
    fetchReportsData();
  }

  Future<void> fetchReportsData() async {
    try {
      final response = await http.get(Uri.parse('http://192.168.1.3:3000/reports'));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          totalInspections = data['totalInspections'];
          commonReasonNotApproved = data['commonReasonNotApproved'] ?? 'None';
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
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildReportCard(
              title: 'Total Inspections',
              value: totalInspections.toString(),
            ),
            _buildReportCard(
              title: 'Common Reason for Not Approved',
              value: commonReasonNotApproved.isEmpty ? 'None' : commonReasonNotApproved,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReportCard({required String title, required String value}) {
    return Card(
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
}
