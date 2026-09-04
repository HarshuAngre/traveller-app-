import 'package:flutter/material.dart';

class CreateTripScreen extends StatefulWidget {
  const CreateTripScreen({super.key});

  @override
  State<CreateTripScreen> createState() => _CreateTripScreenState();
}

class _CreateTripScreenState extends State<CreateTripScreen> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController destinationController =
      TextEditingController();

  final TextEditingController budgetController =
      TextEditingController();

  final TextEditingController notesController =
      TextEditingController();

  DateTime? startDate;
  DateTime? endDate;

  @override
  void dispose() {
    destinationController.dispose();
    budgetController.dispose();
    notesController.dispose();
    super.dispose();
  }

  Future<void> selectStartDate() async {
    final DateTime? selectedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(2100),
    );

    if (selectedDate != null) {
      setState(() {
        startDate = selectedDate;

        if (endDate != null && endDate!.isBefore(selectedDate)) {
          endDate = null;
        }
      });
    }
  }

  Future<void> selectEndDate() async {
    if (startDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select the start date first.'),
        ),
      );
      return;
    }

    final DateTime? selectedDate = await showDatePicker(
      context: context,
      initialDate: startDate!,
      firstDate: startDate!,
      lastDate: DateTime(2100),
    );

    if (selectedDate != null) {
      setState(() {
        endDate = selectedDate;
      });
    }
  }

  String formatDate(DateTime? date) {
    if (date == null) {
      return 'Select date';
    }

    return '${date.day.toString().padLeft(2, '0')}/'
        '${date.month.toString().padLeft(2, '0')}/'
        '${date.year}';
  }

  void createTrip() {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (startDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a start date.'),
        ),
      );
      return;
    }

    if (endDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select an end date.'),
        ),
      );
      return;
    }

    final trip = {
      'destination': destinationController.text.trim(),
      'budget': budgetController.text.trim(),
      'startDate': formatDate(startDate),
      'endDate': formatDate(endDate),
      'notes': notesController.text.trim(),
    };

    debugPrint('Created Trip: $trip');

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Trip created successfully! 🎉'),
        duration: Duration(seconds: 2),
      ),
    );

    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) {
        Navigator.pop(context, trip);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),

      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'Create Trip',
          style: TextStyle(
            color: Colors.black,
            fontSize: 23,
            fontWeight: FontWeight.bold,
          ),
        ),
        iconTheme: const IconThemeData(
          color: Colors.black,
        ),
      ),

      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 10, 20, 30),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(22),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [
                      Color(0xFF1565C0),
                      Color(0xFF42A5F5),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(25),
                ),
                child: const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.flight_takeoff,
                      color: Colors.white,
                      size: 45,
                    ),
                    SizedBox(height: 15),
                    Text(
                      'Plan Your Next Adventure',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 6),
                    Text(
                      'Add the details of your upcoming trip.',
                      style: TextStyle(
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
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 10),

              TextFormField(
                controller: destinationController,
                textCapitalization: TextCapitalization.words,
                decoration: InputDecoration(
                  hintText: 'e.g. Goa, Manali, Dubai',
                  prefixIcon: const Icon(
                    Icons.location_on,
                    color: Color(0xFF1565C0),
                  ),
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(18),
                    borderSide: BorderSide.none,
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(18),
                    borderSide: const BorderSide(
                      color: Color(0xFF1565C0),
                      width: 2,
                    ),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter a destination';
                  }

                  if (value.trim().length < 2) {
                    return 'Enter a valid destination';
                  }

                  return null;
                },
              ),

              const SizedBox(height: 25),

              const Text(
                'Travel Dates',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
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
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 10),

              TextFormField(
                controller: budgetController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  hintText: 'Enter your budget',
                  prefixIcon: const Icon(
                    Icons.currency_rupee,
                    color: Colors.green,
                  ),
                  prefixText: '₹ ',
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(18),
                    borderSide: BorderSide.none,
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(18),
                    borderSide: const BorderSide(
                      color: Color(0xFF1565C0),
                      width: 2,
                    ),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter your budget';
                  }

                  final budget = double.tryParse(value);

                  if (budget == null || budget <= 0) {
                    return 'Enter a valid budget';
                  }

                  return null;
                },
              ),

              const SizedBox(height: 25),

              const Text(
                'Notes',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 10),

              TextFormField(
                controller: notesController,
                maxLines: 4,
                textCapitalization: TextCapitalization.sentences,
                decoration: InputDecoration(
                  hintText: 'Add notes about your trip...',
                  alignLabelWithHint: true,
                  prefixIcon: const Padding(
                    padding: EdgeInsets.only(bottom: 55),
                    child: Icon(
                      Icons.notes,
                      color: Color(0xFF1565C0),
                    ),
                  ),
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(18),
                    borderSide: BorderSide.none,
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(18),
                    borderSide: const BorderSide(
                      color: Color(0xFF1565C0),
                      width: 2,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 35),

              SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton.icon(
                  onPressed: createTrip,
                  icon: const Icon(Icons.add),
                  label: const Text(
                    'Create Trip',
                    style: TextStyle(
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
          border: Border.all(
            color: Colors.transparent,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              icon,
              color: const Color(0xFF1565C0),
              size: 25,
            ),

            const SizedBox(height: 12),

            Text(
              title,
              style: const TextStyle(
                color: Colors.grey,
                fontSize: 12,
              ),
            ),

            const SizedBox(height: 5),

            Text(
              date,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }
}