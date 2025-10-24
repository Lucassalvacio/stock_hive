import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:stock_hive/screens/forms/order_form.dart';
import 'package:intl/intl.dart';

class OrderList extends StatefulWidget {
  final DocumentReference companyRef;
  final String role;
  const OrderList({required this.companyRef, required this.role, super.key});

 
  
  @override
  State<OrderList> createState() => _OrderListState();
}

class _OrderListState extends State<OrderList> with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  // --- Filter/Sort ---
  String? _selectedStatus = 'All';
  String _sortBy = 'createdAt';
  bool _descending = true;

  final List<String> _statuses = [
    'All',
    'Waiting for Pick-Up',
    'Shipping',
    'Delivered',
    'Completed',
  ];

  QuerySnapshot<Map<String, dynamic>>? _lastSnapshot;
  Stream<QuerySnapshot<Map<String, dynamic>>>? _orderStream;

  final NumberFormat _currencyFormat = NumberFormat.currency(
    locale: 'id_ID',
    symbol: 'Rp ',
    decimalDigits: 0,
  );


  @override
  void initState() {
    super.initState();
    _orderStream = _buildQuery().snapshots();
  }

  Query<Map<String, dynamic>> _buildQuery() {
    Query<Map<String, dynamic>> query =
        widget.companyRef.collection('orders');
    if (_selectedStatus != null && _selectedStatus != 'All') {
      query = query.where('status', isEqualTo: _selectedStatus);
    }
    query = query.orderBy(_sortBy, descending: _descending);
    return query;
  }

  void _updateStream() {
    setState(() {
      _orderStream = _buildQuery().snapshots();
    });
  }

  Future<List<Map<String, dynamic>>> getProducts(
      List<DocumentReference> refs) async {
    final snapshots = await Future.wait(refs.map((ref) => ref.get()));
    return snapshots
        .where((s) => s.exists)
        .map((s) => s.data()! as Map<String, dynamic>)
        .toList();
  }

  Future<void> _refresh() async {
    // Manual pull-to-refresh
    setState(() {
      _orderStream = _buildQuery().snapshots();
    });
    await Future.delayed(const Duration(milliseconds: 300));
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    return Column(
      children: [
        // ---------- FILTERS ----------
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              DropdownButton<String>(
                value: _selectedStatus,
                items: _statuses
                    .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                    .toList(),
                onChanged: (v) {
                  _selectedStatus = v;
                  _updateStream(); // ✅ rebuild query only when filter changes
                },
              ),
              DropdownButton<String>(
                value: _sortBy,
                items: const [
                  DropdownMenuItem(
                      value: 'createdAt', child: Text('Created Date')),
                  DropdownMenuItem(value: 'nettPrice', child: Text('Total')),
                  DropdownMenuItem(value: 'platform', child: Text('Platform')),
                ],
                onChanged: (v) {
                  _sortBy = v!;
                  _updateStream();
                },
              ),
              IconButton(
                onPressed: () {
                  _descending = !_descending;
                  _updateStream();
                },
                icon: Icon(
                  _descending ? Icons.arrow_downward : Icons.arrow_upward,
                  color: Colors.blueAccent,
                ),
              ),
            ],
          ),
        ),

        // ---------- ORDER LIST ----------
        Expanded(
          child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
            stream: _orderStream,
            builder: (context, orderSnapshot) {
              if (orderSnapshot.connectionState == ConnectionState.waiting &&
                  _lastSnapshot != null) {
                // Keep showing old data during transition
                return _buildOrderList(_lastSnapshot!);
              }

              if (!orderSnapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }

              _lastSnapshot = orderSnapshot.data!;
              return RefreshIndicator(
                onRefresh: _refresh,
                child: _buildOrderList(orderSnapshot.data!),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildOrderList(QuerySnapshot<Map<String, dynamic>> snapshot) {
  final orders = snapshot.docs;
  if (orders.isEmpty) {
    return const Center(child: Text('No orders found.'));
  }

  return ListView.builder(
    physics: const AlwaysScrollableScrollPhysics(),
    itemCount: orders.length,
    itemBuilder: (context, index) {
      final order = orders[index];
      final data = order.data();
      final refs = List<DocumentReference>.from(data['productRefs'] ?? []);

      return FutureBuilder<List<Map<String, dynamic>>>(
        future: getProducts(refs),
        builder: (context, productSnapshot) {
          final products = productSnapshot.data ?? [];

          // define your status progression order
          final List<String> statusFlow = [
            'Waiting for Pick-Up',
            'Shipping',
            'Delivered',
            'Completed'
          ];

          final String currentStatus = data['status'] ?? 'Waiting for Pick-Up';
          final int currentIndex = statusFlow.indexOf(currentStatus);
          final bool canAdvance = currentIndex != -1 && currentIndex < statusFlow.length - 1;
          final String? nextStatus =
              canAdvance ? statusFlow[currentIndex + 1] : null;

          return Card(
            margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            child: ListTile(
              title: Text(
                '${data['status']} - ${order.id}',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ...products.map(
                    (p) => Text('${p['name']} - Rp ${_currencyFormat.format(p['price'])}'),
                  ),
                  const SizedBox(height: 4),
                  Text('Platform: ${data['platform'] ?? '-'}',
                      style: const TextStyle(fontSize: 12)),
                  Text('Total: Rp ${_currencyFormat.format(data['nettPrice'])}',
                      style: const TextStyle(
                          fontSize: 12, fontWeight: FontWeight.w500)),
                  const SizedBox(height: 8),

                  // ✅ Add a "Next Status" button
                  if (canAdvance)
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blueAccent,
                        minimumSize: const Size(0, 36),
                      ),
                      icon: const Icon(Icons.arrow_forward, size: 18),
                      label: Text('Next: $nextStatus'),
                      onPressed: () async {
                        await order.reference.update({'status': nextStatus});
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                  'Order status updated to "$nextStatus".'),
                              duration: const Duration(seconds: 2),
                            ),
                          );
                        }
                      },
                    )
                  else
                    const Text(
                      'Status: Completed',
                      style: TextStyle(
                        fontStyle: FontStyle.italic,
                        color: Colors.grey,
                      ),
                    ),
                ],
              ),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => OrderForm(
                      companyRef: widget.companyRef,
                      orderDoc: order,
                    ),
                  ),
                );
              },
            ),
          );
        },
      );
    },
  );
}

}