import 'package:flutter/material.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:fluttertoast/fluttertoast.dart';

class NetworkStatus extends StatefulWidget {
  final Widget child;

  const NetworkStatus({Key? key, required this.child}) : super(key: key);

  @override
  _NetworkStatusState createState() => _NetworkStatusState();
}

class _NetworkStatusState extends State<NetworkStatus> {
  bool isOnline = true;

  @override
  void initState() {
    super.initState();
    Connectivity().onConnectivityChanged.listen((ConnectivityResult result) {
      bool newStatus = result != ConnectivityResult.none;
      if (newStatus != isOnline) {
        setState(() {
          isOnline = newStatus;
        });
        showToast(isOnline ? "You are online" : "You are offline");
      }
    });

    // Check initial connectivity status
    _checkInitialConnectivity();
  }

  Future<void> _checkInitialConnectivity() async {
    ConnectivityResult result = await Connectivity().checkConnectivity();
    setState(() {
      isOnline = result != ConnectivityResult.none;
    });
    if (!isOnline) {
      showToast("You are offline");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Main app content
        widget.child,
        // Show overlay when offline
        if (!isOnline)
          Positioned.fill(
            child: Container(
              color: Colors.black54,
              alignment: Alignment.center,
              child: Container(
                padding: const EdgeInsets.all(16.0),
                decoration: BoxDecoration(
                  color: Colors.red,
                  borderRadius: BorderRadius.circular(8.0),
                ),
                child: const Text(
                  "No Internet Connection",
                  style: TextStyle(color: Colors.white, fontSize: 16.0),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

void showToast(String message) {
  Fluttertoast.showToast(
    msg: message,
    toastLength: Toast.LENGTH_SHORT,
    gravity: ToastGravity.BOTTOM,
    backgroundColor: Colors.black54,
    textColor: Colors.white,
    fontSize: 14.0,
  );
}
