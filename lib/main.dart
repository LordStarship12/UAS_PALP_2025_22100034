import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  await initializeDateFormatting('id_ID', null);

  runApp(NyuciHelmApp());
}

class NyuciHelmApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Nyuci Helm Express',
      theme: ThemeData(
        primarySwatch: Colors.orange,
      ),
      home: HelmListPage(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class HelmListPage extends StatefulWidget {
  const HelmListPage({super.key});

  @override
  State<HelmListPage> createState() => _HelmListPageState();
}

class _HelmListPageState extends State<HelmListPage> {
  List<DocumentSnapshot> _allItems = [];
  bool _loading = true;
  final NumberFormat rupiahFormat =
      NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);

  @override
  void initState() {
    super.initState();
    _loadItemsForStore();
  }

  Future<void> _loadItemsForStore() async {
    final itemsSnapshot =
        await FirebaseFirestore.instance.collection('items').get();

    setState(() {
      _allItems = itemsSnapshot.docs;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    //   return Scaffold(
    //     appBar: AppBar(title: Text('Layanan Cuci Helm')),
    //     body: ListView.builder(
    //       itemCount: helmShops.length,
    //       itemBuilder: (context, index) {
    //         final shop = helmShops[index];
    //         return Card(
    //           margin: EdgeInsets.all(10),
    //           child: ListTile(
    //             title: Text(shop['nama']),
    //             subtitle:
    //                 Text('Jenis: ${shop['keterangan']} \nRp ${shop['harga']}'),
    //             trailing: ElevatedButton(
    //               onPressed: () {
    //                 showDialog(
    //                   context: context,
    //                   builder: (ctx) => PemesananForm(shopName: shop['nama']),
    //                 );
    //               },
    //               child: Text('Pesan'),
    //             ),
    //           ),
    //         );
    //       },
    //     ),
    //   );
    // }
    return Scaffold(
        appBar: AppBar(title: const Text('Layanan Cuci Helm')),
        body: _loading
            ? const Center(child: CircularProgressIndicator())
            : ListView.builder(
                itemCount: _allItems.length,
                itemBuilder: (context, index) {
                  final doc = _allItems[index];
                  final data = doc.data()! as Map<String, dynamic>;
                  return Card(
                      margin: const EdgeInsets.all(10),
                      child: ListTile(
                          title: Text((data['name']) ?? '-'),
                          subtitle: Text(
                              'Jenis: ${data['description'] ?? '-'} \n${rupiahFormat.format(data['price'])}'),
                          trailing: ElevatedButton(
                            onPressed: () {
                              showDialog(
                                  context: context,
                                  builder: (context) => OrderForm(
                                        orderRef: doc.reference,
                                        orderData: data,
                                      ));
                            },
                            child: const Text('Pesan'),
                          )));
                }));
  }
}

class OrderForm extends StatefulWidget {
  final DocumentReference orderRef;
  final Map<String, dynamic> orderData;

  const OrderForm({super.key, required this.orderRef, required this.orderData});

  @override
  _OrderFormState createState() => _OrderFormState();
}

class _OrderFormState extends State<OrderForm> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _itemAmountController = TextEditingController();
  final TextEditingController _postDateController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  DateTime? _selectedPostDate;

  DocumentReference? _selectedPayment;

  List<DocumentSnapshot> _payments = [];
  final dateFormatter = DateFormat('dd MMM yyyy', 'id_ID');
  final currencyFormatter =
      NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);

  @override
  void initState() {
    super.initState();
    _fetchDropdownData();
  }

  Future<void> _fetchDropdownData() async {
    final payments =
        await FirebaseFirestore.instance.collection('payments').get();

    setState(() {
      _payments = payments.docs;
    });
  }

  Future<void> _saveOrder() async {
    if (!_formKey.currentState!.validate() || _selectedPayment == null) return;

    final orderData = {
      'amount': _itemAmountController.text.trim(),
      'date': _selectedPostDate?.toIso8601String() ??
          DateTime.now().toIso8601String(),
      'item_ref': widget.orderRef,
      'name': _nameController.text.trim(),
      'payment_ref': _selectedPayment,
      'phone': _phoneController.text.trim(),
    };

    await FirebaseFirestore.instance.collection('orders').add(orderData);

    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Pesan - ${widget.orderData['name']}'),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _itemAmountController,
                decoration: const InputDecoration(labelText: 'Jumlah Helm'),
                validator: (value) =>
                    value == null || value.isEmpty ? 'Wajib diisi' : null,
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: DateTime.now().add(const Duration(days: 1)),
                    firstDate: DateTime.now(),
                    lastDate: DateTime.now().add(const Duration(days: 30)),
                  );
                  if (picked != null) {
                    setState(() {
                      _selectedPostDate = picked;
                      _postDateController.text = dateFormatter.format(picked);
                    });
                  }
                },
                child: Text(
                  _selectedPostDate == null
                      ? 'Pilih Tanggal Ambil'
                      : 'Ambil: ${DateFormat('yyyy-MM-dd').format(_selectedPostDate!)}',
                ),
              ),
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Nama'),
                validator: (value) =>
                    value == null || value.isEmpty ? 'Wajib diisi' : null,
              ),
              TextFormField(
                controller: _phoneController,
                decoration: const InputDecoration(labelText: 'No Hp'),
                validator: (value) =>
                    value == null || value.isEmpty ? 'Wajib diisi' : null,
              ),
              DropdownButtonFormField<DocumentReference>(
                value: _selectedPayment,
                items: _payments
                    .map((doc) => DropdownMenuItem(
                          value: doc.reference,
                          child: Text(doc['name']),
                        ))
                    .toList(),
                onChanged: (val) => setState(() => _selectedPayment = val!),
                decoration: const InputDecoration(labelText: 'Tipe Pembayaran'),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal')),
        ElevatedButton(onPressed: _saveOrder, child: const Text('Kirim')),
      ],
    );
  }
}
