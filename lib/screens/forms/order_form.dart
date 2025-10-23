import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:stock_hive/services/company_service.dart';

class OrderForm extends StatefulWidget {
  final DocumentReference companyRef;
  final DocumentSnapshot? orderDoc;
  const OrderForm({required this.companyRef, this.orderDoc, super.key});

  @override
  State<OrderForm> createState() => _OrderFormState();
}

// {
//   "productRefs": ["/companies/{companyId}/products/{id}", "/companies/{companyId}/products/{id}"],
//   "quantities": [2, 1],
//   "totalPrice": 750000,
//   "discountPercentage": 0.1,
//   "addDiscountAmount": 20000, //Shipping Discount
//   "priceNett": 675000,
//   "platform": "Tokopedia",
//   "createdAt": Timestamp.now(),
// }


class _OrderFormState extends State<OrderForm> {
  final _formKey = GlobalKey<FormState>();

  Map<String, int> _selectedProducts = {}; // productId → quantity
  Map<String, double> _productPrices = {}; // productId → price
  double _total = 0;

  String? _selectedPlatform;
  final List<String> _platforms = ['Tokopedia', 'Shopee', 'Whatsapp Business', 'External Vendor', 'Others'];

  final _totalPriceCtrl = TextEditingController();
  final _discountPercentageCtrl = TextEditingController();
  final _discountAmountCtr = TextEditingController();
  final _platformFeesCtrl = TextEditingController();
  final companyRef = CompanyService().getCompanyRef();



  Future<void> _submitOrder() async {
    if(_formKey.currentState!.validate()){
      final products = _selectedProducts.keys.toList();
      final quantities = _selectedProducts.keys.toList();

      final afterDisc = (int.parse(_totalPriceCtrl.text) - (int.parse( _discountPercentageCtrl.text) * 0.01 * int.parse(_totalPriceCtrl.text))) - int.parse(_discountAmountCtr.text);
      final nettPrice = afterDisc - int.parse(_platformFeesCtrl.text);

      final orderData = {
        'productRefs': products.map((id) => FirebaseFirestore.instance.doc('$companyRef/products/$id')).toList(),
        'quantities' : quantities,
        'totalPrice' : _totalPriceCtrl.text,
        'discountPercentage' : _discountPercentageCtrl.text,
        'addDiscountAmount' : _discountAmountCtr.text,
        'platformFees' : _platformFeesCtrl.text,
        'nettPrice' : nettPrice,
        'platform':_selectedPlatform,
        'createdAt': FieldValue.serverTimestamp()
      };

      await FirebaseFirestore.instance.collection('$companyRef/orders').add(orderData);

    }
  }

  void _calculateTotal() {
    double total = 0;
    _selectedProducts.forEach((productId, qty) {
      final price = _productPrices[productId] ?? 0;
      total += price * qty;
    });
    setState(() {
      _total = total;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.orderDoc == null ? 'Add New Order' : 'Edit Order'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [

            StreamBuilder(
              stream: FirebaseFirestore.instance.collection('$companyRef/products').snapshots(), 
              builder: (context, snapshot){
                if(!snapshot.hasData) return const Center(widthFactor: 30, child: CircularProgressIndicator(),);

                final products = snapshot.data!.docs;
                return Column(
                  children: products.map((e) {
                    final data = e.data() as Map<String, dynamic>;
                    final productId = e.id;
                    final name = data['name'];
                    final price = data['price'].toDouble();

                    final isSelected = _selectedProducts.containsKey(productId);

                    return Card(
                      margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 10),
                      child: ListTile(
                        title:  Text('$name - Rp ${price.toString()}'),
                        subtitle: isSelected ? Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Qty: '),
                            SizedBox(
                              width: 80, 
                              child: TextFormField(
                                initialValue: _selectedProducts[productId]?.toString() ?? '',
                                keyboardType: TextInputType.number,
                                onChanged: (value) {
                                  final qty = int.tryParse(value) ?? 0;
                                  setState(() {
                                    _selectedProducts[productId] = qty;
                                    _productPrices[productId] = price;
                                    _calculateTotal();
               
                                  });
                                },
                              ),)
                          ],
                        ) : const Text('Tap to add this product'),
                      trailing: IconButton(
                        onPressed: () {
                          setState(() {
                            if(isSelected){
                              _selectedProducts.remove(productId);
                              _productPrices.remove(productId);
                            }else {
                              _selectedProducts[productId] = 1;
                              _productPrices[productId] = price;
                            }
                            _calculateTotal();
                          });
                        }, 
                        icon: Icon(
                          isSelected ? Icons.remove_circle : Icons.add_circle,
                        color: isSelected ? Colors.red : Colors.green,
                        )),
                      ),
                    );
                  },).toList(),
                );
              } 
            ),

            TextFormField(controller: _totalPriceCtrl, decoration: const InputDecoration(label: Text("Total Order Price")), onChanged: (value) {setState(() {
              _totalPriceCtrl.text = value;
            });},),
            TextFormField(controller: _discountPercentageCtrl, decoration: const InputDecoration(label: Text("Discount Percentage")), onChanged: (value) {setState(() {
              _discountPercentageCtrl.text = value;
            });},),
            TextFormField(controller: _discountAmountCtr, decoration: const InputDecoration(label: Text("Additional Discount Amount (Delivery Fee, etc.)")), onChanged: (value) {setState(() {
              _discountAmountCtr.text = value;
            });},),

            const SizedBox(height: 16,),

            Row(
              children: [
                const Text("Price After Discounts: "),
                Text(int.tryParse(_totalPriceCtrl.text) != null && int.tryParse(_discountPercentageCtrl.text) != null && int.tryParse(_discountAmountCtr.text) != null?
                (int.parse(_totalPriceCtrl.text) - (int.parse(_totalPriceCtrl.text)*int.parse(_discountPercentageCtrl.text)*0.01) - int.parse(_discountAmountCtr.text)).toString() : '-'),
              ],
            ),

            const SizedBox(height: 16,),

             TextFormField(controller: _platformFeesCtrl, decoration: const InputDecoration(label: Text("Platform Fees (Trx Fee, Insurance Fee, Etc.)")), onChanged: (value) {setState(() {
              _platformFeesCtrl.text = value;
            });},),

            const SizedBox(height: 16,),

            Row(
              children: [
                const Text("Price After Platform Fees: "),
                Text(int.tryParse(_platformFeesCtrl.text) != null && int.tryParse(_totalPriceCtrl.text) != null && int.tryParse(_discountPercentageCtrl.text) != null && int.tryParse(_discountAmountCtr.text) != null ?
                (int.parse(_totalPriceCtrl.text) - (int.parse(_totalPriceCtrl.text)*int.parse(_discountPercentageCtrl.text)*0.01) - int.parse(_discountAmountCtr.text) - int.parse(_platformFeesCtrl.text)).toString() : '-'),
              ],
            ),

            const SizedBox(height: 16,),

            DropdownButtonFormField(
              decoration: const InputDecoration(
                labelText: 'Select Order Platform',
                border: OutlineInputBorder()
              ),
              items: _platforms.map((platform) {
                return DropdownMenuItem<String>(
                  value: platform, 
                  child: Text(platform)
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _selectedPlatform = value;
                });
              },
              validator: (value) => value == null || value.isEmpty ? 'Please select a platform' : null,
            )
          ],
        ),
      ),
    );
  }
}