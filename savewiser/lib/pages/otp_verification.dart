import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class OtpVerificationPage extends StatefulWidget {
  const OtpVerificationPage({super.key});

  @override
  State<OtpVerificationPage> createState() => _OtpVerificationPageState();
}

class _OtpVerificationPageState extends State<OtpVerificationPage> {
  final _phoneController = TextEditingController();
  final _otpController = TextEditingController();
  String? _verificationId;

  Future<void> _verifyPhone() async {
    final phone = _phoneController.text.trim();
    print("🔍 Starting phone verification for $phone");

    await FirebaseAuth.instance.verifyPhoneNumber(
      phoneNumber: phone,
      timeout: const Duration(seconds: 60),
      verificationCompleted: (PhoneAuthCredential credential) async {
        print("✅ verificationCompleted with credential: $credential");

        try {
          await FirebaseAuth.instance.signInWithCredential(credential);
          _showSnackBar("Auto-verified and signed in!");
        } catch (e) {
          print("❌ Error during auto sign-in: $e");
          _showSnackBar("Auto sign-in failed");
        }
      },
      verificationFailed: (FirebaseAuthException e) {
        print("❌ verificationFailed: ${e.code} - ${e.message}");
        _showSnackBar("Verification failed: ${e.message}");
      },
      codeSent: (String verificationId, int? resendToken) {
        print("📨 codeSent, verificationId: $verificationId");
        _showSnackBar("OTP sent!");
        setState(() {
          _verificationId = verificationId;
        });
      },
      codeAutoRetrievalTimeout: (String verificationId) {
        print("⏱ codeAutoRetrievalTimeout, id: $verificationId");
        _verificationId = verificationId;
      },
    );
  }

  Future<void> _signInWithOtp() async {
    final smsCode = _otpController.text.trim();
    print(
      "🔑 Trying to sign in with OTP: $smsCode and verificationId: $_verificationId",
    );

    try {
      final cred = PhoneAuthProvider.credential(
        verificationId: _verificationId!,
        smsCode: smsCode,
      );

      final userCred = await FirebaseAuth.instance.signInWithCredential(cred);
      print("✅ Phone sign-in success. User: ${userCred.user?.uid}");
      _showSnackBar("Phone number verified!");
    } catch (e) {
      print("❌ Error verifying OTP: $e");
      _showSnackBar("Invalid OTP");
    }
  }

  void _showSnackBar(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Phone OTP")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: _phoneController,
              decoration: const InputDecoration(labelText: "Phone (+60...)"),
              keyboardType: TextInputType.phone,
            ),
            const SizedBox(height: 10),
            ElevatedButton(
              onPressed: _verifyPhone,
              child: const Text("Send OTP"),
            ),
            TextField(
              controller: _otpController,
              decoration: const InputDecoration(labelText: "Enter OTP"),
              keyboardType: TextInputType.number,
            ),
            ElevatedButton(
              onPressed: _signInWithOtp,
              child: const Text("Verify OTP"),
            ),
          ],
        ),
      ),
    );
  }
}
