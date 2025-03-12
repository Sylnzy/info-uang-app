import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'firebase_options.dart';
import 'package:flutter/material.dart';
import 'splash_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const InfoUangApp());
}

class InfoUangApp extends StatefulWidget {
  const InfoUangApp({super.key});

  @override
  State<InfoUangApp> createState() => _InfoUangAppState();
}

class _InfoUangAppState extends State<InfoUangApp> {
  ThemeMode _themeMode = ThemeMode.light;

  void _toggleTheme(bool isDark) {
    setState(() {
      _themeMode = isDark ? ThemeMode.dark : ThemeMode.light;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Info Uang',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
        brightness: Brightness.light,
      ),
      darkTheme: ThemeData(
        brightness: Brightness.dark,
        colorScheme: const ColorScheme.dark(),
        useMaterial3: true,
      ),
      themeMode: _themeMode,
      home: MainScreen(
        onToggleTheme: _toggleTheme,
        isDarkMode: _themeMode == ThemeMode.dark,
      ),
    );
  }
}


class Transaction {
  final String? id;
  final String title;
  final double amount;
  final DateTime date;
  final String type;
  final double quantity;
  final double price;

  Transaction({
    this.id,
    required this.title,
    required this.amount,
    required this.date,
    required this.type,
    required this.quantity,
    required this.price,
  });

  factory Transaction.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return Transaction(
      id: doc.id,
      title: data['title'],
      amount: (data['amount'] as num).toDouble(),
      date: (data['date'] as Timestamp).toDate(),
      type: data['type'],
      quantity: (data['quantity'] as num).toDouble(),
      price: (data['price'] as num).toDouble(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'title': title,
      'amount': amount,
      'date': Timestamp.fromDate(date),
      'type': type,
      'quantity': quantity,
      'price': price,
    };
  }
}
/// pergi ke [main_screen.dart]
class MainScreen extends StatefulWidget {
  final Function(bool) onToggleTheme;
  final bool isDarkMode;

  const MainScreen({
    super.key,
    required this.onToggleTheme,
    required this.isDarkMode,
  });

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;
  List<Transaction> _transactions = [];
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  void initState() {
    super.initState();
    _loadTransactions();
  }

  void _loadTransactions() {
    _firestore
        .collection('transactions')
        .orderBy('date', descending: true)
        .snapshots()
        .listen((snapshot) {
      setState(() {
        _transactions =
            snapshot.docs.map((doc) => Transaction.fromFirestore(doc)).toList();
      });
    });
  }

  Future<void> _addTransaction(String title, double amount, DateTime date,
      String type, double quantity, double price) async {
    final newTransaction = Transaction(
      title: title,
      amount: amount,
      date: date,
      type: type,
      quantity: quantity,
      price: price,
    );

    try {
      await _firestore
          .collection('transactions')
          .add(newTransaction.toFirestore());
    } catch (e) {
      // Handle any errors that might occur during adding a transaction
      print('Error adding transaction: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to add transaction: $e')),
      );
    }
  }

  Future<void> _deleteTransaction(String transactionId) async {
    try {
      await _firestore.collection('transactions').doc(transactionId).delete();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to delete transaction: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    Widget currentScreen;

    switch (_selectedIndex) {
      case 0:
        currentScreen = TransactionList(_transactions,
            onDeleteTransaction: _deleteTransaction);
        break;
      case 1:
        currentScreen = AddTransactionScreen(_addTransaction);
        break;
      case 2:
        currentScreen = ExpenseSummaryScreen(_transactions);
        break;
      default:
        currentScreen = TransactionList(_transactions);
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Info Uang'),
        actions: [
          Row(
            children: [
              Text(widget.isDarkMode ? 'Dark' : 'Light'),
              Switch(
                value: widget.isDarkMode,
                onChanged: (value) {
                  widget.onToggleTheme(value);
                },
              ),
            ],
          ),
        ],
      ),
      body: currentScreen,
      bottomNavigationBar: BottomNavigationBar(
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.list),
            label: 'Transactions',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.add),
            label: 'Add Transaction',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.calendar_today_outlined),
            label: 'Total Pengeluaran',
          ),
        ],
        currentIndex: _selectedIndex,
        onTap: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
      ),
    );
  }
}

