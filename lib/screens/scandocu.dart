import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:image/image.dart' as img; // For image compression
import 'config.dart'; // Backend server configuration

class ScanDocumentScreen extends StatefulWidget {
  const ScanDocumentScreen({super.key});

  @override
  _ScanDocumentScreenState createState() => _ScanDocumentScreenState();
}

class _ScanDocumentScreenState extends State<ScanDocumentScreen> {
  final ImagePicker _picker = ImagePicker();
  final TextEditingController _mtopIdController = TextEditingController();

  bool _isMtopValid = false;
  String _mtopIdErrorMessage = "";
  bool isLoading = false; // For general loading state

  // Variables to store the file paths of captured images
  XFile? barangayClearance;
  XFile? policeClearance;
  XFile? sssCertificate;
  XFile? philhealthCertificate;
  XFile? applicationFee;
  XFile? certificateOfRegistration;
  XFile? driversLicense;

  // Loading progress variables for each document
  double barangayClearanceProgress = 0;
  double policeClearanceProgress = 0;
  double sssCertificateProgress = 0;
  double philhealthCertificateProgress = 0;
  double applicationFeeProgress = 0;
  double certificateOfRegistrationProgress = 0;
  double driversLicenseProgress = 0;

  // Method to compress images before upload
  Future<File> compressImage(File imageFile) async {
    final rawImage = img.decodeImage(imageFile.readAsBytesSync());
    if (rawImage == null) throw Exception("Error reading image");

    // Compress the image (resize to a maximum width/height of 1024px)
    final compressedImage = img.copyResize(rawImage, width: 1024, height: 1024);

    // Save the compressed image to a temporary file
    final tempDir = Directory.systemTemp;
    final tempFile = File('${tempDir.path}/${DateTime.now().millisecondsSinceEpoch}.jpg');
    tempFile.writeAsBytesSync(img.encodeJpg(compressedImage, quality: 80));

    return tempFile;
  }

  // Method to open the camera for each document
  Future<void> _openCamera(String documentType) async {
    final XFile? image = await _picker.pickImage(source: ImageSource.camera);
    if (image != null) {
      final compressedFile = await compressImage(File(image.path));

      setState(() {
        switch (documentType) {
          case 'barangay_clearance':
            barangayClearance = XFile(compressedFile.path);
            break;
          case 'police_clearance':
            policeClearance = XFile(compressedFile.path);
            break;
          case 'sss_certificate':
            sssCertificate = XFile(compressedFile.path);
            break;
          case 'philhealth_certificate':
            philhealthCertificate = XFile(compressedFile.path);
            break;
          case 'application_fee':
            applicationFee = XFile(compressedFile.path);
            break;
          case 'certificate_of_registration':
            certificateOfRegistration = XFile(compressedFile.path);
            break;
          case 'drivers_license':
            driversLicense = XFile(compressedFile.path);
            break;
        }
      });
    }
  }

  // Method to validate MTOP ID
  Future<void> _validateMtopId() async {
    String mtopId = _mtopIdController.text.trim();

    if (mtopId.length != 6) {
      setState(() {
        _mtopIdErrorMessage = "MTOP ID must be exactly 6 characters.";
      });
      return;
    }

    var response = await http.get(Uri.parse('http://${Config.serverIp}:3000/check-submission/$mtopId'));

    if (response.statusCode == 200 && response.body == 'not submitted') {
      setState(() {
        _isMtopValid = true;
        _mtopIdErrorMessage = "";
      });
      _showSuccessDialog("MTOP ID is valid. You can now capture documents.");
    } else {
      setState(() {
        _isMtopValid = false;
        _mtopIdErrorMessage = "Invalid MTOP ID";
      });
      _showErrorDialog("MTOP ID not found or already submitted.");
    }
  }

