import 'package:flutter/material.dart';

class PackingScreen extends StatefulWidget {
  const PackingScreen({super.key});

  @override
  State<PackingScreen> createState() => _PackingScreenState();
}

class _PackingScreenState extends State<PackingScreen> {
  final List<Map<String, dynamic>> packingItems = [
    {
      'name': 'T-Shirts',
      'category': 'Clothes',
      'packed': true,
      'icon': Icons.checkroom,
    },
    {
      'name': 'Jeans',
      'category': 'Clothes',
      'packed': false,
      'icon': Icons.checkroom,
    },
    {
      'name': 'Phone Charger',
      'category': 'Electronics',
      'packed': false,
      'icon': Icons.charging_station,
    },
    {
      'name': 'Passport',
      'category': 'Documents',
      'packed': true,
      'icon': Icons.badge,
    },
    {
      'name': 'Toothbrush',
      'category': 'Toiletries',
      'packed': false,
      'icon': Icons.clean_hands,
    },
  ];

  String selectedCategory = 'All';

  int get packedCount {
    return packingItems.where((item) => item['packed'] == true).length;
  }

  int get remainingCount {
    return packingItems.where((item) => item['packed'] == false).length;
  }

  double get progress {
    if (packingItems.isEmpty) {
      return 0;
    }

    return packedCount / packingItems.length;
  }

  List<Map<String, dynamic>> get filteredItems {
    if (selectedCategory == 'All') {
      return packingItems;
    }

    return packingItems
        .where(
          (item) => item['category'] == selectedCategory,
        )
        .toList();
  }

  void showAddItemDialog() {
    final itemController = TextEditingController();
    String category = 'Clothes';

    showDialog(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text(
                'Add Packing Item',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                ),
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: itemController,
                      textCapitalization: TextCapitalization.words,
                      decoration: InputDecoration(
                        labelText: 'Item Name',
                        hintText: 'e.g. Sunglasses',
                        prefixIcon: const Icon(
                          Icons.luggage,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(15),
                        ),
                      ),
                    ),

                    const SizedBox(height: 15),

                    DropdownButtonFormField<String>(
                      initialValue: category,
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
                          value: 'Clothes',
                          child: Text('Clothes'),
                        ),
                        DropdownMenuItem(
                          value: 'Electronics',
                          child: Text('Electronics'),
                        ),
                        DropdownMenuItem(
                          value: 'Documents',
                          child: Text('Documents'),
                        ),
                        DropdownMenuItem(
                          value: 'Toiletries',
                          child: Text('Toiletries'),
                        ),
                        DropdownMenuItem(
                          value: 'Other',
                          child: Text('Other'),
                        ),
                      ],
                      onChanged: (value) {
                        if (value != null) {
                          setDialogState(() {
                            category = value;
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
                    final itemName =
                        itemController.text.trim();

                    if (itemName.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            'Please enter an item name.',
                          ),
                        ),
                      );
                      return;
                    }

                    setState(() {
                      packingItems.add({
                        'name': itemName,
                        'category': category,
                        'packed': false,
                        'icon': getCategoryIcon(category),
                      });
                    });

                    Navigator.pop(dialogContext);

                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                          'Item added to packing list! 🎒',
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

  IconData getCategoryIcon(String category) {
    switch (category) {
      case 'Clothes':
        return Icons.checkroom;

      case 'Electronics':
        return Icons.devices;

      case 'Documents':
        return Icons.description;

      case 'Toiletries':
        return Icons.clean_hands;

      default:
        return Icons.luggage;
    }
  }

  void toggleItem(int index) {
    final item = filteredItems[index];

    setState(() {
      item['packed'] = !item['packed'];
    });
  }

  void deleteItem(int index) {
    final item = filteredItems[index];

    final originalIndex = packingItems.indexOf(item);

    setState(() {
      packingItems.removeAt(originalIndex);
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          '${item['name']} removed from packing list.',
        ),
        action: SnackBarAction(
          label: 'UNDO',
          onPressed: () {
            setState(() {
              packingItems.insert(
                originalIndex,
                item,
              );
            });
          },
        ),
      ),
    );
  }

