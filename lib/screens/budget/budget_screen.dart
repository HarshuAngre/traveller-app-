import 'package:flutter/material.dart';

import '../../core/services/budget_service.dart';

class BudgetScreen extends StatefulWidget {
  const BudgetScreen({super.key});

  @override
  State<BudgetScreen> createState() => _BudgetScreenState();
}

class _BudgetScreenState extends State<BudgetScreen> {
  final BudgetService _budgetService = BudgetService();

  List<Map<String, dynamic>> _trips = [];
  List<Map<String, dynamic>> _expenses = [];
  String? _selectedTripId;
  bool _isLoading = true;
  bool _isChangingTrip = false;
  String? _errorMessage;

  Map<String, dynamic>? get _selectedTrip {
    for (final trip in _trips) {
      if (trip['id']?.toString() == _selectedTripId) {
        return trip;
      }
    }
    return null;
  }

  double get totalBudget => _asDouble(_selectedTrip?['budget_amount']);

  double get totalSpent => _expenses.fold<double>(
        0,
        (sum, expense) => sum + _asDouble(expense['amount']),
      );

  double get remaining => totalBudget - totalSpent;

  @override
  void initState() {
    super.initState();
    _loadTrips();
  }

  double _asDouble(dynamic value) {
    if (value is num) return value.toDouble();
    return double.tryParse(value?.toString() ?? '') ?? 0;
  }

  Future<void> _loadTrips() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final trips = await _budgetService.fetchTrips();

      if (trips.isEmpty) {
        if (!mounted) return;
        setState(() {
          _trips = [];
          _expenses = [];
          _selectedTripId = null;
          _isLoading = false;
        });
        return;
      }

      Map<String, dynamic> selectedTrip = trips.first;
      if (_selectedTripId != null) {
        for (final trip in trips) {
          if (trip['id']?.toString() == _selectedTripId) {
            selectedTrip = trip;
            break;
          }
        }
      }

      final tripId = selectedTrip['id'].toString();
      final expenses = await _budgetService.fetchExpenses(tripId);