  // Method to simulate upload progress
  Future<void> _uploadDocumentWithProgress(String documentType, XFile? document, Function(double) updateProgress) async {
    if (document == null) return;

    // Simulate progress for loading animation
    for (int i = 1; i <= 10; i++) {
      await Future.delayed(const Duration(milliseconds: 100), () {
        setState(() {
          updateProgress(i * 10.0);
        });
      });
    }
  }

  // Method to upload all documents in one request
  Future<void> _uploadDocuments() async {
    if (!_isMtopValid) {
      _showErrorDialog("Please validate the MTOP ID before submitting documents.");
      return;
    }

    if (barangayClearance == null ||
        policeClearance == null ||
        sssCertificate == null ||
        philhealthCertificate == null ||
        applicationFee == null ||
        certificateOfRegistration == null ||
        driversLicense == null) {
      _showErrorDialog("All document types must have images before submission.");
      return;
    }

    var request = http.MultipartRequest('POST', Uri.parse('http://${Config.serverIp}:3000/upload-documents'));
    String mtopId = _mtopIdController.text.trim();
    request.fields['mtop_id'] = mtopId;

    // Add compressed documents to the request
    if (barangayClearance != null) {
      request.files.add(await http.MultipartFile.fromPath(
        'barangay_clearance',
        barangayClearance!.path,
        contentType: MediaType('image', 'jpeg'),
      ));
    }
    if (policeClearance != null) {
      request.files.add(await http.MultipartFile.fromPath(
        'police_clearance',
        policeClearance!.path,
        contentType: MediaType('image', 'jpeg'),
      ));
    }
    if (sssCertificate != null) {
      request.files.add(await http.MultipartFile.fromPath(
        'sss_certificate',
        sssCertificate!.path,
        contentType: MediaType('image', 'jpeg'),
      ));
    }
    if (philhealthCertificate != null) {
      request.files.add(await http.MultipartFile.fromPath(
        'philhealth_certificate',
        philhealthCertificate!.path,
        contentType: MediaType('image', 'jpeg'),
      ));
    }
    if (applicationFee != null) {
      request.files.add(await http.MultipartFile.fromPath(
        'applicant_fee',
        applicationFee!.path,
        contentType: MediaType('image', 'jpeg'),
      ));
    }
    if (certificateOfRegistration != null) {
      request.files.add(await http.MultipartFile.fromPath(
        'certificate_of_registration',
        certificateOfRegistration!.path,
        contentType: MediaType('image', 'jpeg'),
      ));
    }
    if (driversLicense != null) {
      request.files.add(await http.MultipartFile.fromPath(
        'drivers_license',
        driversLicense!.path,
        contentType: MediaType('image', 'jpeg'),
      ));
    }

    setState(() {
      isLoading = true;
    });

    // Simulate progress for each document type
    await _uploadDocumentWithProgress('barangay_clearance', barangayClearance, (progress) {
      barangayClearanceProgress = progress;
    });
    await _uploadDocumentWithProgress('police_clearance', policeClearance, (progress) {
      policeClearanceProgress = progress;
    });
    await _uploadDocumentWithProgress('sss_certificate', sssCertificate, (progress) {
      sssCertificateProgress = progress;
    });
    await _uploadDocumentWithProgress('philhealth_certificate', philhealthCertificate, (progress) {
      philhealthCertificateProgress = progress;
    });
    await _uploadDocumentWithProgress('applicant_fee', applicationFee, (progress) {
      applicationFeeProgress = progress;
    });
    await _uploadDocumentWithProgress('certificate_of_registration', certificateOfRegistration, (progress) {
      certificateOfRegistrationProgress = progress;
    });
    await _uploadDocumentWithProgress('drivers_license', driversLicense, (progress) {
      driversLicenseProgress = progress;
    });

    var response = await request.send();
    setState(() {
      isLoading = false;
    });

    if (response.statusCode == 200) {
      setState(() {
        barangayClearance = null;
        policeClearance = null;
        sssCertificate = null;
        philhealthCertificate = null;
        applicationFee = null;
        certificateOfRegistration = null;
        driversLicense = null;

        _mtopIdController.clear();
        _isMtopValid = false;
        _mtopIdErrorMessage = "";
      });
      _showSuccessDialog("Documents uploaded successfully.");
    } else {
      _showErrorDialog("Failed to upload documents. Please try again.");
    }
  }

