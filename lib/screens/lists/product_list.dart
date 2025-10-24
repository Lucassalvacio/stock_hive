import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shimmer/shimmer.dart';
import 'package:stock_hive/screens/forms/product_form.dart';

class ProductList extends StatefulWidget {
  final DocumentReference companyRef;
  final String role;

  const ProductList({
    required this.companyRef,
    required this.role,
    super.key,
  });

  @override
  State<ProductList> createState() => _ProductListState();
}

class _ProductListState extends State<ProductList> {
  final TextEditingController _searchCtrl = TextEditingController();
  String _searchQuery = '';

  String formatCurrency(num value) {
    final format =
        NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);
    return format.format(value);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text('Products'),
        centerTitle: true,
        backgroundColor: Colors.deepPurple.shade400,
      ),
      body: Column(
        children: [
          // 🔍 Search Bar
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
              controller: _searchCtrl,
              decoration: InputDecoration(
                hintText: 'Search product by name...',
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
              onChanged: (val) =>
                  setState(() => _searchQuery = val.toLowerCase()),
            ),
          ),

          // StreamBuilder
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: widget.companyRef
                  .collection('products')
                  .orderBy('name')
                  .snapshots(),
              builder: (context, snapshot) {
                // ⚡ Shimmer loading state
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return ListView.builder(
                    padding: const EdgeInsets.all(12),
                    itemCount: 5,
                    itemBuilder: (_, __) => Shimmer.fromColors(
                      baseColor: Colors.grey.shade300,
                      highlightColor: Colors.grey.shade100,
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 10),
                        height: 70,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                    ),
                  );
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(
                    child: Text('No products available',
                        style: TextStyle(color: Colors.grey, fontSize: 16)),
                  );
                }

                final docs = snapshot.data!.docs;
                final products = docs
                    .map((d) =>
                        {'id': d.id, ...d.data() as Map<String, dynamic>})
                    .where((p) => p['name']
                        .toString()
                        .toLowerCase()
                        .contains(_searchQuery))
                    .toList();

                // 📊 Analytics summary
                final totalStock = products.fold<int>(
                  0,
                  (summ, p) => summ + ((p['stock'] ?? 0) as int),
                );

                // Total Stock Value (Stock × Price)
                final totalValue = products.fold<num>(
                  0,
                  (acc, p) =>
                      acc +
                      (((p['stock'] ?? 0) as num) * ((p['price'] ?? 0) as num)),
                );

                return Column(
                  children: [
                    // 📊 Summary card
                    Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 8),
                      child: Card(
                        color: Colors.deepPurple.shade50,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16)),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                              vertical: 14, horizontal: 20),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text('Total Stock',
                                      style: TextStyle(
                                          fontSize: 13, color: Colors.black54)),
                                  const SizedBox(height: 4),
                                  Text('$totalStock',
                                      style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16)),
                                ],
                              ),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  const Text('Total Price',
                                      style: TextStyle(
                                          fontSize: 13, color: Colors.black54)),
                                  const SizedBox(height: 4),
                                  Text(formatCurrency(totalValue),
                                      style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16)),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),

                    // 🧾 Product list
                    Expanded(
                      child: ListView.separated(
                        padding: const EdgeInsets.all(12),
                        itemCount: products.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 10),
                        itemBuilder: (context, index) {
                          final data = products[index];
                          final docRef = widget.companyRef
                              .collection('products')
                              .doc(data['id']);

                          return Card(
                            elevation: 2,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: InkWell(
                              borderRadius: BorderRadius.circular(16),
                              onTap: () {
                                if (widget.role.toLowerCase() != 'admin') return;
                                print(data['id']);

                                final docSnapshot = docs.firstWhere(
                                  (d) => d.id == data['id'],
                                  
                                );
                                if (docSnapshot == null) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text("This product no longer exists.")),
                                  );
                                  return;
                                }

                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => ProductForm(
                                      companyRef: widget.companyRef,
                                      productDoc: docSnapshot,
                                    ),
                                  ),
                                );
                              },



                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 16, vertical: 12),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    // Product Info
                                    Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          data['name'] ?? 'Unnamed Product',
                                          style: const TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.w600),
                                        ),
                                        const SizedBox(height: 6),
                                        Text(
                                          'Stock: ${data['stock']}  •  ${formatCurrency(data['price'])}',
                                          style: TextStyle(
                                              color: Colors.grey.shade700),
                                        ),
                                      ],
                                    ),

                                    // Admin Actions
                                    if (widget.role == 'admin')
                                      Row(
                                        children: [
                                          IconButton(
                                            tooltip: 'Duplicate Product',
                                            icon: const Icon(
                                                Icons.copy_outlined,
                                                color: Colors.deepPurple),
                                            onPressed: () async {
                                              final confirmed =
                                                  await showDialog<bool>(
                                                context: context,
                                                builder: (_) => AlertDialog(
                                                  title: const Text(
                                                      'Duplicate Product?'),
                                                  content: Text(
                                                      'Do you want to duplicate "${data['name']}"?'),
                                                  actions: [
                                                    TextButton(
                                                      onPressed: () =>
                                                          Navigator.pop(
                                                              context, false),
                                                      child:
                                                          const Text('Cancel'),
                                                    ),
                                                    ElevatedButton(
                                                      onPressed: () =>
                                                          Navigator.pop(
                                                              context, true),
                                                      child: const Text('Yes'),
                                                    ),
                                                  ],
                                                ),
                                              );
                                              if (confirmed == true) {
                                                await widget.companyRef
                                                    .collection('products')
                                                    .add(data);
                                              }
                                            },
                                          ),
                                          IconButton(
                                            tooltip: 'Delete Product',
                                            icon: const Icon(
                                                Icons.delete_outline,
                                                color: Colors.red),
                                            onPressed: () async {
                                              final confirmed =
                                                  await showDialog<bool>(
                                                context: context,
                                                builder: (_) => AlertDialog(
                                                  title: const Text(
                                                      'Delete Product?'),
                                                  content: Text(
                                                      'Are you sure you want to delete "${data['name']}"?'),
                                                  actions: [
                                                    TextButton(
                                                      onPressed: () =>
                                                          Navigator.pop(
                                                              context, false),
                                                      child:
                                                          const Text('Cancel'),
                                                    ),
                                                    ElevatedButton(
                                                      style: ElevatedButton
                                                          .styleFrom(
                                                        backgroundColor:
                                                            Colors.red,
                                                      ),
                                                      onPressed: () =>
                                                          Navigator.pop(
                                                              context, true),
                                                      child:
                                                          const Text('Delete'),
                                                    ),
                                                  ],
                                                ),
                                              );
                                              if (confirmed == true) {
                                                await docRef.delete();
                                              }
                                            },
                                          ),
                                        ],
                                      ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: widget.role == 'admin'
          ? FloatingActionButton(
              backgroundColor: Colors.deepPurple.shade300,
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ProductForm(companyRef: widget.companyRef),
                  ),
                );
              },
              child: const Icon(Icons.add, size: 28),
            )
          : null,
    );
  }
}
