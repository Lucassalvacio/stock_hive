import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class OrderList extends StatelessWidget {
  final DocumentReference companyRef;
  final String role;
  const OrderList({required this.companyRef, required this.role, super.key});

  @override
  Widget build(BuildContext context) {
    return const Placeholder();
  }
}