  // Dialog methods
  void _showSuccessDialog(String message) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Success'),
          content: Text(message),
          actions: <Widget>[
            TextButton(
              child: const Text('OK'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Error'),
          content: Text(message),
          actions: <Widget>[
            TextButton(
              child: const Text('OK'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
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
          const SizedBox(height: 20),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                TextField(
                  controller: _mtopIdController,
                  maxLength: 6,
                  decoration: InputDecoration(
                    labelText: "Enter MTOP ID",
                    errorText: _mtopIdErrorMessage.isNotEmpty ? _mtopIdErrorMessage : null,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    filled: true,
                    fillColor: Colors.white,
                  ),
                ),
                const SizedBox(height: 10),
                ElevatedButton(
                  onPressed: _validateMtopId,
                  style: ElevatedButton.styleFrom(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 15),
                  ),
                  child: const Text('Check MTOP Validity'),
                ),
                if (_isMtopValid) const Text("MTOP ID is valid", style: TextStyle(color: Colors.green)),
              ],
            ),
          ),
          if (_isMtopValid)
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withOpacity(0.5),
                        spreadRadius: 5,
                        blurRadius: 7,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: ListView(
                    children: [
                      buildRequirementItem(
                        title: 'Barangay Clearance',
                        image: barangayClearance,
                        onCameraPressed: () => _openCamera('barangay_clearance'),
                      ),
                      buildRequirementItem(
                        title: 'Police Clearance',
                        image: policeClearance,
                        onCameraPressed: () => _openCamera('police_clearance'),
                      ),
                      buildRequirementItem(
                        title: 'SSS Certificate',
                        image: sssCertificate,
                        onCameraPressed: () => _openCamera('sss_certificate'),
                      ),
                      buildRequirementItem(
                        title: 'Philhealth Certificate',
                        image: philhealthCertificate,
                        onCameraPressed: () => _openCamera('philhealth_certificate'),
                      ),
                      buildRequirementItem(
                        title: 'Application Fee',
                        image: applicationFee,
                        onCameraPressed: () => _openCamera('application_fee'),
                      ),
                      buildRequirementItem(
                        title: 'Certificate of Registration',
                        subtitle: 'of Motorized Tricycle for Hire',
                        image: certificateOfRegistration,
                        onCameraPressed: () => _openCamera('certificate_of_registration'),
                      ),
                      buildRequirementItem(
                        title: "Driver's License",
                        image: driversLicense,
                        onCameraPressed: () => _openCamera('drivers_license'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
      floatingActionButton: _isMtopValid && !isLoading
          ? FloatingActionButton(
              onPressed: _uploadDocuments,
              backgroundColor: Colors.blue,
              child: const Icon(Icons.upload),
            )
          : null,
    );
  }

  Widget buildRequirementItem({
    required String title,
    String? subtitle,
    required XFile? image,
    required VoidCallback onCameraPressed,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Card(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(15),
        ),
        elevation: 5,
        child: ListTile(
          leading: IconButton(
            icon: const Icon(Icons.camera_alt, color: Colors.blue),
            onPressed: onCameraPressed,
          ),
          title: Text(title),
          subtitle: subtitle != null ? Text(subtitle) : null,
          trailing: image != null
              ? Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.check_circle, color: Colors.green),
                    const SizedBox(width: 5),
                    const Text('Captured', style: TextStyle(color: Colors.green)),
                  ],
                )
              : const Text('Pending', style: TextStyle(color: Colors.red)),
        ),
      ),
    );
  }
}
