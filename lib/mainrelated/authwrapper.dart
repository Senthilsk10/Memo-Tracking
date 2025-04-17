import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../User_authentication/login.dart';

class AuthWrapper extends StatelessWidget {
  final Widget child;

  const AuthWrapper({required this.child});

  Future<bool> _isUserLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('isLoggedIn') ?? false;
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
      future: _isUserLoggedIn(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        if (snapshot.data == true) {
          return child; // Allow access
        }
        return LoginPage(); // Redirect to login
      },
    );
  }
}

class RoleBasedAuthWrapper extends StatelessWidget {
  final Widget child;
  final List<String> allowedRoles;

  const RoleBasedAuthWrapper({required this.child, required this.allowedRoles});

  Future<String?> _getUserRole() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('userType');
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<String?>(
      future: _getUserRole(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        if (snapshot.hasData && allowedRoles.contains(snapshot.data)) {
          return child; // Allow access for specific roles
        }
        return LoginPage(); // Redirect unauthorized users
      },
    );
  }
}
