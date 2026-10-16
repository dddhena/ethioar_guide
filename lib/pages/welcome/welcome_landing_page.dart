import 'dart:async';
import 'package:flutter/material.dart';
import '../../theme/ethio_theme.dart';
import '../../services/theme_service.dart';
import '../../services/auth_service.dart';
import '../../services/session_service.dart';
import '../tourist_home_router.dart';
import '../login_page.dart';
import '../register_page.dart';
import '../journey/choose_journey_page.dart';

class WelcomeLandingPage extends StatefulWidget {
  const WelcomeLandingPage({super.key});

  @override
  State<WelcomeLandingPage> createState() => _WelcomeLandingPageState();
}

class _WelcomeLandingPageState extends State<WelcomeLandingPage>
    with SingleTickerProviderStateMixin {
  final ThemeService _themeService = ThemeService();
  final SessionService _sessionService = SessionService();
  final AuthService _authService = AuthService();

  bool _checkingSession = true;
  bool _hasActiveSession = false;
  String? _currentUserName;
  String? _currentUserEmail;
  String? _sessionNotice;

  late PageController _heritagePageController;
  int _activeHeritageIndex = 0;
  Timer? _carouselTimer;

  final List<Map<String, String>> _heritageHighlights = [
    {
      'title': 'Fasil Ghebbi Castles',
      'location': 'Gondar, Amhara Region',
      'tag': 'UNESCO World Heritage',
      'desc': '17th-century Camelot of Africa featuring majestic imperial castles, banquet halls, and royal archives.',
      'image': 'https://images.unsplash.com/photo-1609137144813-7d8bfe2a0e44?auto=format&fit=crop&w=900&q=80',
      'accent': '0xFF144D3B',
    },
    {
      'title': 'Rock-Hewn Churches',
      'location': 'Lalibela, Wollo',
      'tag': '12th Century Marvel',
      'desc': 'Eleven monolithic medieval cave churches carved from monolithic pink volcanic tuff rock.',
      'image': 'https://images.unsplash.com/photo-1544717305-2782549b5136?auto=format&fit=crop&w=900&q=80',
      'accent': '0xFFD4693F',
    },
    {
      'title': 'Towering Obelisks',
      'location': 'Aksum, Tigray',
      'tag': 'Ancient Axumite Empire',
      'desc': 'Towering granite stelae marking underground royal burial chambers of ancient emperors and queens.',
      'image': 'https://images.unsplash.com/photo-1578925518470-4def7a0f08bb?auto=format&fit=crop&w=900&q=80',
      'accent': '0xFF2E5F80',
    },
    {
      'title': 'Simien Mountains',
      'location': 'Debark, Gondar',
      'tag': 'Roof of Africa',
      'desc': 'Jagged peaks, deep valleys, and rare endemic wildlife including the Walia Ibex and Gelada Baboon.',
      'image': 'https://images.unsplash.com/photo-1526772662000-3f88f10405ff?auto=format&fit=crop&w=900&q=80',
      'accent': '0xFFC59B27',
    },
  ];

  @override
  void initState() {
    super.initState();
    _heritagePageController = PageController(viewportFraction: 0.90);
    _checkUserSession();
    _startCarouselTimer();
  }

  @override
  void dispose() {
    _carouselTimer?.cancel();
    _heritagePageController.dispose();
    super.dispose();
  }

  void _startCarouselTimer() {
    _carouselTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      if (!mounted || !_heritagePageController.hasClients) return;
      final next = (_activeHeritageIndex + 1) % _heritageHighlights.length;
      _heritagePageController.animateToPage(
        next,
        duration: const Duration(milliseconds: 600),
        curve: Curves.easeInOutCubic,
      );
    });
  }

  Future<void> _checkUserSession() async {
    try {
      final status = await _sessionService.checkSessionStatus();
      final user = _authService.currentUser;

      if (mounted) {
        setState(() {
          _checkingSession = false;
          if (status == SessionStatus.active && user != null) {
            _hasActiveSession = true;
            _currentUserName = user.displayName?.isNotEmpty == true
                ? user.displayName
                : user.email?.split('@').first ?? 'Traveler';
            _currentUserEmail = user.email;
          } else if (status == SessionStatus.expired) {
            _hasActiveSession = false;
            _sessionNotice = 'Your previous session expired for security. Please sign in again.';
          } else {
            _hasActiveSession = false;
          }
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() => _checkingSession = false);
      }
    }
  }

  void _resumeSession() async {
    await TouristHomeRouter.navigateAfterLogin(context);
  }

  void _signOutNow() async {
    await _sessionService.logout(context, reason: 'Signed out successfully.');
    setState(() {
      _hasActiveSession = false;
      _currentUserName = null;
      _currentUserEmail = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _themeService,
      builder: (context, _) {
        final isDark = _themeService.isDarkMode;
        final bgColor = isDark ? const Color(0xFF0F141C) : EthioColors.cream;
        final cardColor = isDark ? const Color(0xFF1B2230) : Colors.white;
        final textColor = isDark ? Colors.white : EthioColors.charcoal;
        final subtextColor = isDark ? Colors.white70 : EthioColors.stone;

        return Scaffold(
          backgroundColor: bgColor,
          body: SafeArea(
            child: _checkingSession
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const CircularProgressIndicator(color: EthioColors.forest),
                        const SizedBox(height: 16),
                        Text(
                          'Initializing EthioAR Guide...',
                          style: TextStyle(color: subtextColor, fontSize: 14),
                        ),
                      ],
                    ),
                  )
                : CustomScrollView(
                    slivers: [
                      // 1. Top Navigation Bar
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                          child: Row(
                            children: [
                              // Brand Badge
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                decoration: BoxDecoration(
                                  color: EthioColors.forest,
                                  borderRadius: BorderRadius.circular(12),
                                  boxShadow: [
                                    BoxShadow(
                                      color: EthioColors.forest.withValues(alpha: 0.3),
                                      blurRadius: 8,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: const Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.view_in_ar_rounded, color: Colors.white, size: 18),
                                    SizedBox(width: 6),
                                    Text(
                                      'ETHIO AR',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w900,
                                        fontSize: 12,
                                        letterSpacing: 1.2,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const Spacer(),

                              // Theme Toggle Button
                              IconButton(
                                tooltip: isDark ? 'Switch to Light Mode' : 'Switch to Dark Mode',
                                icon: Icon(
                                  isDark ? Icons.light_mode_rounded : Icons.dark_mode_rounded,
                                  color: textColor,
                                  size: 20,
                                ),
                                onPressed: () => _themeService.toggleTheme(),
                              ),

                              // Info Modal
                              IconButton(
                                tooltip: 'About EthioAR Guide',
                                icon: Icon(Icons.info_outline_rounded, color: textColor, size: 20),
                                onPressed: _showAboutDialog,
                              ),
                            ],
                          ),
                        ),
                      ),

                      // 2. Active Session Card (If User is already logged in)
                      if (_hasActiveSession)
                        SliverToBoxAdapter(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                            child: Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    EthioColors.forest,
                                    EthioColors.forestLight,
                                  ],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                borderRadius: BorderRadius.circular(20),
                                boxShadow: [
                                  BoxShadow(
                                    color: EthioColors.forest.withValues(alpha: 0.3),
                                    blurRadius: 12,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: Row(
                                children: [
                                  CircleAvatar(
                                    radius: 22,
                                    backgroundColor: Colors.white.withValues(alpha: 0.2),
                                    child: const Icon(Icons.person_rounded, color: Colors.white, size: 24),
                                  ),
                                  const SizedBox(width: 14),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Welcome back, $_currentUserName!',
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 15,
                                          ),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          _currentUserEmail ?? 'Active Session Verified',
                                          style: const TextStyle(
                                            color: Colors.white70,
                                            fontSize: 12,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  ElevatedButton(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.white,
                                      foregroundColor: EthioColors.forest,
                                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                    ),
                                    onPressed: _resumeSession,
                                    child: const Text('Continue', style: TextStyle(fontWeight: FontWeight.bold)),
                                  ),
                                  const SizedBox(width: 6),
                                  IconButton(
                                    tooltip: 'Log Out',
                                    icon: const Icon(Icons.logout_rounded, color: Colors.white70, size: 20),
                                    onPressed: _signOutNow,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),

                      // 3. Session Expiration Notice (if triggered)
                      if (_sessionNotice != null)
                        SliverToBoxAdapter(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                              decoration: BoxDecoration(
                                color: EthioColors.terracotta.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: EthioColors.terracotta.withValues(alpha: 0.3)),
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.warning_amber_rounded, color: EthioColors.terracotta, size: 20),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Text(
                                      _sessionNotice!,
                                      style: const TextStyle(color: EthioColors.terracotta, fontSize: 12, fontWeight: FontWeight.w600),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),

                      // 4. Hero Section
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Country pill
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                decoration: BoxDecoration(
                                  color: EthioColors.terracotta.withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(color: EthioColors.terracotta.withValues(alpha: 0.3)),
                                ),
                                child: const Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text('🇪🇹', style: TextStyle(fontSize: 14)),
                                    SizedBox(width: 6),
                                    Text(
                                      'ETHIOPIA',
                                      style: TextStyle(
                                        color: EthioColors.terracotta,
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                        letterSpacing: 0.8,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 14),

                              // Main Title
                              Text(
                                'Discover Ethiopia in\nAugmented Reality',
                                style: TextStyle(
                                  fontSize: 32,
                                  fontWeight: FontWeight.w900,
                                  color: textColor,
                                  height: 1.15,
                                  letterSpacing: -0.5,
                                ),
                              ),
                              const SizedBox(height: 10),

                              // Tagline
                              Text(
                                'Step into living history. Explore 3,000 years of castles, rock-hewn wonders, and mountain landscapes with real-time AR navigation and certified local guides.',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: subtextColor,
                                  height: 1.5,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      // 5. Hero Carousel of Ethiopian Wonders
                      SliverToBoxAdapter(
                        child: SizedBox(
                          height: 250,
                          child: PageView.builder(
                            controller: _heritagePageController,
                            itemCount: _heritageHighlights.length,
                            onPageChanged: (idx) => setState(() => _activeHeritageIndex = idx),
                            itemBuilder: (context, index) {
                              final item = _heritageHighlights[index];
                              return _buildHeritageCard(item, isDark);
                            },
                          ),
                        ),
                      ),

                      // Carousel Indicators
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.only(top: 10, bottom: 20),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: List.generate(_heritageHighlights.length, (idx) {
                              final isSelected = _activeHeritageIndex == idx;
                              return AnimatedContainer(
                                duration: const Duration(milliseconds: 300),
                                margin: const EdgeInsets.symmetric(horizontal: 3),
                                width: isSelected ? 22 : 6,
                                height: 6,
                                decoration: BoxDecoration(
                                  color: isSelected ? EthioColors.forest : Colors.grey.withValues(alpha: 0.3),
                                  borderRadius: BorderRadius.circular(3),
                                ),
                              );
                            }),
                          ),
                        ),
                      ),

                      // 6. Primary Action Buttons
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          child: Column(
                            children: [
                              // Primary "Begin Journey" Button
                              SizedBox(
                                width: double.infinity,
                                height: 54,
                                child: ElevatedButton.icon(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: EthioColors.forest,
                                    foregroundColor: Colors.white,
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                    elevation: 4,
                                    shadowColor: EthioColors.forest.withValues(alpha: 0.4),
                                  ),
                                  onPressed: () {
                                    if (_hasActiveSession) {
                                      _resumeSession();
                                    } else {
                                      Navigator.of(context).push(
                                        MaterialPageRoute(builder: (_) => const ChooseJourneyPage()),
                                      );
                                    }
                                  },
                                  icon: const Icon(Icons.explore_rounded, size: 22),
                                  label: Text(
                                    _hasActiveSession ? 'Enter My Journey Dashboard' : 'Explore Tourist Journeys',
                                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 0.4),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 12),

                              // Auth Actions Row (Sign In & Register)
                              Row(
                                children: [
                                  Expanded(
                                    child: OutlinedButton.icon(
                                      style: OutlinedButton.styleFrom(
                                        padding: const EdgeInsets.symmetric(vertical: 14),
                                        side: BorderSide(color: isDark ? Colors.white24 : EthioColors.divider, width: 1.5),
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                                      ),
                                      onPressed: () => Navigator.of(context).push(
                                        MaterialPageRoute(builder: (_) => const LoginPage()),
                                      ),
                                      icon: Icon(Icons.login_rounded, size: 18, color: textColor),
                                      label: Text('Sign In', style: TextStyle(color: textColor, fontWeight: FontWeight.bold)),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: ElevatedButton.icon(
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: EthioColors.terracotta,
                                        foregroundColor: Colors.white,
                                        padding: const EdgeInsets.symmetric(vertical: 14),
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                                        elevation: 2,
                                      ),
                                      onPressed: () => Navigator.of(context).push(
                                        MaterialPageRoute(builder: (_) => const RegisterPage()),
                                      ),
                                      icon: const Icon(Icons.person_add_rounded, size: 18),
                                      label: const Text('Create Account', style: TextStyle(fontWeight: FontWeight.bold)),
                                    ),
                                  ),
                                ],
                              ),

                              const SizedBox(height: 10),

                              // Guest / Offline Button
                              TextButton.icon(
                                onPressed: () => Navigator.of(context).push(
                                  MaterialPageRoute(builder: (_) => const ChooseJourneyPage()),
                                ),
                                icon: Icon(Icons.lock_open_rounded, size: 16, color: subtextColor),
                                label: Text(
                                  'Continue as Guest (Browse & Navigate without login)',
                                  style: TextStyle(color: subtextColor, fontSize: 13),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      // 7. Interactive Feature Pillars
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(20, 24, 20, 8),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'KEY EXPERIENCES',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 1.1,
                                  color: subtextColor,
                                ),
                              ),
                              const SizedBox(height: 14),
                              _buildFeatureTile(
                                icon: Icons.view_in_ar_rounded,
                                iconColor: EthioColors.forestLight,
                                title: 'AR Spatial Navigation & Wayfinding',
                                desc: 'Directional 3D ground paths and floating indicators point you straight to historical gates and monuments.',
                                cardColor: cardColor,
                                textColor: textColor,
                                subtextColor: subtextColor,
                              ),
                              const SizedBox(height: 10),
                              _buildFeatureTile(
                                icon: Icons.castle_rounded,
                                iconColor: EthioColors.terracotta,
                                title: '3D Heritage Scanner & Markers',
                                desc: 'Point your camera at landmarks to view 3D reconstructions and listen to authenticated historical narrations.',
                                cardColor: cardColor,
                                textColor: textColor,
                                subtextColor: subtextColor,
                              ),
                              const SizedBox(height: 10),
                              _buildFeatureTile(
                                icon: Icons.groups_rounded,
                                iconColor: EthioColors.slate,
                                title: 'Certified Local Guides & Providers',
                                desc: 'Book verified Ethiopian tour guides, cultural transport, and accommodations directly through the app.',
                                cardColor: cardColor,
                                textColor: textColor,
                                subtextColor: subtextColor,
                              ),
                              const SizedBox(height: 10),
                              _buildFeatureTile(
                                icon: Icons.map_rounded,
                                iconColor: const Color(0xFFC59B27),
                                title: '100% Free OpenStreetMap & Offline Mode',
                                desc: 'Fast, license-free navigation and cached landmark guides that work seamlessly throughout Ethiopia.',
                                cardColor: cardColor,
                                textColor: textColor,
                                subtextColor: subtextColor,
                              ),
                            ],
                          ),
                        ),
                      ),

                      // Footer spacing
                      const SliverToBoxAdapter(
                        child: SizedBox(height: 36),
                      ),
                    ],
                  ),
          ),
        );
      },
    );
  }

  Widget _buildHeritageCard(Map<String, String> item, bool isDark) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        boxShadow: const [
          BoxShadow(
            color: Colors.black26,
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(22),
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Background Image
            Image.network(
              item['image']!,
              fit: BoxFit.cover,
              errorBuilder: (_, _, _) => Container(
                color: Color(int.parse(item['accent']!)),
                child: const Center(
                  child: Icon(Icons.landscape_rounded, size: 64, color: Colors.white30),
                ),
              ),
            ),

            // Gradient Overlay
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.black.withValues(alpha: 0.1),
                    Colors.black.withValues(alpha: 0.85),
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
            ),

            // Tag Badge (Top Left)
            Positioned(
              top: 14,
              left: 14,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.65),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.white24),
                ),
                child: Text(
                  item['tag']!,
                  style: const TextStyle(
                    color: Colors.amberAccent,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),

            // Content (Bottom)
            Positioned(
              bottom: 16,
              left: 16,
              right: 16,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    item['title']!,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      const Icon(Icons.location_on_rounded, size: 14, color: Colors.white70),
                      const SizedBox(width: 4),
                      Text(
                        item['location']!,
                        style: const TextStyle(color: Colors.white70, fontSize: 12),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    item['desc']!,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 12,
                      height: 1.3,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeatureTile({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String desc,
    required Color cardColor,
    required Color textColor,
    required Color subtextColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: EthioColors.divider.withValues(alpha: 0.5)),
        boxShadow: const [
          BoxShadow(color: EthioColors.cardShadow, blurRadius: 6, offset: Offset(0, 2)),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: iconColor, size: 24),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: textColor,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  desc,
                  style: TextStyle(
                    fontSize: 12,
                    color: subtextColor,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showAboutDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.view_in_ar_rounded, color: EthioColors.forest, size: 26),
            SizedBox(width: 10),
            Text('About EthioAR Guide'),
          ],
        ),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'EthioAR Guide is an augmented-reality tourism platform showcasing Ethiopian cultural heritage, historic routes, and certified tour guides.',
              style: TextStyle(fontSize: 13, height: 1.4),
            ),
            SizedBox(height: 12),
            Text('• 100% Free OpenStreetMap & Offline Ready\n• Certified Local Guide Integration\n• Real-Time Spatial AR Directions\n• Telebirr & M-Pesa Supported',
              style: TextStyle(fontSize: 12, height: 1.5),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}
