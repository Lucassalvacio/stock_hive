import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class VendorForm extends StatefulWidget {
  final DocumentReference companyRef;
  final DocumentSnapshot? vendorDoc;
  const VendorForm({required this.companyRef, this.vendorDoc, super.key});

  @override
  State<VendorForm> createState() => _VendorFormState();
}

class _VendorFormState extends State<VendorForm> {
  final _formKey = GlobalKey<FormState>();
  final nameCtrl = TextEditingController();
  final contactCtrl = TextEditingController();
  // final productsCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    
    if(widget.vendorDoc != null) {
      final data = widget.vendorDoc!.data() as Map<String, dynamic>;
      nameCtrl.text = data['name'];
      contactCtrl.text = data['contact'];
    }
  }

  Future<void> _save() async{
    if(_formKey.currentState!.validate()){
      final data = {
        'name' : nameCtrl.text,
        'contact' : contactCtrl.text,
        'createdAt' : FieldValue.serverTimestamp()
      };

      final col = widget.companyRef.collection('vendors');
      if(widget.vendorDoc == null){
        await col.add(data);
      }else{
        await widget.vendorDoc!.reference.update(data);
      }
      if(!mounted) return;
      Navigator.pop(context);
      
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.vendorDoc == null ? 'Add New Vendor' : 'Edit Vendor'),
      ),
      body: Form(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            TextFormField(controller: nameCtrl, decoration: const InputDecoration(label: Text("Vendor Name")),validator: (value) {
              if(value == null || value.isEmpty) return 'Please fill this field';
              return null;
            }),
            TextFormField(controller: contactCtrl, decoration: const InputDecoration(label: Text("Vendor Contact")),validator: (value) {
              if(value == null || value.isEmpty) return 'Please fill this field';
              return null;
            }),
            const SizedBox(height: 48,),
            ElevatedButton(onPressed: () => _save, child: const Text("Save"))
          ],
        )
      ),
    );
  }
}