class TransactionList extends StatelessWidget {
  final List<Transaction> transactions;
  final Function(String)?
      onDeleteTransaction; // Tambahkan parameter callback delete

  const TransactionList(this.transactions,
      {super.key, this.onDeleteTransaction});

  double get todaysTotalExpenses {
    final now = DateTime.now();
    return transactions
        .where((tx) =>
            tx.date.day == now.day &&
            tx.date.month == now.month &&
            tx.date.year == now.year)
        .fold(0, (sum, tx) => sum + tx.amount);
  }

  @override
  Widget build(BuildContext context) {
    if (transactions.isEmpty) {
      return const Center(
        child: Text('No transactions added yet!'),
      );
    }

    // Kelompokkan transaksi berdasarkan tanggal
    final Map<DateTime, List<Transaction>> groupedTransactions = {};
    for (var transaction in transactions) {
      final date = DateTime(
          transaction.date.year, transaction.date.month, transaction.date.day);
      if (!groupedTransactions.containsKey(date)) {
        groupedTransactions[date] = [];
      }
      groupedTransactions[date]!.add(transaction);
    }

    // Urutkan tanggal dari yang terbaru
    final sortedDates = groupedTransactions.keys.toList()
      ..sort((a, b) => b.compareTo(a));

    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          margin: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Theme.of(context).primaryColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                "Today's Expenses:",
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                'Rp ${todaysTotalExpenses.toStringAsFixed(0)}',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView.builder(
            itemCount: sortedDates.length,
            itemBuilder: (ctx, dateIndex) {
              final date = sortedDates[dateIndex];
              final dailyTransactions = groupedTransactions[date]!;

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: Text(
                      _formatDate(date),
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey,
                      ),
                    ),
                  ),
                  ...dailyTransactions
                      .map((transaction) => Dismissible(
                            key: Key(transaction.id ?? UniqueKey().toString()),
                            background: Container(
                              color: Colors.red,
                              alignment: Alignment.centerRight,
                              padding: const EdgeInsets.only(right: 20),
                              child: const Icon(
                                Icons.delete,
                                color: Colors.white,
                              ),
                            ),
                            direction: DismissDirection.endToStart,
                            confirmDismiss: (direction) async {
                              return await showDialog(
                                context: context,
                                builder: (ctx) => AlertDialog(
                                  title: const Text('Delete Transaction'),
                                  content: const Text(
                                      'Are you sure you want to delete this transaction?'),
                                  actions: [
                                    TextButton(
                                      child: const Text('No'),
                                      onPressed: () =>
                                          Navigator.of(ctx).pop(false),
                                    ),
                                    TextButton(
                                      child: const Text('Yes'),
                                      onPressed: () =>
                                          Navigator.of(ctx).pop(true),
                                    ),
                                  ],
                                ),
                              );
                            },
                            onDismissed: (direction) {
                              if (onDeleteTransaction != null &&
                                  transaction.id != null) {
                                onDeleteTransaction!(transaction.id!);
                              }
                            },
                            child: Card(
                              margin: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 4), //
                              child: ListTile(
                                leading: _getIcon(transaction.type),
                                title: Text(transaction.title),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Price: Rp ${transaction.price.toStringAsFixed(0)} × ${transaction.quantity.toStringAsFixed(0)}',
                                      style: TextStyle(
                                        color: Colors.grey[600],
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                                trailing: Text(
                                  'Rp ${transaction.amount.toStringAsFixed(0)}',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                          ))
                      .toList(),
                ],
              );
            },
          ),
        ),
      ],
    );
  }

  // Fungsi untuk memformat tanggal
  String _formatDate(DateTime date) {
    final now = DateTime.now();
    if (date.year == now.year &&
        date.month == now.month &&
        date.day == now.day) {
      return 'Today';
    } else if (date.year == now.year &&
        date.month == now.month &&
        date.day == now.day - 1) {
      return 'Yesterday';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }

// ... (icon method remains the same)

  Icon _getIcon(String type) {
    switch (type) {
      case 'Food & Beverage':
        return const Icon(Icons.fastfood);
      case 'Transportation':
        return const Icon(Icons.commute);
      case 'Bills':
        return const Icon(Icons.receipt);
      case 'Entertainment':
        return const Icon(Icons.movie);
      case 'Health':
        return const Icon(Icons.health_and_safety);
      case 'Education':
        return const Icon(Icons.school);
      default:
        return const Icon(Icons.category);
    }
  }
}

