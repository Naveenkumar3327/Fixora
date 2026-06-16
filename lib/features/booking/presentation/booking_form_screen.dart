import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../../core/models/models.dart';
import '../../../core/providers/global_providers.dart';
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
    
    // Create new booking
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

    // Show success dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.check_circle, color: Colors.green, size: 28),
            SizedBox(width: 8),
            Text("Booking Placed!"),
          ],
        ),
        content: Text(
          "Your appointment request has been sent to ${widget.provider.businessName}. You will be notified once they accept it.",
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop(); // dismiss dialog
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(
                  builder: (context) => MyBookingsScreen(customerId: user.uid),
                ),
                (route) => route.isFirst,
              );
            },
            child: const Text("Go to My Bookings"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Book Appointment"),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Quick Summary Card
                Card(
                  elevation: 0,
                  color: Theme.of(context).colorScheme.primary.withOpacity(0.04),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(color: Theme.of(context).colorScheme.primary.withOpacity(0.1)),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Row(
                      children: [
                        Icon(Icons.store, color: Theme.of(context).colorScheme.primary),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                widget.provider.businessName,
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                              ),
                              Text(
                                "${widget.provider.category} Service • Starts at ₹${widget.provider.startingPrice.toInt()}",
                                style: const TextStyle(fontSize: 12, color: Colors.grey),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // Date Picker trigger
                const Text("Select Appointment Date", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                const SizedBox(height: 8),
                InkWell(
                  onTap: _selectDate,
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.withOpacity(0.3)),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.calendar_month, color: Colors.grey),
                            const SizedBox(width: 12),
                            Text(
                              "${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}",
                              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
                            ),
                          ],
                        ),
                        Text(
                          "Change",
                          style: TextStyle(color: Theme.of(context).colorScheme.primary, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // Time Slot selector grid
                const Text("Select Time Slot", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: _timeSlots.map((slot) {
                    final isSelected = _selectedTimeSlot == slot;
                    return ChoiceChip(
                      label: Text(slot, style: TextStyle(fontSize: 12, color: isSelected ? Colors.white : null)),
                      selected: isSelected,
                      selectedColor: Theme.of(context).colorScheme.primary,
                      onSelected: (selected) {
                        if (selected) {
                          setState(() { _selectedTimeSlot = slot; });
                        }
                      },
                    );
                  }).toList(),
                ),
                const SizedBox(height: 24),

                // Problem Description text box
                const Text("Describe your requirements", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _descriptionController,
                  maxLines: 4,
                  decoration: InputDecoration(
                    hintText: "E.g. Leaking faucet in the master washroom, need replacement. Please bring a standard tap package...",
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  validator: (value) => value == null || value.trim().isEmpty ? 'Please enter a description of the issue' : null,
                ),
                const SizedBox(height: 36),

                // Submit button
                ElevatedButton(
                  onPressed: _submitting ? null : _submitBooking,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: _submitting
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : const Text("Confirm & Submit Booking"),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
