import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:crypto/crypto.dart';
import 'dart:convert';
import 'package:memo4/user_types.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({Key? key}) : super(key: key);

  @override
  _RegisterPageState createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _formKey = GlobalKey<FormState>();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  String _institutionalId = '';
  String _name = '';
  String _mobileNumber = '';
  String _password = '';
  String _confirmPassword = '';
  String? _selectedUserType;
  bool _isVerified = false;
  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  final List<String> _userTypes = UserTypes.usertype;

  @override
  void initState() {
    super.initState();
  }

  Future<void> _verifyDetails() async {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();

      setState(() => _isLoading = true);

      try {
        print('\n=== Starting Verification Process ===');
        print('Input Values:');
        print('Institutional ID: $_institutionalId');
        print('Name: $_name');
        print('Mobile: $_mobileNumber');
        print('User Type: $_selectedUserType');

        var querySnapshot = await _firestore
            .collection('registerUser')
            .where('institutionalId', isEqualTo: _institutionalId)
            .get();

        print('Query returned ${querySnapshot.docs.length} documents');

        if (querySnapshot.docs.isEmpty) {
          print('No matching documents found');
          _showErrorDialog(
              'User not found',
              'No user found with Institutional ID: $_institutionalId\n\n'
                  'Please verify your ID or contact admin for registration.');
          return;
        }

        var userData = querySnapshot.docs.first.data();
        print('\nFound user data:');
        print(userData);

        // Case-insensitive name comparison and strict comparison for others
        bool nameMatches = userData['name'].toString().toLowerCase().trim() ==
            _name.toLowerCase().trim();
        bool mobileMatches =
            userData['mobileNumber'].toString().trim() == _mobileNumber.trim();
        bool userTypeMatches = userData['userType'] == _selectedUserType;

        print('\nVerification Results:');
        print('Name matches: $nameMatches');
        print('Mobile matches: $mobileMatches');
        print('User type matches: $userTypeMatches');

        if (nameMatches && mobileMatches && userTypeMatches) {
          if (userData['isRegistered'] == true) {
            _showErrorDialog('Already Registered',
                'This user has already been registered. Please login instead.');
            return;
          }

          setState(() => _isVerified = true);
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
              content: Text('Details verified! Please create a password.')));
        } else {
          List<String> mismatchFields = [];
          if (!nameMatches) mismatchFields.add('Name');
          if (!mobileMatches) mismatchFields.add('Mobile Number');
          if (!userTypeMatches) mismatchFields.add('User Type');

          _showErrorDialog(
              'Verification Failed',
              'The following fields did not match our records:\n'
                  '${mismatchFields.join(", ")}\n\n'
                  'Please check your details and try again.');
        }
      } catch (e) {
        print('Error during verification: $e');
        _showErrorDialog(
            'Error',
            'An error occurred during verification.\n'
                'Please try again or contact support.');
      } finally {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _register() async {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();

      setState(() => _isLoading = true);

      try {
        // Hash the password before saving it to Firestore
        String hashedPassword = _hashPassword(_password);

        // First, get the document reference using the query
        var querySnapshot = await _firestore
            .collection('registerUser')
            .where('institutionalId', isEqualTo: _institutionalId)
            .limit(1) // Limit to one document
            .get();

        if (querySnapshot.docs.isEmpty) {
          _showErrorDialog('User Not Found',
              'No user found with the given Institutional ID.\nPlease verify and try again.');
          return;
        }

        // Get the document reference of the first document
        var docRef = querySnapshot.docs.first.reference;

        // Update the document with the hashed password and registration status
        await docRef.update({
          'password': hashedPassword,
          'isRegistered': true,
          'registrationTimestamp': FieldValue.serverTimestamp(),
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Registration successful!')),
        );

        // Navigate to login page
        Navigator.of(context).pushReplacementNamed('/');
      } catch (e) {
        String errorMessage = 'Failed to complete registration.';

        print('Error during registration: $e');
      } finally {
        setState(() => _isLoading = false);
      }
    }
  }

  String _hashPassword(String password) {
    final bytes = utf8.encode(password); // Convert password to bytes
    final digest = sha256.convert(bytes); // Hash the password with SHA-256
    return digest.toString(); // Return hashed password as a string
  }

  void _showErrorDialog(String title, String message) {
    showDialog(
        context: context,
        builder: (context) => Theme(
              data: ThemeData(
                canvasColor: Colors
                    .white, // Forces the dropdown menu background color to white
              ),
              child: AlertDialog(
                title: Text(title),
                content: Text(message),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: Text('OK'),
                  ),
                ],
              ),
            ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: Text('\t\t\tUser Registration'),
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.of(context).pop(); // Pops the current screen
          },
        ),
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Card(
                        elevation: 4,
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            children: [
                              TextFormField(
                                decoration: InputDecoration(
                                  labelText: 'Institutional ID',
                                  border: OutlineInputBorder(),
                                  prefixIcon: Icon(Icons.badge),
                                ),
                                onSaved: (value) =>
                                    _institutionalId = value?.trim() ?? '',
                                validator: (value) =>
                                    value == null || value.isEmpty
                                        ? 'Enter Institutional ID'
                                        : null,
                              ),
                              SizedBox(height: 16),
                              TextFormField(
                                decoration: InputDecoration(
                                  labelText: 'Name',
                                  border: OutlineInputBorder(),
                                  prefixIcon: Icon(Icons.person),
                                ),
                                onSaved: (value) => _name = value?.trim() ?? '',
                                validator: (value) =>
                                    value == null || value.isEmpty
                                        ? 'Enter Name'
                                        : null,
                              ),
                              SizedBox(height: 16),
                              TextFormField(
                                decoration: InputDecoration(
                                  labelText: 'Mobile Number',
                                  border: OutlineInputBorder(),
                                  prefixIcon: Icon(Icons.phone),
                                ),
                                keyboardType: TextInputType.phone,
                                onSaved: (value) =>
                                    _mobileNumber = value?.trim() ?? '',
                                validator: (value) =>
                                    value == null || value.isEmpty
                                        ? 'Enter Mobile Number'
                                        : null,
                              ),
                              SizedBox(height: 16),
                              Theme(
                                data: ThemeData(
                                  canvasColor: Colors
                                      .white, // Forces the dropdown menu background color to white
                                ),
                                child: DropdownButtonFormField<String>(
                                  decoration: InputDecoration(
                                    labelText: 'User Type',
                                    border: OutlineInputBorder(),
                                    prefixIcon: Icon(Icons.work),
                                  ),
                                  value: _selectedUserType,
                                  onChanged: (value) {
                                    setState(() => _selectedUserType = value);
                                  },
                                  items: _userTypes.map((userType) {
                                    return DropdownMenuItem(
                                      value: userType,
                                      child: Text(userType),
                                    );
                                  }).toList(),
                                  validator: (value) => value == null
                                      ? 'Please select a user type'
                                      : null,
                                ),
                              )
                            ],
                          ),
                        ),
                      ),
                      SizedBox(height: 16),
                      if (_isVerified)
                        Card(
                          elevation: 4,
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              children: [
                                TextFormField(
                                  decoration: InputDecoration(
                                    labelText: 'Create Password',
                                    border: OutlineInputBorder(),
                                    prefixIcon: Icon(Icons.lock),
                                    suffixIcon: IconButton(
                                      icon: Icon(
                                        _obscurePassword
                                            ? Icons.visibility
                                            : Icons.visibility_off,
                                      ),
                                      onPressed: () {
                                        setState(() => _obscurePassword =
                                            !_obscurePassword);
                                      },
                                    ),
                                  ),
                                  obscureText: _obscurePassword,
                                  onSaved: (value) => _password = value ?? '',
                                  onChanged: (value) => _password = value,
                                  validator: (value) {
                                    if (value == null || value.isEmpty) {
                                      return 'Enter a password';
                                    } else if (value.length < 8) {
                                      return 'Password must be at least 8 characters';
                                    } else if (!RegExp(
                                            r'[!@#$%^&*(),.?":{}|<>]')
                                        .hasMatch(value)) {
                                      return 'Password must include at least one special character';
                                    }
                                    return null;
                                  },
                                ),
                                SizedBox(height: 16),
                                TextFormField(
                                  decoration: InputDecoration(
                                    labelText: 'Confirm Password',
                                    border: OutlineInputBorder(),
                                    prefixIcon: Icon(Icons.lock_outline),
                                    suffixIcon: IconButton(
                                      icon: Icon(
                                        _obscureConfirmPassword
                                            ? Icons.visibility
                                            : Icons.visibility_off,
                                      ),
                                      onPressed: () {
                                        setState(() => _obscureConfirmPassword =
                                            !_obscureConfirmPassword);
                                      },
                                    ),
                                  ),
                                  obscureText: _obscureConfirmPassword,
                                  validator: (value) {
                                    if (value != _password) {
                                      return 'Passwords do not match';
                                    }
                                    return null;
                                  },
                                ),
                              ],
                            ),
                          ),
                        ),
                      SizedBox(height: 24),
                      ElevatedButton(
                        onPressed: !_isVerified ? _verifyDetails : _register,
                        style: ElevatedButton.styleFrom(
                          padding: EdgeInsets.symmetric(vertical: 16),
                        ),
                        child: Text(
                          !_isVerified ? 'Verify Details' : 'Register',
                          style: TextStyle(fontSize: 16),
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
