import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/services.dart';
import 'config.dart'; // Import Config class

class InspectionScreen extends StatefulWidget {
  final String loggedInInspectorId;

  const InspectionScreen({super.key, required this.loggedInInspectorId});

  @override
  _InspectionScreenState createState() => _InspectionScreenState();
}

class _InspectionScreenState extends State<InspectionScreen> {
  // Default values for dropdowns
  String selectedVehicleType = 'Tricycle';
  String selectedRegistrationType = 'New';
  String selectedTown = 'San Luis';

  // Checklist states
  bool isSideMirrorChecked = false;
  bool isSignalLightsChecked = false;
  bool isTaillightsChecked = false;
  bool isMotorNumberChecked = false;
  bool isGarbageCanChecked = false;
  bool isChassisNumberChecked = false;
  bool isVehicleRegistrationChecked = false;
  bool isNotOpenPipeChecked = false;
  bool isLightInSidecarChecked = false;

  // MTOP ID logic
  bool isMtopIdAvailable = true;
  bool isMtopIdEditable = true;

  // Controllers for form inputs
  final TextEditingController _applicantNameController = TextEditingController();
  final TextEditingController _mtopIdController = TextEditingController();

  @override
  void initState() {
    super.initState();
  }

  // Check if MTOP ID is valid for new or renewal
  Future<void> checkOrFetchMtopIdDetails(String mtopId) async {
    if (selectedRegistrationType == 'New') {
      final response = await http.get(Uri.parse('http://${Config.serverIp}:3000/inspection/$mtopId'));
      if (response.statusCode == 200) {
        setState(() {
          isMtopIdAvailable = false;
        });
        showNotificationMessage('MTOP ID already exists. Choose another for new registration.', Colors.red);
      } else {
        setState(() {
          isMtopIdAvailable = true;
        });
      }
    } else if (selectedRegistrationType == 'Renewal') {
      final response = await http.get(Uri.parse('http://${Config.serverIp}:3000/inspection/$mtopId'));
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
          isMtopIdEditable = false;
        });
      } else {
        setState(() {
          isMtopIdEditable = true;
        });
        showNotificationMessage('MTOP ID not found. Invalid for renewal.', Colors.red);
      }
    }
  }

  // Show notification message at the top of the screen
  void showNotificationMessage(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: TextStyle(color: Colors.white)),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16.0),
      ),
    );
  }

  // Submit the inspection
  Future<void> submitInspection() async {
    // Determine inspection status
    bool allItemsChecked = isSideMirrorChecked &&
        isSignalLightsChecked &&
        isTaillightsChecked &&
        isMotorNumberChecked &&
        isGarbageCanChecked &&
        isChassisNumberChecked &&
        isVehicleRegistrationChecked &&
        isNotOpenPipeChecked &&
        isLightInSidecarChecked;

    String inspectionStatus = allItemsChecked ? 'Approved' : 'Not Approved';

    // Reasons for "Not Approved"
    List<String> reasonsNotApproved = [];
    if (!allItemsChecked) {
      if (!isSideMirrorChecked) reasonsNotApproved.add('Side Mirror');
      if (!isSignalLightsChecked) reasonsNotApproved.add('Signal Lights');
      if (!isTaillightsChecked) reasonsNotApproved.add('Taillights');
      if (!isMotorNumberChecked) reasonsNotApproved.add('Motor Number');
      if (!isGarbageCanChecked) reasonsNotApproved.add('Garbage Can');
      if (!isChassisNumberChecked) reasonsNotApproved.add('Chassis Number');
      if (!isVehicleRegistrationChecked) reasonsNotApproved.add('Vehicle Registration');
      if (!isNotOpenPipeChecked) reasonsNotApproved.add('Not Open Pipe');
      if (!isLightInSidecarChecked) reasonsNotApproved.add('Light in Sidecar');
    }

    if (_applicantNameController.text.isEmpty || _mtopIdController.text.isEmpty) {
      showNotificationMessage('Applicant Name and MTOP ID are required.', Colors.red);
      return;
    }

    // Prepare data for submission
    final inspectionData = {
      'inspector_id': widget.loggedInInspectorId,
      'applicant_name': _applicantNameController.text,
      'mtop_id': _mtopIdController.text,
      'vehicle_type': selectedVehicleType,
      'registration_type': selectedRegistrationType,
      'town': selectedTown,
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
      'reason_not_approved': reasonsNotApproved.join(', '),
    };

    try {
      final response = await http.post(
        Uri.parse('http://${Config.serverIp}:3000/add-inspection'),
        headers: <String, String>{'Content-Type': 'application/json; charset=UTF-8'},
        body: jsonEncode(inspectionData),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        showNotificationMessage('Inspection $inspectionStatus successfully!', Colors.green);
        resetForm();
      } else {
        showNotificationMessage('Failed to submit inspection. Server error: ${response.statusCode}', Colors.red);
      }
    } catch (error) {
      showNotificationMessage('Error submitting inspection. Please check your connection.', Colors.red);
    }
  }

  // Reset the form
  void resetForm() {
    setState(() {
      _applicantNameController.clear();
      _mtopIdController.clear();
      selectedVehicleType = 'Tricycle';
      selectedRegistrationType = 'New';
      selectedTown = 'San Luis';
      isSideMirrorChecked = false;
      isSignalLightsChecked = false;
      isTaillightsChecked = false;
      isMotorNumberChecked = false;
      isGarbageCanChecked = false;
      isChassisNumberChecked = false;
      isVehicleRegistrationChecked = false;
      isNotOpenPipeChecked = false;
      isLightInSidecarChecked = false;
      isMtopIdEditable = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    bool allItemsChecked = isSideMirrorChecked &&
        isSignalLightsChecked &&
        isTaillightsChecked &&
        isMotorNumberChecked &&
        isGarbageCanChecked &&
        isChassisNumberChecked &&
        isVehicleRegistrationChecked &&
        isNotOpenPipeChecked &&
        isLightInSidecarChecked;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Vehicle Inspection'),
        backgroundColor: Colors.teal,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView(
          children: [
            // Applicant Name
            buildTextField(
              controller: _applicantNameController,
              label: 'Applicant Name',
              icon: Icons.person,
            ),
            const SizedBox(height: 16),
            // MTOP ID
            buildTextField(
              controller: _mtopIdController,
              label: 'MTOP ID',
              icon: Icons.directions_car,
              inputFormatters: [LengthLimitingTextInputFormatter(6)],
              enabled: isMtopIdEditable,
              onChanged: (value) {
                if (value.length == 6) {
                  checkOrFetchMtopIdDetails(value);
                }
              },
            ),
            const SizedBox(height: 16),
            // Vehicle Type Dropdown
            buildDropdown(
              label: 'Vehicle Type',
              value: selectedVehicleType,
              items: ['Tricycle'],
              onChanged: (value) {
                setState(() {
                  selectedVehicleType = value!;
                });
              },
            ),
            const SizedBox(height: 16),
            // Registration Type Dropdown
            buildDropdown(
              label: 'Registration Type',
              value: selectedRegistrationType,
              items: ['New', 'Renewal'],
              onChanged: (value) {
                setState(() {
                  selectedRegistrationType = value!;
                });
              },
            ),
            const SizedBox(height: 16),
            // Town Dropdown
            buildDropdown(
              label: 'Town',
              value: selectedTown,
              items: ['San Luis', 'Lemery', 'Taal', 'Other Town'],
              onChanged: (value) {
                setState(() {
                  selectedTown = value!;
                });
              },
            ),
            const SizedBox(height: 16),
            // Checklist Items
            buildChecklistTile('Side Mirror', isSideMirrorChecked, Icons.car_repair, (value) {
              setState(() {
                isSideMirrorChecked = value!;
              });
            }),
            buildChecklistTile('Signal Lights', isSignalLightsChecked, Icons.lightbulb, (value) {
              setState(() {
                isSignalLightsChecked = value!;
              });
            }),
            buildChecklistTile('Taillights', isTaillightsChecked, Icons.traffic, (value) {
              setState(() {
                isTaillightsChecked = value!;
              });
            }),
            buildChecklistTile('Motor Number', isMotorNumberChecked, Icons.motorcycle, (value) {
              setState(() {
                isMotorNumberChecked = value!;
              });
            }),
            buildChecklistTile('Garbage Can', isGarbageCanChecked, Icons.delete, (value) {
              setState(() {
                isGarbageCanChecked = value!;
              });
            }),
            buildChecklistTile('Chassis Number', isChassisNumberChecked, Icons.build, (value) {
              setState(() {
                isChassisNumberChecked = value!;
              });
            }),
            buildChecklistTile('Vehicle Registration', isVehicleRegistrationChecked,
                Icons.assignment, (value) {
              setState(() {
                isVehicleRegistrationChecked = value!;
              });
            }),
            buildChecklistTile('Not Open Pipe', isNotOpenPipeChecked, Icons.build, (value) {
              setState(() {
                isNotOpenPipeChecked = value!;
              });
            }),
            buildChecklistTile(
                'Light in Sidecar', isLightInSidecarChecked, Icons.light, (value) {
              setState(() {
                isLightInSidecarChecked = value!;
              });
            }),
            const SizedBox(height: 16),
            // Submit Button
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: allItemsChecked ? Colors.green : Colors.red,
                padding: const EdgeInsets.symmetric(vertical: 16),
                textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: submitInspection,
              child: Text(allItemsChecked ? 'Submit Approved' : 'Submit Not Approved'),
            ),
          ],
        ),
      ),
    );
  }

  // Reusable method to build a text field
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
        prefixIcon: Icon(icon, color: Colors.teal),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        enabledBorder: OutlineInputBorder(
          borderSide: const BorderSide(color: Colors.teal),
          borderRadius: BorderRadius.circular(12),
        ),
        focusedBorder: OutlineInputBorder(
          borderSide: const BorderSide(color: Colors.teal, width: 2.0),
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      inputFormatters: inputFormatters,
      enabled: enabled,
      onChanged: onChanged,
    );
  }

  // Reusable method to build a checklist item
  Widget buildChecklistTile(
      String title, bool value, IconData icon, void Function(bool?) onChanged) {
    return CheckboxListTile(
      title: Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
      value: value,
      onChanged: onChanged,
      secondary: Icon(icon, color: Colors.teal),
      activeColor: Colors.teal,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
    );
  }

  // Reusable method to build a dropdown
  Widget buildDropdown({
    required String label,
    required String value,
    required List<String> items,
    required ValueChanged<String?> onChanged,
  }) {
    return DropdownButtonFormField<String>(
      value: value,
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        enabledBorder: OutlineInputBorder(
          borderSide: const BorderSide(color: Colors.teal),
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      items: items.map((item) => DropdownMenuItem(value: item, child: Text(item))).toList(),
      onChanged: onChanged,
    );
  }
}
