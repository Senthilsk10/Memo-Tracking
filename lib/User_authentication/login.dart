import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:animated_text_kit/animated_text_kit.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:memo4/user_types.dart';
import 'forgotpass.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

class LoginPage extends StatefulWidget {
  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  String _institutionalId = '';
  String _password = '';
  String? _selectedUserType;
  bool _isLoading = false;
  bool _obscurePassword = true;

  final List<String> _userTypes = UserTypes.usertype;

  final String thirukkuralQuote =
      "தன்னிலைத் தன்னை நின்று சிந்தியேன் கற்றார்\nஅவர்களே வாழ்வர் வாழ்வு.\n\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t\t- திருவள்ளுவர்";

  // AppSheet-like color palette
  final Color _primaryColor = Color(0xFF4285F4); // Google Blue
  final Color _secondaryColor = Color(0xFF34A853); // Google Green
  final Color _errorColor = Color(0xFFEA4335); // Google Red

  // Hash the password with SHA-256
  String _hashPassword(String password) {
    final bytes = utf8.encode(password);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  Future<void> _saveUserSession(
      String institutionalId, String userType, String mobile) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isLoggedIn', true);
    await prefs.setString('institutionalId', institutionalId);
    await prefs.setString('userType', userType);
    await prefs.setString('mobile', mobile);
  }

  void _subscribeToWorkerTypeTopic(String userType) {
    final topic = UserTypes.userTypeMapping[userType];
    if (topic != null) {
      FirebaseMessaging.instance.subscribeToTopic(topic);
    }
  }

  // Function to show toast message
  void _showToast(String message, {bool isError = false}) {
    Fluttertoast.showToast(
      msg: message,
      toastLength: Toast.LENGTH_LONG,
      gravity: ToastGravity.BOTTOM,
      backgroundColor: isError ? _errorColor : _secondaryColor,
      textColor: Colors.white,
      fontSize: 16.0,
    );
  }

  // Function to handle login
  Future<void> _login() async {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();
      setState(() {
        _isLoading = true;
      });

      try {
        // Query Firestore to find user by institutionalId
        var querySnapshot = await FirebaseFirestore.instance
            .collection('registerUser')
            .where('institutionalId', isEqualTo: _institutionalId)
            .get();

        if (querySnapshot.docs.isEmpty) {
          _showToast('No user found with ID: $_institutionalId', isError: true);
          return;
        }

        var userDoc = querySnapshot.docs.first;
        var userData = userDoc.data() as Map<String, dynamic>;

        // Safely retrieve fields
        String institutionalId = userData['institutionalId'] ?? '';
        String userType = userData['userType'] ?? '';
        String mobile = userData['mobile'] ?? '';
        String storedPasswordHash = userData['password'] ?? '';

        // Check if userType and password match
        if (userType != _selectedUserType) {
          _showToast('Selected user type does not match records',
              isError: true);
          return;
        }

        // Hash the entered password and compare with the stored hash
        String enteredPasswordHash = _hashPassword(_password);

        if (storedPasswordHash != enteredPasswordHash) {
          _showToast('Incorrect password', isError: true);
          return;
        }

        // Save session data
        await _saveUserSession(institutionalId, userType, mobile);
        // _subscribeToWorkerTypeTopic(userType);
        // Show login success toast
        _showToast('Logged in successfully as $userType');

        // Navigate based on userType
        _navigateBasedOnUserType(userType);
      } catch (e) {
        _showToast('An error occurred while processing your login',
            isError: true);
      } finally {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  // Navigate to the respective dashboard based on userType
  void _navigateBasedOnUserType(String userType) {
    switch (userType) {
      case 'Ward Staff Nurse':
        Navigator.pushNamedAndRemoveUntil(context, '/memo', (route) => false);
        break;
      case 'Approvers - Ward Incharge':
      case 'Approvers - Nursing Superintendent':
      case 'Approvers - RMO (Resident Medical Officer)':
      case 'Approvers - Medical Superintendent (MS)':
      case 'Approvers - Dean':
        Navigator.pushReplacementNamed(context, '/approver');
        break;
      case 'Responder - Carpenter':
      case 'Responder - Plumber':
      case 'Responder - Housekeeping Supervisor':
      case 'Responder - Biomedical Engineer':
      case 'Responder - Civil':
      case 'Responder - PWD Electrician':
      case 'Responder - Hospital Electrician':
      case 'Responder - Laundry':
      case 'Responder - Manifold':
        Navigator.pushReplacementNamed(context, '/responder');
        break;
      case 'Admin':
        Navigator.pushReplacementNamed(context, '/admin');
        break;
      default:
        _showToast('Invalid user type', isError: true);
    }
  }

  // Forgot password flow
  void _forgotPassword() {
    try {
      // Navigate to the Forgot Password page
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => ForgotPasswordPage()),
      );
    } catch (e) {
      _showToast('Error during navigation to Forgot Password page',
          isError: true);
    }
  }

