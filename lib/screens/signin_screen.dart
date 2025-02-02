import 'package:flutter/material.dart';
import 'package:login_signup/widgets/custom_scaffold.dart';
import 'dashboard.dart';  // Import DashboardScreen
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../theme/theme.dart';
import 'config.dart'; // Import the Config class for server IP

class SignInScreen extends StatefulWidget {
  const SignInScreen({super.key});

  @override
  State<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends State<SignInScreen> {
  final _formSignInKey = GlobalKey<FormState>();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _isPasswordVisible = false;

  Future<void> _login() async {
    if (_formSignInKey.currentState!.validate()) {
      final email = _emailController.text;
      final password = _passwordController.text;

      final loginData = {
        'email': email,
        'password': password,
      };

      try {
        final response = await http.post(
          Uri.parse('http://${Config.serverIp}:3000/login'),  // Use the dynamic server IP
          headers: {
            'Content-Type': 'application/json',
          },
          body: jsonEncode(loginData),
        );

        if (response.statusCode == 200) {
          final responseBody = jsonDecode(response.body);
          final String name = responseBody['user']['name'];  // Extract the user's name
          final String inspectorId = responseBody['user']['inspector_id'];  // Extract the inspector's ID

          // Show success message at the top with inspector ID
          _showTopMessage('Welcome, $name! Inspector ID: $inspectorId', Colors.green);

          // Navigate to the dashboard with the user's name and inspector ID
          Future.delayed(const Duration(seconds: 2), () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) =>
                    DashboardScreen(name: name, inspectorId: inspectorId),
              ),
            );
          });
        } else if (response.statusCode == 401) {
          // Invalid credentials
          _showTopMessage('Invalid credentials', Colors.red);
        } else {
          // Other server errors
          _showTopMessage('An error occurred. Please try again.', Colors.red);
        }
      } catch (e) {
        // Handle connection errors
        _showTopMessage('Error connecting to the server', Colors.red);
      }
    }
  }

  void _showTopMessage(String message, Color backgroundColor) {
    final overlay = Overlay.of(context);
    final overlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        top: MediaQuery.of(context).padding.top + 10, // Top with safe area
        left: 10,
        right: 10,
        child: Material(
          color: Colors.transparent,
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 20),
            decoration: BoxDecoration(
              color: backgroundColor,
              borderRadius: BorderRadius.circular(10),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 10,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                Icon(
                  backgroundColor == Colors.green
                      ? Icons.check_circle
                      : Icons.error,
                  color: Colors.white,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    message,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    // Show overlay
    overlay.insert(overlayEntry);

    // Remove overlay after 2 seconds
    Future.delayed(const Duration(seconds: 2), () {
      overlayEntry.remove();
    });
  }

  @override
  Widget build(BuildContext context) {
    return CustomScaffold(
      child: Column(
        children: [
          const Expanded(
            flex: 2,
            child: SizedBox(
              height: 20,
            ),
          ),
          Expanded(
            flex: 6,
            child: Container(
              padding: const EdgeInsets.fromLTRB(25.0, 50.0, 25.0, 20.0),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(40.0),
                  topRight: Radius.circular(40.0),
                ),
              ),
              child: SingleChildScrollView(
                child: Form(
                  key: _formSignInKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Text(
                        'Inspector Login',
                        style: TextStyle(
                          fontSize: 30.0,
                          fontWeight: FontWeight.w900,
                          color: lightColorScheme.primary,
                        ),
                      ),
                      const SizedBox(height: 40.0),
                      TextFormField(
                        controller: _emailController,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter Email';
                          }
                          return null;
                        },
                        decoration: InputDecoration(
                          label: const Text('Email'),
                          hintText: 'Enter Email',
                          hintStyle: const TextStyle(color: Colors.black26),
                          border: OutlineInputBorder(
                            borderSide: const BorderSide(color: Colors.black12),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderSide: const BorderSide(color: Colors.black12),
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                      const SizedBox(height: 25.0),
                      TextFormField(
                        controller: _passwordController,
                        obscureText: !_isPasswordVisible,
                        obscuringCharacter: '*',
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter Password';
                          }
                          return null;
                        },
                        decoration: InputDecoration(
                          label: const Text('Password'),
                          hintText: 'Enter Password',
                          hintStyle: const TextStyle(color: Colors.black26),
                          border: OutlineInputBorder(
                            borderSide: const BorderSide(color: Colors.black12),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderSide: const BorderSide(color: Colors.black12),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _isPasswordVisible
                                  ? Icons.visibility
                                  : Icons.visibility_off,
                            ),
                            onPressed: () {
                              setState(() {
                                _isPasswordVisible = !_isPasswordVisible;
                              });
                            },
                          ),
                        ),
                      ),
                      const SizedBox(height: 25.0),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _login,
                          child: const Text('Login'),
                        ),
                      ),
                      const SizedBox(height: 25.0),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Expanded(
                            child: Divider(
                              thickness: 0.7,
                              color: Colors.grey.withOpacity(0.5),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 25.0),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
