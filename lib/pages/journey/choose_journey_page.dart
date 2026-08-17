import 'package:flutter/material.dart';
import '../../services/journey_preference_service.dart';
import '../../theme/ethio_theme.dart';
import '../../widgets/journey/journey_experience_card.dart';
import 'guided_journey_dashboard_page.dart';
import 'ar_discovery_dashboard_page.dart';

class ChooseJourneyPage extends StatelessWidget {
  const ChooseJourneyPage({super.key});

  static const _guideImage =
      'https://images.unsplash.com/photo-1526772662000-3f88f10405ff?auto=format&fit=crop&w=800&q=80';
  static const _arImage =
      'https://images.unsplash.com/photo-1587974925564-afea072b4b87?auto=format&fit=crop&w=800&q=80';

  void _selectGuided(BuildContext context) {
    JourneyPreferenceService.instance.setMode(JourneyMode.guided);
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const GuidedJourneyDashboardPage()),
    );
  }

  void _selectAr(BuildContext context) {
    JourneyPreferenceService.instance.setMode(JourneyMode.ar);
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const ArDiscoveryDashboardPage()),
    );
  }

  void _skipForNow(BuildContext context) {
    JourneyPreferenceService.instance.setMode(JourneyMode.guided);
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const GuidedJourneyDashboardPage()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: EthioColors.cream,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: CustomScrollView(
              slivers: [
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(24, 28, 24, 8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 8,
                              height: 8,
                              decoration: const BoxDecoration(
                                color: EthioColors.forest,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              width: 8,
                              height: 8,
                              decoration: BoxDecoration(
                                color: EthioColors.divider,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              width: 8,
                              height: 8,
                              decoration: BoxDecoration(
                                color: EthioColors.divider,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const Spacer(),
                            Text(
                              'Step 1 of 3',
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontSize: 12),
                            ),
                          ],
                        ),
                        const SizedBox(height: 28),
                        Text(
                          'Welcome back!',
                          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                color: EthioColors.terracotta,
                                fontWeight: FontWeight.w500,
                              ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'How would you like to explore?',
                          style: Theme.of(context).textTheme.headlineMedium,
                        ),
                        const SizedBox(height: 10),
                        Text(
                          'Choose your way to discover Ethiopia. You can change this anytime.',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ],
                    ),
                  ),
                ),
                SliverLayoutBuilder(
                  builder: (context, constraints) {
                    final wide = constraints.crossAxisExtent >= 640;
                    if (wide) {
                      return SliverPadding(
                        padding: const EdgeInsets.fromLTRB(24, 20, 24, 12),
                        sliver: SliverToBoxAdapter(
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: JourneyExperienceCard(
                                  title: 'Guided Journey',
                                  subtitle: 'Explore with a local guide',
                                  description:
                                      "Meet a human tour guide who can take you through Ethiopia's history, culture, landmarks, and hidden stories.",
                                  buttonLabel: 'Explore with a Guide',
                                  icon: Icons.person_outline_rounded,
                                  imageUrl: _guideImage,
                                  accentColor: EthioColors.forest,
                                  onTap: () => _selectGuided(context),
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: JourneyExperienceCard(
                                  title: 'AR Discovery',
                                  subtitle: 'Explore with augmented reality',
                                  description:
                                      'Discover places at your own pace with interactive AR information, historical visuals, location-based guidance, and immersive experiences.',
                                  buttonLabel: 'Start AR Discovery',
                                  icon: Icons.view_in_ar_rounded,
                                  imageUrl: _arImage,
                                  accentColor: EthioColors.slate,
                                  onTap: () => _selectAr(context),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }

                    return SliverPadding(
                      padding: const EdgeInsets.fromLTRB(24, 20, 24, 12),
                      sliver: SliverList(
                        delegate: SliverChildListDelegate([
                          JourneyExperienceCard(
                            title: 'Guided Journey',
                            subtitle: 'Explore with a local guide',
                            description:
                                "Meet a human tour guide who can take you through Ethiopia's history, culture, landmarks, and hidden stories.",
                            buttonLabel: 'Explore with a Guide',
                            icon: Icons.person_outline_rounded,
                            imageUrl: _guideImage,
                            accentColor: EthioColors.forest,
                            onTap: () => _selectGuided(context),
                          ),
                          const SizedBox(height: 20),
                          JourneyExperienceCard(
                            title: 'AR Discovery',
                            subtitle: 'Explore with augmented reality',
                            description:
                                'Discover places at your own pace with interactive AR information, historical visuals, location-based guidance, and immersive experiences.',
                            buttonLabel: 'Start AR Discovery',
                            icon: Icons.view_in_ar_rounded,
                            imageUrl: _arImage,
                            accentColor: EthioColors.slate,
                            onTap: () => _selectAr(context),
                          ),
                        ]),
                      ),
                    );
                  },
                ),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.only(top: 8, bottom: 32),
                    child: Center(
                      child: TextButton(
                        onPressed: () => _skipForNow(context),
                        child: const Text('Explore later'),
                      ),
                    ),
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