  // Navigate to Register Page
  void _navigateToRegister() {
    Navigator.pushNamed(context, '/register');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: Text('Login'),
        backgroundColor: _primaryColor,
      ),
      body: Container(
        padding: EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                // Thirukkural section
                Container(
                  height: 100,
                  padding: EdgeInsets.all(16),
                  child: AnimatedTextKit(
                    animatedTexts: [
                      TypewriterAnimatedText(
                        thirukkuralQuote,
                        textStyle: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: _primaryColor,
                        ),
                        speed: Duration(milliseconds: 100),
                      ),
                    ],
                    repeatForever: true,
                  ),
                ),
                SizedBox(height: 20),

                Theme(
                  data: ThemeData(
                    canvasColor: Colors
                        .white, // Forces the dropdown menu background color to white
                  ),
                  child: DropdownButtonFormField<String>(
                    decoration: InputDecoration(
                      labelText: 'User Type',
                      filled: true,
                      fillColor: Colors
                          .white, // Set the form field background to white
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(color: _primaryColor, width: 1),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide:
                            BorderSide(color: Colors.grey.shade400, width: 1),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(color: _primaryColor, width: 2),
                      ),
                    ),
                    value: _selectedUserType,
                    onChanged: (value) {
                      setState(() {
                        _selectedUserType = value as String?;
                      });
                    },
                    items: _userTypes.map((userType) {
                      return DropdownMenuItem(
                        value: userType,
                        child: Text(userType),
                      );
                    }).toList(),
                    validator: (value) =>
                        value == null ? 'Please select a User Type' : null,
                    isExpanded: true,
                  ),
                ),

                SizedBox(height: 20), // Institutional ID input
                TextFormField(
                  decoration: InputDecoration(
                    labelText: 'Institutional ID',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: _primaryColor, width: 1),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide:
                          BorderSide(color: Colors.grey.shade400, width: 1),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: _primaryColor, width: 2),
                    ),
                    prefixIcon:
                        Icon(Icons.account_circle, color: _primaryColor),
                  ),
                  onChanged: (value) => _institutionalId = value,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your Institutional ID';
                    }
                    return null;
                  },
                ),
                SizedBox(height: 16),

                // Password input
                TextFormField(
                  decoration: InputDecoration(
                    labelText: 'Password',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: _primaryColor, width: 1),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide:
                          BorderSide(color: Colors.grey.shade400, width: 1),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: _primaryColor, width: 2),
                    ),
                    prefixIcon: Icon(Icons.lock, color: _primaryColor),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePassword
                            ? Icons.visibility_off
                            : Icons.visibility,
                        color: _primaryColor,
                      ),
                      onPressed: () {
                        setState(() {
                          _obscurePassword = !_obscurePassword;
                        });
                      },
                    ),
                  ),
                  obscureText: _obscurePassword,
                  onChanged: (value) => _password = value,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your password';
                    }
                    if (value.length < 6) {
                      return 'Password must be at least 6 characters';
                    }
                    return null;
                  },
                ),
                SizedBox(height: 16),

                // Login Button (Modern Flutter Styling)
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _primaryColor,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    minimumSize: Size(double.infinity, 50),
                  ),
                  onPressed: _isLoading ? null : _login,
                  child: _isLoading
                      ? CircularProgressIndicator(color: Colors.white)
                      : Text('Login', style: TextStyle(fontSize: 16)),
                ),
                SizedBox(height: 16),

                // Forgot Password
                TextButton(
                  onPressed: _forgotPassword,
                  child: Text(
                    'Forgot Password?',
                    style: TextStyle(color: _primaryColor),
                  ),
                ),

                // Register Button
                TextButton(
                  onPressed: _navigateToRegister,
                  child: Text(
                    'New user? Register here',
                    style: TextStyle(color: _secondaryColor),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
