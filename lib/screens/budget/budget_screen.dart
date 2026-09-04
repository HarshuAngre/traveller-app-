import 'package:flutter/material.dart';

class BudgetScreen extends StatefulWidget {
  const BudgetScreen({super.key});

  @override
  State<BudgetScreen> createState() => _BudgetScreenState();
}

class _BudgetScreenState extends State<BudgetScreen> {
  double totalBudget = 20000;

  final List<Map<String, dynamic>> expenses = [
    {
      'name': 'Hotel',
      'amount': 5000.0,
      'category': 'Accommodation',
      'icon': Icons.hotel,
    },
    {
      'name': 'Travel',
      'amount': 2500.0,
      'category': 'Transport',
      'icon': Icons.directions_car,
    },
  ];

  double get totalSpent {
    return expenses.fold(
      0,
      (sum, expense) => sum + (expense['amount'] as double),
    );
  }

  double get remaining {
    return totalBudget - totalSpent;
  }

  void showAddExpenseDialog() {
    final nameController = TextEditingController();
    final amountController = TextEditingController();

    String selectedCategory = 'Food';

    showDialog(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text(
                'Add Expense',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                ),
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
                        prefixIcon: const Icon(
                          Icons.receipt_long,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(15),
                        ),
                      ),
                    ),

                    const SizedBox(height: 15),