      if (!mounted) return;
      setState(() {
        _trips = trips;
        _selectedTripId = tripId;
        _expenses = expenses;
        _isLoading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorMessage = _readableError(error);
      });
    }
  }

  Future<void> _selectTrip(String tripId) async {
    if (tripId == _selectedTripId) return;

    setState(() {
      _selectedTripId = tripId;
      _isChangingTrip = true;
      _errorMessage = null;
      _expenses = [];
    });

    try {
      final expenses = await _budgetService.fetchExpenses(tripId);
      if (!mounted) return;
      setState(() {
        _expenses = expenses;
        _isChangingTrip = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _isChangingTrip = false;
        _errorMessage = _readableError(error);
      });
    }
  }

  Future<void> _refreshExpenses() async {
    final tripId = _selectedTripId;
    if (tripId == null) return;

    try {
      final expenses = await _budgetService.fetchExpenses(tripId);
      if (!mounted) return;
      setState(() => _expenses = expenses);
    } catch (error) {
      if (!mounted) return;
      _showSnackBar('Could not refresh expenses: ${_readableError(error)}');
    }
  }

  Future<void> _showExpenseDialog({
    Map<String, dynamic>? expense,
  }) async {
    final tripId = _selectedTripId;
    if (tripId == null) return;

    final nameController = TextEditingController(
      text: expense?['title']?.toString() ?? '',
    );
    final amountController = TextEditingController(
      text: expense == null
          ? ''
          : _asDouble(expense['amount']).toStringAsFixed(2),
    );

    const categories = [
      'Food',
      'Transport',
      'Accommodation',
      'Shopping',
      'Entertainment',
      'Other',
    ];

    String selectedCategory = categories.contains(expense?['category'])
        ? expense!['category'].toString()
        : 'Food';
    DateTime selectedDate = _parseDate(expense?['expense_date']);
    bool isSaving = false;

    try {
      await showDialog<void>(
        context: context,
        builder: (dialogContext) {
          return StatefulBuilder(
            builder: (context, setDialogState) {
              return AlertDialog(
                title: Text(
                  expense == null ? 'Add Expense' : 'Edit Expense',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                content: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextField(
                        controller: nameController,
                        textCapitalization: TextCapitalization.words,
                        decoration: InputDecoration(
                          labelText: 'Expense Name',
                          hintText: 'e.g. Dinner',
                          prefixIcon: const Icon(Icons.receipt_long),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(15),
                          ),
                        ),
                      ),
                      const SizedBox(height: 15),
                      TextField(
                        controller: amountController,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        decoration: InputDecoration(
                          labelText: 'Amount',
                          hintText: 'e.g. 500',
                          prefixIcon: const Icon(Icons.currency_rupee),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(15),
                          ),
                        ),
                      ),
                      const SizedBox(height: 15),
                      DropdownButtonFormField<String>(
                        initialValue: selectedCategory,
                        isExpanded: true,
                        decoration: InputDecoration(
                          labelText: 'Category',
                          prefixIcon: const Icon(Icons.category),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(15),
                          ),
                        ),
                        items: categories
                            .map(
                              (category) => DropdownMenuItem<String>(
                                value: category,
                                child: Text(category),
                              ),
                            )
                            .toList(),
                        onChanged: (value) {
                          if (value != null) {
                            setDialogState(() => selectedCategory = value);
                          }
                        },
                      ),
                      const SizedBox(height: 15),
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: isSaving
                              ? null
                              : () async {
                                  final picked = await showDatePicker(
                                    context: dialogContext,
                                    initialDate: selectedDate,
                                    firstDate: DateTime(2000),
                                    lastDate: DateTime(2100),
                                  );
                                  if (picked != null && dialogContext.mounted) {
                                    setDialogState(() => selectedDate = picked);
                                  }
                                },
                          icon: const Icon(Icons.calendar_month),
                          label: Text('Date: ${_formatDate(selectedDate)}'),
                        ),
                      ),
                    ],
                  ),
                ),
                actions: [
                  TextButton(
                    onPressed: isSaving
                        ? null
                        : () => Navigator.pop(dialogContext),
                    child: const Text('Cancel'),
                  ),
                  ElevatedButton(
                    onPressed: isSaving
                        ? null
                        : () async {
                            final title = nameController.text.trim();
                            final amount = double.tryParse(
                              amountController.text.trim(),
                            );

                            if (title.isEmpty ||
                                amount == null ||
                                !amount.isFinite ||
                                amount <= 0) {
                              ScaffoldMessenger.of(dialogContext).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    'Enter an expense name and a valid amount.',
                                  ),
                                ),
                              );
                              return;
                            }

                            setDialogState(() => isSaving = true);
                            try {
                              if (expense == null) {
                                await _budgetService.addExpense(
                                  tripId: tripId,
                                  title: title,
                                  category: selectedCategory,
                                  amount: amount,
                                  expenseDate: selectedDate,
                                );
                              } else {
                                await _budgetService.updateExpense(
                                  expenseId: expense['id'].toString(),
                                  tripId: tripId,
                                  title: title,
                                  category: selectedCategory,
                                  amount: amount,
                                  expenseDate: selectedDate,
                                );
                              }

                              if (!mounted || !dialogContext.mounted) return;
                              Navigator.pop(dialogContext);
                              await _refreshExpenses();
                              if (!mounted) return;
                              _showSnackBar(
                                expense == null
                                    ? 'Expense saved successfully!'
                                    : 'Expense updated successfully!',
                              );
                            } catch (error) {
                              if (!dialogContext.mounted) return;
                              setDialogState(() => isSaving = false);
                              ScaffoldMessenger.of(dialogContext).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    'Could not save expense: ${_readableError(error)}',
                                  ),
                                ),
                              );
                            }
                          },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1565C0),
                      foregroundColor: Colors.white,
                    ),
                    child: isSaving
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : Text(expense == null ? 'Add' : 'Save'),
                  ),
                ],
              );
            },
          );
        },
      );
    } finally {
      nameController.dispose();
      amountController.dispose();
    }
  }

  Future<void> _editBudget() async {
    final trip = _selectedTrip;
    final tripId = _selectedTripId;
    if (trip == null || tripId == null) return;

    final controller = TextEditingController(
      text: totalBudget.toStringAsFixed(0),
    );
    bool isSaving = false;

    try {
      await showDialog<void>(
        context: context,
        builder: (dialogContext) {
          return StatefulBuilder(
            builder: (context, setDialogState) {
              return AlertDialog(
                title: const Text(
                  'Set Trip Budget',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                content: TextField(
                  controller: controller,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: InputDecoration(
                    labelText: 'Total Budget',
                    prefixText: '₹ ',
                    prefixIcon: const Icon(Icons.account_balance_wallet),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                  ),
                ),
                actions: [
                  TextButton(
                    onPressed: isSaving
                        ? null
                        : () => Navigator.pop(dialogContext),
                    child: const Text('Cancel'),
                  ),
                  ElevatedButton(
                    onPressed: isSaving
                        ? null
                        : () async {
                            final newBudget = double.tryParse(
                              controller.text.trim(),
                            );
                            if (newBudget == null ||
                                !newBudget.isFinite ||
                                newBudget < 0) {
                              ScaffoldMessenger.of(dialogContext).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    'Enter a valid budget amount (zero or more).',
                                  ),
                                ),
                              );
                              return;
                            }

                            setDialogState(() => isSaving = true);
                            try {
                              await _budgetService.updateTripBudget(
                                tripId: tripId,
                                amount: newBudget,
                              );
                              if (!mounted || !dialogContext.mounted) return;
                              setState(() {
                                trip['budget_amount'] = newBudget;
                              });
                              Navigator.pop(dialogContext);
                              _showSnackBar('Budget updated successfully!');
                            } catch (error) {
                              if (!dialogContext.mounted) return;
                              setDialogState(() => isSaving = false);
                              ScaffoldMessenger.of(dialogContext).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    'Could not update budget: ${_readableError(error)}',
                                  ),
                                ),
                              );
                            }
                          },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1565C0),
                      foregroundColor: Colors.white,
                    ),
                    child: isSaving
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Text('Save'),
                  ),
                ],
              );
            },
          );
        },
      );
    } finally {
      controller.dispose();
    }
  }

  Future<void> _deleteExpense(Map<String, dynamic> expense) async {
    final tripId = _selectedTripId;
    if (tripId == null) return;

    try {
      await _budgetService.deleteExpense(
        expenseId: expense['id'].toString(),
        tripId: tripId,
      );

      if (!mounted) return;
      final messenger = ScaffoldMessenger.of(context);
      messenger.hideCurrentSnackBar();
      messenger.showSnackBar(
        SnackBar(
          content: Text('${expense['title']} expense deleted.'),
          action: SnackBarAction(
            label: 'UNDO',
            onPressed: () => _undoDeleteExpense(expense),
          ),
        ),
      );
    } catch (error) {
      await _refreshExpenses();
      if (!mounted) return;
      _showSnackBar('Could not delete expense: ${_readableError(error)}');
    }
  }

  Future<void> _undoDeleteExpense(Map<String, dynamic> expense) async {
    try {
      await _budgetService.restoreExpense(expense);
      await _refreshExpenses();
      if (!mounted) return;
      _showSnackBar('Expense restored.');
    } catch (error) {
      if (!mounted) return;
      _showSnackBar('Could not restore expense: ${_readableError(error)}');
    }
  }

  void _showSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  String _readableError(Object error) {
    return error.toString().replaceFirst('Exception: ', '');
  }

  DateTime _parseDate(dynamic value) {
    if (value == null) return DateTime.now();
    return DateTime.tryParse(value.toString()) ?? DateTime.now();
  }

  String _formatDate(DateTime date) {
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

  IconData _getCategoryIcon(String category) {
    switch (category) {
      case 'Food':
        return Icons.restaurant;
      case 'Transport':
        return Icons.directions_car;
      case 'Accommodation':
        return Icons.hotel;
      case 'Shopping':
        return Icons.shopping_bag;
      case 'Entertainment':
        return Icons.movie;
      default:
        return Icons.receipt_long;
    }
  }

  Color _getCategoryColor(String category) {
    switch (category) {
      case 'Food':
        return Colors.orange;
      case 'Transport':
        return Colors.blue;
      case 'Accommodation':
        return Colors.purple;
      case 'Shopping':
        return Colors.pink;
      case 'Entertainment':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
        title: const Text(
          'Budget Tracker',
          style: TextStyle(
            color: Colors.black,
            fontSize: 23,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          if (_selectedTripId != null)
            IconButton(
              onPressed: _editBudget,
              tooltip: 'Edit trip budget',
              icon: const Icon(Icons.edit, color: Colors.black),
            ),
        ],
      ),
      body: _buildBody(),
      floatingActionButton: !_isLoading &&
              _errorMessage == null &&
              _selectedTripId != null
          ? FloatingActionButton.extended(
              onPressed: () => _showExpenseDialog(),
              backgroundColor: const Color(0xFF1565C0),
              foregroundColor: Colors.white,
              icon: const Icon(Icons.add),
              label: const Text(
                'Add Expense',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            )
          : null,
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: Color(0xFF1565C0)),
      );
    }

    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.cloud_off, size: 52, color: Colors.grey),
              const SizedBox(height: 12),
              const Text(
                'Could not load your budget',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(_errorMessage!, textAlign: TextAlign.center),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: _loadTrips,
                icon: const Icon(Icons.refresh),
                label: const Text('Try again'),
              ),
            ],
          ),
        ),
      );
    }

    if (_trips.isEmpty) {
      return _buildNoTrips();
    }

    final progress = totalBudget <= 0
        ? 0.0
        : (totalSpent / totalBudget).clamp(0.0, 1.0).toDouble();

    return RefreshIndicator(
      onRefresh: _loadTrips,
      color: const Color(0xFF1565C0),
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(20, 10, 20, 100),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildTripSelector(),
            const SizedBox(height: 16),
            _buildBudgetOverview(progress),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: _buildSummaryCard(
                    title: 'Spent',
                    amount: totalSpent,
                    icon: Icons.trending_up,
                    color: Colors.red,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildSummaryCard(
                    title: 'Remaining',
                    amount: remaining,
                    icon: Icons.savings,
                    color: remaining >= 0 ? Colors.green : Colors.red,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 30),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Expenses',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                ),
                Text(
                  '${_expenses.length} items',
                  style: const TextStyle(color: Colors.grey),
                ),
              ],
            ),
            const SizedBox(height: 15),
            if (_isChangingTrip)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 24),
                child: Center(child: CircularProgressIndicator()),
              )
            else if (_expenses.isEmpty)
              _buildEmptyExpenses()
            else
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _expenses.length,
                separatorBuilder: (context, index) =>
                    const SizedBox(height: 10),
                itemBuilder: (context, index) =>
                    _buildExpenseCard(_expenses[index]),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildTripSelector() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.08),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: DropdownButtonFormField<String>(
        key: ValueKey(_selectedTripId),
        initialValue: _selectedTripId,
        isExpanded: true,
        decoration: const InputDecoration(
          labelText: 'Select trip',
          border: InputBorder.none,
          prefixIcon: Icon(Icons.flight_takeoff, color: Color(0xFF1565C0)),
        ),
        items: _trips.map((trip) {
          final destination = trip['destination']?.toString() ?? 'Untitled trip';
          final title = trip['title']?.toString() ?? destination;
          final label = title == destination ? destination : '$title • $destination';
          return DropdownMenuItem<String>(
            value: trip['id'].toString(),
            child: Text(label, overflow: TextOverflow.ellipsis),
          );
        }).toList(),
        onChanged: (value) {
          if (value != null) _selectTrip(value);
        },
      ),
    );
  }

  Widget _buildBudgetOverview(double progress) {
    return Container(
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
          const Text(
            'Trip Budget',
            style: TextStyle(color: Colors.white70, fontSize: 15),
          ),
          const SizedBox(height: 5),
          Text(
            '₹${totalBudget.toStringAsFixed(0)}',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 32,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 20),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 10,
              backgroundColor: Colors.white.withValues(alpha: 0.25),
              valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            '${(progress * 100).toStringAsFixed(0)}% of your budget used',
            style: const TextStyle(color: Colors.white70),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard({
    required String title,
    required double amount,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.10),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 27),
          const SizedBox(height: 12),
          Text(
            title,
            style: const TextStyle(color: Colors.grey, fontSize: 13),
          ),
          const SizedBox(height: 5),
          Text(
            '₹${amount.toStringAsFixed(0)}',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: amount < 0 ? Colors.red : Colors.black,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExpenseCard(Map<String, dynamic> expense) {
    final category = expense['category']?.toString() ?? 'Other';
    final categoryColor = _getCategoryColor(category);
    final expenseDate = _parseDate(expense['expense_date']);
    final expenseId = expense['id'].toString();

    return Dismissible(
      key: ValueKey(expenseId),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(
          color: Colors.red,
          borderRadius: BorderRadius.circular(18),
        ),
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      onDismissed: (direction) {
        setState(() {
          _expenses.removeWhere((item) => item['id'].toString() == expenseId);
        });
        _deleteExpense(expense);
      },
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: () => _showExpenseDialog(expense: expense),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withValues(alpha: 0.05),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 25,
                  backgroundColor: categoryColor.withValues(alpha: 0.12),
                  child: Icon(
                    _getCategoryIcon(category),
                    color: categoryColor,
                  ),
                ),
                const SizedBox(width: 15),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        expense['title']?.toString() ?? 'Expense',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '$category • ${_formatDate(expenseDate)}',
                        style: const TextStyle(color: Colors.grey, fontSize: 12),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      '₹${_asDouble(expense['amount']).toStringAsFixed(0)}',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Icon(
                      Icons.edit_outlined,
                      size: 15,
                      color: Colors.grey,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyExpenses() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(30),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: const Column(
        children: [
          Icon(Icons.receipt_long, size: 60, color: Colors.grey),
          SizedBox(height: 15),
          Text(
            'No Expenses Yet',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 5),
          Text(
            'Add your first expense using the button below.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Widget _buildNoTrips() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.luggage, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            const Text(
              'No Trips Available',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'Create a trip in My Trips first. You can then set its budget and add expenses here.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 18),
            OutlinedButton.icon(
              onPressed: _loadTrips,
              icon: const Icon(Icons.refresh),
              label: const Text('Refresh'),
            ),
          ],
        ),
      ),
    );
  }
}
