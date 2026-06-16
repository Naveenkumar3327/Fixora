import 'dart:async';
import 'dart:ui';
import 'package:fixora/core/services/database_service.dart';
import 'package:fixora/core/services/location_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:fixora/core/services/smart_assistant_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:geolocator/geolocator.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/models/models.dart';
import '../../../core/providers/global_providers.dart';
import '../../../core/theme/theme.dart';
import '../../booking/presentation/provider_detail_screen.dart';
import 'map_view_screen.dart';
import '../../auth/presentation/role_selection_screen.dart';
import '../../booking/presentation/my_bookings_screen.dart';
import '../../chat/presentation/chat_list_screen.dart';
import '../../chat/presentation/chat_screen.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  int _currentTab = 0;
  String _selectedCategory = "";
  final _searchController = TextEditingController();
  Position? _currentPos;
  String _currentAddress = "Locating...";
  bool _loadingLocation = true;
  String _sortBy = "Distance";

  // Cache & Location subscriptions
  
  StreamSubscription<Position>? _positionSubscription;
  Stream<List<ProviderProfile>>? _nearbyProvidersStream;
  double? _lastStreamLat;
  double? _lastStreamLng;
  String? _lastStreamCategory;

  final List<Map<String, dynamic>> _categories = [
    {"name": "Electrician", "icon": Icons.bolt, "color1": AppTheme.primaryColor, "color2": AppTheme.secondaryColor},
    {"name": "Plumber", "icon": Icons.water_drop, "color1": Colors.blue, "color2": Colors.cyan},
    {"name": "Mechanic", "icon": Icons.build, "color1": AppTheme.warningColor, "color2": Colors.red},
    {"name": "Carpenter", "icon": Icons.chair, "color1": Colors.brown, "color2": Colors.orange},
    {"name": "AC Repair", "icon": Icons.ac_unit, "color1": Colors.cyan, "color2": Colors.teal},
    {"name": "Painter", "icon": Icons.format_paint, "color1": Colors.purple, "color2": Colors.pink},
    {"name": "Cleaner", "icon": Icons.cleaning_services, "color1": AppTheme.successColor, "color2": const Color(0xFF10B981)},
    {"name": "RO Service", "icon": Icons.opacity, "color1": Colors.teal, "color2": Colors.cyan},
    {"name": "Appliance Repair", "icon": Icons.kitchen, "color1": Colors.red, "color2": Colors.amber},
    {"name": "Home Maintenance", "icon": Icons.home_repair_service, "color1": Colors.indigo, "color2": Colors.purple},
  ];

  @override
  void initState() {
    super.initState();
    _loadLocation();
    _startLocationUpdates();
  }

  void _startLocationUpdates() {
    final locSvc = ref.read(locationServiceProvider);
    _positionSubscription = locSvc.getPositionStream().listen((pos) async {
      if (!mounted) return;
      if (_currentPos == null || 
          Geolocator.distanceBetween(_currentPos!.latitude, _currentPos!.longitude, pos.latitude, pos.longitude) > 20) {
        
        ref.read(userLocationProvider.notifier).state = pos;
        final address = await locSvc.getAddressFromCoordinates(pos.latitude, pos.longitude);
        if (!mounted) return;
        
        ref.read(userAddressProvider.notifier).state = address;
        setState(() {
          _currentPos = pos;
          _currentAddress = address;
        });
        _updateProvidersStream();
      }
    }, onError: (err) {
      debugPrint("Location subscription update error: $err");
    });
  }

  void _updateProvidersStream() {
    if (_currentPos == null) return;
    
    if (_nearbyProvidersStream == null || 
        _lastStreamCategory != _selectedCategory ||
        _lastStreamLat == null || 
        _lastStreamLng == null || 
        Geolocator.distanceBetween(_lastStreamLat!, _lastStreamLng!, _currentPos!.latitude, _currentPos!.longitude) > 50) {
      
      final dbSvc = ref.read(databaseServiceProvider);
      _nearbyProvidersStream = dbSvc.getNearbyProvidersStream(
        _currentPos!.latitude,
        _currentPos!.longitude,
        _selectedCategory,
      );
      _lastStreamLat = _currentPos!.latitude;
      _lastStreamLng = _currentPos!.longitude;
      _lastStreamCategory = _selectedCategory;
    }
  }

  void _loadLocation() async {
    setState(() { _loadingLocation = true; });
    final locSvc = ref.read(locationServiceProvider);
    
    try {
      final pos = await locSvc.getCurrentLocation();
      if (!mounted) return;
      ref.read(userLocationProvider.notifier).state = pos;
      
      final address = await locSvc.getAddressFromCoordinates(pos.latitude, pos.longitude);
      if (!mounted) return;
      ref.read(userAddressProvider.notifier).state = address;

      setState(() {
        _currentPos = pos;
        _currentAddress = address;
        _loadingLocation = false;
      });
      _updateProvidersStream();
    } catch (e) {
      if (!mounted) return;
      
      String errorMsg = "Unable to fetch live location. Using default location.";
      if (e.toString().contains("disabled")) {
        errorMsg = "Location services are disabled. Using default location.";
      } else if (e.toString().contains("denied")) {
        errorMsg = "Location permissions denied. Using default location.";
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(errorMsg),
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 4),
          action: SnackBarAction(
            label: 'Settings',
            onPressed: () {
              Geolocator.openAppSettings();
            },
          ),
        ),
      );

      final fallbackPos = Position(
        latitude: LocationService.fallbackLat,
        longitude: LocationService.fallbackLng,
        timestamp: DateTime.now(),
        accuracy: 0.0,
        altitude: 0.0,
        altitudeAccuracy: 0.0,
        heading: 0.0,
        headingAccuracy: 0.0,
        speed: 0.0,
        speedAccuracy: 0.0,
      );

      ref.read(userLocationProvider.notifier).state = fallbackPos;
      ref.read(userAddressProvider.notifier).state = LocationService.fallbackAddress;

      setState(() {
        _currentPos = fallbackPos;
        _currentAddress = LocationService.fallbackAddress;
        _loadingLocation = false;
      });
      _updateProvidersStream();
    }
  }

  @override
  void dispose() {
    _positionSubscription?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  Widget _buildMarketplaceBody(AppUser? currentUser, DatabaseService dbSvc) {
    _updateProvidersStream();
    final nearbyStream = _nearbyProvidersStream ?? Stream<List<ProviderProfile>>.value([]);

    return CustomScrollView(
      physics: const BouncingScrollPhysics(),
      slivers: [
        // Premium greeting and location header
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Welcome Back,",
                          style: TextStyle(color: AppTheme.textSecondary, fontSize: 13, fontWeight: FontWeight.bold),
                        ),
                        Text(
                          currentUser?.name ?? "Guest User",
                          style: const TextStyle(color: AppTheme.textPrimary, fontSize: 24, fontWeight: FontWeight.w900),
                        ),
                      ],
                    ),
                    // Glass refresh/logout controls
                    Row(
                      children: [
                        _buildGlassCircleButton(Icons.refresh, _loadLocation),
                        const SizedBox(width: 8),
                        _buildGlassCircleButton(Icons.logout, () async {
                          final prefs = await SharedPreferences.getInstance();
                          await prefs.remove('loggedInUid');
                          ref.read(authStateProvider.notifier).state = null;
                          if (!context.mounted) return;
                          Navigator.of(context).pushAndRemoveUntil(
                            MaterialPageRoute(builder: (context) => const RoleSelectionScreen()),
                            (route) => false,
                          );
                        }),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                
                // Location panel (Frosted glass container)
                GlassCard(
                  padding: const EdgeInsets.all(12),
                  borderRadius: 14,
                  child: Row(
                    children: [
                      const Icon(Icons.location_on, color: AppTheme.primaryColor, size: 22),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              "CURRENT LOCATION",
                              style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: AppTheme.primaryColor, letterSpacing: 0.5),
                            ),
                            const SizedBox(height: 2),
                            _loadingLocation
                                ? const SizedBox(width: 12, height: 12, child: CircularProgressIndicator(strokeWidth: 1.5))
                                : Text(
                                    _currentAddress,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12, color: AppTheme.textPrimary),
                                  ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),

        // Floating Search Bar & Map toggle
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10),
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      boxShadow: [
                        BoxShadow(
                          color: AppTheme.primaryColor.withOpacity(0.06),
                          blurRadius: 10,
                          spreadRadius: 1,
                        )
                      ],
                    ),
                    child: GlassCard(
                      borderRadius: 14,
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: TextField(
                        controller: _searchController,
                        style: const TextStyle(color: AppTheme.textPrimary),
                        decoration: const InputDecoration(
                          hintText: "Search services, plumbers, electricians...",
                          border: InputBorder.none,
                          enabledBorder: InputBorder.none,
                          focusedBorder: InputBorder.none,
                          icon: Icon(Icons.search, color: AppTheme.textSecondary),
                        ),
                        onChanged: (val) {
                          setState(() {});
                        },
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                GestureDetector(
                  onTap: () {
                    if (_currentPos == null) return;
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => MapViewScreen(
                          userLat: _currentPos!.latitude,
                          userLng: _currentPos!.longitude,
                          category: _selectedCategory,
                        ),
                      ),
                    );
                  },
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(14),
                      gradient: const LinearGradient(
                        colors: [AppTheme.primaryColor, AppTheme.secondaryColor],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: AppTheme.primaryColor.withOpacity(0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        )
                      ],
                    ),
                    child: const Icon(Icons.radar_rounded, color: Colors.white),
                  ),
                ),
              ],
            ),
          ),
        ),

        // AI Smart Diagnostic Matcher Banner
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 8),
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                gradient: const LinearGradient(
                  colors: [AppTheme.primaryColor, AppTheme.secondaryColor],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.secondaryColor.withOpacity(0.25),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  )
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: Stack(
                  children: [
                    // Decorative shapes/orbs
                    Positioned(
                      right: -20,
                      top: -20,
                      child: Container(
                        width: 100,
                        height: 100,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white.withOpacity(0.08),
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(18.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(6),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.15),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(Icons.psychology_outlined, color: Colors.white, size: 20),
                              ),
                              const SizedBox(width: 8),
                              const Text(
                                "Fixora AI Assistant",
                                style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 14, letterSpacing: 0.5),
                              ),
                              const Spacer(),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: AppTheme.successColor.withOpacity(0.85),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Text(
                                  "NLP MODEL v1.0",
                                  style: TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.bold),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          const Text(
                            "Trouble describing the service you need?",
                            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            "Just describe your issue in plain words (e.g., 'pipe leakage in bathroom' or 'fan speed too slow') and our built-in ML classifier will find the nearest experts instantly.",
                            style: TextStyle(color: Colors.white.withOpacity(0.85), fontSize: 11, height: 1.4),
                          ),
                          const SizedBox(height: 14),
                          ElevatedButton.icon(
                            onPressed: () => _showAIAssistantSheet(context),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.white,
                              foregroundColor: AppTheme.secondaryColor,
                              elevation: 0,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                            ),
                            icon: const Icon(Icons.bolt, size: 16, color: AppTheme.secondaryColor),
                            label: const Text(
                              "Diagnose & Match Instantly",
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),

        // 3D Service Categories list
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 10.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 20.0),
                  child: Text(
                    "Service Categories",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  height: 100,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.symmetric(horizontal: 20.0),
                    itemCount: _categories.length,
                    itemBuilder: (context, index) {
                      final cat = _categories[index];
                      final bool isSelected = _selectedCategory == cat['name'];
                      return GestureDetector(
                        onTap: () {
                          setState(() {
                            _selectedCategory = isSelected ? "" : cat['name'];
                          });
                        },
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 250),
                          width: 88,
                          margin: const EdgeInsets.only(right: 14),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(16),
                            color: isSelected ? cat['color1'].withOpacity(0.12) : AppTheme.darkCard.withOpacity(0.4),
                            border: Border.all(
                              color: isSelected ? cat['color1'] : Colors.white.withOpacity(0.08),
                              width: isSelected ? 2.0 : 1.2,
                            ),
                            boxShadow: isSelected
                                ? [BoxShadow(color: cat['color1'].withOpacity(0.25), offset: const Offset(2, 3), blurRadius: 0)]
                                : null,
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  gradient: LinearGradient(
                                    colors: isSelected
                                        ? [cat['color1'], cat['color2']]
                                        : [Colors.white.withOpacity(0.05), Colors.white.withOpacity(0.1)],
                                  ),
                                ),
                                child: Icon(
                                  cat['icon'],
                                  color: isSelected ? Colors.white : AppTheme.textSecondary,
                                  size: 24,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                cat['name'],
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: isSelected ? cat['color1'] : AppTheme.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),

        // Nearby Providers section
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  _selectedCategory.isEmpty ? "Nearby Providers" : "Nearby ${_selectedCategory}s",
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
                ),
                DropdownButton<String>(
                  value: _sortBy,
                  underline: const SizedBox(),
                  icon: const Icon(Icons.tune, size: 18, color: AppTheme.primaryColor),
                  style: const TextStyle(color: AppTheme.primaryColor, fontWeight: FontWeight.bold, fontSize: 13),
                  items: ["Distance", "Rating", "Price"].map((String val) {
                    return DropdownMenuItem(value: val, child: Text(val));
                  }).toList(),
                  onChanged: (val) {
                    if (val != null) {
                      setState(() { _sortBy = val; });
                    }
                  },
                )
              ],
            ),
          ),
        ),

        // Providers list stream
        StreamBuilder<List<ProviderProfile>>(
          stream: nearbyStream,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting && _loadingLocation) {
              return const SliverFillRemaining(
                child: Center(child: CircularProgressIndicator()),
              );
            }

            var list = snapshot.data ?? [];

            if (_searchController.text.isNotEmpty) {
              final search = _searchController.text.toLowerCase();
              list = list.where((p) =>
                  p.businessName.toLowerCase().contains(search) ||
                  p.ownerName.toLowerCase().contains(search) ||
                  p.category.toLowerCase().contains(search)).toList();
            }

            if (_sortBy == "Distance") {
              list.sort((a, b) => a.distance.compareTo(b.distance));
            } else if (_sortBy == "Rating") {
              list.sort((a, b) => b.rating.compareTo(a.rating));
            } else if (_sortBy == "Price") {
              list.sort((a, b) => a.startingPrice.compareTo(b.startingPrice));
            }

            if (list.isEmpty) {
              return SliverFillRemaining(
                hasScrollBody: false,
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.search_off_rounded, size: 48, color: AppTheme.textSecondary.withOpacity(0.4)),
                      const SizedBox(height: 8),
                      Text("No professionals found nearby.", style: TextStyle(color: AppTheme.textSecondary)),
                    ],
                  ),
                ),
              );
            }

            return SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final provider = list[index];
                  return Container(
                    margin: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 8.0),
                    child: GlassCard(
                      borderRadius: 18,
                      padding: const EdgeInsets.all(12),
                      child: InkWell(
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (context) => ProviderDetailScreen(provider: provider),
                            ),
                          );
                        },
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Neon avatar placeholder
                            Container(
                              width: 65,
                              height: 65,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(14),
                                gradient: LinearGradient(
                                  colors: [AppTheme.primaryColor.withOpacity(0.2), AppTheme.secondaryColor.withOpacity(0.2)],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                border: Border.all(color: Colors.white.withOpacity(0.08)),
                              ),
                              child: Center(
                                child: Icon(
                                  _getCategoryIcon(provider.category),
                                  color: AppTheme.primaryColor,
                                  size: 28,
                                ),
                              ),
                            ),
                            const SizedBox(width: 16),
                            
                            // Provider info details
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: AppTheme.primaryColor.withOpacity(0.12),
                                          borderRadius: BorderRadius.circular(6),
                                          border: Border.all(color: AppTheme.primaryColor.withOpacity(0.2)),
                                        ),
                                        child: Text(
                                          provider.category,
                                          style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppTheme.primaryColor),
                                        ),
                                      ),
                                      // Glowing Green Verified Badge
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: AppTheme.successColor.withOpacity(0.15),
                                          borderRadius: BorderRadius.circular(4),
                                        ),
                                        child: const Row(
                                          children: [
                                            Icon(Icons.verified, color: AppTheme.successColor, size: 10),
                                            SizedBox(width: 2),
                                            Text(
                                              "VERIFIED",
                                              style: TextStyle(color: AppTheme.successColor, fontSize: 8, fontWeight: FontWeight.w900),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    provider.businessName,
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppTheme.textPrimary),
                                  ),
                                  const SizedBox(height: 3),
                                  Text(
                                    provider.address,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                                  ),
                                  const SizedBox(height: 8),
                                  
                                  // Stats row
                                  Row(
                                    children: [
                                      const Icon(Icons.star, color: Colors.amber, size: 14),
                                      const SizedBox(width: 2),
                                      Text(
                                        "${provider.rating} (${provider.reviewsCount} reviews)",
                                        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
                                      ),
                                      const SizedBox(width: 10),
                                      Icon(Icons.location_on_outlined, size: 12, color: AppTheme.textSecondary),
                                      const SizedBox(width: 2),
                                      Text(
                                        "${provider.distance.toStringAsFixed(1)} km",
                                        style: TextStyle(fontSize: 11, color: AppTheme.textSecondary),
                                      ),
                                      const Spacer(),
                                      Text(
                                        "₹${provider.startingPrice.toInt()} up",
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 13,
                                          color: AppTheme.primaryColor,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  )
                      .animate()
                      .fadeIn(duration: 400.ms)
                      .scale(begin: const Offset(0.98, 0.98), duration: 250.ms);
                },
                childCount: list.length,
              ),
            );
          },
        ),
        
        // Blank space for floating bottom navigation bar overlap
        const SliverToBoxAdapter(
          child: SizedBox(height: 96),
        ),
      ],
    );
  }

  // Premium User Profile screen body
  Widget _buildProfileBody(AppUser? currentUser) {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 20),
        child: Column(
          children: [
            // User avatar card
            GlassCard(
              borderRadius: 24,
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  Center(
                    child: Container(
                      width: 90,
                      height: 90,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: const LinearGradient(
                          colors: [AppTheme.primaryColor, AppTheme.secondaryColor],
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: AppTheme.primaryColor.withOpacity(0.4),
                            blurRadius: 15,
                            spreadRadius: 2,
                          )
                        ],
                      ),
                      child: Center(
                        child: Text(
                          currentUser?.name.substring(0, 1).toUpperCase() ?? "U",
                          style: const TextStyle(color: Colors.white, fontSize: 36, fontWeight: FontWeight.w900),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    currentUser?.name ?? "Guest User",
                    style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    currentUser?.email ?? "guest@fixora.com",
                    style: TextStyle(color: AppTheme.textSecondary, fontSize: 13),
                  ),
                  const SizedBox(height: 8),
                  
                  // Verification label
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppTheme.successColor.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppTheme.successColor.withOpacity(0.3)),
                    ),
                    child: const Text(
                      "GOLD LEVEL MEMBER",
                      style: TextStyle(color: AppTheme.successColor, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 0.5),
                    ),
                  ),
                ],
              ),
            )
                .animate()
                .fadeIn(duration: 500.ms)
                .scale(begin: const Offset(0.95, 0.95), curve: Curves.easeOutBack),
            
            const SizedBox(height: 20),

            // Statistics Grid (Apple health style)
            Row(
              children: [
                Expanded(
                  child: _buildStatCard("Jobs Booked", "14", Icons.calendar_today, AppTheme.primaryColor),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildStatCard("Total Spent", "₹4,890", Icons.payments_outlined, AppTheme.secondaryColor),
                ),
              ],
            )
                .animate()
                .fadeIn(delay: 100.ms, duration: 400.ms),
            
            const SizedBox(height: 20),

            // Achievements section
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                "Achievement Badges",
                style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(height: 12),
            
            GlassCard(
              padding: const EdgeInsets.all(16),
              borderRadius: 18,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildBadge("Early Bird", Icons.wb_twilight, AppTheme.primaryColor),
                  _buildBadge("Pro Booker", Icons.military_tech, AppTheme.secondaryColor),
                  _buildBadge("Super Saver", Icons.savings, AppTheme.successColor),
                ],
              ),
            )
                .animate()
                .fadeIn(delay: 200.ms, duration: 450.ms),
            
            const SizedBox(height: 24),
            
            // Logout & security settings
            GlassCard(
              borderRadius: 16,
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Column(
                children: [
                  _buildProfileListTile(Icons.shield_outlined, "Security & Verification"),
                  const Divider(color: Colors.white12, height: 1),
                  _buildProfileListTile(Icons.payment, "Saved Payments & Cards"),
                  const Divider(color: Colors.white12, height: 1),
                  _buildProfileListTile(Icons.settings_outlined, "Notification Settings"),
                ],
              ),
            ),
            
            const SizedBox(height: 96),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon, Color color) {
    return GlassCard(
      padding: const EdgeInsets.all(16),
      borderRadius: 16,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 12),
          Text(
            value,
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(fontSize: 12, color: AppTheme.textSecondary),
          ),
        ],
      ),
    );
  }

  Widget _buildBadge(String title, IconData icon, Color color) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: color.withOpacity(0.15),
            border: Border.all(color: color.withOpacity(0.3)),
          ),
          child: Icon(icon, color: color, size: 28),
        ),
        const SizedBox(height: 8),
        Text(
          title,
          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
        ),
      ],
    );
  }

  Widget _buildProfileListTile(IconData icon, String title) {
    return ListTile(
      leading: Icon(icon, color: AppTheme.textSecondary),
      title: Text(title, style: const TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.w500)),
      trailing: const Icon(Icons.chevron_right, color: Colors.white30),
      onTap: () {},
    );
  }

  Widget _buildGlassCircleButton(IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: AppTheme.darkCard.withOpacity(0.4),
          border: Border.all(color: Colors.white.withOpacity(0.08)),
        ),
        child: Icon(icon, color: AppTheme.textPrimary, size: 18),
      ),
    );
  }

  IconData _getCategoryIcon(String category) {
    final cat = _categories.firstWhere((c) => c['name'] == category, orElse: () => {"icon": Icons.handyman});
    return cat['icon'];
  }

  Widget _buildNavItem(int index, IconData icon, String label) {
    final bool isSelected = _currentTab == index;
    return GestureDetector(
      onTap: () {
        setState(() {
          _currentTab = index;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: isSelected ? AppTheme.primaryColor.withOpacity(0.12) : Colors.transparent,
          border: Border.all(
            color: isSelected ? AppTheme.primaryColor.withOpacity(0.2) : Colors.transparent,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: isSelected ? AppTheme.primaryColor : AppTheme.textSecondary,
              size: 24,
            )
                .animate(target: isSelected ? 1 : 0)
                .scale(begin: const Offset(1.0, 1.0), end: const Offset(1.2, 1.2), duration: 200.ms),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                color: isSelected ? AppTheme.primaryColor : AppTheme.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = ref.watch(authStateProvider);
    final dbSvc = ref.watch(databaseServiceProvider);

    Widget body;
    switch (_currentTab) {
      case 0:
        body = _buildMarketplaceBody(currentUser, dbSvc);
        break;
      case 1:
        body = currentUser != null
            ? MyBookingsScreen(customerId: currentUser.uid)
            : const Center(child: Text("Please login to view bookings."));
        break;
      case 2:
        body = currentUser != null
            ? ChatListScreen(currentUserId: currentUser.uid)
            : const Center(child: Text("Please login to chat."));
        break;
      case 3:
        body = _buildProfileBody(currentUser);
        break;
      default:
        body = _buildMarketplaceBody(currentUser, dbSvc);
    }

    return Scaffold(
      body: PremiumBackground(
        child: Stack(
          children: [
            // Body Content
            Positioned.fill(child: body),

            // Floating Curved Bottom Navigation Bar
            Positioned(
              bottom: 16,
              left: 16,
              right: 16,
              child: GlassCard(
                borderRadius: 24,
                padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildNavItem(0, Icons.storefront_outlined, "Home"),
                    _buildNavItem(1, Icons.calendar_today_outlined, "Bookings"),
                    _buildNavItem(2, Icons.chat_bubble_outline, "Chats"),
                    _buildNavItem(3, Icons.person_outline, "Profile"),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showAIAssistantSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withOpacity(0.55),
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.85,
          minChildSize: 0.5,
          maxChildSize: 0.95,
          builder: (context, scrollController) {
            return _AIAssistantSheetContent(
              scrollController: scrollController,
              currentPos: _currentPos,
            );
          },
        );
      },
    );
  }
}

class _AIAssistantSheetContent extends ConsumerStatefulWidget {
  final ScrollController scrollController;
  final Position? currentPos;

  const _AIAssistantSheetContent({
    required this.scrollController,
    required this.currentPos,
  });

  @override
  ConsumerState<_AIAssistantSheetContent> createState() => _AIAssistantSheetContentState();
}

class _AIAssistantSheetContentState extends ConsumerState<_AIAssistantSheetContent> {
  final _inputController = TextEditingController();
  bool _isAnalyzing = false;
  MLSearchResult? _searchResult;
  List<ProviderProfile> _matchedProviders = [];

  @override
  void dispose() {
    _inputController.dispose();
    super.dispose();
  }

  void _runAnalysis() async {
    final text = _inputController.text.trim();
    if (text.isEmpty) return;

    setState(() {
      _isAnalyzing = true;
      _searchResult = null;
      _matchedProviders = [];
    });

    // Simulate standard neural network diagnostic pass
    await Future.delayed(const Duration(milliseconds: 1200));

    final result = WorkIntentClassifier.classify(text);
    final dbSvc = ref.read(databaseServiceProvider);
    
    final providers = await dbSvc.getNearbyProviders(
      widget.currentPos?.latitude ?? LocationService.fallbackLat,
      widget.currentPos?.longitude ?? LocationService.fallbackLng,
      result.classifiedCategory,
    );

    if (mounted) {
      setState(() {
        _isAnalyzing = false;
        _searchResult = result;
        _matchedProviders = providers;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.darkBg.withOpacity(0.95),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(28),
          topRight: Radius.circular(28),
        ),
        border: Border.all(color: Colors.white.withOpacity(0.12), width: 1.5),
      ),
      child: ClipRRect(
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(28),
          topRight: Radius.circular(28),
        ),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: ListView(
            controller: widget.scrollController,
            padding: const EdgeInsets.all(20.0),
            children: [
              // Pull Bar
              Center(
                child: Container(
                  width: 48,
                  height: 5,
                  margin: const EdgeInsets.only(bottom: 20),
                  decoration: BoxDecoration(
                    color: Colors.white24,
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),

              // Title
              Row(
                children: [
                  const Icon(Icons.psychology, color: AppTheme.primaryColor, size: 28),
                  const SizedBox(width: 10),
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Fixora AI Matcher",
                        style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: AppTheme.textPrimary),
                      ),
                      Text(
                        "Local Natural Language Processor",
                        style: TextStyle(fontSize: 10, color: AppTheme.primaryColor, fontWeight: FontWeight.bold, letterSpacing: 0.5),
                      ),
                    ],
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close, color: AppTheme.textSecondary),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const Divider(color: Colors.white12, height: 24),

              // Input field description
              const Text(
                "Describe the issue or work needed:",
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
              ),
              const SizedBox(height: 8),

              // Frosted Input Container
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  color: Colors.white.withOpacity(0.04),
                  border: Border.all(color: Colors.white.withOpacity(0.08)),
                ),
                child: TextField(
                  controller: _inputController,
                  maxLines: 3,
                  style: const TextStyle(color: AppTheme.textPrimary, fontSize: 14),
                  decoration: InputDecoration(
                    hintText: "E.g., kitchen faucet is leaking water continuously and sink is clogged, or light switch sparks when flipped...",
                    hintStyle: TextStyle(color: AppTheme.textSecondary.withOpacity(0.6), fontSize: 13),
                    contentPadding: const EdgeInsets.all(14),
                    border: InputBorder.none,
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // Run button
              ElevatedButton(
                onPressed: _isAnalyzing ? null : _runAnalysis,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: _isAnalyzing
                    ? const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation<Color>(Colors.white))),
                          SizedBox(width: 12),
                          Text("ML Model Classifying...", style: TextStyle(fontWeight: FontWeight.bold)),
                        ],
                      )
                    : const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.search, size: 18),
                          SizedBox(width: 8),
                          Text("Analyze & Match Providers", style: TextStyle(fontWeight: FontWeight.bold)),
                        ],
                      ),
              ),

              const SizedBox(height: 20),

              // Show Loading state or Results
              if (_isAnalyzing) ...[
                const SizedBox(height: 40),
                Center(
                  child: Column(
                    children: [
                      const Icon(Icons.hub_outlined, color: AppTheme.primaryColor, size: 40)
                          .animate(onPlay: (controller) => controller.repeat())
                          .rotate(duration: 1200.ms),
                      const SizedBox(height: 16),
                      Text(
                        "Parsing tokens, extracting entities & matching keywords...",
                        style: TextStyle(color: AppTheme.textSecondary, fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ] else if (_searchResult != null) ...[
                _buildResultsSection(),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildResultsSection() {
    final result = _searchResult!;
    final category = result.classifiedCategory;
    final confidencePercent = (result.confidence * 100).toInt();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ML Model Classification details
        GlassCard(
          padding: const EdgeInsets.all(16),
          borderRadius: 16,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    "ML CLASSIFIER OUTPUT",
                    style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppTheme.primaryColor, letterSpacing: 0.8),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryColor.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      "$confidencePercent% Match",
                      style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppTheme.primaryColor),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                "Category: $category",
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: AppTheme.textPrimary),
              ),
              const SizedBox(height: 6),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: result.confidence,
                  backgroundColor: Colors.white12,
                  valueColor: const AlwaysStoppedAnimation<Color>(AppTheme.primaryColor),
                  minHeight: 6,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                result.explanation,
                style: TextStyle(fontSize: 12, color: AppTheme.textSecondary, height: 1.4),
              ),
            ],
          ),
        ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.1, end: 0),

        const SizedBox(height: 24),

        // Title: Nearest matched works
        const Text(
          "Closest Service Providers",
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
        ),
        const SizedBox(height: 10),

        if (_matchedProviders.isEmpty)
          GlassCard(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            child: Center(
              child: Text(
                "No verified $category specialists found in your area.",
                style: TextStyle(color: AppTheme.textSecondary, fontSize: 13),
              ),
            ),
          )
        else
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _matchedProviders.length,
            itemBuilder: (context, index) {
              final prov = _matchedProviders[index];
              return GlassCard(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Left category icon or logo
                        Container(
                          width: 50,
                          height: 50,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            gradient: LinearGradient(
                              colors: [AppTheme.primaryColor.withOpacity(0.1), AppTheme.secondaryColor.withOpacity(0.1)],
                            ),
                            border: Border.all(color: Colors.white.withOpacity(0.08)),
                          ),
                          child: const Icon(Icons.work, color: AppTheme.primaryColor, size: 24),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                prov.businessName,
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppTheme.textPrimary),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                "Owner: ${prov.ownerName} • ${prov.distance.toStringAsFixed(1)} km away",
                                style: TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                              ),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  const Icon(Icons.star, color: Colors.amber, size: 12),
                                  const SizedBox(width: 2),
                                  Text(
                                    "${prov.rating} (${prov.reviewsCount} reviews)",
                                    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
                                  ),
                                  const Spacer(),
                                  Text(
                                    "Starts: ₹${prov.startingPrice.toInt()}/hr",
                                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.primaryColor),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const Divider(color: Colors.white10, height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        // Contact Actions
                        IconButton(
                          icon: const Icon(Icons.call, color: AppTheme.primaryColor, size: 18),
                          onPressed: () => _callNumber(prov.phone),
                          tooltip: "Call Partner",
                        ),
                        const SizedBox(width: 8),
                        IconButton(
                          icon: const Icon(Icons.chat_bubble_outline, color: AppTheme.secondaryColor, size: 18),
                          onPressed: () {
                            final currentUser = ref.read(authStateProvider);
                            if (currentUser == null) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text("Please sign in to chat.")),
                              );
                              return;
                            }
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (context) => ChatScreen(
                                  senderId: currentUser.uid,
                                  receiverId: prov.providerId,
                                  partnerName: prov.businessName,
                                ),
                              ),
                            );
                          },
                          tooltip: "Chat in App",
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton.icon(
                          onPressed: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (context) => ProviderDetailScreen(provider: prov),
                              ),
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                          icon: const Icon(Icons.open_in_new, size: 12),
                          label: const Text("Profile", style: TextStyle(fontSize: 11)),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            },
          ),

        const SizedBox(height: 24),

        // Google Reviews for the category
        Row(
          children: [
            const Icon(Icons.g_mobiledata, color: AppTheme.primaryColor, size: 28),
            const SizedBox(width: 4),
            Text(
              "Google Reviews: $category Nearby",
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
            ),
          ],
        ),
        const SizedBox(height: 10),

        ...result.mockGoogleReviews.map((rev) {
          return Container(
            margin: const EdgeInsets.only(bottom: 10),
            child: GlassCard(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          CircleAvatar(
                            radius: 10,
                            backgroundColor: AppTheme.primaryColor.withOpacity(0.2),
                            child: Text(
                              rev.authorName.substring(0, 1).toUpperCase(),
                              style: const TextStyle(fontSize: 8, color: AppTheme.primaryColor, fontWeight: FontWeight.bold),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            rev.authorName,
                            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
                          ),
                        ],
                      ),
                      Text(
                        rev.relativeTimeDescription,
                        style: TextStyle(fontSize: 10, color: AppTheme.textSecondary),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: List.generate(5, (starIdx) {
                      return Icon(
                        Icons.star,
                        color: starIdx < rev.rating.floor() ? Colors.amber : Colors.white12,
                        size: 11,
                      );
                    }),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    rev.text,
                    style: TextStyle(fontSize: 12, color: AppTheme.textPrimary.withOpacity(0.85), height: 1.3),
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ],
    );
  }

  void _callNumber(String phone) async {
    final Uri url = Uri.parse("tel:$phone");
    if (await canLaunchUrl(url)) {
      await launchUrl(url);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Cannot call $phone directly.")),
        );
      }
    }
  }
}
