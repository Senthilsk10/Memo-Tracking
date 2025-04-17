import 'package:flutter/material.dart';
import 'package:crypto/crypto.dart';
import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:memo4/user_types.dart';

class ForgotPasswordPage extends StatefulWidget {
  const ForgotPasswordPage({Key? key}) : super(key: key);

  @override
  _ForgotPasswordPageState createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends State<ForgotPasswordPage> {
  final List<String> userTypes = UserTypes.usertype;

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _mobileNumberController = TextEditingController();
  final TextEditingController _institutionalIdController =
      TextEditingController();
  final TextEditingController _newPasswordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();

  final _formKey = GlobalKey<FormState>();
  bool _isVerified = false;
  String? _selectedUserType;

  // Hash password using SHA-256
  String _hashPassword(String password) {
    var bytes = utf8.encode(password);
    var digest = sha256.convert(bytes);
    return digest.toString();
  }

  // Verify user details
  Future<bool> _verifyUserDetails() async {
    try {
      var querySnapshot = await FirebaseFirestore.instance
          .collection('registerUser')
          .where('name', isEqualTo: _nameController.text)
          .where('mobileNumber', isEqualTo: _mobileNumberController.text)
          .where('userType', isEqualTo: _selectedUserType)
          .where('institutionalId', isEqualTo: _institutionalIdController.text)
          .where('isRegistered', isEqualTo: true)
          .get();

      return querySnapshot.docs.isNotEmpty;
    } catch (e) {
      print('Verification error: $e');
      return false;
    }
  }

  // Update password in Firestore
  Future<void> _updatePassword() async {
    try {
      var querySnapshot = await FirebaseFirestore.instance
          .collection('registerUser')
          .where('name', isEqualTo: _nameController.text)
          .where('mobileNumber', isEqualTo: _mobileNumberController.text)
          .where('userType', isEqualTo: _selectedUserType)
          .where('institutionalId', isEqualTo: _institutionalIdController.text)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        var userDoc = querySnapshot.docs.first;

        String hashedNewPassword = _hashPassword(_newPasswordController.text);

        await userDoc.reference.update({'password': hashedNewPassword});

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Password updated successfully'),
            backgroundColor: Colors.green,
          ),
        );

        Navigator.of(context).pop();
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to update password: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: Text('Reset Password',
            style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Card(
            elevation: 4,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(15),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'Forgot Password',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: Colors.blue,
                          ),
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: 20),
                    _buildTextFormField(
                      controller: _nameController,
                      labelText: 'Full Name',
                      icon: Icons.person,
                      enabled: !_isVerified,
                      validator: (value) => value == null || value.isEmpty
                          ? 'Please enter your full name'
                          : null,
                    ),
                    SizedBox(height: 16),
                    _buildTextFormField(
                      controller: _mobileNumberController,
                      labelText: 'Mobile Number',
                      icon: Icons.phone,
                      keyboardType: TextInputType.phone,
                      enabled: !_isVerified,
                      validator: (value) => value == null || value.isEmpty
                          ? 'Please enter your mobile number'
                          : null,
                    ),
                    SizedBox(height: 16),
                    _buildTextFormField(
                      controller: _institutionalIdController,
                      labelText: 'Institutional ID',
                      icon: Icons.badge,
                      enabled: !_isVerified,
                      validator: (value) => value == null || value.isEmpty
                          ? 'Please enter your Institutional ID'
                          : null,
                    ),
                    SizedBox(height: 16),
                    if (!_isVerified) _buildUserTypeDropdown(),
                    SizedBox(height: 20),
                    if (!_isVerified) _buildVerificationButton(),
                    if (_isVerified) ...[
                      _buildTextFormField(
                        controller: _newPasswordController,
                        labelText: 'New Password',
                        icon: Icons.lock,
                        obscureText: true,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter a new password';
                          }
                          if (value.length < 6) {
                            return 'Password must be at least 6 characters';
                          }
                          return null;
                        },
                      ),
                      SizedBox(height: 16),
                      _buildTextFormField(
                        controller: _confirmPasswordController,
                        labelText: 'Confirm New Password',
                        icon: Icons.lock,
                        obscureText: true,
                        validator: (value) {
                          if (value != _newPasswordController.text) {
                            return 'Passwords do not match';
                          }
                          return null;
                        },
                      ),
                      SizedBox(height: 20),
                      _buildUpdatePasswordButton(),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextFormField({
    required TextEditingController controller,
    required String labelText,
    required IconData icon,
    bool obscureText = false,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
    bool enabled = true,
  }) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: labelText,
        prefixIcon: Icon(icon, color: Colors.blue),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: Colors.blue, width: 2),
        ),
      ),
      obscureText: obscureText,
      keyboardType: keyboardType,
      validator: validator,
      enabled: enabled,
    );
  }

  Widget _buildUserTypeDropdown() {
    return DropdownButtonFormField<String>(
      decoration: InputDecoration(
        labelText: 'User Type',
        prefixIcon: Icon(Icons.work, color: Colors.blue),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: Colors.blue, width: 2),
        ),
      ),
      value: _selectedUserType,
      hint: Text('Select User Type'),
      items: userTypes.map((String type) {
        return DropdownMenuItem<String>(
          value: type,
          child: Text(type),
        );
      }).toList(),
      onChanged: _isVerified
          ? null
          : (value) {
              setState(() {
                _selectedUserType = value;
              });
            },
      validator: (value) {
        if (value == null) {
          return 'Please select a user type';
        }
        return null;
      },
    );
  }

  Widget _buildVerificationButton() {
    return ElevatedButton(
      onPressed: () async {
        if (_formKey.currentState!.validate()) {
          bool verified = await _verifyUserDetails();
          if (verified) {
            setState(() {
              _isVerified = true;
            });
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('User verified successfully'),
                backgroundColor: Colors.green,
              ),
            );
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Verification failed'),
                backgroundColor: Colors.red,
              ),
            );
          }
        }
      },
      child:
          Text('Verify Details', style: TextStyle(fontWeight: FontWeight.bold)),
      style: ElevatedButton.styleFrom(
        backgroundColor: Color(0xfff5f6f8),
        padding: EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    );
  }

  Widget _buildUpdatePasswordButton() {
    return ElevatedButton(
      onPressed: () {
        if (_formKey.currentState!.validate()) {
          _updatePassword();
        }
      },
      child:
          Text('Reset Password', style: TextStyle(fontWeight: FontWeight.bold)),
      style: ElevatedButton.styleFrom(
        backgroundColor: Color(0xfff0f1f2),
        padding: EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    );
  }

  @override
  void dispose() {
    // Clean up controllers
    _nameController.dispose();
    _mobileNumberController.dispose();
    _institutionalIdController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }
}
