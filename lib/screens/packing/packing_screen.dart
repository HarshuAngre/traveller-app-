import 'package:flutter/material.dart';

import '../../core/services/packing_service.dart';

class PackingScreen extends StatefulWidget {
  const PackingScreen({super.key});

  @override
  State<PackingScreen> createState() => _PackingScreenState();
}

class _PackingScreenState extends State<PackingScreen> {
  static const String _generalTripKey = '__general_checklist__';
  static const List<String> _categories = [
    'Clothes',
    'Electronics',
    'Documents',
    'Toiletries',
    'Other',
  ];

  final PackingService _packingService = PackingService();
  final Set<String> _busyItemIds = <String>{};

  List<Map<String, dynamic>> packingItems = [];
  List<Map<String, dynamic>> trips = [];
  String selectedCategory = 'All';
  String _selectedTripKey = _generalTripKey;
  bool _isLoading = true;
  bool _isClearing = false;
  String? _loadError;

  String? get _selectedTripId =>
      _selectedTripKey == _generalTripKey ? null : _selectedTripKey;

  int get packedCount =>
      packingItems.where((item) => item['packed'] == true).length;

  int get remainingCount => packingItems.length - packedCount;

  double get progress =>
      packingItems.isEmpty ? 0 : packedCount / packingItems.length;

  List<Map<String, dynamic>> get filteredItems {
    if (selectedCategory == 'All') return packingItems;
    return packingItems
        .where((item) => item['category'] == selectedCategory)
        .toList();
  }

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    setState(() {
      _isLoading = true;
      _loadError = null;
    });

