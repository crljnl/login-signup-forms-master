import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/services.dart';

class InspectionScreen extends StatefulWidget {
  final String loggedInInspectorId;

  const InspectionScreen({super.key, required this.loggedInInspectorId});

  @override
  _InspectionScreenState createState() => _InspectionScreenState();
}

class _InspectionScreenState extends State<InspectionScreen> {
  List<String> validInspectorIds = [];

  String selectedVehicleType = 'Motorcycle';
  String selectedRegistrationType = 'New';

  bool isMtopIdAvailable = true;
  bool isMtopIdValidForRenewal = false;
  bool isMtopIdEditable = true;

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

  final TextEditingController _applicantNameController = TextEditingController();
  final TextEditingController _mtopIdController = TextEditingController();
  final TextEditingController _inspectorIdController = TextEditingController();

  Future<void> fetchInspectorIds() async {
    final response = await http.get(
      Uri.parse('http://192.168.100.170:3000/inspectors'),
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

  Future<void> checkMtopIdAvailability(String mtopId) async {
    final response = await http.get(
      Uri.parse('http://192.168.100.170:3000/inspection/$mtopId'),
    );

    if (response.statusCode == 200) {
      setState(() {
        isMtopIdAvailable = false;
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
        isMtopIdAvailable = true;
      });
    }
  }

  Future<void> fetchInspectionDetails(String mtopId) async {
    final response = await http.get(
      Uri.parse('http://192.168.100.170:3000/inspection/$mtopId'),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      setState(() {
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
        isMtopIdValidForRenewal = true;
        isMtopIdEditable = false;
      });
    } else {
      setState(() {
        isMtopIdValidForRenewal = false;
        isMtopIdEditable = true;
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
    fetchInspectorIds();
    _inspectorIdController.text = widget.loggedInInspectorId;
  }

  Future<void> submitInspection(String inspectionStatus) async {
    if (_inspectorIdController.text != widget.loggedInInspectorId) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('You can only submit inspections with your inspector ID.'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 2),
        ),
      );
      return;
    }

    // Initialize a list for storing unchecked reasons
    List<String> reasonsNotApproved = [];

    // For "Approved" submission: Ensure all items are checked
    if (inspectionStatus == 'Approved') {
      if (!isSideMirrorChecked || !isSignalLightsChecked || !isTaillightsChecked ||
          !isMotorNumberChecked || !isGarbageCanChecked || !isChassisNumberChecked ||
          !isVehicleRegistrationChecked || !isNotOpenPipeChecked || !isLightInSidecarChecked) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('All checklist items must be checked for an Approved submission.'),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 2),
          ),
        );
        return;
      } else {
        // No unchecked items, so set reason to "No reason for not approved"
        reasonsNotApproved.add('No reason for not approved');
      }
    }

    // For "Not Approved" submission: Collect unchecked items
    if (inspectionStatus == 'Not Approved') {
      if (!isSideMirrorChecked) reasonsNotApproved.add('Side Mirror');
      if (!isSignalLightsChecked) reasonsNotApproved.add('Signal Lights');
      if (!isTaillightsChecked) reasonsNotApproved.add('Taillights');
      if (!isMotorNumberChecked) reasonsNotApproved.add('Motor Number');
      if (!isGarbageCanChecked) reasonsNotApproved.add('Garbage Can');
      if (!isChassisNumberChecked) reasonsNotApproved.add('Chassis Number');
      if (!isVehicleRegistrationChecked) reasonsNotApproved.add('Vehicle Registration');
      if (!isNotOpenPipeChecked) reasonsNotApproved.add('Not Open Pipe');
      if (!isLightInSidecarChecked) reasonsNotApproved.add('Light in Sidecar');

      if (reasonsNotApproved.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Cannot submit as Not Approved when all items are checked.'),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 2),
          ),
        );
        return;
      }
    }

    try {
      final response = await http.post(
        Uri.parse('http://192.168.100.170:3000/add-inspection'),
        headers: <String, String>{'Content-Type': 'application/json; charset=UTF-8'},
        body: jsonEncode({
          'inspector_id': widget.loggedInInspectorId,
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
          'inspection_status': inspectionStatus,
          'reason_not_approved': reasonsNotApproved.join(', ') // Join unchecked reasons
        }),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Inspection $inspectionStatus successfully!'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );

        // Reset form after submission
        setState(() {
          _applicantNameController.clear();
          _mtopIdController.clear();
          selectedVehicleType = 'Motorcycle';
          selectedRegistrationType = 'New';
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
          isMtopIdEditable = true;
        });
      } else {
        print('Failed to submit inspection. Status Code: ${response.statusCode}');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to submit inspection. Server error: ${response.statusCode}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (error) {
      print('Error submitting inspection: $error');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Error submitting inspection. Please check your connection.'),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 2),
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
          const SizedBox(height: 20),

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
                        isMtopIdEditable = true;
                      } else {
                        isMtopIdAvailable = true;
                        isMtopIdValidForRenewal = false;
                        isMtopIdEditable = true;
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
                  decoration: const InputDecoration(
                    labelText: 'Inspector ID (Auto-filled)',
                  ),
                  enabled: false,
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
                        : true,
                    inputFormatters: [
                      LengthLimitingTextInputFormatter(6), // Limit MTOP ID to 6 characters
                    ],
                    onChanged: (value) {
                      if (selectedRegistrationType == 'New') {
                        if (value.length == 6) {
                          checkMtopIdAvailability(value);
                        }
                      } else if (selectedRegistrationType == 'Renewal' && value.length == 6) {
                        if (isMtopIdEditable) {
                          fetchInspectionDetails(value);
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

          // Approved Button
          ElevatedButton(
            onPressed: () {
              if (_mtopIdController.text.length != 6) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('MTOP ID must be exactly 6 characters'),
                    backgroundColor: Colors.red,
                    duration: Duration(seconds: 2),
                  ),
                );
              } else if (_applicantNameController.text.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Applicant Name is required'),
                    backgroundColor: Colors.red,
                    duration: Duration(seconds: 2),
                  ),
                );
              } else {
                submitInspection('Approved');
              }
            },
            child: const Text('Submit Approved Inspection'),
          ),

          const SizedBox(height: 20),

          // Not Approved Button
          ElevatedButton(
            onPressed: () {
              if (_mtopIdController.text.length != 6) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('MTOP ID must be exactly 6 characters'),
                    backgroundColor: Colors.red,
                    duration: Duration(seconds: 2),
                  ),
                );
              } else if (_applicantNameController.text.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Applicant Name is required'),
                    backgroundColor: Colors.red,
                    duration: Duration(seconds: 2),
                  ),
                );
              } else {
                submitInspection('Not Approved');
              }
            },
            child: const Text('Submit Not Approved Inspection'),
          ),

          const SizedBox(height: 20),
        ],
      ),
    );
  }
}
