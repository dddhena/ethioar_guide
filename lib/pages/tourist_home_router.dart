import 'package:flutter/material.dart';
import '../models/user_profile.dart';
import '../services/auth_service.dart';
import '../services/firestore_service.dart';
import '../services/journey_preference_service.dart';
import 'dashboard_page.dart';
import 'journey/ar_discovery_dashboard_page.dart';
import 'journey/choose_journey_page.dart';
import 'journey/guided_journey_dashboard_page.dart';

/// Routes tourists to the journey picker or their chosen dashboard after login.
class TouristHomeRouter {
  static Future<Widget> resolveHome() async {
    final uid = AuthService().currentUser?.uid;
    if (uid == null) return const ChooseJourneyPage();

    UserProfile profile;
    try {
      profile = await FirestoreService().getUserProfileModel(uid);
    } catch (_) {
      profile = UserProfile(uid: uid, name: '', email: '', role: 'tourist');
    }

    if (!profile.isTourist) {
      return const DashboardPage();
    }

    return switch (JourneyPreferenceService.instance.mode) {
      JourneyMode.guided => const GuidedJourneyDashboardPage(),
      JourneyMode.ar => const ArDiscoveryDashboardPage(),
      JourneyMode.unset => const ChooseJourneyPage(),
    };
  }

  static Future<void> navigateAfterLogin(BuildContext context) async {
    final home = await resolveHome();
    if (!context.mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => home),
    );
  }
}
