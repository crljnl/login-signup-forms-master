import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

class InspectionScreen extends StatefulWidget {
  final String loggedInInspectorId; // Add the logged-in inspector ID

  const InspectionScreen({super.key, required this.loggedInInspectorId});

  @override
  _InspectionScreenState createState() => _InspectionScreenState();
}

class _InspectionScreenState extends State<InspectionScreen> {
  List<String> validInspectorIds = [];

  // Default values
  String selectedVehicleType = 'Motorcycle';
  String selectedRegistrationType = 'New';

  bool isMtopIdAvailable = true; // Flag to check if MTOP ID is available for New registrations
  bool isMtopIdValidForRenewal = false; // Flag to check if MTOP ID is valid for Renewal
  bool isMtopIdEditable = true; // Flag to allow or prevent MTOP ID editing in Renewal

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

  // Controllers for text fields
  final TextEditingController _applicantNameController = TextEditingController();
  final TextEditingController _mtopIdController = TextEditingController();
  final TextEditingController _inspectorIdController = TextEditingController();

  // Fetch valid inspector IDs
  Future<void> fetchInspectorIds() async {
    final response = await http.get(
      Uri.parse('http://192.168.1.14:3000/inspectors'),
    );

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      setState(() {
        validInspectorIds = data.map((e) => e['inspector_id'].toString()).toList();
      });
    } else {
      print('Failed to fetch inspector IDs with status code: ${response.statusCode}');
    }
  }

  // Check if MTOP ID exists for new registrations
  Future<void> checkMtopIdAvailability(String mtopId) async {
    final response = await http.get(
      Uri.parse('http://192.168.1.14:3000/inspection/$mtopId'),
    );

    if (response.statusCode == 200) {
      setState(() {
        isMtopIdAvailable = false; // MTOP ID already exists in the database
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('MTOP ID already exists, choose another for new registration'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 2),
          ),
        );
      });
    } else {
      setState(() {
        isMtopIdAvailable = true; // MTOP ID is available for new registration
      });
    }
  }

  // Fetch inspection details for renewal
  Future<void> fetchInspectionDetails(String mtopId) async {
    final response = await http.get(
      Uri.parse('http://192.168.1.14:3000/inspection/$mtopId'),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      setState(() {
        // Populate form fields with existing data for renewals
        _applicantNameController.text = data['applicant_name'];
        isSideMirrorChecked = data['side_mirror'];
        isSignalLightsChecked = data['signal_lights'];
        isTaillightsChecked = data['taillights'];
        isMotorNumberChecked = data['motor_number'];
        isGarbageCanChecked = data['garbage_can'];
        isChassisNumberChecked = data['chassis_number'];
        isVehicleRegistrationChecked = data['vehicle_registration'];
        isNotOpenPipeChecked = data['not_open_pipe'];
        isLightInSidecarChecked = data['light_in_sidecar'];
        isMtopIdValidForRenewal = true; // Valid MTOP ID for renewal
        isMtopIdEditable = false; // Prevent further editing of MTOP ID
      });
    } else {
      setState(() {
        isMtopIdValidForRenewal = false; // Invalid MTOP ID for renewal
        isMtopIdEditable = true; // Allow editing in case of invalid MTOP ID
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('MTOP ID not found, invalid for renewal'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 2),
          ),
        );
      });
    }
  }

  @override
  void initState() {
    super.initState();
    fetchInspectorIds(); // Fetch inspector IDs on initialization
  }

  // Submitting the inspection form data to the backend
  Future<void> submitInspection() async {
    final response = await http.post(
      Uri.parse('http://192.168.1.14:3000/add-inspection'),
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
      },
      body: jsonEncode({
        'inspector_id': _inspectorIdController.text,
        'applicant_name': _applicantNameController.text,
        'mtop_id': _mtopIdController.text,
        'vehicle_type': selectedVehicleType,
        'registration_type': selectedRegistrationType,
        'side_mirror': isSideMirrorChecked,
        'signal_lights': isSignalLightsChecked,
        'taillights': isTaillightsChecked,
        'motor_number': isMotorNumberChecked,
        'garbage_can': isGarbageCanChecked,
        'chassis_number': isChassisNumberChecked,
        'vehicle_registration': isVehicleRegistrationChecked,
        'not_open_pipe': isNotOpenPipeChecked,
        'light_in_sidecar': isLightInSidecarChecked,
      }),
    );

    if (response.statusCode == 200) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Inspection submitted successfully!'),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 2),
        ),
      );

      // Clear all fields for both New and Renewal submissions
      setState(() {
        _applicantNameController.clear();
        _mtopIdController.clear();
        _inspectorIdController.clear();
        selectedVehicleType = 'Motorcycle';
        selectedRegistrationType = 'New';

        // Clear checklist fields
        isSideMirrorChecked = false;
        isSignalLightsChecked = false;
        isTaillightsChecked = false;
        isMotorNumberChecked = false;
        isGarbageCanChecked = false;
        isChassisNumberChecked = false;
        isVehicleRegistrationChecked = false;
        isNotOpenPipeChecked = false;
        isLightInSidecarChecked = false;
        isMtopIdAvailable = true;
        isMtopIdValidForRenewal = false;
        isMtopIdEditable = true; // Reset MTOP ID editable state
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Failed to submit inspection.'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 2),
        ),
      );
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

          // Registration Type Dropdown
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Select Registration Type:'),
                DropdownButton<String>(
                  value: selectedRegistrationType,
                  items: const [
                    DropdownMenuItem(value: 'New', child: Text('New')),
                    DropdownMenuItem(value: 'Renewal', child: Text('Renewal')),
                  ],
                  onChanged: (value) {
                    setState(() {
                      selectedRegistrationType = value!;
                      if (value == 'New') {
                        // Clear the form if the user switches to "New"
                        _applicantNameController.clear();
                        _mtopIdController.clear();
                        isSideMirrorChecked = false;
                        isSignalLightsChecked = false;
                        isTaillightsChecked = false;
                        isMotorNumberChecked = false;
                        isGarbageCanChecked = false;
                        isChassisNumberChecked = false;
                        isVehicleRegistrationChecked = false;
                        isNotOpenPipeChecked = false;
                        isLightInSidecarChecked = false;
                        isMtopIdAvailable = true;
                        isMtopIdValidForRenewal = false;
                        isMtopIdEditable = true; // Allow editing MTOP ID
                      } else {
                        // Reset availability flags when switching to "Renewal"
                        isMtopIdAvailable = true;
                        isMtopIdValidForRenewal = false;
                        isMtopIdEditable = true; // Allow editing until fetched
                        _mtopIdController.clear();
                      }
                    });
                  },
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // Inspector ID Input Section
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: _inspectorIdController,
                  decoration: InputDecoration(
                    labelText: 'Enter Inspector ID',
                    errorText: _inspectorIdController.text.isNotEmpty &&
                            !validInspectorIds.contains(_inspectorIdController.text)
                        ? 'Invalid Inspector ID'
                        : null,
                  ),
                  onChanged: (value) {
                    // Logic to handle Inspector ID change if needed
                  },
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // Form Fields
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: ListView(
                children: [
                  TextField(
                    controller: _applicantNameController,
                    decoration: const InputDecoration(
                      labelText: 'Applicant Name',
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: _mtopIdController,
                    decoration: const InputDecoration(
                      labelText: 'MTOP ID',
                    ),
                    enabled: selectedRegistrationType == 'Renewal'
                        ? isMtopIdEditable
                        : true, // Disable MTOP ID field if it's in renewal mode and fetched
                    onChanged: (value) {
                      if (selectedRegistrationType == 'New') {
                        // If New, enforce 6-character limit and prompt if exceeded
                        if (value.length > 6) {
                          setState(() {
                            // Trim the value to 6 characters
                            _mtopIdController.text = value.substring(0, 6);
                            _mtopIdController.selection = TextSelection.fromPosition(
                              TextPosition(offset: _mtopIdController.text.length),
                            );
                          });
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('MTOP ID cannot exceed 6 characters'),
                              backgroundColor: Colors.red,
                              duration: Duration(seconds: 2),
                            ),
                          );
                        } else if (value.length == 6) {
                          // When 6 characters are entered, check availability
                          checkMtopIdAvailability(value);
                        }
                      } else if (selectedRegistrationType == 'Renewal' && value.length == 6) {
                        if (isMtopIdEditable) {
                          fetchInspectionDetails(value); // Fetch inspection details for renewal
                        } else {
                          // If the MTOP ID is being changed after it's set, show error
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('You cannot change the MTOP ID for renewal.'),
                              backgroundColor: Colors.red,
                              duration: Duration(seconds: 2),
                            ),
                          );
                        }
                      }
                    },
                  ),
                  const SizedBox(height: 10),

                  // Vehicle Type Dropdown
                  DropdownButton<String>(
                    value: selectedVehicleType,
                    items: const [
                      DropdownMenuItem(value: 'Motorcycle', child: Text('Motorcycle')),
                      DropdownMenuItem(value: 'Tricycle', child: Text('Tricycle')),
                      DropdownMenuItem(value: 'Etrike', child: Text('Etrike')),
                    ],
                    onChanged: (value) {
                      setState(() {
                        selectedVehicleType = value!;
                      });
                    },
                  ),

                  const SizedBox(height: 20),

                  // Checklist of Vehicle Requirements
                  CheckboxListTile(
                    title: const Text('Side Mirror'),
                    value: isSideMirrorChecked,
                    onChanged: (bool? value) {
                      setState(() {
                        isSideMirrorChecked = value!;
                      });
                    },
                  ),
                  CheckboxListTile(
                    title: const Text('Signal Lights'),
                    value: isSignalLightsChecked,
                    onChanged: (bool? value) {
                      setState(() {
                        isSignalLightsChecked = value!;
                      });
                    },
                  ),
                  CheckboxListTile(
                    title: const Text('Taillights'),
                    value: isTaillightsChecked,
                    onChanged: (bool? value) {
                      setState(() {
                        isTaillightsChecked = value!;
                      });
                    },
                  ),
                  CheckboxListTile(
                    title: const Text('Motor Number'),
                    value: isMotorNumberChecked,
                    onChanged: (bool? value) {
                      setState(() {
                        isMotorNumberChecked = value!;
                      });
                    },
                  ),
                  CheckboxListTile(
                    title: const Text('Garbage Can'),
                    value: isGarbageCanChecked,
                    onChanged: (bool? value) {
                      setState(() {
                        isGarbageCanChecked = value!;
                      });
                    },
                  ),
                  CheckboxListTile(
                    title: const Text('Chassis Number'),
                    value: isChassisNumberChecked,
                    onChanged: (bool? value) {
                      setState(() {
                        isChassisNumberChecked = value!;
                      });
                    },
                  ),
                  CheckboxListTile(
                    title: const Text('Vehicle Registration'),
                    value: isVehicleRegistrationChecked,
                    onChanged: (bool? value) {
                      setState(() {
                        isVehicleRegistrationChecked = value!;
                      });
                    },
                  ),
                  CheckboxListTile(
                    title: const Text('Not Open Pipe'),
                    value: isNotOpenPipeChecked,
                    onChanged: (bool? value) {
                      setState(() {
                        isNotOpenPipeChecked = value!;
                      });
                    },
                  ),
                  CheckboxListTile(
                    title: const Text('Light in Sidecar'),
                    value: isLightInSidecarChecked,
                    onChanged: (bool? value) {
                      setState(() {
                        isLightInSidecarChecked = value!;
                      });
                    },
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 20),

          // Submit Button with validation logic for "New" registration
          ElevatedButton(
            onPressed: selectedRegistrationType == 'New'
                ? isMtopIdAvailable && _mtopIdController.text.length == 6
                    ? () {
                        if (_applicantNameController.text.isNotEmpty) {
                          // Allow only the logged-in inspector to submit new registrations
                          if (_inspectorIdController.text == widget.loggedInInspectorId) {
                            submitInspection();
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Only the logged-in inspector can submit this form.'),
                                backgroundColor: Colors.red,
                                duration: Duration(seconds: 2),
                              ),
                            );
                          }
                        } else {
                          // Show warning if applicant's name is missing
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Applicant Name is required'),
                              backgroundColor: Colors.red,
                              duration: Duration(seconds: 2),
                            ),
                          );
                        }
                      }
                    : () {
                        // Show warning if MTOP ID is less than 6 characters
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('MTOP ID must be exactly 6 characters'),
                            backgroundColor: Colors.red,
                            duration: Duration(seconds: 2),
                          ),
                        );
                      }
                : isMtopIdValidForRenewal
                    ? () {
                        // No restrictions for renewal submissions
                        if (_inspectorIdController.text.isNotEmpty &&
                            validInspectorIds.contains(_inspectorIdController.text)) {
                          submitInspection();
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Invalid Inspector ID'),
                              backgroundColor: Colors.red,
                              duration: Duration(seconds: 2),
                            ),
                          );
                        }
                      }
                    : null, // Disable submit button if MTOP ID is invalid for renewal
            child: const Text('Submit Inspection'),
          ),

          const SizedBox(height: 20),
        ],
      ),
    );
  }
}
