import 'dart:async';
import 'package:flutter/material.dart';
import '../../models/landmark.dart';
import '../../theme/ethio_theme.dart';
import '../camera_preview.dart';

class ArAttractionExperiencePage extends StatefulWidget {
  final String attractionName;
  final Landmark? landmark;

  const ArAttractionExperiencePage({
    super.key,
    required this.attractionName,
    this.landmark,
  });

  @override
  State<ArAttractionExperiencePage> createState() => _ArAttractionExperiencePageState();
}

class _ArAttractionExperiencePageState extends State<ArAttractionExperiencePage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // Audio narration state
  bool _isPlayingAudio = false;
  double _audioProgress = 0.0;
  Timer? _audioTimer;

  // AR Marker Scanner state
  bool _isScanning = false;
  bool _markerDetected = false;

  // AR Tag interaction state
  int _selectedArTagIndex = 0;

  final List<Map<String, String>> _arTags = [
    {
      'title': 'Royal Castle of Emperor Fasilides',
      'year': '1636 AD',
      'detail': 'Two-storey stone castle with battlements and four domed corner towers constructed of brown basalt stone.',
      'architect': 'Emperor Fasilides & Ethiopian Craftsmen',
    },
    {
      'title': 'Northern Banquet Hall',
      'year': '1667 AD',
      'detail': 'Used for imperial banquets, reception of foreign dignitaries, and coronation celebrations.',
      'architect': 'Emperor Yohannes I',
    },
    {
      'title': 'Imperial Library & Archives',
      'year': '1682 AD',
      'detail': 'Housed illuminated Ge\'ez manuscripts, chronicles, and astronomical treatises.',
      'architect': 'Emperor Iyasu the Great',
    },
  ];

  final List<Map<String, String>> _historicalGallery = [
    {
      'caption': 'Fasilides Castle Central Keep (19th Century Archival Photograph)',
      'year': 'Circa 1880',
      'url': 'https://images.unsplash.com/photo-1609137144813-7d8bfe2a0e44?auto=format&fit=crop&w=800&q=80',
    },
    {
      'caption': 'Fasilides Bath & Pavilion during Timket Festival',
      'year': 'Annual Epiphany Celebration',
      'url': 'https://images.unsplash.com/photo-1544717305-2782549b5136?auto=format&fit=crop&w=800&q=80',
    },
    {
      'caption': 'Restored Stone Archways and Turrets',
      'year': 'UNESCO World Heritage Preservation',
      'url': 'https://images.unsplash.com/photo-1578925518470-4def7a0f08bb?auto=format&fit=crop&w=800&q=80',
    },
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _audioTimer?.cancel();
    _tabController.dispose();
    super.dispose();
  }

  void _toggleAudio() {
    if (_isPlayingAudio) {
      _audioTimer?.cancel();
      setState(() => _isPlayingAudio = false);
    } else {
      setState(() => _isPlayingAudio = true);
      _audioTimer = Timer.periodic(const Duration(milliseconds: 200), (t) {
        if (!mounted) {
          t.cancel();
          return;
        }
        setState(() {
          _audioProgress += 0.01;
          if (_audioProgress >= 1.0) {
            _audioProgress = 0.0;
            _isPlayingAudio = false;
            t.cancel();
          }
        });
      });
    }
  }

  void _simulateScan() {
    setState(() {
      _isScanning = true;
      _markerDetected = false;
    });

    Timer(const Duration(seconds: 2), () {
      if (mounted) {
        setState(() {
          _isScanning = false;
          _markerDetected = true;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: EthioColors.cream,
      appBar: AppBar(
        title: Row(
          children: [
            const Icon(Icons.castle_rounded, color: EthioColors.forest),
            const SizedBox(width: 8),
            Text(widget.attractionName),
          ],
        ),
        backgroundColor: Colors.white,
        elevation: 1,
        bottom: TabBar(
          controller: _tabController,
          labelColor: EthioColors.forest,
          unselectedLabelColor: EthioColors.muted,
          indicatorColor: EthioColors.forest,
          indicatorWeight: 3,
          isScrollable: true,
          tabs: const [
            Tab(icon: Icon(Icons.info_outline_rounded), text: 'Historical Info'),
            Tab(icon: Icon(Icons.headphones_rounded), text: '🎧 Audio Guide'),
            Tab(icon: Icon(Icons.view_in_ar_rounded), text: '📷 AR Experience'),
            Tab(icon: Icon(Icons.photo_library_outlined), text: 'Archival Photos'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildHistoricalInfoTab(),
          _buildAudioGuideTab(),
          _buildArExperienceTab(),
          _buildHistoricalPhotosTab(),
        ],
      ),
    );
  }

  // 1. Historical Information Tab
  Widget _buildHistoricalInfoTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Arrival Celebration Banner
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF2D5A3D), Color(0xFF1E3E2A)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.celebration_rounded, color: Colors.amber, size: 28),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'You Have Arrived!',
                        style: TextStyle(
                          color: Colors.amber,
                          fontWeight: FontWeight.w800,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Welcome to ${widget.attractionName}. Start your interactive AR discovery tour.',
                        style: const TextStyle(color: Colors.white, fontSize: 13),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Key Facts Grid
          Row(
            children: [
              Expanded(
                child: _buildFactCard(
                  icon: Icons.calendar_today_rounded,
                  label: 'Built',
                  value: '1636–1700s',
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildFactCard(
                  icon: Icons.verified_user_rounded,
                  label: 'Status',
                  value: 'UNESCO Heritage',
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildFactCard(
                  icon: Icons.architecture_rounded,
                  label: 'Style',
                  value: 'Nubian-Baroque',
                ),
              ),
            ],
          ),

          const SizedBox(height: 24),
          const Text(
            'About the Monument',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: EthioColors.charcoal),
          ),
          const SizedBox(height: 10),
          Text(
            widget.landmark?.description ??
                'Fasil Ghebbi (Royal Enclosure) is the fortress-city that served as the residence of the Ethiopian Emperor Fasilides and his successors in Gondar. Enclosed by a 900-meter-long rampart, the complex contains six royal castles, palaces, churches, monasteries, and unique historical structures reflecting Nubian, Arab, and European Baroque influences adapted to Ethiopian Orthodox traditions.',
            style: const TextStyle(fontSize: 14, height: 1.6, color: EthioColors.charcoal),
          ),

          const SizedBox(height: 24),
          const Text(
            'Interactive Spatial Anchors',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: EthioColors.charcoal),
          ),
          const SizedBox(height: 12),

          ..._arTags.map((tag) => _buildArTagCard(tag)),
        ],
      ),
    );
  }

  Widget _buildFactCard({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: EthioColors.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: EthioColors.forest),
          const SizedBox(height: 8),
          Text(label, style: const TextStyle(fontSize: 11, color: EthioColors.muted)),
          const SizedBox(height: 2),
          Text(value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: EthioColors.charcoal)),
        ],
      ),
    );
  }

  Widget _buildArTagCard(Map<String, String> tag) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: EthioColors.divider),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: EthioColors.forestLight.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.place_rounded, color: EthioColors.forest, size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        tag['title']!,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: EthioColors.sand,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        tag['year']!,
                        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: EthioColors.charcoal),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(tag['detail']!, style: const TextStyle(fontSize: 12, height: 1.4, color: EthioColors.muted)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // 2. Audio Guide Tab
  Widget _buildAudioGuideTab() {
    return Center(
      child: Container(
        constraints: const dynamicConstraints(maxWidth: 480),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 140,
              height: 140,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const RadialGradient(
                  colors: [Color(0xFF3D7A52), Color(0xFF2D5A3D)],
                ),
                boxShadow: [
                  BoxShadow(
                    color: EthioColors.forest.withValues(alpha: 0.3),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: const Icon(Icons.headphones_rounded, size: 64, color: Colors.white),
            ),
            const SizedBox(height: 24),
            Text(
              '${widget.attractionName} Audio Narration',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: EthioColors.charcoal),
            ),
            const SizedBox(height: 6),
            const Text(
              'Narrated by Certified Ethiopian Heritage Historian',
              style: TextStyle(fontSize: 13, color: EthioColors.muted),
            ),
            const SizedBox(height: 32),

            // Audio Waveform Visualization Simulation
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(24, (i) {
                final height = _isPlayingAudio ? (10 + (i * 7 % 35) + (_audioProgress * 20 % 15)) : 8.0;
                return Container(
                  width: 4,
                  height: height,
                  margin: const EdgeInsets.symmetric(horizontal: 2),
                  decoration: BoxDecoration(
                    color: (i / 24) <= _audioProgress ? EthioColors.forest : EthioColors.divider,
                    borderRadius: BorderRadius.circular(4),
                  ),
                );
              }),
            ),
            const SizedBox(height: 24),

            // Progress Slider
            Slider(
              value: _audioProgress,
              onChanged: (val) => setState(() => _audioProgress = val),
              activeColor: EthioColors.forest,
              inactiveColor: EthioColors.divider,
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${(_audioProgress * 3.5).toStringAsFixed(1)} min',
                  style: const TextStyle(fontSize: 12, color: EthioColors.muted),
                ),
                const Text(
                  '3:30 min',
                  style: TextStyle(fontSize: 12, color: EthioColors.muted),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Audio Play/Pause Button
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: EthioColors.forest,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              onPressed: _toggleAudio,
              icon: Icon(_isPlayingAudio ? Icons.pause_rounded : Icons.play_arrow_rounded, size: 28),
              label: Text(
                _isPlayingAudio ? 'Pause Narration' : 'Listen to Audio Tour',
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 3. AR Experience & Marker Scanning Tab
  Widget _buildArExperienceTab() {
    return Stack(
      children: [
        // Camera Viewport Simulation / Feed
        Container(
          color: Colors.black87,
          child: const Center(
            child: CameraPreviewPage(),
          ),
        ),

        // Floating AR Spatial Pins Overlaid on Camera
        Positioned(
          top: 80,
          left: 40,
          child: _buildFloatingArPin(
            title: 'Royal Castle Keep (1636 AD)',
            distance: '12m away',
            isSelected: _selectedArTagIndex == 0,
            onTap: () => setState(() => _selectedArTagIndex = 0),
          ),
        ),

        Positioned(
          top: 180,
          right: 30,
          child: _buildFloatingArPin(
            title: 'Emperor Yohannes Archives',
            distance: '28m away',
            isSelected: _selectedArTagIndex == 1,
            onTap: () => setState(() => _selectedArTagIndex = 1),
          ),
        ),

        // Bottom AR Controls & Marker Scan Trigger
        Positioned(
          bottom: 24,
          left: 20,
          right: 20,
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.85),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.white24),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    const Icon(Icons.view_in_ar_rounded, color: Colors.amber, size: 22),
                    const SizedBox(width: 8),
                    const Expanded(
                      child: Text(
                        'Point camera at castles or physical plaques',
                        style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.white,
                          side: const BorderSide(color: Colors.white54),
                        ),
                        onPressed: _simulateScan,
                        icon: const Icon(Icons.qr_code_scanner_rounded, size: 18),
                        label: Text(_isScanning ? 'Scanning Marker...' : '📸 Scan Marker'),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: EthioColors.forest,
                          foregroundColor: Colors.white,
                        ),
                        onPressed: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('3D Historical Reconstitution Model loaded in spatial memory!'),
                              backgroundColor: EthioColors.forest,
                            ),
                          );
                        },
                        icon: const Icon(Icons.threed_rotation_rounded, size: 18),
                        label: const Text('View 3D Model'),
                      ),
                    ),
                  ],
                ),
                if (_markerDetected) ...[
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.green.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.greenAccent),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.check_circle, color: Colors.greenAccent, size: 16),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Historical Plaque Marker Recognized: "Emperor Fasilides Main Gateway"',
                            style: TextStyle(color: Colors.greenAccent, fontSize: 12, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFloatingArPin({
    required String title,
    required String distance,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? EthioColors.forest.withValues(alpha: 0.9) : Colors.black.withValues(alpha: 0.75),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: isSelected ? Colors.amber : Colors.white54, width: 1.5),
          boxShadow: const [
            BoxShadow(color: Colors.black45, blurRadius: 8, offset: Offset(0, 4)),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.museum_rounded, color: Colors.amber, size: 18),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                ),
                Text(
                  distance,
                  style: const TextStyle(color: Colors.amberAccent, fontSize: 10),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // 4. Historical Photos Tab
  Widget _buildHistoricalPhotosTab() {
    return ListView.separated(
      padding: const EdgeInsets.all(20),
      itemCount: _historicalGallery.length,
      separatorBuilder: (_, _) => const SizedBox(height: 20),
      itemBuilder: (context, idx) {
        final item = _historicalGallery[idx];
        return Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: EthioColors.divider),
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Image.network(
                item['url']!,
                height: 220,
                width: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => Container(
                  height: 200,
                  color: EthioColors.sand,
                  child: const Center(child: Icon(Icons.castle_rounded, size: 48, color: EthioColors.stone)),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: EthioColors.sand,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            item['year']!,
                            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: EthioColors.earth),
                          ),
                        ),
                        const Spacer(),
                        const Icon(Icons.zoom_in_rounded, size: 18, color: EthioColors.muted),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      item['caption']!,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: EthioColors.charcoal),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class dynamicConstraints extends BoxConstraints {
  const dynamicConstraints({super.maxWidth});
}
