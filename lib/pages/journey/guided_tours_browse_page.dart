import 'package:flutter/material.dart';
import '../../models/tour_package.dart';
import '../../services/guide_service.dart';
import '../../theme/ethio_theme.dart';
import '../../widgets/app_scaffold.dart';

class GuidedToursBrowsePage extends StatelessWidget {
  const GuidedToursBrowsePage({super.key});

  @override
  Widget build(BuildContext context) {
    final service = GuideService();
    return AppScaffold(
      title: 'Guided Tours',
      body: FutureBuilder<List<TourPackage>>(
        future: _loadAllTours(service),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final tours = snapshot.data ?? [];
          if (tours.isEmpty) {
            return Center(
              child: Text(
                'No guided tours available yet.',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            );
          }
          return ListView.separated(
            itemCount: tours.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final tour = tours[index];
              return _TourCard(tour: tour);
            },
          );
        },
      ),
    );
  }

  Future<List<TourPackage>> _loadAllTours(GuideService service) async {
    final guides = await service.fetchActiveGuides();
    final tours = <TourPackage>[];
    for (final guide in guides) {
      tours.addAll(await service.fetchToursForGuide(guide.id));
    }
    return tours;
  }
}

class _TourCard extends StatelessWidget {
  final TourPackage tour;

  const _TourCard({required this.tour});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: EthioColors.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(tour.name, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 6),
          Text(tour.description, style: Theme.of(context).textTheme.bodyMedium),
          const SizedBox(height: 10),
          Row(
            children: [
              Icon(Icons.schedule, size: 16, color: EthioColors.muted),
              const SizedBox(width: 4),
              Text('${tour.durationHours}h', style: Theme.of(context).textTheme.bodyMedium),
              const Spacer(),
              Text(
                'ETB ${tour.price.toStringAsFixed(0)}',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(color: EthioColors.forest),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
