import 'package:flutter/material.dart';
import 'package:login_signup/screens/inspection.dart';
import 'package:login_signup/screens/scandocu.dart';

class DashboardScreen extends StatelessWidget {
  final String name;

  const DashboardScreen({super.key, required this.name});

  @override
  Widget build(BuildContext context) {
    // Get the current time
    final currentTime = DateTime.now();
    final start = DateTime(currentTime.year, currentTime.month, currentTime.day, 8, 0);
    final end = DateTime(currentTime.year, currentTime.month, currentTime.day, 17, 0);

    // Determine whether to show the red dot
    bool showRedDot = currentTime.isAfter(start) && currentTime.isBefore(end);

    return Scaffold(
      body: Column(
        children: [
          // Blue header with logout button, title, and notification icon
          Container(
            color: Colors.blue, // Blue background for the header
            padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 20.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Logout button
                IconButton(
                  icon: Icon(Icons.logout, color: Colors.white),
                  onPressed: () {
                    // Show logout confirmation dialog
                    showDialog(
                      context: context,
                      builder: (BuildContext context) {
                        return AlertDialog(
                          title: const Text("Logout"),
                          content: const Text("Are you sure you want to log out?"),
                          actions: [
                            TextButton(
                              child: const Text("Cancel"),
                              onPressed: () {
                                Navigator.of(context).pop(); // Close the dialog
                              },
                            ),
                            TextButton(
                              child: const Text("Logout"),
                              onPressed: () {
                                Navigator.of(context).pop(); // Close the dialog
                                Navigator.of(context).pop(); // Navigate back to the login screen or previous screen
                              },
                            ),
                          ],
                        );
                      },
                    );
                  },
                ),
                // Dashboard title
                Text(
                  'Dashboard',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFFFFFFFF), // White text
                      ),
                ),
                // Notification icon with red dot if applicable
                Stack(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.notifications, color: Colors.white),
                      onPressed: () {
                        // Show dialog with message based on the time
                        String message = showRedDot
                            ? "There is an inspection today"
                            : "No inspection today";
                        showDialog(
                          context: context,
                          builder: (BuildContext context) {
                            return AlertDialog(
                              title: const Text("Notification"),
                              content: Text(message),
                              actions: [
                                TextButton(
                                  child: const Text("OK"),
                                  onPressed: () {
                                    Navigator.of(context).pop();
                                  },
                                ),
                              ],
                            );
                          },
                        );
                      },
                    ),
                    if (showRedDot)
                      Positioned(
                        right: 11,
                        top: 11,
                        child: Container(
                          padding: const EdgeInsets.all(2),
                          decoration: const BoxDecoration(
                            color: Colors.red,
                            shape: BoxShape.circle,
                          ),
                          constraints: const BoxConstraints(
                            minWidth: 8,
                            minHeight: 8,
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 20.0),

          // Greeting message inside a card for a more professional look
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 20.0),
            padding: const EdgeInsets.all(20.0),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(15.0),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 10.0,
                  spreadRadius: 2.0,
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                const Icon(
                  Icons.person_outline,
                  size: 40,
                  color: Colors.blueAccent,
                ),
                const SizedBox(width: 15),
                Expanded(
                  child: Text(
                    'Hi, $name! Welcome to the Dashboard.',
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20.0),

          // Dashboard Buttons
          Expanded(
            child: Row(
              children: [
                Expanded(
                  child: GridView.count(
                    padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 40.0),
                    crossAxisCount: 2, // Two buttons in a row
                    mainAxisSpacing: 20.0,
                    crossAxisSpacing: 20.0,
                    children: [
                      _buildDashboardButton(
                        icon: Icons.document_scanner,
                        label: 'Scan Documents',
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const ScanDocumentScreen(),
                            ),
                          );
                        },
                      ),
                      _buildDashboardButton(
                        icon: Icons.checklist_rounded,
                        label: 'Inspection',
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const InspectionScreen(),
                            ),
                          );
                        },
                      ),
                      _buildDashboardButton(
                        icon: Icons.analytics_outlined,
                        label: 'Reports',
                        onTap: () {
                          // Handle Reports action
                        },
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

  // Method to build each dashboard button
  Widget _buildDashboardButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(15.0),
          boxShadow: [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 5.0,
              spreadRadius: 1.0,
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 50.0,
              color: Colors.black54,
            ),
            const SizedBox(height: 10.0),
            Text(
              label,
              style: const TextStyle(
                fontSize: 16.0,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
