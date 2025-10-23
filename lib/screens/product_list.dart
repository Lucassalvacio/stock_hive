import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:stock_hive/screens/product_form.dart';

class ProductList extends StatelessWidget {
  final DocumentReference companyRef;
  final String role;
  const ProductList({required this.companyRef, required this.role, super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: companyRef.collection('products').snapshots(), 
      builder: (context, snapshot) {
        if(!snapshot.hasData) return const Center(widthFactor: 30, child:  CircularProgressIndicator(),);
        final docs = snapshot.data!.docs;
        return ListView(
          children: docs.map((doc) {
            final data = doc.data() as Map<String, dynamic>;
            return ListTile(
              title: Text(data['name']),
              subtitle: Text('Stock : ${data['stock']} - Rp. ${data['price']}'),
              trailing: 
              role == 'admin' ? Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(onPressed: () => companyRef.collection('products').add(data), icon: const Icon(Icons.copy)),
                  IconButton(onPressed: () => doc.reference.delete(), icon: const Icon(Icons.delete)),
                ],
              ) : null,
              onTap: () {
                if(role == 'admin') {
                  Navigator.push(context, MaterialPageRoute(builder: (_) => ProductForm(companyRef: companyRef, productDoc: doc,)));
                }
              },
            );
          }).toList(),
        );
      });
  }
}