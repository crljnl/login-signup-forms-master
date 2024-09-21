import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class ScanDocumentScreen extends StatefulWidget {
  const ScanDocumentScreen({super.key});

  @override
  _ScanDocumentScreenState createState() => _ScanDocumentScreenState();
}

class _ScanDocumentScreenState extends State<ScanDocumentScreen> {
  // Checkbox state variables
  bool isBarangayClearanceChecked = false;
  bool isPoliceClearanceChecked = false;
  bool isSSSCertificateChecked = false;
  bool isPhilhealthCertificateChecked = false;
  bool isApplicationFeeChecked = false;
  bool isCertificateOfRegistrationChecked = false;
  bool isDriversLicenseChecked = false;

  final ImagePicker _picker = ImagePicker();

  // Method to open camera
  Future<void> _openCamera() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.camera);
    if (image != null) {
      // Handle the captured image here
      print('Image path: ${image.path}');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Scan Documents'),
        backgroundColor: Colors.blue,
      ),
      body: Column(
        children: [
          const SizedBox(height: 20), // Top padding

          // Requirements Container
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.blue.shade100,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  buildRequirementItem(
                    title: 'Barangay Clearance',
                    isChecked: isBarangayClearanceChecked,
                    onChanged: (bool? value) {
                      setState(() {
                        isBarangayClearanceChecked = value ?? false;
                      });
                    },
                  ),
                  buildRequirementItem(
                    title: 'Police Clearance',
                    isChecked: isPoliceClearanceChecked,
                    onChanged: (bool? value) {
                      setState(() {
                        isPoliceClearanceChecked = value ?? false;
                      });
                    },
                  ),
                  buildRequirementItem(
                    title: 'SSS Certificate',
                    isChecked: isSSSCertificateChecked,
                    onChanged: (bool? value) {
                      setState(() {
                        isSSSCertificateChecked = value ?? false;
                      });
                    },
                  ),
                  buildRequirementItem(
                    title: 'Philhealth Certificate',
                    isChecked: isPhilhealthCertificateChecked,
                    onChanged: (bool? value) {
                      setState(() {
                        isPhilhealthCertificateChecked = value ?? false;
                      });
                    },
                  ),
                  buildRequirementItem(
                    title: 'Application Fee',
                    isChecked: isApplicationFeeChecked,
                    onChanged: (bool? value) {
                      setState(() {
                        isApplicationFeeChecked = value ?? false;
                      });
                    },
                  ),
                  buildRequirementItem(
                    title: 'Certificate of Registration',
                    subtitle: 'of Motorized Tricycle for Hire',
                    isChecked: isCertificateOfRegistrationChecked,
                    onChanged: (bool? value) {
                      setState(() {
                        isCertificateOfRegistrationChecked = value ?? false;
                      });
                    },
                  ),
                  buildRequirementItem(
                    title: "Driver's License",
                    isChecked: isDriversLicenseChecked,
                    onChanged: (bool? value) {
                      setState(() {
                        isDriversLicenseChecked = value ?? false;
                      });
                    },
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // Handle submit action
          print('Submit button pressed');
        },
        child: const Icon(Icons.check),
      ),
    );
  }

  Widget buildRequirementItem({
    required String title,
    String? subtitle,
    required bool isChecked,
    required ValueChanged<bool?> onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.camera_alt),
                onPressed: _openCamera, // Open camera when button is pressed
              ),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title),
                  if (subtitle != null)
                    Text(
                      subtitle,
                      style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
                    ),
                ],
              ),
            ],
          ),
          Checkbox(
            value: isChecked,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }
}