import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'otp_verification.dart';
import '../config/auth_service.dart';
import '../config/appconfig.dart';

class Signup extends StatefulWidget {
  const Signup({super.key});

  @override
  State<Signup> createState() => _SignupState();
}

class _SignupState extends State<Signup> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController usernameController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController contactNumberController = TextEditingController();
  final TextEditingController confirmPasswordController = TextEditingController();

  bool _isPasswordVisible = false;
  bool _isConfirmPasswordVisible = false;

  // These booleans control the final "Sign up" button state
  bool _isEmailVerified = false;
  bool _isPhoneVerified = false;

  String? usernameError;
  String? emailError;
  String? contactError;
  String? passwordError;
  String? confirmPasswordError;

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(message),
      backgroundColor: Colors.red,
      duration: const Duration(seconds: 3),
      behavior: SnackBarBehavior.floating,
      margin: EdgeInsets.only(
        bottom: MediaQuery.of(context).size.height - 100,
        left: 20,
        right: 20,
      ),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(10)),
      ),
    ));
  }

  // --- VALIDATION FUNCTIONS ---
  String? _validateContactNumber(String? value) {
    if (value == null || value.isEmpty) return 'Contact number is required';
    if (!RegExp(r'^\d{10}$').hasMatch(value)) return 'Invalid contact number (10 digits)';
    return null;
  }

  String? _validateUsername(String? value) {
    setState(() {
      if (value == null || value.isEmpty) usernameError = 'Username is required';
      else if (value.length < 2) usernameError = 'Too short';
      else if (!RegExp(r'^[a-zA-Z ]+$').hasMatch(value)) usernameError = 'Only letters allowed';
      else usernameError = null;
    });
    return null;
  }

  String? _validateEmail(String? value) {
    setState(() {
      if (value == null || value.isEmpty) emailError = 'Email is required';
      else if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) emailError = 'Invalid email';
      else emailError = null;
    });
    return null;
  }

  String? _validateContactWithState(String? value) {
    setState(() { contactError = _validateContactNumber(value); });
    return null;
  }

  String? _validatePassword(String? value) {
    setState(() {
      if (value == null || value.isEmpty) passwordError = 'Password is required';
      else if (value.length < 8) passwordError = 'Min 8 characters';
      else passwordError = null;
    });
    return null;
  }

  String? _validateConfirmPassword(String? value) {
    setState(() {
      if (value == null || value.isEmpty) confirmPasswordError = 'Confirm password';
      else if (value != passwordController.text) confirmPasswordError = 'Passwords do not match';
      else confirmPasswordError = null;
    });
    return null;
  }

  bool _isFormValid() {
    _validateUsername(usernameController.text);
    _validateEmail(emailController.text);
    _validateContactWithState(contactNumberController.text);
    _validatePassword(passwordController.text);
    _validateConfirmPassword(confirmPasswordController.text);

    return usernameError == null && emailError == null && contactError == null &&
        passwordError == null && confirmPasswordError == null;
  }

  // --- UI BUILDERS ---
  Widget _buildEmailVerifyButton() {
    if (_isEmailVerified) {
      return const Text('Verified', style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold));
    } else if (emailError == null && emailController.text.isNotEmpty) {
      return ElevatedButton(
        onPressed: () async {
          final email = emailController.text.trim();
          try {
            final response = await http.post(
              Uri.parse('${AppConfig.apiBaseUrl}/user/verify/email-otp'),
              headers: {'Content-Type': 'application/json'},
              body: jsonEncode({'email': email}),
            );
            if (response.statusCode == 200) {
              // CHANGE: Ensure we wait for the result from the OTP screen
              final result = await Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => OtpVerification(verificationType: 'email', contactInfo: email)),
              );
              // CHANGE: Explicitly update the verified state variable
              if (result == true) {
                setState(() {
                  _isEmailVerified = true;
                });
              }
            } else {
              _showErrorSnackBar('Failed to send email OTP');
            }
          } catch (e) { _showErrorSnackBar('Connection Error'); }
        },
        style: ElevatedButton.styleFrom(backgroundColor: const Color.fromARGB(255, 14, 66, 170)),
        child: const Text('Verify', style: TextStyle(color: Colors.white, fontSize: 12)),
      );
    }
    return const SizedBox.shrink();
  }

  Widget _buildPhoneVerifyButton() {
    if (_isPhoneVerified) {
      return const Text('Verified', style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold));
    } else if (contactError == null && contactNumberController.text.isNotEmpty) {
      return ElevatedButton(
        onPressed: () async {
          final phone = contactNumberController.text.trim();
          try {
            final response = await http.post(
              Uri.parse('${AppConfig.apiBaseUrl}/user/verify/phone-otp'),
              headers: {'Content-Type': 'application/json'},
              // CHANGE: Key matched to 'phoneNumber' for backend consistency
              body: jsonEncode({'phoneNumber': phone}),
            );
            if (response.statusCode == 200) {
              // CHANGE: Ensure we wait for the result from the OTP screen
              final result = await Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => OtpVerification(verificationType: 'phone', contactInfo: phone)),
              );
              // CHANGE: Explicitly update the verified state variable
              if (result == true) {
                setState(() {
                  _isPhoneVerified = true;
                });
              }
            } else {
              _showErrorSnackBar('Failed to send phone OTP');
            }
          } catch (e) { _showErrorSnackBar('Connection Error'); }
        },
        style: ElevatedButton.styleFrom(backgroundColor: const Color.fromARGB(255, 14, 66, 170)),
        child: const Text('Verify', style: TextStyle(color: Colors.white, fontSize: 12)),
      );
    }
    return const SizedBox.shrink();
  }

  @override
  Widget build(BuildContext context) {
    final sw = MediaQuery.of(context).size.width;
    final sh = MediaQuery.of(context).size.height;

    return Scaffold(
      body: Stack(
        children: [
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color.fromARGB(255, 255, 196, 107), Colors.white, Color.fromARGB(255, 143, 255, 147)],
                begin: Alignment.topLeft, end: Alignment.bottomRight,
              ),
            ),
          ),
          SingleChildScrollView(
            child: Form(
              key: _formKey,
              child: Column(children: [
                SizedBox(height: sh * 0.15),
                Center(
                  child: Column(children: [
                    Text('Create Account', style: TextStyle(color: const Color.fromARGB(255, 14, 66, 170), fontSize: sw * 0.06, fontWeight: FontWeight.bold)),
                    SizedBox(height: sh * 0.04),

                    _buildInputField(usernameController, Icons.person, "Full Name", sw, sh, _validateUsername, usernameError),
                    SizedBox(height: sh * 0.02),

                    _buildVerifiedField(emailController, Icons.email, "Email", sw, sh, _validateEmail, emailError, _buildEmailVerifyButton()),
                    SizedBox(height: sh * 0.02),

                    _buildVerifiedField(contactNumberController, Icons.call, "Contact Number", sw, sh, _validateContactWithState, contactError, _buildPhoneVerifyButton()),
                    SizedBox(height: sh * 0.02),

                    _buildPasswordField(passwordController, "Password", sw, sh, _isPasswordVisible, (v)=>setState(()=>_isPasswordVisible=v), _validatePassword, passwordError),
                    SizedBox(height: sh * 0.02),
                    _buildPasswordField(confirmPasswordController, "Confirm Password", sw, sh, _isConfirmPasswordVisible, (v)=>setState(()=>_isConfirmPasswordVisible=v), _validateConfirmPassword, confirmPasswordError),

                    SizedBox(height: sh * 0.04),

                    Container(
                      width: sw * 0.5,
                      height: sh * 0.07,
                      decoration: BoxDecoration(color: const Color.fromARGB(255, 255, 230, 160), borderRadius: BorderRadius.circular(15), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.2), offset: const Offset(3, 3), blurRadius: 8)]),
                      child: ElevatedButton(
                        onPressed: () async {
                          // CHANGE: The Sign Up button now correctly checks the verified booleans updated via setState
                          if (_isFormValid()) {
                            if (!_isEmailVerified) {
                              _showErrorSnackBar('Email not verified');
                              return;
                            }
                            if (!_isPhoneVerified) {
                              _showErrorSnackBar('Phone not verified');
                              return;
                            }

                            try {
                              final authservice = AuthService();
                              await authservice.signUp(
                                  fullName: usernameController.text.trim(),
                                  password: passwordController.text.trim(),
                                  email: emailController.text.trim(),
                                  contactNumber: contactNumberController.text.trim(),
                                  context: context,
                                  isAdmin: false);
                            } catch (e) {
                              _showErrorSnackBar(e.toString());
                            }
                          }
                        },
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.transparent, shadowColor: Colors.transparent),
                        child: Text('Sign up', style: TextStyle(fontSize: sw * 0.05, color: const Color.fromARGB(255, 14, 66, 170), fontWeight: FontWeight.bold)),
                      ),
                    ),
                    SizedBox(height: 20),
                  ]),
                ),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  // Helper UI methods stay exactly the same
  Widget _buildInputField(TextEditingController controller, IconData icon, String hint, double sw, double sh, Function(String?) validator, String? error) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Container(padding: EdgeInsets.symmetric(horizontal: sw * 0.04), width: sw * 0.8, height: sh * 0.06, decoration: BoxDecoration(color: const Color.fromARGB(255, 255, 230, 160), borderRadius: BorderRadius.circular(15)),
          child: TextFormField(controller: controller, decoration: InputDecoration(hintText: hint, border: InputBorder.none, prefixIcon: Icon(icon, color: const Color.fromARGB(255, 14, 66, 170))), onChanged: (v) => validator(v))),
      if (error != null) Padding(padding: EdgeInsets.only(left: sw * 0.12, top: 4), child: Text(error, style: const TextStyle(color: Colors.red, fontSize: 11)))
    ]);
  }

  Widget _buildVerifiedField(TextEditingController controller, IconData icon, String hint, double sw, double sh, Function(String?) validator, String? error, Widget button) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Container(padding: EdgeInsets.symmetric(horizontal: sw * 0.04), width: sw * 0.8, height: sh * 0.06, decoration: BoxDecoration(color: const Color.fromARGB(255, 255, 230, 160), borderRadius: BorderRadius.circular(15)),
          child: Row(children: [Expanded(child: TextFormField(controller: controller, decoration: InputDecoration(hintText: hint, border: InputBorder.none, prefixIcon: Icon(icon, color: const Color.fromARGB(255, 14, 66, 170))), onChanged: (v) => validator(v))), button])),
      if (error != null) Padding(padding: EdgeInsets.only(left: sw * 0.12, top: 4), child: Text(error, style: const TextStyle(color: Colors.red, fontSize: 11)))
    ]);
  }

  Widget _buildPasswordField(TextEditingController controller, String hint, double sw, double sh, bool visible, Function(bool) toggle, Function(String?) validator, String? error) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Container(padding: EdgeInsets.symmetric(horizontal: sw * 0.04), width: sw * 0.8, height: sh * 0.06, decoration: BoxDecoration(color: const Color.fromARGB(255, 255, 230, 160), borderRadius: BorderRadius.circular(15)),
          child: TextFormField(controller: controller, obscureText: !visible, decoration: InputDecoration(hintText: hint, border: InputBorder.none, prefixIcon: const Icon(Icons.lock, color: Color.fromARGB(255, 14, 66, 170)), suffixIcon: IconButton(icon: Icon(visible ? Icons.visibility : Icons.visibility_off), onPressed: () => toggle(!visible))), onChanged: (v) => validator(v))),
      if (error != null) Padding(padding: EdgeInsets.only(left: sw * 0.12, top: 4), child: Text(error, style: const TextStyle(color: Colors.red, fontSize: 11)))
    ]);
  }
}