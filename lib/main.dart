import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dashboard.dart'; 

void main() {
  runApp(MaterialApp(
    debugShowCheckedModeBanner: false,
    home: BronzePrestigeGateScreen(),
  ));
}

class BronzePrestigeGateScreen extends StatefulWidget {
  @override
  _BronzePrestigeGateScreenState createState() => _BronzePrestigeGateScreenState();
}

class _BronzePrestigeGateScreenState extends State<BronzePrestigeGateScreen> {
  // 🌍 REPLACE THIS WITH YOUR DEDICATED ORACLE CLOUD CORE PUBLIC IP ADDRESS:
  final String serverIpAddress = "150.230.127.46";
  
  bool isVerifying = false;

  // Function to initialize payment token request from your VPS backend
  Future<void> initializeAndPay() async {
    setState(() { isVerifying = true; });

    try {
      // 1. Tell your live VPS backend to generate a fresh subscription check token
      final response = await http.post(
        Uri.parse('http://$serverIpAddress:3000/api/checkout/initialize'),
        headers: {"Content-Type": "application/json"},
      ).timeout(Duration(seconds: 15));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final String paymentUrl = data['authorization_url'];
        final String reference = data['reference'];

        // 2. Launch the real live Paystack payment gateway page on the phone browser
        final Uri url = Uri.parse(paymentUrl);
        if (await launchUrl(url, mode: LaunchMode.externalApplication)) {
          
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              backgroundColor: Color(0xFFCD7F32),
              content: Text("Awaiting secure authorization from bank..."),
              duration: Duration(seconds: 4),
            ),
          );

          // 3. Start looping a clean subscription status check to your VPS server
          pollSubscriptionStatus(reference);
        } else {
          showError("Could not launch secure payment gateway.");
        }
      } else {
        showError("Server Gateway Busy. Try again in 60 seconds.");
      }
    } catch (e) {
      showError("Connection Timeout. Check your mobile network data.");
    }
  }

  // Polls your live server to confirm Paystack successfully caught the money
  Future<void> pollSubscriptionStatus(String reference) async {
    int checkCount = 0;
    bool paid = false;

    while (checkCount < 30 && !paid) {
      await Future.delayed(Duration(seconds: 5)); // Check every 5 seconds
      try {
        final response = await http.get(
          Uri.parse('http://$serverIpAddress:3000/api/subscription/verify/$reference')
        ).timeout(Duration(seconds: 4));

        if (response.statusCode == 200) {
          final data = json.decode(response.body);
          if (data['status'] == 'active') {
            paid = true;
            
            // 🛡️ CRITICAL FIX: Verifies context is safely attached before swapping screens
            if (!mounted) return;
            
            // Unlocks the premium core dashboard using the valid backend-generated token
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) => PremiumDashboardScreen(paymentReference: reference, serverIp: serverIpAddress),
              ),
            );
            return;
          }
        }
      } catch (e) {
        // Suppress errors and keep trying in case of temporary cellular mast handovers
      }
      checkCount++;
    }

    if (!mounted) return;
    setState(() { isVerifying = false; });
    showError("Payment Timeout: Tap again if payment was completed.");
  }

  void showError(String message) {
    if (!mounted) return;
    setState(() { isVerifying = false; });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: Colors.redAccent,
        content: Text(message),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final Color basaltBlack = Color(0xFF0D0E12);
    final Color industrialBronze = Color(0xFFCD7F32);
    final Color darkCardBackground = Color(0xFF161922);

    return Scaffold(
      backgroundColor: basaltBlack,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Spacer(),
              
              Icon(
                Icons.gpp_maybe_outlined,
                size: 90,
                color: industrialBronze,
              ),
              SizedBox(height: 24),
              
              Text(
                "NETWORK STABILIZER",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 2.0,
                ),
              ),
              SizedBox(height: 8),
              Text(
                "MTN • AIRTEL • GLO HIGH-STABILITY SYSTEM",
                style: TextStyle(
                  color: industrialBronze,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 1.0,
                ),
              ),
              
              SizedBox(height: 35),
              
              Container(
                width: double.infinity,
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: darkCardBackground,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: industrialBronze.withOpacity(0.3), width: 1),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "CURRENT SYSTEM TELEMETRY:",
                      style: TextStyle(color: industrialBronze, fontSize: 10, fontWeight: FontWeight.bold),
                    ),
                    SizedBox(height: 12),
                    buildStaticLogItem("Tunnel Tier", "BRONZE (Public Carrier Route)"),
                    buildStaticLogItem("Data Status", "Unoptimized Signal Queue"),
                    buildStaticLogItem("Routing Node", "Congested Carrier DNS (>280ms lag)"),
                  ],
                ),
              ),
              
              Spacer(),
              
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: industrialBronze,
                  foregroundColor: basaltBlack,
                  minimumSize: Size(double.infinity, 56),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  elevation: 4,
                ),
                onPressed: isVerifying ? null : initializeAndPay,
                child: isVerifying 
                  ? SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(color: basaltBlack, strokeWidth: 2.5),
                    )
                  : Text(
                      "DEPLOY ELITE GOLD BOOSTER — ₦3,500",
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5,
                      ),
                    ),
              ),
              SizedBox(height: 10),
              Text(
                "Secured via Paystack Banking Gateway. 30-Day Automated License.",
                style: TextStyle(color: Colors.white24, fontSize: 10),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget buildStaticLogItem(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.between,
        children: [
          Text(label, style: TextStyle(color: Colors.white54, fontSize: 12)),
          Text(value, style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}
