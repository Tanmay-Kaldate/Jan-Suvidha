import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../config/appconfig.dart';
import 'user_widgets/common_widgets.dart';

class OtpVerification extends StatefulWidget {
  final String verificationType; // 'email' or 'phone'
  final String contactInfo;
  const OtpVerification(
      {super.key, required this.verificationType, required this.contactInfo});

  @override
  State<OtpVerification> createState() => _OtpVerificationState();
}

class _OtpVerificationState extends State<OtpVerification> {
  final List<TextEditingController> _controllers = List.generate(
    4,
        (index) => TextEditingController(),
  );

  final List<FocusNode> _focusNodes = List.generate(
    4,
        (index) => FocusNode(),
  );

  Timer? _resendTimer;
  int _resendTimeout = 60;
  bool _canResend = false;

  @override
  void dispose() {
    _resendTimer?.cancel();
    for (var controller in _controllers) {
      controller.dispose();
    }
    for (var node in _focusNodes) {
      node.dispose();
    }
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _startResendTimer();
  }

  void _startResendTimer() {
    setState(() {
      _resendTimeout = 60;
      _canResend = false;
    });
    _resendTimer?.cancel();
    _resendTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_resendTimeout > 0) {
        setState(() => _resendTimeout--);
      } else {
        setState(() => _canResend = true);
        timer.cancel();
      }
    });
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(message),
      backgroundColor: Colors.red,
      duration: const Duration(seconds: 3),
      behavior: SnackBarBehavior.floating,
    ));
  }

  void _resendOtp() async {
    try {
      // Logic fix: Ensure we call 'send' endpoints, not 'verify' endpoints for resending
      final endpoint = widget.verificationType == 'email' ? 'email-otp' : 'phone-otp';

      // Match the JSON key your backend controller expects
      final bodyKey = widget.verificationType == 'email' ? 'email' : 'phoneNumber';

      await http.post(
        Uri.parse('${AppConfig.apiBaseUrl}/user/verify/$endpoint'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({bodyKey: widget.contactInfo}),
      );
      _startResendTimer();
    } catch (e) {
      _showErrorSnackBar('Failed to resend OTP');
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final baseColor = const Color.fromARGB(255, 14, 66, 170);

    return Scaffold(
      body: Stack(
        children: [
          const GradientBackground(),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.06),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'OTP Verification',
                  style: TextStyle(
                    fontSize: screenWidth * 0.07,
                    fontWeight: FontWeight.bold,
                    color: baseColor,
                  ),
                ),
                SizedBox(height: screenHeight * 0.015),
                Text(
                  'Enter the OTP sent to ${widget.contactInfo}',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: screenWidth * 0.04,
                    color: const Color.fromARGB(255, 88, 88, 88),
                  ),
                ),
                SizedBox(height: screenHeight * 0.04),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: List.generate(
                    4,
                        (index) => SizedBox(
                      width: screenWidth * 0.15,
                      height: screenWidth * 0.15,
                      child: TextField(
                        controller: _controllers[index],
                        focusNode: _focusNodes[index],
                        textAlign: TextAlign.center,
                        keyboardType: TextInputType.number,
                        maxLength: 1,
                        style: TextStyle(fontSize: screenWidth * 0.06),
                        decoration: InputDecoration(
                          counterText: '',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(screenWidth * 0.025),
                            borderSide: BorderSide(color: baseColor),
                          ),
                        ),
                        onChanged: (value) {
                          if (value.length == 1 && index < 3) {
                            _focusNodes[index + 1].requestFocus();
                          }
                          if (value.isEmpty && index > 0) {
                            _focusNodes[index - 1].requestFocus();
                          }
                        },
                      ),
                    ),
                  ),
                ),
                SizedBox(height: screenHeight * 0.04),
                StyledContainer(
                  height: screenHeight * 0.07,
                  width: screenWidth * 0.5,
                  child: ElevatedButton(
                    onPressed: () async {
                      String otp = _controllers.map((c) => c.text).join();
                      if (otp.length != 4) {
                        _showErrorSnackBar('Enter complete OTP');
                        return;
                      }

                      try {
                        final endpoint = widget.verificationType == 'email'
                            ? 'verify-email'
                            : 'verify-phone';

                        // Fix: Match backend controller keys ('email' or 'phoneNumber')
                        final bodyKey = widget.verificationType == 'email' ? 'email' : 'phoneNumber';

                        final response = await http.post(
                          Uri.parse('${AppConfig.apiBaseUrl}/user/verify/$endpoint'),
                          headers: {'Content-Type': 'application/json'},
                          body: jsonEncode({
                            bodyKey: widget.contactInfo,
                            'otp': otp
                          }),
                        );

                        final data = jsonDecode(response.body);

                        if (response.statusCode == 200 && data['success'] == true) {
                          // This returns 'true' to signup.dart to trigger setState(() => _isEmailVerified = true)
                          Navigator.pop(context, true);
                        } else {
                          _showErrorSnackBar(data['message'] ?? 'Invalid OTP');
                        }
                      } catch (e) {
                        _showErrorSnackBar('Connection Error');
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      shadowColor: Colors.transparent,
                    ),
                    child: Text(
                      'Verify',
                      style: TextStyle(
                        fontSize: screenWidth * 0.05,
                        color: baseColor,
                      ),
                    ),
                  ),
                ),
                SizedBox(height: screenHeight * 0.03),
                TextButton(
                  onPressed: _canResend ? _resendOtp : null,
                  child: Text(
                    _canResend ? 'Resend OTP' : 'Resend in $_resendTimeout',
                    style: TextStyle(
                      color: baseColor,
                      fontSize: screenWidth * 0.04,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const Positioned(
            bottom: 0, left: 0, right: 0,
            child: BottomRoundedBar(),
          ),
          Positioned(
            bottom: screenHeight * 0.03,
            left: screenWidth * 0.05,
            child: FloatingActionButton(
              onPressed: () => Navigator.pop(context, false),
              backgroundColor: const Color.fromARGB(255, 254, 183, 101),
              mini: true,
              child: const Icon(Icons.arrow_back_ios_new, color: Color.fromARGB(255, 15, 62, 129)),
            ),
          ),
        ],
      ),
    );
  }
}