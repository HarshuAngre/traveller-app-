class Trip {
  const Trip({
    required this.id,
    required this.destination,
    required this.title,
    required this.budgetAmount,
    required this.currency,
    required this.status,
    this.country,
    this.description,
    this.startDate,
    this.endDate,
    this.createdAt,
  });

  final String id;
  final String title;
  final String destination;
  final String? country;
  final String? description;
  final DateTime? startDate;
  final DateTime? endDate;
  final double budgetAmount;
  final String currency;
  final String status;
  final DateTime? createdAt;

  factory Trip.fromJson(Map<String, dynamic> json) {
    return Trip(
      id: json['id'].toString(),
      title: (json['title'] as String?) ?? '',
      destination: (json['destination'] as String?) ?? '',
      country: json['country'] as String?,
      description: json['description'] as String?,
      startDate: _parseDate(json['start_date']),
      endDate: _parseDate(json['end_date']),
      budgetAmount: (json['budget_amount'] as num?)?.toDouble() ?? 0,
      currency: (json['currency'] as String?) ?? 'INR',
      status: (json['status'] as String?) ?? 'planned',
      createdAt: _parseDateTime(json['created_at']),
    );
  }

  static DateTime? _parseDate(dynamic value) {
    if (value == null) return null;
    return DateTime.tryParse(value.toString());
  }

  static DateTime? _parseDateTime(dynamic value) {
    if (value == null) return null;
    return DateTime.tryParse(value.toString());
  }

  static String dateOnly(DateTime date) {
    final local = DateTime(date.year, date.month, date.day);
    return '${local.year.toString().padLeft(4, '0')}-'
        '${local.month.toString().padLeft(2, '0')}-'
        '${local.day.toString().padLeft(2, '0')}';
  }

  static String formatDate(DateTime? date) {
    if (date == null) return 'Not selected';
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${date.day.toString().padLeft(2, '0')} '
        '${months[date.month - 1]} ${date.year}';
  }

  String get formattedBudget {
    final rounded = budgetAmount == budgetAmount.roundToDouble();
    final amount = rounded
        ? budgetAmount.toStringAsFixed(0)
        : budgetAmount.toStringAsFixed(2);
    return currency.toUpperCase() == 'INR' ? '₹$amount' : '$currency $amount';
  }

  String get dateRange => '${formatDate(startDate)} - ${formatDate(endDate)}';

  String get countryLabel => country == null || country!.trim().isEmpty
      ? 'Travel plan'
      : country!.trim();

  String get notesLabel => description == null || description!.trim().isEmpty
      ? 'No notes added.'
      : description!.trim();
}