    try {
      final fetchedTrips = await _packingService.fetchTrips();
      final fetchedItems = await _packingService.fetchItems(tripId: null);
      if (!mounted) return;

      setState(() {
        trips = fetchedTrips;
        packingItems = fetchedItems.map(_mapDatabaseItem).toList();
        _isLoading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _loadError = _friendlyError(error);
        _isLoading = false;
      });
    }
  }

  Future<void> _loadItems({bool showLoader = true}) async {
    if (showLoader) {
      setState(() {
        _isLoading = true;
        _loadError = null;
      });
    }

    try {
      final fetchedItems = await _packingService.fetchItems(
        tripId: _selectedTripId,
      );
      if (!mounted) return;
      setState(() {
        packingItems = fetchedItems.map(_mapDatabaseItem).toList();
        _isLoading = false;
        _loadError = null;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _loadError = _friendlyError(error);
        _isLoading = false;
      });
    }
  }

  Map<String, dynamic> _mapDatabaseItem(Map<String, dynamic> row) {
    final category = (row['category'] as String?) ?? 'Other';
    return {
      'id': row['id'] as String,
      'name': (row['name'] as String?) ?? 'Unnamed item',
      'category': category,
      'packed': row['is_packed'] == true,
      'quantity': row['quantity'] ?? 1,
      'trip_id': row['trip_id'],
      'notes': row['notes'],
      'is_packed': row['is_packed'] == true,
      'icon': getCategoryIcon(category),
    };
  }

  String _friendlyError(Object error) {
    final message = error.toString();
    if (message.contains('SocketException') ||
        message.contains('Failed host lookup')) {
      return 'Could not reach the server. Check your internet connection.';
    }
    return message.replaceFirst('Exception: ', '');
  }

  void _showMessage(String message, {bool isError = false, SnackBarAction? action}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: isError ? Colors.red.shade700 : null,
          action: action,
        ),
      );
  }

  Future<void> _selectTrip(String? tripKey) async {
    if (tripKey == null || tripKey == _selectedTripKey) return;
    setState(() {
      _selectedTripKey = tripKey;
      selectedCategory = 'All';
    });
    await _loadItems();
  }

  Future<void> showAddItemDialog() async {
    final itemController = TextEditingController();
    String category = 'Clothes';
    bool saving = false;

    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (dialogContext, setDialogState) {
            return AlertDialog(
              title: const Text(
                'Add Packing Item',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: itemController,
                      enabled: !saving,
                      textCapitalization: TextCapitalization.words,
                      decoration: InputDecoration(
                        labelText: 'Item Name',
                        hintText: 'e.g. Sunglasses',
                        prefixIcon: const Icon(Icons.luggage),
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
                        prefixIcon: const Icon(Icons.category),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(15),
                        ),
                      ),
                      items: _categories
                          .map(
                            (value) => DropdownMenuItem(
                              value: value,
                              child: Text(value),
                            ),
                          )
                          .toList(),
                      onChanged: saving
                          ? null
                          : (value) {
                              if (value != null) {
                                setDialogState(() => category = value);
                              }
                            },
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: saving
                      ? null
                      : () => Navigator.pop(dialogContext),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: saving
                      ? null
                      : () async {
                          final itemName = itemController.text.trim();
                          if (itemName.isEmpty) {
                            _showMessage('Please enter an item name.', isError: true);
                            return;
                          }

                          setDialogState(() => saving = true);
                          try {
                            await _packingService.addItem(
                              name: itemName,
                              category: category,
                              tripId: _selectedTripId,
                            );
                            if (!mounted || !dialogContext.mounted) return;
                            Navigator.pop(dialogContext);
                            await _loadItems(showLoader: false);
                            _showMessage('Item added to packing list! 🎒');
                          } catch (error) {
                            if (!mounted || !dialogContext.mounted) return;
                            setDialogState(() => saving = false);
                            _showMessage(_friendlyError(error), isError: true);
                          }
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1565C0),
                    foregroundColor: Colors.white,
                  ),
                  child: saving
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text('Add'),
                ),
              ],
            );
          },
        );
      },
    );
    itemController.dispose();
  }

  Future<void> _showEditItemDialog(Map<String, dynamic> item) async {
    final itemController = TextEditingController(text: item['name'] as String);
    String category = item['category'] as String;
    if (!_categories.contains(category)) category = 'Other';
    bool saving = false;

    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (dialogContext, setDialogState) {
            return AlertDialog(
              title: const Text(
                'Edit Packing Item',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: itemController,
                      enabled: !saving,
                      textCapitalization: TextCapitalization.words,
                      decoration: InputDecoration(
                        labelText: 'Item Name',
                        prefixIcon: const Icon(Icons.luggage),
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
                        prefixIcon: const Icon(Icons.category),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(15),
                        ),
                      ),
                      items: _categories
                          .map(
                            (value) => DropdownMenuItem(
                              value: value,
                              child: Text(value),
                            ),
                          )
                          .toList(),
                      onChanged: saving
                          ? null
                          : (value) {
                              if (value != null) {
                                setDialogState(() => category = value);
                              }
                            },
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: saving
                      ? null
                      : () => Navigator.pop(dialogContext),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: saving
                      ? null
                      : () async {
                          final name = itemController.text.trim();
                          if (name.isEmpty) {
                            _showMessage('Please enter an item name.', isError: true);
                            return;
                          }

                          setDialogState(() => saving = true);
                          try {
                            await _packingService.updateItem(
                              itemId: item['id'] as String,
                              name: name,
                              category: category,
                            );
                            if (!mounted || !dialogContext.mounted) return;
                            Navigator.pop(dialogContext);
                            await _loadItems(showLoader: false);
                            _showMessage('Packing item updated.');
                          } catch (error) {
                            if (!mounted || !dialogContext.mounted) return;
                            setDialogState(() => saving = false);
                            _showMessage(_friendlyError(error), isError: true);
                          }
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1565C0),
                    foregroundColor: Colors.white,
                  ),
                  child: saving
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
    itemController.dispose();
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

  Future<void> toggleItem(int index) async {
    final item = filteredItems[index];
    final itemId = item['id'] as String;
    if (_busyItemIds.contains(itemId)) return;

    final newPackedState = !(item['packed'] == true);
    setState(() => _busyItemIds.add(itemId));
    try {
      await _packingService.updatePackedStatus(
        itemId: itemId,
        isPacked: newPackedState,
      );
      if (!mounted) return;
      setState(() {
        item['packed'] = newPackedState;
        item['is_packed'] = newPackedState;
        _busyItemIds.remove(itemId);
      });
    } catch (error) {
      if (!mounted) return;
      setState(() => _busyItemIds.remove(itemId));
      _showMessage(_friendlyError(error), isError: true);
    }
  }

  Future<void> deleteItem(Map<String, dynamic> item) async {
    final itemId = item['id'] as String;
    final originalIndex = packingItems.indexWhere((entry) => entry['id'] == itemId);
    if (originalIndex < 0) return;

    setState(() => packingItems.removeAt(originalIndex));
    try {
      await _packingService.deleteItem(itemId);
      if (!mounted) return;
      _showMessage(
        '${item['name']} removed from packing list.',
        action: SnackBarAction(
          label: 'UNDO',
          onPressed: () => _restoreDeletedItems([item], originalIndex),
        ),
      );
    } catch (error) {
      if (!mounted) return;
      await _loadItems(showLoader: false);
      _showMessage(_friendlyError(error), isError: true);
    }
  }

  Future<void> _restoreDeletedItems(
    List<Map<String, dynamic>> items,
    int originalIndex,
  ) async {
    try {
      final rows = items.map((item) {
        return {
          ...item,
          'is_packed': item['packed'] == true,
        };
      }).toList();
      await _packingService.restoreItems(rows);
      if (!mounted) return;
      await _loadItems(showLoader: false);
      _showMessage('Packing item restored.');
    } catch (error) {
      if (!mounted) return;
      _showMessage(_friendlyError(error), isError: true);
    }
  }

  Future<void> clearPackedItems() async {
    final packedItems = packingItems
        .where((item) => item['packed'] == true)
        .toList();

    if (packedItems.isEmpty) {
      _showMessage('There are no packed items to clear.');
      return;
    }

    final shouldClear = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Clear Packed Items?'),
          content: Text(
            'This will remove ${packedItems.length} packed '
            'item${packedItems.length == 1 ? '' : 's'} from this list.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: const Text(
                'Clear',
                style: TextStyle(color: Colors.red),
              ),
            ),
          ],
        );
      },
    );

    if (!mounted || shouldClear != true) return;
    setState(() => _isClearing = true);
    try {
      final ids = packedItems.map((item) => item['id'] as String).toList();
      await _packingService.deleteItems(ids);
      if (!mounted) return;
      setState(() {
        packingItems.removeWhere((item) => item['packed'] == true);
        _isClearing = false;
      });
      _showMessage(
        'Packed items cleared.',
        action: SnackBarAction(
          label: 'UNDO',
          onPressed: () => _restoreDeletedItems(packedItems, 0),
        ),
      );
    } catch (error) {
      if (!mounted) return;
      setState(() => _isClearing = false);
      await _loadItems(showLoader: false);
      _showMessage(_friendlyError(error), isError: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final items = filteredItems;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
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
            icon: const Icon(Icons.more_vert, color: Colors.black),
            onSelected: (value) {
              if (value == 'clear') clearPackedItems();
              if (value == 'refresh') _loadInitialData();
            },
            itemBuilder: (context) => const [
              PopupMenuItem(
                value: 'clear',
                child: Row(
                  children: [
                    Icon(Icons.clear_all, color: Colors.red),
                    SizedBox(width: 10),
                    Text('Clear Packed Items'),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'refresh',
                child: Row(
                  children: [
                    Icon(Icons.refresh),
                    SizedBox(width: 10),
                    Text('Refresh List'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _loadError != null
              ? _buildErrorState()
              : SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(20, 10, 20, 100),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildProgressCard(),
                      const SizedBox(height: 20),
                      _buildTripSelector(),
                      const SizedBox(height: 25),
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
                            ..._categories.map(_buildCategoryChip),
                          ],
                        ),
                      ),
                      const SizedBox(height: 25),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
                            style: const TextStyle(color: Colors.grey),
                          ),
                        ],
                      ),
                      const SizedBox(height: 15),
                      if (items.isEmpty)
                        _buildEmptyState()
                      else
                        ListView.separated(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: items.length,
                          separatorBuilder: (context, index) =>
                              const SizedBox(height: 10),
                          itemBuilder: (context, index) =>
                              _buildPackingItem(items[index], index),
                        ),
                    ],
                  ),
                ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _isLoading || _loadError != null ? null : showAddItemDialog,
        backgroundColor: const Color(0xFF1565C0),
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text(
          'Add Item',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  Widget _buildProgressCard() {
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
          const Row(
            children: [
              Icon(Icons.luggage, color: Colors.white, size: 35),
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
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '$packedCount of ${packingItems.length} items packed',
                style: const TextStyle(color: Colors.white70, fontSize: 14),
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
              backgroundColor: Colors.white.withValues(alpha: 0.25),
              valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
            ),
          ),
          const SizedBox(height: 15),
          Text(
            remainingCount == 0
                ? 'Everything is packed! 🎉'
                : '$remainingCount item${remainingCount == 1 ? '' : 's'} remaining',
            style: const TextStyle(color: Colors.white70),
          ),
        ],
      ),
    );
  }

  Widget _buildTripSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Packing For',
          style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 10),
        DropdownButtonFormField<String>(
          initialValue: _selectedTripKey,
          isExpanded: true,
          decoration: InputDecoration(
            prefixIcon: const Icon(Icons.luggage),
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(15),
              borderSide: BorderSide.none,
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 15,
              vertical: 12,
            ),
          ),
          items: [
            const DropdownMenuItem<String>(
              value: _generalTripKey,
              child: Text('General Checklist'),
            ),
            ...trips.map((trip) {
              final destination = (trip['destination'] as String?) ?? 'Trip';
              final title = (trip['title'] as String?) ?? destination;
              return DropdownMenuItem<String>(
                value: trip['id'] as String,
                child: Text(
                  title == destination ? destination : '$title — $destination',
                  overflow: TextOverflow.ellipsis,
                ),
              );
            }),
          ],
          onChanged: _isClearing ? null : _selectTrip,
        ),
        const SizedBox(height: 5),
        const Text(
          'Items are saved separately for each trip.',
          style: TextStyle(color: Colors.grey, fontSize: 12),
        ),
      ],
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
          setState(() => selectedCategory = category);
        },
        selectedColor: const Color(0xFF1565C0),
        backgroundColor: Colors.white,
        labelStyle: TextStyle(
          color: isSelected ? Colors.white : Colors.black87,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
        side: BorderSide.none,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
      ),
    );
  }

  Widget _buildPackingItem(Map<String, dynamic> item, int index) {
    final bool isPacked = item['packed'] == true;
    final itemId = item['id'] as String;
    final bool isBusy = _busyItemIds.contains(itemId);

    return Dismissible(
      key: ValueKey(itemId),
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
      confirmDismiss: (direction) async => !isBusy,
      onDismissed: (direction) => deleteItem(item),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
        ),
        child: Row(
          children: [
            GestureDetector(
              onTap: isBusy ? null : () => toggleItem(index),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
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
                child: isBusy
                    ? const Padding(
                        padding: EdgeInsets.all(5),
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : isPacked
                        ? const Icon(Icons.check, color: Colors.white, size: 18)
                        : null,
              ),
            ),
            const SizedBox(width: 15),
            CircleAvatar(
              radius: 23,
              backgroundColor: const Color(0xFFE3F2FD),
              child: Icon(
                item['icon'] as IconData,
                color: const Color(0xFF1565C0),
              ),
            ),
            const SizedBox(width: 13),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item['name'] as String,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      decoration: isPacked
                          ? TextDecoration.lineThrough
                          : TextDecoration.none,
                      color: isPacked ? Colors.grey : Colors.black,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    item['category'] as String,
                    style: const TextStyle(color: Colors.grey, fontSize: 12),
                  ),
                ],
              ),
            ),
            IconButton(
              tooltip: 'Edit item',
              onPressed: isBusy ? null : () => _showEditItemDialog(item),
              icon: const Icon(Icons.edit_outlined, size: 19),
              color: Colors.blueGrey,
              visualDensity: VisualDensity.compact,
            ),
            Icon(
              isPacked ? Icons.check_circle : Icons.radio_button_unchecked,
              color: isPacked ? Colors.green : Colors.grey,
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
      child: Column(
        children: [
          const Icon(Icons.luggage, size: 60, color: Colors.grey),
          const SizedBox(height: 15),
          const Text(
            'No Items Found',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 5),
          Text(
            selectedCategory == 'All'
                ? 'Add something to your packing list.'
                : 'No $selectedCategory items yet. Try another category or add an item.',
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.cloud_off, size: 55, color: Colors.grey),
            const SizedBox(height: 15),
            const Text(
              'Could not load packing list',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              _loadError ?? 'Please try again.',
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 18),
            ElevatedButton.icon(
              onPressed: _loadInitialData,
              icon: const Icon(Icons.refresh),
              label: const Text('Try Again'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1565C0),
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
