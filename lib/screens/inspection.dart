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
  List<String> validInspectorIds = [];

  String selectedVehicleType = 'Tricycle';
  String selectedRegistrationType = 'New';
  String selectedTown = 'San Luis';

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
      Uri.parse('http://${Config.serverIp}:3000/inspectors'),
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
      Uri.parse('http://${Config.serverIp}:3000/inspection/$mtopId'),
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
      Uri.parse('http://${Config.serverIp}:3000/inspection/$mtopId'),
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

    List<String> reasonsNotApproved = [];

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
        reasonsNotApproved.add('No reason for not approved');
      }
    }

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
        Uri.parse('http://${Config.serverIp}:3000/add-inspection'),
        headers: <String, String>{'Content-Type': 'application/json; charset=UTF-8'},
        body: jsonEncode({
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
          'reason_not_approved': reasonsNotApproved.join(', ')
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

        setState(() {
          _applicantNameController.clear();
          _mtopIdController.clear();
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
          selectedTown = 'San Luis';
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to submit inspection. Server error: ${response.statusCode}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (error) {
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
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            const SizedBox(height: 10),
            Expanded(
              child: ListView(
                children: [
                  buildEnhancedDropdown(
                    title: "Vehicle Type",
                    value: selectedVehicleType,
                    items: const ['Tricycle'],
                    onChanged: (value) {
                      setState(() {
                        selectedVehicleType = value!;
                      });
                    },
                  ),
                  const SizedBox(height: 10),
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
                  buildTextField(
                    controller: _applicantNameController,
                    label: 'Applicant Name',
                    icon: Icons.person,
                  ),
                  const SizedBox(height: 20),
                  buildTextField(
                    controller: _mtopIdController,
                    label: 'MTOP ID',
                    icon: Icons.directions_car,
                    inputFormatters: [LengthLimitingTextInputFormatter(6)],
                    enabled: selectedRegistrationType == 'Renewal' ? isMtopIdEditable : true,
                    onChanged: (value) {
                      if (selectedRegistrationType == 'New' && value.length == 6) {
                        checkMtopIdAvailability(value);
                      } else if (selectedRegistrationType == 'Renewal' && value.length == 6) {
                        fetchInspectionDetails(value);
                      }
                    },
                  ),
                  const SizedBox(height: 20),
                  buildEnhancedDropdown(
                    title: "Name of the Town",
                    value: selectedTown,
                    items: const ['San Luis', 'Lemery', 'Taal', 'Other Town'],
                    onChanged: (value) {
                      setState(() {
                        selectedTown = value!;
                      });
                    },
                  ),
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

  Widget buildEnhancedDropdown({
    required String title,
    required String value,
    required List<String> items,
    required void Function(String?) onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        Container(
          decoration: BoxDecoration(
            color: Colors.grey[200],
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey[400]!),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: DropdownButtonFormField<String>(
            decoration: const InputDecoration(border: InputBorder.none),
            value: value,
            items: items.map((item) {
              return DropdownMenuItem(value: item, child: Text(item));
            }).toList(),
            onChanged: onChanged,
            isExpanded: true,
            style: const TextStyle(fontSize: 16, color: Colors.black),
            dropdownColor: Colors.white,
            icon: const Icon(Icons.arrow_drop_down, color: Colors.blue),
          ),
        ),
      ],
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