class AddTransactionScreen extends StatefulWidget {
  final Function(String, double, DateTime, String, double, double) addTransaction;

  const AddTransactionScreen(this.addTransaction, {super.key});

  @override
  State<AddTransactionScreen> createState() => _AddTransactionScreenState();
}

class _AddTransactionScreenState extends State<AddTransactionScreen> {
  final _titleController = TextEditingController();
  final _priceController = TextEditingController();
  final _quantityController = TextEditingController();
  DateTime? _selectedDate;
  String _selectedType = 'Food & Beverage';
  double _totalAmount = 0;

  @override
  void dispose() {
    _titleController.dispose();
    _priceController.dispose();
    _quantityController.dispose();
    super.dispose();
  }

  void _calculateTotal() {
    final price = double.tryParse(_priceController.text) ?? 0;
    final quantity = double.tryParse(_quantityController.text) ?? 0;
    setState(() {
      _totalAmount = price * quantity;
    });
  }

  void _submitData() {
    final enteredTitle = _titleController.text;
    final enteredPrice = double.tryParse(_priceController.text) ?? 0;
    final enteredQuantity = double.tryParse(_quantityController.text) ?? 0;

    if (enteredTitle.isEmpty ||
        enteredPrice <= 0 ||
        enteredQuantity <= 0 ||
        _selectedDate == null) {
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Invalid Input'),
          content: const Text(
              'Please enter valid title, price, quantity, and date.'),
          actions: [
            TextButton(
              child: const Text('Okay'),
              onPressed: () => Navigator.of(ctx).pop(),
            ),
          ],
        ),
      );
      return;
    }

    widget.addTransaction(
      enteredTitle,
      _totalAmount,
      _selectedDate!,
      _selectedType,
      enteredQuantity,
      enteredPrice,
    );

    // Clear controllers and reset state
    _titleController.clear();
    _priceController.clear();
    _quantityController.clear();
    setState(() {
      _selectedDate = null;
      _selectedType = 'Food & Beverage';
      _totalAmount = 0;
    });
  }

  void _presentDatePicker() {
    showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2023),
      lastDate: DateTime.now(),
    ).then((pickedDate) {
      if (pickedDate == null) {
        return;
      }
      setState(() {
        _selectedDate = pickedDate;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextField(
                decoration: const InputDecoration(
                  labelText: 'Title',
                  border: OutlineInputBorder(),
                ),
                controller: _titleController,
              ),
              const SizedBox(height: 16),
              TextField(
                decoration: const InputDecoration(
                  labelText: 'Price per Item',
                  border: OutlineInputBorder(),
                  prefixText: 'Rp ',
                ),
                controller: _priceController,
                keyboardType: TextInputType.number,
                onChanged: (_) => _calculateTotal(),
              ),
              const SizedBox(height: 16),
              TextField(
                decoration: const InputDecoration(
                  labelText: 'Quantity',
                  border: OutlineInputBorder(),
                ),
                controller: _quantityController,
                keyboardType: TextInputType.number,
                onChanged: (_) => _calculateTotal(),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Total: ',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    Text(
                      'Rp ${_totalAmount.toStringAsFixed(0)}',
                      style: const TextStyle(
                          fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                decoration: const InputDecoration(
                  labelText: 'Type',
                  border: OutlineInputBorder(),
                ),
                value: _selectedType,
                onChanged: (newValue) {
                  setState(() {
                    _selectedType = newValue!;
                  });
                },
                items: const [
                  DropdownMenuItem(
                      value: 'Food & Beverage', child: Text('Food & Beverage')),
                  DropdownMenuItem(
                      value: 'Transportation', child: Text('Transportation')),
                  DropdownMenuItem(value: 'Bills', child: Text('Bills')),
                  DropdownMenuItem(
                      value: 'Entertainment', child: Text('Entertainment')),
                  DropdownMenuItem(value: 'Health', child: Text('Health')),
                  DropdownMenuItem(value: 'Education', child: Text('Education')),
                ],
              ),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      _selectedDate == null
                          ? 'No Date Chosen!'
                          : 'Picked Date: ${_selectedDate!.day}/${_selectedDate!.month}/${_selectedDate!.year}',
                    ),
                  ),
                  TextButton(
                    onPressed: _presentDatePicker,
                    child: const Text('Choose Date'),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _submitData,
                child: const Text('Add Transaction'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ... (Semua kode sebelum ExpenseSummaryScreen tetap sama) ...

class ExpenseSummaryScreen extends StatefulWidget {
  final List<Transaction> transactions;

  const ExpenseSummaryScreen(this.transactions, {super.key});

  @override
  State<ExpenseSummaryScreen> createState() => _ExpenseSummaryScreenState();
}

class _ExpenseSummaryScreenState extends State<ExpenseSummaryScreen> {
  int selectedYear = DateTime.now().year;
  int selectedMonth = DateTime.now().month;

  // Fungsi menghitung total dari daftar transaksi yang difilter
  double _calculateTotal(List<Transaction> filteredTransactions) {
    return filteredTransactions.fold(
        0, (sum, transaction) => sum + transaction.amount);
  }

  // Fungsi untuk memfilter transaksi berdasarkan periode yang dipilih
  List<Transaction> _filterTransactionsByPeriod(String period) {
    final now = DateTime.now();
    final startOfYear = DateTime(selectedYear);
    final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
    final startOfMonth = DateTime(selectedYear, selectedMonth);
    final endOfMonth = DateTime(selectedYear, selectedMonth + 1, 0);

    switch (period) {
      case 'This Week':
        return widget.transactions
            .where((tx) =>
                tx.date
                    .isAfter(startOfWeek.subtract(const Duration(days: 1))) &&
                tx.date.isBefore(now.add(const Duration(days: 1))))
            .toList();
      case 'Selected Month':
        return widget.transactions
            .where((tx) =>
                tx.date
                    .isAfter(startOfMonth.subtract(const Duration(days: 1))) &&
                tx.date.isBefore(endOfMonth.add(const Duration(days: 1))))
            .toList();
      case 'Selected Year':
        return widget.transactions
            .where((tx) => tx.date.year == selectedYear)
            .toList();
      default:
        return widget.transactions;
    }
  }

  // Fungsi untuk mendapatkan breakdown per kategori berdasarkan jenis transaksi
  Map<String, double> _getTypeBreakdown(List<Transaction> transactions) {
    final typeBreakdown = <String, double>{};
    for (var tx in transactions) {
      typeBreakdown[tx.type] = (typeBreakdown[tx.type] ?? 0) + tx.amount;
    }
    return typeBreakdown;
  }

  @override
  Widget build(BuildContext context) {
    if (widget.transactions.isEmpty) {
      return const Center(
        child: Text('No transactions added yet!'),
      );
    }

    final thisWeekTotal =
        _calculateTotal(_filterTransactionsByPeriod('This Week'));
    final selectedMonthTotal =
        _calculateTotal(_filterTransactionsByPeriod('Selected Month'));
    final selectedYearTotal =
        _calculateTotal(_filterTransactionsByPeriod('Selected Year'));

    final selectedMonthTransactions =
        _filterTransactionsByPeriod('Selected Month');
    final typeBreakdown = _getTypeBreakdown(selectedMonthTransactions);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Card untuk memilih tahun dan bulan
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Period Selection',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: DropdownButtonFormField<int>(
                          decoration: const InputDecoration(
                            labelText: 'Year',
                            border: OutlineInputBorder(),
                          ),
                          value: selectedYear,
                          items: List.generate(
                            5,
                            (index) => DropdownMenuItem(
                              value: DateTime.now().year - index,
                              child: Text('${DateTime.now().year - index}'),
                            ),
                          ),
                          onChanged: (value) {
                            if (value != null) {
                              setState(() {
                                selectedYear = value;
                              });
                            }
                          },
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: DropdownButtonFormField<int>(
                          decoration: const InputDecoration(
                            labelText: 'Month',
                            border: OutlineInputBorder(),
                          ),
                          value: selectedMonth,
                          items: List.generate(
                            12,
                            (index) => DropdownMenuItem(
                              value: index + 1,
                              child: Text(_getMonthName(index + 1)),
                            ),
                          ),
                          onChanged: (value) {
                            if (value != null) {
                              setState(() {
                                selectedMonth = value;
                              });
                            }
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  // Tombol "Kembali ke Sekarang"
                  ElevatedButton(
                    onPressed: () {
                      setState(() {
                        selectedYear = DateTime.now().year;
                        selectedMonth = DateTime.now().month;
                      });
                    },
                    child: const Text("Kembali ke Sekarang"),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          // Card untuk ringkasan pengeluaran
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Expense Summary',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _SummaryItem(
                    title: 'This Week',
                    amount: thisWeekTotal,
                    icon: Icons.calendar_view_week,
                  ),
                  const Divider(),
                  _SummaryItem(
                    title: '${_getMonthName(selectedMonth)} $selectedYear',
                    amount: selectedMonthTotal,
                    icon: Icons.calendar_view_month,
                  ),
                  const Divider(),
                  _SummaryItem(
                    title: 'Year $selectedYear',
                    amount: selectedYearTotal,
                    icon: Icons.calendar_today,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          // Card untuk breakdown kategori
          if (typeBreakdown.isNotEmpty)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Category Breakdown - ${_getMonthName(selectedMonth)} $selectedYear',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    ...typeBreakdown.entries
                        .map((entry) => Column(
                              children: [
                                _SummaryItem(
                                  title: entry.key,
                                  amount: entry.value,
                                  icon: _getIcon(entry.key),
                                ),
                                if (entry.key != typeBreakdown.keys.last)
                                  const Divider(),
                              ],
                            ))
                        .toList(),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  // Fungsi untuk mendapatkan nama bulan berdasarkan nomor bulan
  String _getMonthName(int month) {
    const monthNames = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December'
    ];
    return monthNames[month - 1];
  }

  // Fungsi untuk mendapatkan ikon yang sesuai berdasarkan tipe transaksi
  IconData _getIcon(String type) {
    switch (type) {
      case 'Food & Beverage':
        return Icons.fastfood;
      case 'Transportation':
        return Icons.commute;
      case 'Bills':
        return Icons.receipt;
      case 'Entertainment':
        return Icons.movie; // Ikon untuk Entertainment
      case 'Health':
        return Icons.health_and_safety; // Ikon untuk Health
      case 'Education':
        return Icons.school; // Ikon untuk Education
      default:
        return Icons.category;
    }
  }
}

class _SummaryItem extends StatelessWidget {
  final String title;
  final double amount;
  final IconData icon;

  const _SummaryItem({
    required this.title,
    required this.amount,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              title,
              style: const TextStyle(fontSize: 16),
            ),
          ),
          Text(
            'Rp ${amount.toStringAsFixed(0)}',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
