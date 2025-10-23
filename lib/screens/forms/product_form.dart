import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class ProductForm extends StatefulWidget {
  final DocumentReference companyRef;
  final DocumentSnapshot? productDoc;
  const ProductForm({required this.companyRef, this.productDoc, super.key});
  @override
  State<ProductForm> createState() => _ProductFormState();
}

class _ProductFormState extends State<ProductForm> {
  final _formkey = GlobalKey<FormState>();
  final nameCtrl = TextEditingController();
  final stockCtrl = TextEditingController();
  final priceCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    if(widget.productDoc != null){
      final data = widget.productDoc!.data() as Map<String, dynamic>;
      nameCtrl.text = data['name'];
      stockCtrl.text = data['stock'].toString();
      priceCtrl.text = data['price'].toString();
    }
  }

  Future<void> _save() async {
    if(_formkey.currentState!.validate()) {
      final data = {
        'name' : nameCtrl.text.trim(),
        'price' : priceCtrl.text.trim(),
        'stock' : stockCtrl.text.trim(),
        'createdAt' : FieldValue.serverTimestamp(),
      };
      final col = widget.companyRef.collection('products');
      if(widget.productDoc == null){
        await col.add(data);
      }else{
        await widget.productDoc!.reference.update(data);
      }
      if(!mounted) return;
      Navigator.pop(context);
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.productDoc == null ? 'Add New Product' : 'Edit Product')),
      body: Form(
        key: _formkey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            TextFormField(controller: nameCtrl, decoration: const InputDecoration(label: Text('Product Name')), validator: (value) {
              if(value == null || value.isEmpty) return 'Please fill this field';
              return null;
            }),
            TextFormField(controller: stockCtrl, decoration: const InputDecoration(label: Text('Product Stock')), validator: (value) {
              if(value == null || value.isEmpty) return 'Please fill this field';
              if(int.tryParse(value) == null) return 'Stock must be numerical';
              return null;
            },),
            TextFormField(controller: priceCtrl, decoration: const InputDecoration(label: Text('Product Price')), validator: (value) {
              if(value == null || value.isEmpty) return 'Please fill this field';
              if(int.tryParse(value) == null) return 'Stock must be numerical';
              return null;
            }),
            const SizedBox(height: 48,),
            ElevatedButton(onPressed: _save, child: const Text('Save'))
          ],
        )
      ),
    );
  }
}