import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

class InspectionScreen extends StatefulWidget {
  const InspectionScreen({super.key});

  @override
  _InspectionScreenState createState() => _InspectionScreenState();
}

class _InspectionScreenState extends State<InspectionScreen> {
  // Vehicle selection state variable
  String selectedVehicleType = 'Motorcycle';

  // Checkboxes state variables
  bool isSideMirrorChecked = false;
  bool isSignalLightsChecked = false;
  bool isTaillightsChecked = false;
  bool isMotorNumberChecked = false;
  bool isGarbageCanChecked = false;
  bool isChassisNumberChecked = false;
  bool isVehicleRegistrationChecked = false;
  bool isNotOpenPipeChecked = false;
  bool isLightInSidecarChecked = false;

  bool isNewRegistration = true;
  String inspectorId = ''; // Inspector ID fetched from the server

  // Controllers for text fields
  final TextEditingController _applicantNameController = TextEditingController();
  final TextEditingController _mtopIdController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Call login function to fetch inspectorId when the screen initializes
    login('email@example.com', 'password123');
  }

  Future<void> login(String email, String password) async {
    final response = await http.post(
      Uri.parse('http://192.168.5.122:3000/login'),  // Replace with actual IP address if necessary
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
      },
      body: jsonEncode(<String, String>{
        'email': email,
        'password': password,
      }),
    );

    // Print the response body to debug
    print('Response body: ${response.body}');

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      setState(() {
        inspectorId = data['user']['id'].toString();  // Make sure 'id' matches your JSON structure
      });
    } else {
      // Handle errors or unsuccessful login attempts
      print('Failed to log in with status code: ${response.statusCode}');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Vehicle Inspection'),
        backgroundColor: Colors.blue,
      ),
      body: Column(
        children: [
          const SizedBox(height: 20), // Top padding

          // Inspector ID Section
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      'Inspector ID: $inspectorId', // Display Inspector ID
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // New or Renewal Button Section
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton(
                  onPressed: () {
                    setState(() {
                      isNewRegistration = true;
                    });
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isNewRegistration ? Colors.blue : Colors.grey.shade300,
                    padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                  ),
                  child: Text(
                    'New',
                    style: TextStyle(color: isNewRegistration ? Colors.white : Colors.black87),
                  ),
                ),
                ElevatedButton(
                  onPressed: () {
                    setState(() {
                      isNewRegistration = false;
                    });
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: !isNewRegistration ? Colors.blue : Colors.grey.shade300,
                    padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                  ),
                  child: Text(
                    'Renewal',
                    style: TextStyle(color: !isNewRegistration ? Colors.white : Colors.black87),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // Applicant Name and MTOP ID Input Fields
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Applicant Name:",
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                TextFormField(
                  controller: _applicantNameController,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    hintText: 'Enter applicant name',
                  ),
                ),

                const SizedBox(height: 20),

                const Text(
                  "MTOP ID:",
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                TextFormField(
                  controller: _mtopIdController,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    hintText: 'Enter MTOP ID',
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // Types of Vehicle Section inside a box
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Container(
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey),
                borderRadius: BorderRadius.circular(10),
              ),
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Types of Vehicle:",
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  RadioListTile<String>(
                    title: const Text("Motorcycle"),
                    value: 'Motorcycle',
                    groupValue: selectedVehicleType,
                    onChanged: (String? value) {
                      setState(() {
                        selectedVehicleType = value!;
                      });
                    },
                  ),
                  RadioListTile<String>(
                    title: const Text("E-trike"),
                    value: 'E-trike',
                    groupValue: selectedVehicleType,
                    onChanged: (String? value) {
                      setState(() {
                        selectedVehicleType = value!;
                      });
                    },
                  ),
                  RadioListTile<String>(
                    title: const Text("Tricycle"),
                    value: 'Tricycle',
                    groupValue: selectedVehicleType,
                    onChanged: (String? value) {
                      setState(() {
                        selectedVehicleType = value!;
                      });
                    },
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 20),

          // List of Requirements Section
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: ListView(
                children: [
                  ListTile(
                    title: const Text("Side Mirror"),
                    trailing: Checkbox(
                      value: isSideMirrorChecked,
                      onChanged: (bool? value) {
                        setState(() {
                          isSideMirrorChecked = value ?? false;
                        });
                      },
                    ),
                  ),
                  ListTile(
                    title: const Text("Signal Light Headlights"),
                    trailing: Checkbox(
                      value: isSignalLightsChecked,
                      onChanged: (bool? value) {
                        setState(() {
                          isSignalLightsChecked = value ?? false;
                        });
                      },
                    ),
                  ),
                  ListTile(
                    title: const Text("Taillights"),
                    trailing: Checkbox(
                      value: isTaillightsChecked,
                      onChanged: (bool? value) {
                        setState(() {
                          isTaillightsChecked = value ?? false;
                        });
                      },
                    ),
                  ),
                  ListTile(
                    title: const Text("Motor Number"),
                    trailing: Checkbox(
                      value: isMotorNumberChecked,
                      onChanged: (bool? value) {
                        setState(() {
                          isMotorNumberChecked = value ?? false;
                        });
                      },
                    ),
                  ),
                  ListTile(
                    title: const Text("Garbage Can"),
                    trailing: Checkbox(
                      value: isGarbageCanChecked,
                      onChanged: (bool? value) {
                        setState(() {
                          isGarbageCanChecked = value ?? false;
                        });
                      },
                    ),
                  ),
                  ListTile(
                    title: const Text("Chassis Number"),
                    trailing: Checkbox(
                      value: isChassisNumberChecked,
                      onChanged: (bool? value) {
                        setState(() {
                          isChassisNumberChecked = value ?? false;
                        });
                      },
                    ),
                  ),
                  ListTile(
                    title: const Text("Vehicle Registration Form"),
                    trailing: Checkbox(
                      value: isVehicleRegistrationChecked,
                      onChanged: (bool? value) {
                        setState(() {
                          isVehicleRegistrationChecked = value ?? false;
                        });
                      },
                    ),
                  ),
                  ListTile(
                    title: const Text("Not Open Pipe"),
                    trailing: Checkbox(
                      value: isNotOpenPipeChecked,
                      onChanged: (bool? value) {
                        setState(() {
                          isNotOpenPipeChecked = value ?? false;
                        });
                      },
                    ),
                  ),
                  ListTile(
                    title: const Text("Light in the Sidecar"),
                    trailing: Checkbox(
                      value: isLightInSidecarChecked,
                      onChanged: (bool? value) {
                        setState(() {
                          isLightInSidecarChecked = value ?? false;
                        });
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Action Buttons (Clear, Reject, Approve)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton(
                  onPressed: () {
                    // Clear action
                    setState(() {
                      selectedVehicleType = 'Motorcycle';
                      isSideMirrorChecked = false;
                      isSignalLightsChecked = false;
                      isTaillightsChecked = false;
                      isMotorNumberChecked = false;
                      isGarbageCanChecked = false;
                      isChassisNumberChecked = false;
                      isVehicleRegistrationChecked = false;
                      isNotOpenPipeChecked = false;
                      isLightInSidecarChecked = false;
                      
                      // Clear text fields
                      _applicantNameController.clear();
                      _mtopIdController.clear();
                    });
                  },
                  child: const Text('Clear'),
                ),
                ElevatedButton(
                  onPressed: () {
                    // Reject action
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red, // Set background to red for reject
                  ),
                  child: const Text('Reject'),
                ),
                ElevatedButton(
                  onPressed: () {
                    // Approve action
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green, // Set background to green for approve
                  ),
                  child: const Text('Approve'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
