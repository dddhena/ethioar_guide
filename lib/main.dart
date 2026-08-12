import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'pages/login_page.dart';
import 'pages/register_page.dart';
import 'pages/dashboard_page.dart';
// This app expects you to run `flutterfire configure` locally to generate
// lib/firebase_options.dart with DefaultFirebaseOptions. After that the app
// initializes Firebase for all supported platforms using the generated options.

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  late Future<FirebaseApp> _initialization;

  @override
  void initState() {
    super.initState();
    // Initialize Firebase with the generated platform-specific options.
    _initialization = Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  }

  @override
  Widget build(BuildContext context) {

    return FutureBuilder<FirebaseApp>(
      future: _initialization,
      builder: (context, snapshot) {
        // Show loading while initializing
        if (snapshot.connectionState != ConnectionState.done) {
          return const MaterialApp(
            home: Scaffold(
              body: Center(child: CircularProgressIndicator()),
            ),
          );
        }

        // If initialization failed, show an error but allow the user to continue
        if (snapshot.hasError) {
          return MaterialApp(
            home: Scaffold(
              appBar: AppBar(title: const Text('EthioAR Guide')),
              body: Center(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.error, size: 48, color: Colors.red),
                      const SizedBox(height: 12),
                      const Text('⚠️ Firebase initialization failed', style: TextStyle(fontSize: 18)),
                      const SizedBox(height: 8),
                      Text(snapshot.error.toString()),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const HomeDecider())),
                        child: const Text('Continue (offline)'),
                      )
                    ],
                  ),
                ),
              ),
            ),
          );
        }

        // Initialization succeeded — show the app
        return MaterialApp(
          title: 'EthioAR Guide',
          theme: ThemeData(primarySwatch: Colors.teal),
          home: const HomeDecider(),
          routes: {
            '/login': (_) => const LoginPage(),
            '/register': (_) => const RegisterPage(),
            '/dashboard': (_) => const DashboardPage(),
          },
        );
      },
    );
  }
}

class HomeDecider extends StatelessWidget {
  const HomeDecider({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Show a simple connected message and link to login
    return Scaffold(
      appBar: AppBar(title: const Text('EthioAR Guide')),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('✅ Firebase connected', style: TextStyle(fontSize: 18)),
            const SizedBox(height: 16),
            ElevatedButton(onPressed: () => Navigator.of(context).pushNamed('/login'), child: const Text('Go to Login')),
            const SizedBox(height: 8),
            ElevatedButton(onPressed: () => Navigator.of(context).pushNamed('/register'), child: const Text('Create Account')),
          ],
        ),
      ),
    );
  }
}
