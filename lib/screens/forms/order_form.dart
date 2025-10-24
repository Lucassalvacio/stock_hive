import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class OrderForm extends StatefulWidget {
  final DocumentReference companyRef;
  final DocumentSnapshot? orderDoc;
  const OrderForm({required this.companyRef, this.orderDoc, super.key});

  @override
  State<OrderForm> createState() => _OrderFormState();
}

class _OrderFormState extends State<OrderForm> {
  final _formKey = GlobalKey<FormState>();

  final Map<String, int> _selectedProducts = {};
  final Map<String, double> _productPrices = {};

  String? _selectedPlatform;
  final List<String> _platforms = [
    'Tokopedia',
    'Shopee',
    'Whatsapp Business',
    'External Vendor',
    'Others'
  ];

  final _totalPriceCtrl = TextEditingController();
  final _discountPercentageCtrl = TextEditingController();
  final _discountAmountCtrl = TextEditingController();
  final _platformFeesCtrl = TextEditingController();

  final NumberFormat _currencyFormat = NumberFormat.currency(
    locale: 'id_ID',
    symbol: 'Rp ',
    decimalDigits: 0,
  );

  @override
  void initState() {
    super.initState();
    if (widget.orderDoc != null) _loadOrderData();
  }

  Future<void> _loadOrderData() async {
    final data = widget.orderDoc!.data() as Map<String, dynamic>;
    _totalPriceCtrl.text = (data['totalPrice'] ?? '').toString();
    _discountPercentageCtrl.text =
        (data['discountPercentage'] ?? '').toString();
    _discountAmountCtrl.text = (data['addDiscountAmount'] ?? '').toString();
    _platformFeesCtrl.text = (data['platformFees'] ?? '').toString();
    _selectedPlatform = data['platform'];

    final productRefs = List<DocumentReference>.from(data['productRefs'] ?? []);
    final quantities = List<num>.from(data['quantities'] ?? []);
    _selectedProducts.clear();
    _productPrices.clear();

    for (int i = 0; i < productRefs.length && i < quantities.length; i++) {
      final ref = productRefs[i];
      final qty = quantities[i].toInt();
      final doc = await ref.get();
      if (doc.exists) {
        final productData = doc.data() as Map<String, dynamic>;
        _selectedProducts[ref.id] = qty;
        _productPrices[ref.id] =
            double.tryParse(productData['price'].toString()) ?? 0.0;
      }
    }
    _calculateTotal();
    if (mounted) setState(() {});
  }

  void _calculateTotal() {
    double total = 0;
    _selectedProducts.forEach((id, qty) {
      total += (_productPrices[id] ?? 0) * qty;
    });
    _totalPriceCtrl.text = total.toInt().toString();
  }