  void clearPackedItems() {
    final packedItems = packingItems
        .where((item) => item['packed'] == true)
        .toList();

    if (packedItems.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'There are no packed items to clear.',
          ),
        ),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Clear Packed Items?'),
          content: Text(
            'This will remove ${packedItems.length} packed '
            'item${packedItems.length == 1 ? '' : 's'} from your list.',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext);
              },
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                setState(() {
                  packingItems.removeWhere(
                    (item) => item['packed'] == true,
                  );
                });

                Navigator.pop(dialogContext);

                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text(
                      'Packed items cleared.',
                    ),
                  ),
                );
              },
              child: const Text(
                'Clear',
                style: TextStyle(
                  color: Colors.red,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final items = filteredItems;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),

      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(
          color: Colors.black,
        ),
        title: const Text(
          'Packing Checklist',
          style: TextStyle(
            color: Colors.black,
            fontSize: 23,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(
              Icons.more_vert,
              color: Colors.black,
            ),
            onSelected: (value) {
              if (value == 'clear') {
                clearPackedItems();
              }
            },
            itemBuilder: (context) {
              return const [
                PopupMenuItem(
                  value: 'clear',
                  child: Row(
                    children: [
                      Icon(
                        Icons.clear_all,
                        color: Colors.red,
                      ),
                      SizedBox(width: 10),
                      Text('Clear Packed Items'),
                    ],
                  ),
                ),
              ];
            },
          ),
        ],
      ),

      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 10, 20, 100),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Progress card
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
                  const Row(
                    children: [
                      Icon(
                        Icons.luggage,
                        color: Colors.white,
                        size: 35,
                      ),
                      SizedBox(width: 12),
                      Text(
                        'Ready to Pack?',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 23,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 20),

                  Row(
                    mainAxisAlignment:
                        MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '$packedCount of ${packingItems.length} items packed',
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 14,
                        ),
                      ),
                      Text(
                        '${(progress * 100).toStringAsFixed(0)}%',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 10),

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

                  const SizedBox(height: 15),

                  Text(
                    remainingCount == 0
                        ? 'Everything is packed! 🎉'
                        : '$remainingCount item${remainingCount == 1 ? '' : 's'} remaining',
                    style: const TextStyle(
                      color: Colors.white70,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 25),

            // Category filters
            const Text(
              'Categories',
              style: TextStyle(
                fontSize: 21,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 12),

            SizedBox(
              height: 42,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: [
                  _buildCategoryChip('All'),
                  _buildCategoryChip('Clothes'),
                  _buildCategoryChip('Electronics'),
                  _buildCategoryChip('Documents'),
                  _buildCategoryChip('Toiletries'),
                  _buildCategoryChip('Other'),
                ],
              ),
            ),

            const SizedBox(height: 25),

            // List heading
            Row(
              mainAxisAlignment:
                  MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Packing List',
                  style: TextStyle(
                    fontSize: 21,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  '${items.length} items',
                  style: const TextStyle(
                    color: Colors.grey,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 15),

            if (items.isEmpty)
              _buildEmptyState()
            else
              ListView.separated(
                shrinkWrap: true,
                physics:
                    const NeverScrollableScrollPhysics(),
                itemCount: items.length,
                separatorBuilder: (context, index) =>
                    const SizedBox(height: 10),
                itemBuilder: (context, index) {
                  return _buildPackingItem(
                    items[index],
                    index,
                  );
                },
              ),
          ],
        ),
      ),

      floatingActionButton: FloatingActionButton.extended(
        onPressed: showAddItemDialog,
        backgroundColor: const Color(0xFF1565C0),
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text(
          'Add Item',
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _buildCategoryChip(String category) {
    final bool isSelected = selectedCategory == category;

    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        label: Text(category),
        selected: isSelected,
        onSelected: (selected) {
          setState(() {
            selectedCategory = category;
          });
        },
        selectedColor: const Color(0xFF1565C0),
        backgroundColor: Colors.white,
        labelStyle: TextStyle(
          color: isSelected ? Colors.white : Colors.black87,
          fontWeight:
              isSelected ? FontWeight.bold : FontWeight.normal,
        ),
        side: BorderSide.none,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
      ),
    );
  }

  Widget _buildPackingItem(
    Map<String, dynamic> item,
    int index,
  ) {
    final bool isPacked = item['packed'] == true;

    return Dismissible(
      key: ValueKey(
        '${item['name']}_${item['category']}_$index',
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
        deleteItem(index);
      },
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
        ),
        child: Row(
          children: [
            GestureDetector(
              onTap: () {
                toggleItem(index);
              },
              child: AnimatedContainer(
                duration: const Duration(
                  milliseconds: 200,
                ),
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: isPacked
                      ? const Color(0xFF1565C0)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: isPacked
                        ? const Color(0xFF1565C0)
                        : Colors.grey,
                    width: 2,
                  ),
                ),
                child: isPacked
                    ? const Icon(
                        Icons.check,
                        color: Colors.white,
                        size: 18,
                      )
                    : null,
              ),
            ),

            const SizedBox(width: 15),

            CircleAvatar(
              radius: 23,
              backgroundColor:
                  const Color(0xFFE3F2FD),
              child: Icon(
                item['icon'],
                color: const Color(0xFF1565C0),
              ),
            ),

            const SizedBox(width: 13),

            Expanded(
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [
                  Text(
                    item['name'],
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      decoration: isPacked
                          ? TextDecoration.lineThrough
                          : TextDecoration.none,
                      color: isPacked
                          ? Colors.grey
                          : Colors.black,
                    ),
                  ),

                  const SizedBox(height: 4),

                  Text(
                    item['category'],
                    style: const TextStyle(
                      color: Colors.grey,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),

            Icon(
              isPacked
                  ? Icons.check_circle
                  : Icons.radio_button_unchecked,
              color: isPacked
                  ? Colors.green
                  : Colors.grey,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
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
            Icons.luggage,
            size: 60,
            color: Colors.grey,
          ),
          SizedBox(height: 15),
          Text(
            'No Items Found',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 5),
          Text(
            'Add something to your packing list.',
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