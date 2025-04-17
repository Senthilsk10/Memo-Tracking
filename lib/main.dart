import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:fluttertoast/fluttertoast.dart';
import '../mainrelated/authwrapper.dart';
import '../admin/oadmin.dart';
import '../User_authentication/register.dart';
import '../responder/responder.dart';
import '../User_authentication/login.dart';
import '../approver/approver.dart';
import '../memoissuer/memo.dart';
import '../User_authentication/profile.dart';
import '../mainrelated/network.dart';
import 'package:memo4/welcome.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

/// Background handler
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  print("🔙 Background message: ${message.notification?.title}");
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  if (kIsWeb) {
    await Firebase.initializeApp(
      options: FirebaseOptions(
        apiKey: "AIzaSyDS8srYC86pg9R5cvQAgluKf5dHJ2DdWqo",
        authDomain: "memo4-a7d0c.firebaseapp.com",
        projectId: "memo4-a7d0c",
        storageBucket: "memo4-a7d0c.firebasestorage.app",
        messagingSenderId: "667241246281",
        appId: "1:667241246281:web:d8867bc6f181148f9b9998",
        measurementId: "G-QRS76FTH6X",
      ),
    );
  } else {
    await Firebase.initializeApp();
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
  }

  final prefs = await SharedPreferences.getInstance();
  final bool isLoggedIn = prefs.getBool('isLoggedIn') ?? false;
  final String userType = prefs.getString('userType') ?? '';

  String initialRoute;
  if (!isLoggedIn) {
    initialRoute = '/welcome';
  } else {
    switch (userType) {
      case 'Ward Staff Nurse':
        initialRoute = '/memo';
        break;
      case 'Approvers - Ward Incharge':
      case 'Approvers - Nursing Superintendent':
      case 'Approvers - RMO (Resident Medical Officer)':
      case 'Approvers - Medical Superintendent (MS)':
      case 'Approvers - Dean':
        initialRoute = '/approver';
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
        initialRoute = '/responder';
        break;
      case 'Admin':
        initialRoute = '/admin';
        break;
      default:
        initialRoute = '/';
        break;
    }
  }

  runApp(MyApp(initialRoute: initialRoute, userType: userType));
}

ThemeData appTheme() {
  return ThemeData(
    primaryColor: Color(0xff0ee87b),
    colorScheme: ColorScheme.fromSwatch(primarySwatch: Colors.blue).copyWith(
      secondary: Color(0xfffafcff),
    ),
    scaffoldBackgroundColor: Colors.white,
    textTheme: TextTheme(
      titleLarge: TextStyle(
          fontSize: 24, fontWeight: FontWeight.bold, color: Colors.black),
      bodyLarge: TextStyle(fontSize: 16, color: Colors.black),
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: Color(0xFF4285F4),
      titleTextStyle: TextStyle(color: Colors.white, fontSize: 20),
    ),
    dropdownMenuTheme: DropdownMenuThemeData(
      menuStyle: MenuStyle(
        backgroundColor: MaterialStateProperty.all(Colors.white),
      ),
      textStyle: TextStyle(color: Colors.black),
    ),
  );
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

class MyApp extends StatefulWidget {
  final String initialRoute;
  final String userType;

  MyApp({required this.initialRoute, required this.userType});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  void initState() {
    super.initState();
    initNotifications();
  }

  Future<void> initNotifications() async {
    final FirebaseMessaging messaging = FirebaseMessaging.instance;

    await messaging.requestPermission();
    final token = await messaging.getToken();
    print("📱 FCM Token: $token");

    // Foreground notification listener
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      print("📩 Foreground message: ${message.notification?.title}");

      RemoteNotification? notification = message.notification;
      AndroidNotification? android = message.notification?.android;

      if (notification != null && android != null) {
        flutterLocalNotificationsPlugin.show(
          notification.hashCode,
          notification.title,
          notification.body,
          NotificationDetails(
            android: AndroidNotificationDetails(
              'default_channel',
              'Default',
              importance: Importance.high,
              priority: Priority.high,
              icon: '@mipmap/ic_launcher',
            ),
          ),
        );
      }
    });

    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      print('📬 App opened from notification: ${message.notification?.title}');
      // Optionally navigate based on message.data['route']
    });

    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    final InitializationSettings initializationSettings =
        InitializationSettings(android: initializationSettingsAndroid);

    await flutterLocalNotificationsPlugin.initialize(initializationSettings);
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'MemoTrack',
      debugShowCheckedModeBanner: false,
      theme: appTheme(),
      initialRoute: widget.initialRoute,
      builder: (context, child) {
        return Stack(
          children: [child!, NetworkStatus(child: child!)],
        );
      },
      routes: {
        '/welcome': (context) => WelcomePage(),
        '/login': (context) => LoginPage(),
        '/register': (context) => RegisterPage(),
        '/memo': (context) => RoleBasedAuthWrapper(
              child: MemoPage(),
              allowedRoles: ['Ward Staff Nurse'],
            ),
        '/admin': (context) => RoleBasedAuthWrapper(
              child: AdminDashboard(),
              allowedRoles: ['Admin'],
            ),
        '/approver': (context) => AuthWrapper(
              child: FutureBuilder<String?>(
                future: _getUserRole(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return Scaffold(
                      body: Center(child: CircularProgressIndicator()),
                    );
                  }
                  if (snapshot.hasData) {
                    return ApproverPage(userRole: snapshot.data!);
                  }
                  return LoginPage();
                },
              ),
            ),
        '/profile': (context) => AuthWrapper(child: ProfilePage()),
        '/responder': (context) => AuthWrapper(
              child: FutureBuilder<String?>(
                future: _getUserRole(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return Scaffold(
                      body: Center(child: CircularProgressIndicator()),
                    );
                  }
                  if (snapshot.hasData) {
                    return ResponderPage(
                      userType: snapshot.data!,
                      institutionalId: '',
                    );
                  }
                  return LoginPage();
                },
              ),
            ),
      },
    );
  }

  Future<String?> _getUserRole() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('userType');
  }
}
