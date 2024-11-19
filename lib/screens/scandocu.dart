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
  // Checkbox state variables
  bool isBarangayClearanceChecked = false;
  bool isPoliceClearanceChecked = false;
  bool isSSSCertificateChecked = false;
  bool isPhilhealthCertificateChecked = false;
  bool isApplicationFeeChecked = false;
  bool isCertificateOfRegistrationChecked = false;
  bool isDriversLicenseChecked = false;

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

  // Method to view the captured image
  void _viewImage(XFile? image) {
    if (image != null) {
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return Dialog(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Image.file(
                  File(image.path),
                  fit: BoxFit.contain,
                ),
                TextButton(
                  child: const Text('Close'),
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                ),
              ],
            ),
          );
        },
      );
    } else {
      _showErrorDialog("No image available for viewing.");
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
        isBarangayClearanceChecked = true;
        isPoliceClearanceChecked = true;
        isSSSCertificateChecked = true;
        isPhilhealthCertificateChecked = true;
        isApplicationFeeChecked = true;
        isCertificateOfRegistrationChecked = true;
        isDriversLicenseChecked = true;

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
                  ),
                ),
                ElevatedButton(
                  onPressed: _validateMtopId,
                  child: const Text('Validate MTOP ID'),
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
                    color: Colors.blue.shade100,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      buildRequirementItem(
                        title: 'Barangay Clearance',
                        isChecked: isBarangayClearanceChecked,
                        progress: barangayClearanceProgress,
                        image: barangayClearance,
                        onChanged: (bool? value) {
                          setState(() {
                            isBarangayClearanceChecked = value ?? false;
                          });
                        },
                        onCameraPressed: () => _openCamera('barangay_clearance'),
                        onView: () => _viewImage(barangayClearance),
                      ),
                      buildRequirementItem(
                        title: 'Police Clearance',
                        isChecked: isPoliceClearanceChecked,
                        progress: policeClearanceProgress,
                        image: policeClearance,
                        onChanged: (bool? value) {
                          setState(() {
                            isPoliceClearanceChecked = value ?? false;
                          });
                        },
                        onCameraPressed: () => _openCamera('police_clearance'),
                        onView: () => _viewImage(policeClearance),
                      ),
                      buildRequirementItem(
                        title: 'SSS Certificate',
                        isChecked: isSSSCertificateChecked,
                        progress: sssCertificateProgress,
                        image: sssCertificate,
                        onChanged: (bool? value) {
                          setState(() {
                            isSSSCertificateChecked = value ?? false;
                          });
                        },
                        onCameraPressed: () => _openCamera('sss_certificate'),
                        onView: () => _viewImage(sssCertificate),
                      ),
                      buildRequirementItem(
                        title: 'Philhealth Certificate',
                        isChecked: isPhilhealthCertificateChecked,
                        progress: philhealthCertificateProgress,
                        image: philhealthCertificate,
                        onChanged: (bool? value) {
                          setState(() {
                            isPhilhealthCertificateChecked = value ?? false;
                          });
                        },
                        onCameraPressed: () => _openCamera('philhealth_certificate'),
                        onView: () => _viewImage(philhealthCertificate),
                      ),
                      buildRequirementItem(
                        title: 'Application Fee',
                        isChecked: isApplicationFeeChecked,
                        progress: applicationFeeProgress,
                        image: applicationFee,
                        onChanged: (bool? value) {
                          setState(() {
                            isApplicationFeeChecked = value ?? false;
                          });
                        },
                        onCameraPressed: () => _openCamera('application_fee'),
                        onView: () => _viewImage(applicationFee),
                      ),
                      buildRequirementItem(
                        title: 'Certificate of Registration',
                        subtitle: 'of Motorized Tricycle for Hire',
                        isChecked: isCertificateOfRegistrationChecked,
                        progress: certificateOfRegistrationProgress,
                        image: certificateOfRegistration,
                        onChanged: (bool? value) {
                          setState(() {
                            isCertificateOfRegistrationChecked = value ?? false;
                          });
                        },
                        onCameraPressed: () => _openCamera('certificate_of_registration'),
                        onView: () => _viewImage(certificateOfRegistration),
                      ),
                      buildRequirementItem(
                        title: "Driver's License",
                        isChecked: isDriversLicenseChecked,
                        progress: driversLicenseProgress,
                        image: driversLicense,
                        onChanged: (bool? value) {
                          setState(() {
                            isDriversLicenseChecked = value ?? false;
                          });
                        },
                        onCameraPressed: () => _openCamera('drivers_license'),
                        onView: () => _viewImage(driversLicense),
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
              child: const Text('Submit'),
            )
          : null,
    );
  }

  Widget buildRequirementItem({
    required String title,
    String? subtitle,
    required bool isChecked,
    required double progress,
    required XFile? image,
    required ValueChanged<bool?> onChanged,
    required VoidCallback onCameraPressed,
    required VoidCallback onView,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Expanded(
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.camera_alt),
                  onPressed: onCameraPressed,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title),
                      if (subtitle != null)
                        Text(
                          subtitle,
                          style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
                        ),
                      if (progress > 0)
                        LinearProgressIndicator(
                          value: progress / 100,
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.visibility),
                onPressed: onView,
              ),
              Checkbox(
                value: isChecked,
                onChanged: onChanged,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
