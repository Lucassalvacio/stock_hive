import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:stock_hive/services/auth_service.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formkey = GlobalKey<FormState>();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  bool isLoading = false;
  bool isPasswordVisible = false;


  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }
  
  Future<void> _login() async {
    if(!_formkey.currentState!.validate()) return;
    setState(() {
      isLoading = true;
    });

    try {
      final user = await AuthService().login(emailController.text.trim(), passwordController.text.trim());

      if(!mounted) return;
      if(user != null) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Login Successful!')),);
      }
    }on FirebaseAuthException catch (e){
      if(!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message ?? 'Login failed')),
      );
    }finally{
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> _loginWithGoogle() async {
    setState(() {
      isLoading = true;
    });

    try {
      final user = await AuthService().signInWithGoogle();

      if(!mounted) return;
      if(user != null){
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Welcome, ${user.displayName ?? 'user'}!')),);
      }
    } catch (e){
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Google Sign-In Failed: $e')),);
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
          child: Card(
            elevation: 6,
            shape: RoundedRectangleBorder( borderRadius: BorderRadius.circular(16)),
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Form(
                key: _formkey,
                child: Column(
                  mainAxisSize:  MainAxisSize.min,
                  children: [
                    const Text("Welcome Back"),
                    const SizedBox(height:  8,),
                    const Text('Login to your account'),
                    const SizedBox(height: 32,),

                    //email
                    TextFormField(
                      controller: emailController,
                      decoration: const InputDecoration(
                        labelText: "Email",
                        prefixIcon: Icon(Icons.email_outlined),
                        border: OutlineInputBorder()
                      ),
                      validator: (value) {
                        if(value == null || value.isEmpty){
                          return "Please enter your email";
                        }
                        if(!value.contains('@')){
                          return " Enter a valid email";
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16,),

                    //Password
                    TextFormField(
                      controller: passwordController,
                      obscureText: !isPasswordVisible,
                      decoration: InputDecoration(
                        labelText: "Password",
                        prefixIcon: const Icon(Icons.lock_outline),
                        suffixIcon: IconButton(
                          onPressed: () => setState(() {
                            isPasswordVisible = !isPasswordVisible;
                          }),
                          icon: Icon(isPasswordVisible ? Icons.visibility_off : Icons.visibility,)
                        )
                      ),
                      validator: (value) {
                        if(value == null || value.isEmpty){
                          return "Please enter your password";
                        }
                        return null;
                      },
                    ),

                    //Login Button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: isLoading ? null : _login, 
                        child: isLoading ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(),
                        ) : const Text("Login")
                      ),
                    ),

                    const SizedBox(height: 16,),

                    //Google Login 
                    OutlinedButton.icon(
                      onPressed: isLoading ? null : _loginWithGoogle, 
                      label: const Text("Sign in with Google"), 
                      icon: Image.asset('assets/google_logo.png', height: 20,), 
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size(double.infinity, 48),
                        side: const BorderSide(color: Colors.grey),
                      ),),

                    const SizedBox(height: 16),

                    TextButton(
                      onPressed: () {},
                      child: const Text("Forgot password?"),
                    )
                  ],
                ),
              ),
            ),
          ),
        )),
      
    );  
  }
}