import 'package:flutter/material.dart';

class InspectionScreen extends StatefulWidget {
  const InspectionScreen({super.key});

  @override
  _InspectionScreenState createState() => _InspectionScreenState();
}

class _InspectionScreenState extends State<InspectionScreen> {
  // Checkboxes state variables
  bool isMotorcycleChecked = false;
  bool isEtrikeChecked = false;
  bool isTricycleChecked = false;

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

          // Search Section moved to top
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        decoration: InputDecoration(
                          hintText: 'Search',
                          prefixIcon: const Icon(Icons.search),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          filled: true,
                          fillColor: Colors.grey.shade200,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // Inspection Number Input
                const TextField(
                  decoration: InputDecoration(
                    labelText: 'Inspector ID:',
                    border: OutlineInputBorder(),
                    filled: true,
                    fillColor: Colors.grey,
                  ),
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
                  CheckboxListTile(
                    title: const Text("Motorcycle"),
                    value: isMotorcycleChecked,
                    onChanged: (bool? value) {
                      setState(() {
                        isMotorcycleChecked = value ?? false;
                      });
                    },
                  ),
                  CheckboxListTile(
                    title: const Text("E-trike"),
                    value: isEtrikeChecked,
                    onChanged: (bool? value) {
                      setState(() {
                        isEtrikeChecked = value ?? false;
                      });
                    },
                  ),
                  CheckboxListTile(
                    title: const Text("Tricycle"),
                    value: isTricycleChecked,
                    onChanged: (bool? value) {
                      setState(() {
                        isTricycleChecked = value ?? false;
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
                      isMotorcycleChecked = false;
                      isEtrikeChecked = false;
                      isTricycleChecked = false;
                      isSideMirrorChecked = false;
                      isSignalLightsChecked = false;
                      isTaillightsChecked = false;
                      isMotorNumberChecked = false;
                      isGarbageCanChecked = false;
                      isChassisNumberChecked = false;
                      isVehicleRegistrationChecked = false;
                      isNotOpenPipeChecked = false;
                      isLightInSidecarChecked = false;
                    });
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.grey.shade300,
                    padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                  ),
                  child: const Text(
                    'Clear',
                    style: TextStyle(color: Colors.black87),
                  ),
                ),
                ElevatedButton(
                  onPressed: () {
                    // Reject action
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                  ),
                  child: const Text('Reject'),
                ),
                ElevatedButton(
                  onPressed: () {
                    // Approve action
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
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