                    TextField(
                      controller: amountController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: 'Amount',
                        hintText: 'e.g. 500',
                        prefixIcon: const Icon(
                          Icons.currency_rupee,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(15),
                        ),
                      ),
                    ),

                    const SizedBox(height: 15),

                    DropdownButtonFormField<String>(
                      initialValue: selectedCategory,
                      decoration: InputDecoration(
                        labelText: 'Category',
                        prefixIcon: const Icon(
                          Icons.category,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(15),
                        ),
                      ),
                      items: const [
                        DropdownMenuItem(
                          value: 'Food',
                          child: Text('Food'),
                        ),
                        DropdownMenuItem(
                          value: 'Transport',
                          child: Text('Transport'),
                        ),
                        DropdownMenuItem(
                          value: 'Accommodation',
                          child: Text('Accommodation'),
                        ),
                        DropdownMenuItem(
                          value: 'Shopping',
                          child: Text('Shopping'),
                        ),
                        DropdownMenuItem(
                          value: 'Entertainment',
                          child: Text('Entertainment'),
                        ),
                        DropdownMenuItem(
                          value: 'Other',
                          child: Text('Other'),
                        ),
                      ],
                      onChanged: (value) {
                        if (value != null) {
                          setDialogState(() {
                            selectedCategory = value;
                          });
                        }
                      },
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(dialogContext);
                  },
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () {
                    final name = nameController.text.trim();
                    final amount =
                        double.tryParse(amountController.text.trim());

                    if (name.isEmpty || amount == null || amount <= 0) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            'Please enter a valid expense.',
                          ),
                        ),
                      );
                      return;
                    }

                    setState(() {
                      expenses.add({
                        'name': name,
                        'amount': amount,
                        'category': selectedCategory,
                        'icon': _getCategoryIcon(
                          selectedCategory,
                        ),
                      });
                    });

                    Navigator.pop(dialogContext);

                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                          'Expense added successfully! 💰',
                        ),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1565C0),
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Add'),
                ),
              ],
            );
          },
        );
      },
    );
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

  void deleteExpense(int index) {
    final expense = expenses[index];

    setState(() {
      expenses.removeAt(index);
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          '${expense['name']} expense deleted.',
        ),
        action: SnackBarAction(
          label: 'UNDO',
          onPressed: () {
            setState(() {
              expenses.insert(index, expense);
            });
          },
        ),
      ),
    );
  }

  void editBudget() {
    final controller = TextEditingController(
      text: totalBudget.toStringAsFixed(0),
    );

    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text(
            'Set Trip Budget',
            style: TextStyle(
              fontWeight: FontWeight.bold,
            ),
          ),
          content: TextField(
            controller: controller,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              labelText: 'Total Budget',
              prefixText: '₹ ',
              prefixIcon: const Icon(
                Icons.account_balance_wallet,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(15),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext);
              },
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                final newBudget =
                    double.tryParse(controller.text.trim());

                if (newBudget == null || newBudget <= 0) {
                  return;
                }

                setState(() {
                  totalBudget = newBudget;
                });

                Navigator.pop(dialogContext);

                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text(
                      'Budget updated successfully!',
                    ),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1565C0),
                foregroundColor: Colors.white,
              ),
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final double progress = totalBudget <= 0
        ? 0
        : (totalSpent / totalBudget).clamp(0.0, 1.0);

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),

      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(
          color: Colors.black,
        ),
        title: const Text(
          'Budget Tracker',
          style: TextStyle(
            color: Colors.black,
            fontSize: 23,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            onPressed: editBudget,
            icon: const Icon(
              Icons.edit,
              color: Colors.black,
            ),
          ),
        ],
      ),

      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 10, 20, 30),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Budget overview
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
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Trip Budget',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 15,
                    ),
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
                      backgroundColor:
                          Colors.white.withValues(alpha: 0.25),
                      valueColor:
                          const AlwaysStoppedAnimation<Color>(
                        Colors.white,
                      ),
                    ),
                  ),

                  const SizedBox(height: 10),

                  Text(
                    '${(progress * 100).toStringAsFixed(0)}% of your budget used',
                    style: const TextStyle(
                      color: Colors.white70,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Statistics
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
                    color: remaining >= 0
                        ? Colors.green
                        : Colors.red,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 30),

            // Expenses header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Expenses',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                Text(
                  '${expenses.length} items',
                  style: const TextStyle(
                    color: Colors.grey,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 15),

            if (expenses.isEmpty)
              _buildEmptyExpenses()
            else
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: expenses.length,
                separatorBuilder: (context, index) =>
                    const SizedBox(height: 10),
                itemBuilder: (context, index) {
                  final expense = expenses[index];

                  return _buildExpenseCard(
                    expense,
                    index,
                  );
                },
              ),
          ],
        ),
      ),

      floatingActionButton: FloatingActionButton.extended(
        onPressed: showAddExpenseDialog,
        backgroundColor: const Color(0xFF1565C0),
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text(
          'Add Expense',
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
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
          Icon(
            icon,
            color: color,
            size: 27,
          ),

          const SizedBox(height: 12),

          Text(
            title,
            style: const TextStyle(
              color: Colors.grey,
              fontSize: 13,
            ),
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

  Widget _buildExpenseCard(
    Map<String, dynamic> expense,
    int index,
  ) {
    final Color categoryColor =
        _getCategoryColor(expense['category']);

    return Dismissible(
      key: ValueKey(
        '${expense['name']}_$index',
      ),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(
          color: Colors.red,
          borderRadius: BorderRadius.circular(18),
        ),
        child: const Icon(
          Icons.delete,
          color: Colors.white,
        ),
      ),
      onDismissed: (direction) {
        deleteExpense(index);
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 25,
              backgroundColor:
                  categoryColor.withValues(alpha: 0.12),
              child: Icon(
                expense['icon'],
                color: categoryColor,
              ),
            ),

            const SizedBox(width: 15),

            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    expense['name'],
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),

                  const SizedBox(height: 4),

                  Text(
                    expense['category'],
                    style: const TextStyle(
                      color: Colors.grey,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),

            Text(
              '₹${(expense['amount'] as double).toStringAsFixed(0)}',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ],
        ),
      ),
    );
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
          Icon(
            Icons.receipt_long,
            size: 60,
            color: Colors.grey,
          ),

          SizedBox(height: 15),

          Text(
            'No Expenses Yet',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),

          SizedBox(height: 5),

          Text(
            'Add your first expense using the button below.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.grey,
            ),
          ),
        ],
      ),
    );
  }
}