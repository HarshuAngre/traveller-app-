import 'package:flutter/material.dart';

import '../../core/models/trip.dart';

class CreateTripScreen extends StatefulWidget {
  const CreateTripScreen({super.key, this.trip});

  final Trip? trip;

  @override
  State<CreateTripScreen> createState() => _CreateTripScreenState();
}

class _CreateTripScreenState extends State<CreateTripScreen> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController destinationController;
  late final TextEditingController countryController;
  late final TextEditingController budgetController;
  late final TextEditingController notesController;

  DateTime? startDate;
  DateTime? endDate;

  bool get _isEditing => widget.trip != null;

  @override
  void initState() {
    super.initState();
    final trip = widget.trip;
    destinationController = TextEditingController(
      text: trip?.destination ?? '',
    );
    countryController = TextEditingController(text: trip?.country ?? '');
    budgetController = TextEditingController(
      text: trip == null ? '' : _budgetInput(trip.budgetAmount),
    );
    notesController = TextEditingController(text: trip?.description ?? '');
    startDate = trip?.startDate;
    endDate = trip?.endDate;
  }

  String _budgetInput(double value) => value == value.roundToDouble()
      ? value.toStringAsFixed(0)
      : value.toStringAsFixed(2);

  @override
  void dispose() {
    destinationController.dispose();
    countryController.dispose();
    budgetController.dispose();
    notesController.dispose();
    super.dispose();
  }

  Future<void> selectStartDate() async {
    final now = DateTime.now();
    final selectedDate = await showDatePicker(
      context: context,
      initialDate: startDate ?? now,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );

    if (selectedDate == null) return;
    setState(() {
      startDate = selectedDate;
      if (endDate != null && endDate!.isBefore(selectedDate)) {
        endDate = null;
      }
    });
  }

  Future<void> selectEndDate() async {
    if (startDate == null) {
      _showMessage('Please select the start date first.');
      return;
    }

    final selectedDate = await showDatePicker(
      context: context,
      initialDate: endDate ?? startDate!,
      firstDate: startDate!,
      lastDate: DateTime(2100),
    );

    if (selectedDate != null) {
      setState(() => endDate = selectedDate);
    }
  }

  String formatDate(DateTime? date) =>
      date == null ? 'Select date' : Trip.formatDate(date);

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  void _saveTrip() {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    if (startDate == null) {
      _showMessage('Please select a start date.');
      return;
    }
    if (endDate == null) {
      _showMessage('Please select an end date.');
      return;
    }
    if (endDate!.isBefore(startDate!)) {
      _showMessage('End date cannot be before the start date.');
      return;
    }

    final budget = double.tryParse(budgetController.text.trim());
    if (budget == null || budget <= 0) {
      _showMessage('Please enter a valid budget.');
      return;
    }

    Navigator.pop<Map<String, dynamic>>(context, {
      'destination': destinationController.text.trim(),
      'country': countryController.text.trim(),
      'budget': budget,
      'startDate': startDate!,
      'endDate': endDate!,
      'notes': notesController.text.trim(),
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
        title: Text(
          _isEditing ? 'Edit Trip' : 'Create Trip',
          style: const TextStyle(
            color: Colors.black,
            fontSize: 23,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 10, 20, 30),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(22),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF1565C0), Color(0xFF42A5F5)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(25),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(
                      Icons.flight_takeoff,
                      color: Colors.white,
                      size: 45,
                    ),
                    const SizedBox(height: 15),
                    Text(
                      _isEditing
                          ? 'Update Your Adventure'
                          : 'Plan Your Next Adventure',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      _isEditing
                          ? 'Update the details of your trip.'
                          : 'Add the details of your upcoming trip.',
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 30),
              const Text(
                'Destination',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: destinationController,
                textCapitalization: TextCapitalization.words,
                decoration: _inputDecoration(
                  'e.g. Goa, Manali, Dubai',
                  Icons.location_on,
                ),
                validator: (value) {
                  if (value == null || value.trim().length < 2) {
                    return 'Please enter a valid destination';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),
              const Text(
                'Country / Region',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: countryController,
                textCapitalization: TextCapitalization.words,
                decoration: _inputDecoration(
                  'e.g. India, UAE, Thailand',
                  Icons.public,
                ),
              ),
              const SizedBox(height: 25),
              const Text(
                'Travel Dates',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: _dateCard(
                      title: 'Start Date',
                      date: formatDate(startDate),
                      icon: Icons.calendar_today,
                      onTap: selectStartDate,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _dateCard(
                      title: 'End Date',
                      date: formatDate(endDate),
                      icon: Icons.event,
                      onTap: selectEndDate,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 25),
              const Text(
                'Budget',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: budgetController,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: _inputDecoration(
                  'Enter your budget',
                  Icons.currency_rupee,
                ).copyWith(prefixText: '₹ '),
                validator: (value) {
                  final amount = double.tryParse(value?.trim() ?? '');
                  if (amount == null || amount <= 0) {
                    return 'Enter a valid budget';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 25),
              const Text(
                'Notes',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: notesController,
                maxLines: 4,
                textCapitalization: TextCapitalization.sentences,
                decoration: _inputDecoration(
                  'Add notes about your trip...',
                  Icons.notes,
                ).copyWith(alignLabelWithHint: true),
              ),
              const SizedBox(height: 35),
              SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton.icon(
                  onPressed: _saveTrip,
                  icon: Icon(_isEditing ? Icons.save : Icons.add),
                  label: Text(
                    _isEditing ? 'Save Changes' : 'Create Trip',
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1565C0),
                    foregroundColor: Colors.white,
                    elevation: 3,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(String hint, IconData icon) {
    return InputDecoration(
      hintText: hint,
      prefixIcon: Icon(icon, color: const Color(0xFF1565C0)),
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: const BorderSide(color: Color(0xFF1565C0), width: 2),
      ),
    );
  }

  Widget _dateCard({
    required String title,
    required String date,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: const Color(0xFF1565C0), size: 25),
            const SizedBox(height: 12),
            Text(
              title,
              style: const TextStyle(color: Colors.grey, fontSize: 12),
            ),
            const SizedBox(height: 5),
            Text(
              date,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }
}
