
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();



  Future<User?> login(String email, String password) async {
    final result = await _auth.signInWithEmailAndPassword(email: email, password: password);
    return result.user;
  }

  Future<User?> signInWithGoogle() async {
    final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
    if (googleUser == null) return null;

    final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
    final credential = GoogleAuthProvider.credential(
      accessToken: googleAuth.accessToken,
      idToken: googleAuth.idToken,
    );

    final result = await _auth.signInWithCredential(credential);
    final user = result.user;

    if(user != null){
      final userRef = _db.collection('users').doc(user.uid);
      final doc = await userRef.get();
      if(!doc.exists){
        await userRef.set({
          'uid': user.uid,
          'email': user.email,
          'name': user.displayName,
          'role': 'user',
          'createdAt': FieldValue.serverTimestamp(),
        });
      }
    }

    return user;
  }

  Future<void> logout() async{
    await _auth.signOut();
    await _googleSignIn.signOut();
  }

  Stream<User?> get userChanges => _auth.authStateChanges();
}
