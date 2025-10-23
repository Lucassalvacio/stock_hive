import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:stock_hive/screens/forms/vendor_form.dart';

class VendorList extends StatelessWidget {
  final DocumentReference companyRef;
  final String role;
  const VendorList({required this.companyRef, required this.role, super.key});

  

  @override
  Widget build(BuildContext context) {
    return StreamBuilder(
      stream: companyRef.collection('vendors').snapshots(), 
      builder: (context, snapshot){
        if(!snapshot.hasData) return const Center(child:  CircularProgressIndicator(),);
        final docs = snapshot.data!.docs;
        return ListView(
          children: docs.map((doc) {
            final data = doc.data();
            return ListTile(
              title: Text(data['name']),
              subtitle: Text('Contact : ${data['contact']} - Bought : 0'),
              
              trailing: role == 'admin' ? IconButton(onPressed: () => doc.reference.delete(), icon: const Icon(Icons.delete)) : null,
              onTap: () {
                if(role == 'admin') {
                  Navigator.push(context, MaterialPageRoute(builder: (_) => VendorForm(companyRef: companyRef, vendorDoc: doc)));
                }
              },
            );
          }).toList(),
        );
    } );
  }
}