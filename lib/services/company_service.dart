
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class CompanyService {

  
  Future<DocumentReference<Map<String, dynamic>>> getCompanyRef() async {
  final uid = FirebaseAuth.instance.currentUser!.uid;
  final userDoc = await FirebaseFirestore.instance
      .collection('users')
      .doc(uid)
      .get();

  return userDoc['companyRef'] as DocumentReference<Map<String, dynamic>>;
}
}