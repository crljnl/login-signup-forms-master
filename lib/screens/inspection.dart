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
      Uri.parse('http://192.168.1.2:3000/inspectors'),
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
      Uri.parse('http://192.168.1.2:3000/inspection/$mtopId'),
    );

    if (response.statusCode == 200) {
      setState(() {
        isMtopIdAvailable = false;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('MTOP ID already exists, choose another for new registration'),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 2),
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
      Uri.parse('http://192.168.1.2:3000/inspection/$mtopId'),
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
          const SnackBar(
            content: Text('MTOP ID not found, invalid for renewal'),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 2),
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
        const SnackBar(
          content: Text('You can only submit inspections with your inspector ID.'),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    // Initialize a list for storing unchecked reasons
    List<String> reasonsNotApproved = [];

    // For "Approved" submission: Ensure all items are checked
    if (inspectionStatus == 'Approved') {
      if (!isSideMirrorChecked ||
          !isSignalLightsChecked ||
          !isTaillightsChecked ||
          !isMotorNumberChecked ||
          !isGarbageCanChecked ||
          !isChassisNumberChecked ||
          !isVehicleRegistrationChecked ||
          !isNotOpenPipeChecked ||
          !isLightInSidecarChecked) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('All checklist items must be checked for an Approved submission.'),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 2),
          ),
        );
        return;
      } else {
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
        Uri.parse('http://192.168.1.2:3000/add-inspection'),
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
            duration: const Duration(seconds: 2),
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
        backgroundColor: Color.fromARGB(255, 58, 157, 250),
        elevation: 4,
        actions: [
          IconButton(
            icon: Icon(Icons.help_outline, color: Colors.white),
            onPressed: () {
              // Add help button functionality if needed
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Header Section
            const SizedBox(height: 10),
            Expanded(
              child: ListView(
                children: [
                  // Vehicle type dropdown
                  buildDropdown(
                    title: "Select Vehicle Type",
                    value: selectedVehicleType,
                    items: const ['Motorcycle', 'Tricycle', 'Etrike'],
                    onChanged: (value) {
                      setState(() {
                        selectedVehicleType = value!;
                      });
                    },
                  ),
                  const SizedBox(height: 10),

                  // Registration type dropdown
                  buildDropdown(
                    title: "Registration Type",
                    value: selectedRegistrationType,
                    items: const ['New', 'Renewal'],
                    onChanged: (value) {
                      setState(() {
                        selectedRegistrationType = value!;
                      });
                    },
                  ),
                  const SizedBox(height: 20),

                  // Applicant Name
                  buildTextField(
                    controller: _applicantNameController,
                    label: 'Applicant Name',
                    icon: Icons.person,
                  ),
                  const SizedBox(height: 20),

                  // MTOP ID
                  buildTextField(
                    controller: _mtopIdController,
                    label: 'MTOP ID',
                    icon: Icons.directions_car,
                    inputFormatters: [LengthLimitingTextInputFormatter(6)],
                    enabled: selectedRegistrationType == 'Renewal'
                        ? isMtopIdEditable
                        : true,
                    onChanged: (value) {
                      if (selectedRegistrationType == 'New' && value.length == 6) {
                        checkMtopIdAvailability(value);
                      } else if (selectedRegistrationType == 'Renewal' && value.length == 6) {
                        fetchInspectionDetails(value);
                      }
                    },
                  ),
                  const SizedBox(height: 20),

                  // Checklist Items
                  buildChecklistTile('Side Mirror', isSideMirrorChecked, Icons.car_repair, (bool? value) {
                    setState(() {
                      isSideMirrorChecked = value!;
                    });
                  }),
                  buildChecklistTile('Signal Lights', isSignalLightsChecked, Icons.lightbulb, (bool? value) {
                    setState(() {
                      isSignalLightsChecked = value!;
                    });
                  }),
                  buildChecklistTile('Taillights', isTaillightsChecked, Icons.traffic, (bool? value) {
                    setState(() {
                      isTaillightsChecked = value!;
                    });
                  }),
                  buildChecklistTile('Motor Number', isMotorNumberChecked, Icons.format_list_numbered, (bool? value) {
                    setState(() {
                      isMotorNumberChecked = value!;
                    });
                  }),
                  buildChecklistTile('Garbage Can', isGarbageCanChecked, Icons.delete, (bool? value) {
                    setState(() {
                      isGarbageCanChecked = value!;
                    });
                  }),
                  buildChecklistTile('Chassis Number', isChassisNumberChecked, Icons.build, (bool? value) {
                    setState(() {
                      isChassisNumberChecked = value!;
                    });
                  }),
                  buildChecklistTile('Vehicle Registration', isVehicleRegistrationChecked, Icons.assignment, (bool? value) {
                    setState(() {
                      isVehicleRegistrationChecked = value!;
                    });
                  }),
                  buildChecklistTile('Not Open Pipe', isNotOpenPipeChecked, Icons.no_stroller, (bool? value) {
                    setState(() {
                      isNotOpenPipeChecked = value!;
                    });
                  }),
                  buildChecklistTile('Light in Sidecar', isLightInSidecarChecked, Icons.lightbulb_outline, (bool? value) {
                    setState(() {
                      isLightInSidecarChecked = value!;
                    });
                  }),

                  const SizedBox(height: 20),

                  // Submit buttons
                  buildSubmitButton('Submit Approved Inspection', Colors.green, 'Approved'),
                  const SizedBox(height: 10),
                  buildSubmitButton('Submit Not Approved Inspection', Colors.red, 'Not Approved'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget buildDropdown({
    required String title,
    required String value,
    required List<String> items,
    required void Function(String?) onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        DropdownButton<String>(
          value: value,
          items: items.map((item) {
            return DropdownMenuItem(value: item, child: Text(item));
          }).toList(),
          onChanged: onChanged,
          isExpanded: true,
        ),
      ],
    );
  }

  Widget buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    List<TextInputFormatter>? inputFormatters,
    bool enabled = true,
    Function(String)? onChanged,
  }) {
    return TextField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        border: OutlineInputBorder(),
      ),
      inputFormatters: inputFormatters,
      enabled: enabled,
      onChanged: onChanged,
    );
  }

  Widget buildChecklistTile(
    String title,
    bool value,
    IconData icon,
    void Function(bool?) onChanged,
  ) {
    return CheckboxListTile(
      title: Text(title),
      value: value,
      onChanged: onChanged,
      secondary: Icon(icon),
    );
  }

  Widget buildSubmitButton(String text, Color color, String status) {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        foregroundColor: Colors.white, backgroundColor: color,
        padding: const EdgeInsets.symmetric(vertical: 16),
      ),
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
          submitInspection(status);
        }
      },
      child: Text(text),
    );
  }
}
