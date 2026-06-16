import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/models/models.dart';
import '../../../core/providers/global_providers.dart';
import '../../provider/presentation/provider_dashboard_screen.dart';

class ProviderRegistrationScreen extends ConsumerStatefulWidget {
  final AppUser user;
  const ProviderRegistrationScreen({super.key, required this.user});

  @override
  ConsumerState<ProviderRegistrationScreen> createState() => _ProviderRegistrationScreenState();
}

class _ProviderRegistrationScreenState extends ConsumerState<ProviderRegistrationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _businessNameController = TextEditingController();
  final _experienceController = TextEditingController();
  final _whatsappController = TextEditingController();
  final _priceController = TextEditingController();
  final _addressController = TextEditingController();
  final _hoursController = TextEditingController(text: "9:00 AM - 6:00 PM");
  
  String _selectedCategory = "Electrician";
  double _lat = 28.6304;
  double _lng = 77.2177;
  bool _locating = false;
  bool _saving = false;

  final List<String> _categories = [
    "Electrician",
    "Plumber",
    "Mechanic",
    "Carpenter",
    "AC Repair",
    "Painter",
    "Cleaner",
    "RO Service",
    "Appliance Repair",
    "Home Maintenance"
  ];

  @override
  void initState() {
    super.initState();
    _fetchCurrentLocation();
  }

  void _fetchCurrentLocation() async {
    setState(() { _locating = true; });
    final locSvc = ref.read(locationServiceProvider);
    final pos = await locSvc.getCurrentLocation();
    if (!mounted) return;
    
    // Reverse geocode to fill address field
    final address = await locSvc.getAddressFromCoordinates(pos.latitude, pos.longitude);
    if (!mounted) return;
    
    setState(() {
      _lat = pos.latitude;
      _lng = pos.longitude;
      _addressController.text = address;
      _locating = false;
    });
  }

  void _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() { _saving = true; });

    final dbSvc = ref.read(databaseServiceProvider);
    final profile = ProviderProfile(
      providerId: widget.user.uid,
      businessName: _businessNameController.text.trim(),
      ownerName: widget.user.name,
      category: _selectedCategory,
      rating: 5.0, // default new provider rating
      reviewsCount: 0,
      address: _addressController.text.trim(),
      phone: widget.user.phone ?? _whatsappController.text.trim(),
      whatsapp: _whatsappController.text.trim(),
      email: widget.user.email,
      latitude: _lat,
      longitude: _lng,
      isVerified: true, // Auto-verified for local mock run convenience
      startingPrice: double.parse(_priceController.text.trim()),
      experienceYears: int.parse(_experienceController.text.trim()),
      workingHours: _hoursController.text.trim(),
      serviceArea: 'Within 5 km',
    );

    // Save profile to database
    await dbSvc.createOrUpdateProviderProfile(profile);
    if (!mounted) return;

    // Update user state and navigate
    ref.read(authStateProvider.notifier).state = widget.user;

    setState(() { _saving = false; });
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Business profile created successfully!")),
    );

    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (context) => const ProviderDashboardScreen()),
      (route) => false,
    );
  }

  @override
  void dispose() {
    _businessNameController.dispose();
    _experienceController.dispose();
    _whatsappController.dispose();
    _priceController.dispose();
    _addressController.dispose();
    _hoursController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Register Business"),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  "Tell us about your services. This information helps local customers locate and hire you.",
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 24),
                
                TextFormField(
                  controller: _businessNameController,
                  decoration: InputDecoration(
                    labelText: 'Business Name',
                    prefixIcon: const Icon(Icons.storefront),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  validator: (value) => value == null || value.trim().isEmpty ? 'Please enter your business name' : null,
                ),
                const SizedBox(height: 16),

                DropdownButtonFormField<String>(
                  value: _selectedCategory,
                  decoration: InputDecoration(
                    labelText: 'Service Category',
                    prefixIcon: const Icon(Icons.category_outlined),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  items: _categories.map((c) {
                    return DropdownMenuItem(value: c, child: Text(c));
                  }).toList(),
                  onChanged: (val) {
                    if (val != null) {
                      setState(() { _selectedCategory = val; });
                    }
                  },
                ),
                const SizedBox(height: 16),

                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _experienceController,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          labelText: 'Experience (Years)',
                          prefixIcon: const Icon(Icons.work_history_outlined),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        validator: (value) => value == null || int.tryParse(value) == null ? 'Enter valid years' : null,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: TextFormField(
                        controller: _priceController,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          labelText: 'Starting Price (₹)',
                          prefixIcon: const Icon(Icons.payments_outlined),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        validator: (value) => value == null || double.tryParse(value) == null ? 'Enter price' : null,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                TextFormField(
                  controller: _whatsappController,
                  keyboardType: TextInputType.phone,
                  decoration: InputDecoration(
                    labelText: 'WhatsApp Contact Number',
                    prefixIcon: const Icon(Icons.chat_bubble_outline),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  validator: (value) => value == null || value.trim().isEmpty ? 'Enter WhatsApp contact' : null,
                ),
                const SizedBox(height: 16),

                TextFormField(
                  controller: _hoursController,
                  decoration: InputDecoration(
                    labelText: 'Working Hours',
                    prefixIcon: const Icon(Icons.access_time),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  validator: (value) => value == null || value.trim().isEmpty ? 'Enter working hours' : null,
                ),
                const SizedBox(height: 16),

                TextFormField(
                  controller: _addressController,
                  maxLines: 2,
                  decoration: InputDecoration(
                    labelText: 'Service Center Address',
                    prefixIcon: const Icon(Icons.location_on_outlined),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  validator: (value) => value == null || value.trim().isEmpty ? 'Please enter address' : null,
                ),
                const SizedBox(height: 12),

                // Location GPS details
                Card(
                  elevation: 0,
                  color: Theme.of(context).colorScheme.primary.withOpacity(0.04),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(color: Theme.of(context).colorScheme.primary.withOpacity(0.1)),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Row(
                      children: [
                        Icon(Icons.gps_fixed, color: Theme.of(context).colorScheme.primary),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "GPS Coordinates Detected",
                                style: TextStyle(fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.primary, fontSize: 13),
                              ),
                              const SizedBox(height: 2),
                              Text("Lat: ${_lat.toStringAsFixed(6)}, Lng: ${_lng.toStringAsFixed(6)}", style: const TextStyle(fontSize: 12, color: Colors.grey)),
                            ],
                          ),
                        ),
                        TextButton(
                          onPressed: _locating ? null : _fetchCurrentLocation,
                          child: _locating
                              ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                              : const Text("Refresh"),
                        )
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                ElevatedButton(
                  onPressed: _saving ? null : _saveProfile,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.all(16),
                  ),
                  child: _saving
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : const Text("Save and Enter Dashboard"),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
