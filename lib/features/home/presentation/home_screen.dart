import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import '../../../core/models/models.dart';
import '../../../core/providers/global_providers.dart';
import '../../booking/presentation/provider_detail_screen.dart';
import 'map_view_screen.dart';
import '../../auth/presentation/role_selection_screen.dart';
import '../../booking/presentation/my_bookings_screen.dart';
import '../../chat/presentation/chat_list_screen.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  String _selectedCategory = "";
  final _searchController = TextEditingController();
  Position? _currentPos;
  String _currentAddress = "Locating...";
  bool _loadingLocation = true;
  String _sortBy = "Distance"; // or "Rating", "Price"

  final List<Map<String, dynamic>> _categories = [
    {"name": "Electrician", "icon": Icons.bolt, "color": Colors.amber},
    {"name": "Plumber", "icon": Icons.water_drop, "color": Colors.blue},
    {"name": "Mechanic", "icon": Icons.build, "color": Colors.orange},
    {"name": "Carpenter", "icon": Icons.chair, "color": Colors.brown},
    {"name": "AC Repair", "icon": Icons.ac_unit, "color": Colors.cyan},
    {"name": "Painter", "icon": Icons.format_paint, "color": Colors.purple},
    {"name": "Cleaner", "icon": Icons.cleaning_services, "color": Colors.green},
    {"name": "RO Service", "icon": Icons.opacity, "color": Colors.teal},
    {"name": "Appliance Repair", "icon": Icons.kitchen, "color": Colors.red},
    {"name": "Home Maintenance", "icon": Icons.home_repair_service, "color": Colors.indigo},
  ];

  @override
  void initState() {
    super.initState();
    _loadLocation();
  }

  void _loadLocation() async {
    setState(() { _loadingLocation = true; });
    final locSvc = ref.read(locationServiceProvider);
    
    // Fetch coordinates
    final pos = await locSvc.getCurrentLocation();
    if (!mounted) return;
    ref.read(userLocationProvider.notifier).state = pos;
    
    // Fetch address string
    final address = await locSvc.getAddressFromCoordinates(pos.latitude, pos.longitude);
    if (!mounted) return;
    ref.read(userAddressProvider.notifier).state = address;

    setState(() {
      _currentPos = pos;
      _currentAddress = address;
      _loadingLocation = false;
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = ref.watch(authStateProvider);
    final dbSvc = ref.watch(databaseServiceProvider);
    
    // Listen to provider updates reactively
    final nearbyStream = _currentPos != null 
        ? dbSvc.getNearbyProvidersStream(_currentPos!.latitude, _currentPos!.longitude, _selectedCategory)
        : Stream<List<ProviderProfile>>.value([]);

    return Scaffold(
      body: SafeArea(
        child: NestedScrollView(
          headerSliverBuilder: (context, innerBoxIsScrolled) => [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20.0, 16.0, 20.0, 8.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header Bar (Location + Profile)
                    Row(
                      children: [
                        Icon(Icons.location_on, color: Theme.of(context).colorScheme.primary, size: 28),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "YOUR LOCATION",
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: Theme.of(context).colorScheme.primary,
                                  letterSpacing: 1,
                                ),
                              ),
                              _loadingLocation
                                  ? const SizedBox(
                                      width: 12,
                                      height: 12,
                                      child: CircularProgressIndicator(strokeWidth: 1.5),
                                    )
                                  : Text(
                                      _currentAddress,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                                    ),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.refresh, size: 20),
                          onPressed: _loadLocation,
                        ),
                        const SizedBox(width: 4),
                        // Logged in User Profile Icon or Login Button
                        currentUser != null
                            ? PopupMenuButton<String>(
                                icon: CircleAvatar(
                                  radius: 18,
                                  backgroundColor: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                                  child: Text(
                                    currentUser.name.substring(0, 1).toUpperCase(),
                                    style: TextStyle(fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.primary),
                                  ),
                                ),
                                onSelected: (val) {
                                  if (val == 'logout') {
                                    ref.read(authStateProvider.notifier).state = null;
                                    Navigator.of(context).pushAndRemoveUntil(
                                      MaterialPageRoute(builder: (context) => const RoleSelectionScreen()),
                                      (route) => false,
                                    );
                                  } else if (val == 'bookings') {
                                    Navigator.of(context).push(
                                      MaterialPageRoute(builder: (context) => MyBookingsScreen(customerId: currentUser.uid)),
                                    );
                                  } else if (val == 'chats') {
                                    Navigator.of(context).push(
                                      MaterialPageRoute(builder: (context) => ChatListScreen(currentUserId: currentUser.uid)),
                                    );
                                  }
                                },
                                itemBuilder: (context) => [
                                  PopupMenuItem(value: 'name', enabled: false, child: Text("Hello, ${currentUser.name}")),
                                  const PopupMenuDivider(),
                                  const PopupMenuItem(value: 'bookings', child: Row(children: [Icon(Icons.calendar_today, size: 18), SizedBox(width: 8), Text("My Bookings")])),
                                  const PopupMenuItem(value: 'chats', child: Row(children: [Icon(Icons.chat_bubble_outline, size: 18), SizedBox(width: 8), Text("My Chats")])),
                                  const PopupMenuItem(value: 'logout', child: Row(children: [Icon(Icons.logout, color: Colors.red, size: 18), SizedBox(width: 8), Text("Logout", style: TextStyle(color: Colors.red))])),
                                ],
                              )
                            : OutlinedButton(
                                onPressed: () {
                                  Navigator.of(context).push(
                                    MaterialPageRoute(builder: (context) => const RoleSelectionScreen()),
                                  );
                                },
                                style: OutlinedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                ),
                                child: const Text("Sign In", style: TextStyle(fontSize: 12)),
                              ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    // Coordinate status indicators
                    if (_currentPos != null)
                      Text(
                        "GPS coords: Lat: ${_currentPos!.latitude.toStringAsFixed(4)}, Lng: ${_currentPos!.longitude.toStringAsFixed(4)}",
                        style: const TextStyle(fontSize: 9, color: Colors.grey),
                      ),
                    const SizedBox(height: 16),

                    // Search & Map Toggle
                    Row(
                      children: [
                        Expanded(
                          child: Container(
                            decoration: BoxDecoration(
                              color: Theme.of(context).cardTheme.color,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.grey.withOpacity(0.15)),
                            ),
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            child: TextField(
                              controller: _searchController,
                              decoration: const InputDecoration(
                                hintText: "Search categories, plumbers, electricians...",
                                border: InputBorder.none,
                                icon: Icon(Icons.search, color: Colors.grey),
                              ),
                              onChanged: (val) {
                                setState(() {});
                              },
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        InkWell(
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
                              color: Theme.of(context).colorScheme.primary,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(Icons.map_outlined, color: Colors.white),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
          body: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 8),
                // Category section title
                const Text(
                  "Categories",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                
                // Horizontal categories
                SizedBox(
                  height: 90,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: _categories.length,
                    itemBuilder: (context, index) {
                      final cat = _categories[index];
                      final bool isSelected = _selectedCategory == cat['name'];
                      return GestureDetector(
                        onTap: () {
                          setState(() {
                            if (isSelected) {
                              _selectedCategory = "";
                            } else {
                              _selectedCategory = cat['name'];
                            }
                          });
                        },
                        child: Container(
                          width: 80,
                          margin: const EdgeInsets.only(right: 12),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? Theme.of(context).colorScheme.primary.withOpacity(0.1)
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? Theme.of(context).colorScheme.primary
                                      : cat['color'].withOpacity(0.12),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  cat['icon'],
                                  color: isSelected ? Colors.white : cat['color'],
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
                                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                  color: isSelected ? Theme.of(context).colorScheme.primary : null,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 20),

                // Sort & Filters row
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      _selectedCategory.isEmpty ? "All Nearby Professionals" : "Nearby ${_selectedCategory}s",
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    DropdownButton<String>(
                      value: _sortBy,
                      underline: const SizedBox(),
                      icon: const Icon(Icons.tune, size: 18),
                      style: TextStyle(color: Theme.of(context).colorScheme.primary, fontWeight: FontWeight.w600, fontSize: 13),
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
                const SizedBox(height: 12),

                // List of Nearby Providers
                Expanded(
                  child: StreamBuilder<List<ProviderProfile>>(
                    stream: nearbyStream,
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting && _loadingLocation) {
                        return const Center(child: CircularProgressIndicator());
                      }

                      if (snapshot.hasError) {
                        return Center(child: Text("Error: ${snapshot.error}"));
                      }

                      var list = snapshot.data ?? [];

                      // Apply search filter (if search text exists)
                      if (_searchController.text.isNotEmpty) {
                        final search = _searchController.text.toLowerCase();
                        list = list.where((p) =>
                            p.businessName.toLowerCase().contains(search) ||
                            p.ownerName.toLowerCase().contains(search) ||
                            p.category.toLowerCase().contains(search)).toList();
                      }

                      // Apply Sorting
                      if (_sortBy == "Distance") {
                        list.sort((a, b) => a.distance.compareTo(b.distance));
                      } else if (_sortBy == "Rating") {
                        list.sort((a, b) => b.rating.compareTo(a.rating));
                      } else if (_sortBy == "Price") {
                        list.sort((a, b) => a.startingPrice.compareTo(b.startingPrice));
                      }

                      if (list.isEmpty) {
                        return Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.search_off, size: 48, color: Colors.grey.withOpacity(0.5)),
                              const SizedBox(height: 8),
                              const Text("No providers found matching this criteria.", style: TextStyle(color: Colors.grey)),
                            ],
                          ),
                        );
                      }

                      return ListView.builder(
                        itemCount: list.length,
                        itemBuilder: (context, index) {
                          final provider = list[index];
                          return Card(
                            margin: const EdgeInsets.only(bottom: 14),
                            child: InkWell(
                              onTap: () {
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (context) => ProviderDetailScreen(provider: provider),
                                  ),
                                );
                              },
                              borderRadius: BorderRadius.circular(16),
                              child: Padding(
                                padding: const EdgeInsets.all(14.0),
                                child: Row(
                                  children: [
                                    // Simulated Image Placeholder
                                    Container(
                                      width: 65,
                                      height: 65,
                                      decoration: BoxDecoration(
                                        color: Theme.of(context).colorScheme.primary.withOpacity(0.08),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Icon(
                                        _getCategoryIcon(provider.category),
                                        color: Theme.of(context).colorScheme.primary,
                                        size: 28,
                                      ),
                                    ),
                                    const SizedBox(width: 16),
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
                                                  color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                                                  borderRadius: BorderRadius.circular(6),
                                                ),
                                                child: Text(
                                                  provider.category,
                                                  style: TextStyle(
                                                    fontSize: 10,
                                                    fontWeight: FontWeight.bold,
                                                    color: Theme.of(context).colorScheme.primary,
                                                  ),
                                                ),
                                              ),
                                              Row(
                                                children: [
                                                  const Icon(Icons.star, color: Colors.amber, size: 14),
                                                  const SizedBox(width: 2),
                                                  Text(
                                                    "${provider.rating}",
                                                    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                                                  ),
                                                ],
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 6),
                                          Text(
                                            provider.businessName,
                                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            provider.address,
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: const TextStyle(fontSize: 12, color: Colors.grey),
                                          ),
                                          const SizedBox(height: 6),
                                          Row(
                                            children: [
                                              const Icon(Icons.navigation_outlined, size: 12, color: Colors.grey),
                                              const SizedBox(width: 4),
                                              Text(
                                                "${provider.distance.toStringAsFixed(2)} km away",
                                                style: const TextStyle(fontSize: 11, color: Colors.grey),
                                              ),
                                              const Spacer(),
                                              Text(
                                                "Starts at ₹${provider.startingPrice.toInt()}",
                                                style: TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 12,
                                                  color: Theme.of(context).colorScheme.primary,
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
                          );
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  IconData _getCategoryIcon(String category) {
    final cat = _categories.firstWhere((c) => c['name'] == category, orElse: () => {"icon": Icons.handyman});
    return cat['icon'];
  }
}