  Future<void> _submitOrder() async {
    if (!_formKey.currentState!.validate()) return;

    final compRef = widget.companyRef.path;
    final products = _selectedProducts.keys.toList();
    final quantities = _selectedProducts.values.toList();

    // safely parse numeric values
    final totalPrice = double.tryParse(_totalPriceCtrl.text) ?? 0;
    final discountPercentage =
        double.tryParse(_discountPercentageCtrl.text) ?? 0;
    final discountAmount = double.tryParse(_discountAmountCtrl.text) ?? 0;
    final platformFees = double.tryParse(_platformFeesCtrl.text) ?? 0;

    // compute derived values
    final afterDisc =
        totalPrice - (discountPercentage / 100 * totalPrice) - discountAmount;
    final nettPrice = afterDisc - platformFees;

    final orderData = {
      'productRefs': products
          .map((id) => FirebaseFirestore.instance.doc('$compRef/products/$id'))
          .toList(),
      'quantities': quantities,
      'totalPrice': totalPrice,
      'discountPercentage': discountPercentage,
      'addDiscountAmount': discountAmount,
      'platformFees': platformFees,
      'nettPrice': nettPrice,
      'platform': _selectedPlatform,
      'status': widget.orderDoc == null
          ? 'Waiting for Pick-Up'
          : widget.orderDoc!.get('status'), // keep existing status if editing
      'updatedAt': FieldValue.serverTimestamp(),
      if (widget.orderDoc == null) 'createdAt': FieldValue.serverTimestamp(),
    };

    if (widget.orderDoc == null) {
      // ➕ Create new order
      await FirebaseFirestore.instance
          .collection('$compRef/orders')
          .add(orderData);
    } else {
      // ✏️ Update existing order
      await widget.orderDoc!.reference.update(orderData);
    }

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(widget.orderDoc == null
            ? 'Order created successfully!'
            : 'Order updated successfully!'),
      ),
    );
    Navigator.pop(context);
  }

  Widget _sectionTitle(String text) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 8.0),
        child: Text(text,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
      );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.orderDoc == null ? 'Add New Order' : 'Edit Order'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _sectionTitle("Products"),
            StreamBuilder(
              stream: widget.companyRef.collection('products').snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(
                      child: Padding(
                    padding: EdgeInsets.all(24.0),
                    child: CircularProgressIndicator(),
                  ));
                }

                final products = snapshot.data!.docs;
                return Column(
                  children: products.map((e) {
                    final data = e.data();
                    final productId = e.id;
                    final name = data['name'];
                    final price = data['price'];
                    final isSelected = _selectedProducts.containsKey(productId);

                    return Card(
                      margin: const EdgeInsets.symmetric(vertical: 6),
                      child: ListTile(
                        title:
                            Text('$name - Rp ${_currencyFormat.format(price)}'),
                        subtitle: isSelected
                            ? Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text('Qty:'),
                                  SizedBox(
                                    width: 80,
                                    child: TextFormField(
                                      initialValue: _selectedProducts[productId]
                                              ?.toString() ??
                                          '',
                                      keyboardType: TextInputType.number,
                                      decoration: const InputDecoration(
                                        isDense: true,
                                        contentPadding:
                                            EdgeInsets.symmetric(vertical: 6),
                                      ),
                                      onChanged: (v) {
                                        final qty = int.tryParse(v) ?? 0;
                                        setState(() {
                                          _selectedProducts[productId] = qty;
                                          _productPrices[productId] =
                                              double.parse(price.toString());
                                          _calculateTotal();
                                        });
                                      },
                                    ),
                                  ),
                                ],
                              )
                            : const Text('Tap to add this product'),
                        trailing: IconButton(
                          onPressed: () {
                            setState(() {
                              if (isSelected) {
                                _selectedProducts.remove(productId);
                                _productPrices.remove(productId);
                              } else {
                                _selectedProducts[productId] = 1;
                                _productPrices[productId] =
                                    double.parse(price.toString());
                              }
                              _calculateTotal();
                            });
                          },
                          icon: Icon(
                            isSelected ? Icons.remove_circle : Icons.add_circle,
                            color: isSelected ? Colors.red : Colors.green,
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                );
              },
            ),
            const Divider(height: 32),
            _sectionTitle("Pricing Details"),
            _buildTextField("Total Order Price", _totalPriceCtrl),
            _buildTextField("Discount Percentage", _discountPercentageCtrl),
            _buildTextField("Additional Discount Amount (Delivery Fee, etc.)",
                _discountAmountCtrl),
            _buildTextField("Platform Fees (Trx Fee, Insurance Fee, etc.)",
                _platformFeesCtrl),
            const SizedBox(height: 12),
            _buildSummaryRow(
                "Price After Discounts:",
                (int.tryParse(_totalPriceCtrl.text) ?? 0) -
                    ((int.tryParse(_discountPercentageCtrl.text) ?? 0) *
                            0.01 *
                            (int.tryParse(_totalPriceCtrl.text) ?? 0))
                        .toInt() -
                    (int.tryParse(_discountAmountCtrl.text) ?? 0)),
            _buildSummaryRow(
                "Price After Platform Fees:",
                (int.tryParse(_totalPriceCtrl.text) ?? 0) -
                    ((int.tryParse(_discountPercentageCtrl.text) ?? 0) *
                            0.01 *
                            (int.tryParse(_totalPriceCtrl.text) ?? 0))
                        .toInt() -
                    (int.tryParse(_discountAmountCtrl.text) ?? 0) -
                    (int.tryParse(_platformFeesCtrl.text) ?? 0)),
            const Divider(height: 32),
            _sectionTitle("Platform"),
            DropdownButtonFormField(
              decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  labelText: 'Select Order Platform'),
              items: _platforms
                  .map((p) => DropdownMenuItem(value: p, child: Text(p)))
                  .toList(),
              onChanged: (v) => setState(() => _selectedPlatform = v),
              initialValue: _selectedPlatform,
              validator: (v) => v == null ? 'Please select a platform' : null,
            ),
            const SizedBox(height: 24),
            if (widget.orderDoc != null) ...[
              const Divider(height: 32),
              _sectionTitle("Order Status"),
              FutureBuilder<DocumentSnapshot>(
                future: widget.orderDoc!.reference.get(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

                  final data = snapshot.data!.data() as Map<String, dynamic>;
                  final currentStatus = data['status'] ?? 'Waiting for Pick-Up';

                  final statuses = [
                    'Waiting for Pick-Up',
                    'Shipping',
                    'Delivered',
                    'Completed'
                  ];

                  // Find current index and compute next
                  final currentIndex = statuses.indexOf(currentStatus);
                  final nextIndex = (currentIndex + 1 < statuses.length)
                      ? currentIndex + 1
                      : currentIndex;

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text("Current Status: ",
                          style: TextStyle(fontWeight: FontWeight.w600)),
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8.0),
                        child: Text(
                          currentStatus,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: _statusColor(currentStatus),
                          ),
                        ),
                      ),
                      ElevatedButton.icon(
                        onPressed: currentIndex < statuses.length - 1
                            ? () async {
                                final newStatus = statuses[nextIndex];
                                final confirmed = await showDialog<bool>(
                                  context: context,
                                  builder: (context) => AlertDialog(
                                    title: const Text('Confirm Status Update'),
                                    content: Text(
                                        'Are you sure you want to change status from "$currentStatus" to "$newStatus"?'),
                                    actions: [
                                      TextButton(
                                        onPressed: () =>
                                            Navigator.pop(context, false),
                                        child: const Text('Cancel'),
                                      ),
                                      ElevatedButton(
                                        onPressed: () =>
                                            Navigator.pop(context, true),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.amber[700],
                                        ),
                                        child: const Text('Yes, Proceed'),
                                      ),
                                    ],
                                  ),
                                );

                                if (confirmed == true) {
                                  await widget.orderDoc!.reference
                                      .update({'status': newStatus});
                                  if (!mounted) return;
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                        content: Text(
                                            'Status updated to "$newStatus"')),
                                  );
                                  setState(() {});
                                }
                              }
                            : null,
                        icon: const Icon(Icons.sync),
                        label: Text(currentIndex < statuses.length - 1
                            ? "Update to Next Status (${statuses[nextIndex]})"
                            : "Order Completed"),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.amber[700],
                          minimumSize: const Size.fromHeight(45),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ],
          ],
        ),
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(16),
        child: ElevatedButton.icon(
          style: ElevatedButton.styleFrom(
            minimumSize: const Size.fromHeight(50),
            backgroundColor: Colors.amber[700],
          ),
          onPressed: _submitOrder,
          icon: const Icon(Icons.save),
          label: Text(widget.orderDoc != null ? 'Update Order' : 'Add Order'),
        ),
      ),
    );
  }

  Widget _buildTextField(String label, TextEditingController controller) =>
      Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: TextFormField(
          controller: controller,
          decoration: InputDecoration(
            labelText: label,
            border: const OutlineInputBorder(),
          ),
          keyboardType: TextInputType.number,
        ),
      );

  Widget _buildSummaryRow(String label, num value) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
            Text(_currencyFormat.format(value),
                style: const TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
      );
  Color _statusColor(String status) {
    switch (status) {
      case 'Waiting for Pick-Up':
        return Colors.orange;
      case 'Shipping':
        return Colors.blue;
      case 'Delivered':
        return Colors.green;
      case 'Completed':
        return Colors.grey;
      default:
        return Colors.black;
    }
  }
}
