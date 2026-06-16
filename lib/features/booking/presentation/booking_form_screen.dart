import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:uuid/uuid.dart';
import '../../../core/models/models.dart';
import '../../../core/providers/global_providers.dart';
import '../../../core/theme/theme.dart';
import 'my_bookings_screen.dart';

class BookingFormScreen extends ConsumerStatefulWidget {
  final ProviderProfile provider;

  const BookingFormScreen({super.key, required this.provider});

  @override
  ConsumerState<BookingFormScreen> createState() => _BookingFormScreenState();
}

class _BookingFormScreenState extends ConsumerState<BookingFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _descriptionController = TextEditingController();
  
  DateTime _selectedDate = DateTime.now().add(const Duration(days: 1));
  String _selectedTimeSlot = "10:00 AM - 12:00 PM";
  bool _submitting = false;

  final List<String> _timeSlots = [
    "08:00 AM - 10:00 AM",
    "10:00 AM - 12:00 PM",
    "12:00 PM - 02:00 PM",
    "02:00 PM - 04:00 PM",
    "04:00 PM - 06:00 PM",
    "06:00 PM - 08:00 PM",
  ];

  @override
  void dispose() {
    _descriptionController.dispose();
    super.dispose();
  }

  void _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 30)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.dark(
              primary: AppTheme.primaryColor,
              onPrimary: Colors.white,
              surface: AppTheme.darkCard,
              onSurface: AppTheme.textPrimary,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  void _submitBooking() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() { _submitting = true; });

    final user = ref.read(authStateProvider);
    if (user == null) return;

    final dbSvc = ref.read(databaseServiceProvider);
    
    final bookingId = "book_${const Uuid().v4().substring(0, 8)}";
    final booking = Booking(
      id: bookingId,
      customerId: user.uid,
      customerName: user.name,
      providerId: widget.provider.providerId,
      providerBusinessName: widget.provider.businessName,
      category: widget.provider.category,
      dateTime: _selectedDate,
      timeSlot: _selectedTimeSlot,
      description: _descriptionController.text.trim(),
      status: BookingStatus.pending,
      cost: widget.provider.startingPrice,
      statusTimeline: [
        "Booking Submitted: ${DateTime.now().hour.toString().padLeft(2, '0')}:${DateTime.now().minute.toString().padLeft(2, '0')}"
      ],
    );

    await dbSvc.createBooking(booking);

    setState(() { _submitting = false; });

    if (!mounted) return;

    // Show premium confirmation dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.darkCard,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: BorderSide(color: AppTheme.successColor.withOpacity(0.3), width: 1.5),
        ),
        title: Row(
          children: [
            const Icon(Icons.check_circle_rounded, color: AppTheme.successColor, size: 32)
                .animate()
                .scale(duration: 500.ms, curve: Curves.elasticOut),
            const SizedBox(width: 12),
            const Text("Booking Placed!", style: TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.w900)),
          ],
        ),
        content: Text(
          "Your appointment request has been sent to ${widget.provider.businessName}. You will be notified once they accept it.",
          style: TextStyle(color: AppTheme.textPrimary.withOpacity(0.9), height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(
                  builder: (context) => MyBookingsScreen(customerId: user.uid),
                ),
                (route) => route.isFirst,
              );
            },
            child: const Text("Go to My Bookings", style: TextStyle(color: AppTheme.primaryColor, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text("Book Appointment"),
      ),
      body: PremiumBackground(
        child: SafeArea(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 12.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Provider Summary Card
                    GlassCard(
                      padding: const EdgeInsets.all(16.0),
                      borderRadius: 18,
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: AppTheme.primaryColor.withOpacity(0.12),
                              border: Border.all(color: AppTheme.primaryColor.withOpacity(0.2)),
                            ),
                            child: const Icon(Icons.store, color: AppTheme.primaryColor, size: 24),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  widget.provider.businessName,
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppTheme.textPrimary),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  "${widget.provider.category} Service • Starts at ₹${widget.provider.startingPrice.toInt()}",
                                  style: TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Date Picker trigger
                    const Text("Select Appointment Date", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppTheme.textPrimary)),
                    const SizedBox(height: 10),
                    GestureDetector(
                      onTap: _selectDate,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                        decoration: BoxDecoration(
                          color: AppTheme.darkCard.withOpacity(0.4),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: Colors.white.withOpacity(0.08), width: 1.2),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                const Icon(Icons.calendar_month, color: AppTheme.primaryColor),
                                const SizedBox(width: 12),
                                Text(
                                  "${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}",
                                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
                                ),
                              ],
                            ),
                            const Text(
                              "Change",
                              style: TextStyle(color: AppTheme.primaryColor, fontWeight: FontWeight.w900, fontSize: 13),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Time Slot selector grid
                    const Text("Select Time Slot", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppTheme.textPrimary)),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: _timeSlots.map((slot) {
                        final isSelected = _selectedTimeSlot == slot;
                        return GestureDetector(
                          onTap: () {
                            setState(() { _selectedTimeSlot = slot; });
                          },
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? AppTheme.primaryColor.withOpacity(0.12)
                                  : AppTheme.darkCard.withOpacity(0.4),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: isSelected ? AppTheme.primaryColor : Colors.white.withOpacity(0.08),
                                width: isSelected ? 1.8 : 1.2,
                              ),
                              boxShadow: isSelected
                                  ? [BoxShadow(color: AppTheme.primaryColor.withOpacity(0.2), blurRadius: 4)]
                                  : null,
                            ),
                            child: Text(
                              slot,
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                color: isSelected ? AppTheme.primaryColor : AppTheme.textSecondary,
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 24),

                    // Problem Description text box
                    const Text("Describe your requirements", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppTheme.textPrimary)),
                    const SizedBox(height: 10),
                    TextFormField(
                      controller: _descriptionController,
                      maxLines: 4,
                      style: const TextStyle(color: AppTheme.textPrimary),
                      decoration: const InputDecoration(
                        hintText: "Describe the repair or maintenance needed in detail...",
                      ),
                      validator: (value) => value == null || value.trim().isEmpty ? 'Please enter a description of the issue' : null,
                    ),
                    const SizedBox(height: 36),

                    // Confirm Submit button
                    GestureDetector(
                      onTap: _submitting ? null : _submitBooking,
                      child: Container(
                        height: 52,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(14),
                          gradient: const LinearGradient(
                            colors: [AppTheme.primaryColor, AppTheme.secondaryColor],
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: AppTheme.primaryColor.withOpacity(0.4),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            )
                          ],
                        ),
                        child: Center(
                          child: _submitting
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                                )
                              : const Text(
                                  "Confirm & Submit Booking",
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                        ),
                      ),
                    )
                        .animate()
                        .scale(begin: const Offset(0.98, 0.98), duration: 150.ms),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

