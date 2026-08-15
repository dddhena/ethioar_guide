import 'package:flutter/material.dart';
import '../../models/service_provider.dart';
import '../../services/service_provider_service.dart';
import '../../widgets/app_scaffold.dart';
import 'provider_details_page.dart';
import 'my_reservations_page.dart';
import 'register_provider_page.dart';

class ServiceProvidersListPage extends StatefulWidget {
  final String? initialCategory;

  const ServiceProvidersListPage({super.key, this.initialCategory});

  @override
  State<ServiceProvidersListPage> createState() => _ServiceProvidersListPageState();
}

class _ServiceProvidersListPageState extends State<ServiceProvidersListPage> {
  final ServiceProviderService _service = ServiceProviderService();

  String _selectedCategory = 'all'; // 'all', 'hotel', 'restaurant', 'transport'
  String _searchQuery = '';
  bool _loading = true;
  List<ServiceProvider> _providers = [];

  final List<Map<String, String>> _categories = [
    {'id': 'all', 'label': '🌟 All Services', 'type': 'all'},
    {'id': 'hotel', 'label': '🏨 Hotels & Resorts', 'type': 'hotel'},
    {'id': 'restaurant', 'label': '🍽️ Restaurants', 'type': 'restaurant'},
    {'id': 'transport', 'label': '🚗 Transport & 4WD', 'type': 'transport'},
  ];

  @override
  void initState() {
    super.initState();
    if (widget.initialCategory != null) {
      _selectedCategory = widget.initialCategory!;
    }
    _loadProviders();
  }

  Future<void> _loadProviders() async {
    setState(() => _loading = true);
    final list = await _service.fetchApprovedProviders(
      businessType: _selectedCategory == 'all' ? null : _selectedCategory,
    );
    if (mounted) {
      setState(() {
        _providers = list;
        _loading = false;
      });
    }
  }

  List<ServiceProvider> get _filteredProviders {
    if (_searchQuery.trim().isEmpty) return _providers;
    final q = _searchQuery.toLowerCase();
    return _providers.where((p) {
      return p.businessName.toLowerCase().contains(q) ||
          p.city.toLowerCase().contains(q) ||
          p.description.toLowerCase().contains(q);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: 'Tourism Services & Stays',
      actions: [
        IconButton(
          icon: const Icon(Icons.bookmark_border),
          tooltip: 'My Reservations',
          onPressed: () => Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const MyReservationsPage()),
          ),
        ),
        IconButton(
          icon: const Icon(Icons.add_business),
          tooltip: 'Register Your Business',
          onPressed: () => Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const RegisterProviderPage()),
          ),
        ),
      ],
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSearchBar(),
          const SizedBox(height: 10),
          _buildCategoryFilter(),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${_filteredProviders.length} Providers Available',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                ),
                Text(
                  'Instant Booking Available',
                  style: TextStyle(fontSize: 12, color: Colors.teal.shade700, fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _filteredProviders.isEmpty
                    ? _buildEmptyState()
                    : ListView.builder(
                        itemCount: _filteredProviders.length,
                        itemBuilder: (context, i) {
                          return _buildProviderCard(_filteredProviders[i]);
                        },
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return TextField(
      decoration: InputDecoration(
        hintText: 'Search hotels, restaurants, transport by name or city...',
        prefixIcon: const Icon(Icons.search),
        filled: true,
        fillColor: Colors.grey.shade100,
        contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
      ),
      onChanged: (v) => setState(() => _searchQuery = v),
    );
  }

  Widget _buildCategoryFilter() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: _categories.map((cat) {
          final isSelected = _selectedCategory == cat['id'];
          return Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: ChoiceChip(
              label: Text(cat['label']!),
              selected: isSelected,
              selectedColor: Colors.teal.shade700,
              labelStyle: TextStyle(
                color: isSelected ? Colors.white : Colors.teal.shade900,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                fontSize: 12,
              ),
              backgroundColor: Colors.teal.shade50,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              onSelected: (selected) {
                if (selected) {
                  setState(() {
                    _selectedCategory = cat['id']!;
                  });
                  _loadProviders();
                }
              },
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildProviderCard(ServiceProvider provider) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => ProviderDetailsPage(provider: provider),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CircleAvatar(
                    radius: 26,
                    backgroundColor: Colors.teal.shade50,
                    child: Text(provider.typeIcon, style: const TextStyle(fontSize: 26)),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          provider.businessName,
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 3),
                        Row(
                          children: [
                            Icon(Icons.location_on, size: 14, color: Colors.grey.shade600),
                            const SizedBox(width: 2),
                            Text(
                              '${provider.city} • ${provider.priceRange}',
                              style: TextStyle(fontSize: 12, color: Colors.grey.shade700, fontWeight: FontWeight.w500),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.amber.shade50,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.amber.shade300),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.star, size: 14, color: Colors.amber),
                        const SizedBox(width: 3),
                        Text(
                          provider.rating.toStringAsFixed(1),
                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.amber.shade900),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                provider.description,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontSize: 13, color: Colors.grey.shade700),
              ),
              if (provider.facilities.isNotEmpty) ...[
                const SizedBox(height: 10),
                Wrap(
                  spacing: 6,
                  runSpacing: 4,
                  children: provider.facilities.take(4).map((f) {
                    return Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: Colors.grey.shade300),
                      ),
                      child: Text(f, style: const TextStyle(fontSize: 11, color: Colors.black87)),
                    );
                  }).toList(),
                ),
              ],
              const Divider(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Opening: ${provider.openingHours}',
                    style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                  ),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.teal.shade700,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    icon: const Icon(Icons.calendar_today, size: 14),
                    label: const Text('View & Reserve', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => ProviderDetailsPage(provider: provider),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.hotel_class_outlined, size: 64, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            const Text(
              'No service providers match your search',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 6),
            Text(
              'Try changing your category or search query.',
              style: TextStyle(color: Colors.grey.shade600),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  _selectedCategory = 'all';
                  _searchQuery = '';
                });
                _loadProviders();
              },
              child: const Text('Reset Filters'),
            ),
          ],
        ),
      ),
    );
  }
}
