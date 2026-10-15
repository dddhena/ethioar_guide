import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'theme/ethio_theme.dart';
import 'services/location_service.dart';
import 'services/theme_service.dart';
import 'pages/login_page.dart';
import 'pages/register_page.dart';
import 'pages/dashboard_page.dart';
import 'pages/journey/choose_journey_page.dart';
import 'pages/journey/guided_journey_dashboard_page.dart';
import 'pages/journey/ar_discovery_dashboard_page.dart';
import 'pages/profile_page.dart';
import 'pages/nearby_landmarks_page.dart';
import 'pages/providers/service_providers_list_page.dart';
import 'pages/providers/my_reservations_page.dart';
import 'pages/providers/register_provider_page.dart';
import 'pages/providers/provider_dashboard_page.dart';
import 'pages/providers/admin_providers_page.dart';
import 'pages/admin/admin_dashboard.dart';
import 'pages/guides/guide_dashboard_page.dart';
import 'pages/recommendations_page.dart';
// This app expects you to run `flutterfire configure` locally to generate
// lib/firebase_options.dart with DefaultFirebaseOptions. After that the app
// initializes Firebase for all supported platforms using the generated options.

import 'pages/welcome/welcome_landing_page.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  late Future<FirebaseApp> _initialization;
  final ThemeService _themeService = ThemeService();

  @override
  void initState() {
    super.initState();
    // Initialize Firebase with the generated platform-specific options.
    _initialization = Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
    _themeService.initialize();
    LocationService.getCurrentPositionWeb(); // Pre-warm location cache for instant availability across all pages
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _themeService,
      builder: (context, child) {
        return MaterialApp(
          title: 'EthioAR Guide',
          theme: buildEthioTheme(),
          darkTheme: buildEthioDarkTheme(),
          themeMode: _themeService.isDarkMode ? ThemeMode.dark : ThemeMode.light,
          routes: {
            '/welcome': (_) => const WelcomeLandingPage(),
            '/login': (_) => const LoginPage(),
            '/register': (_) => const RegisterPage(),
            '/dashboard': (_) => const DashboardPage(),
            '/choose-journey': (_) => const ChooseJourneyPage(),
            '/guided-journey': (_) => const GuidedJourneyDashboardPage(),
            '/ar-discovery': (_) => const ArDiscoveryDashboardPage(),
            '/profile': (_) => const ProfilePage(),
            '/nearby': (_) => const NearbyLandmarksPage(),
            '/services': (_) => const ServiceProvidersListPage(),
            '/my-reservations': (_) => const MyReservationsPage(),
            '/provider-dashboard': (_) => const ProviderDashboardPage(),
            '/register-provider': (_) => const RegisterProviderPage(),
            '/admin-providers': (_) => const AdminProvidersPage(),
            '/admin-dashboard': (_) => const AdminDashboard(),
            '/guide-dashboard': (_) => const GuideDashboardPage(),
            '/recommendations': (_) => const RecommendationsPage(),
          },
          home: FutureBuilder<FirebaseApp>(
            future: _initialization,
            builder: (context, snapshot) {
              // While initializing, show a clean branded splash
              if (snapshot.connectionState != ConnectionState.done) {
                return const Scaffold(
                  backgroundColor: EthioColors.cream,
                  body: Center(
                    child: CircularProgressIndicator(color: EthioColors.forest),
                  ),
                );
              }

              // Return beautiful welcome landing page for all users (online or offline)
              return const WelcomeLandingPage();
            },
          ),
        );
      },
    );
  }
}
