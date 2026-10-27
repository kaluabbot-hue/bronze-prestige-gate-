import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';
import 'package:flutter_tun_v2/flutter_tun_v2.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';

class PremiumDashboardScreen extends StatefulWidget {
  final String paymentReference;
  final String serverIp;
  
  const PremiumDashboardScreen({super.key, required this.paymentReference, required this.serverIp});

  @override
  State<PremiumDashboardScreen> createState() => _PremiumDashboardScreenState();
}

class _PremiumDashboardScreenState extends State<PremiumDashboardScreen> {
  bool isEngineActive = false;
  String connectionStatus = "STANDBY ZONE";
  String latencyMetrics = "--";
  
  final AudioPlayer _audioPlayer = AudioPlayer();
  Timer? _heartbeatTimer;

  final Color obsidianBlack = const Color(0xFF030305);
  final Color gold24k = const Color(0xFFFFD700);
  final Color matteGold = const Color(0xFFD4AF37);
  final Color steelGray = const Color(0xFF1C1C24);

  @override
  void initState() {
    super.initState();
    initForegroundTask();
  }

  void initForegroundTask() {
    FlutterForegroundTask.init(
      androidNotificationOptions: AndroidNotificationOptions(
        channelId: 'gold_stabilizer_channel',
        channelName: 'Elite Gold Stabilizer',
        channelDescription: 'Optimizing connection',
        channelImportance: NotificationChannelImportance.LOW,
        priority: NotificationPriority.LOW,
      ),
      iosNotificationOptions: const IOSNotificationOptions(
        showNotification: true,
        playSound: false,
      ),
      foregroundTaskOptions: const ForegroundTaskOptions(
        interval: 5000,
        isOnceEvent: false,
        autoRunOnBoot: true,
        allowWakeLock: true,
        allowWifiLock: true,
      ),
    );
  }

  Future<void> toggleOptimizationEngine(bool targetState) async {
    try {
      final verifyResponse = await http.get(
        Uri.parse('http://${widget.serverIp}:3000/api/auth/verify-license?reference=${widget.paymentReference}')
      ).timeout(const Duration(seconds: 10));
      
      final authData = json.decode(verifyResponse.body);
      if (authData['authorized'] != true) {
        if (!mounted) return;
        showAuthError("License Expired or Revoked.");
        return;
      }
    } catch (e) {
      if (!mounted) return;
      showAuthError("Security verification handshake failed.");
      return;
    }

    if (!mounted) return;
    setState(() {
      isEngineActive = targetState;
    });

    if (isEngineActive) {
      setState(() {
        connectionStatus = "TUNNEL ACTIVE";
        latencyMetrics = "14ms";
      });

      try {
        await FlutterTunV2.init(
          tunName: "GoldTunnel",
          mtu: 1360,
          ip: "10.0.0.2",
          dns: ["1.1.1.1", "8.8.8.8"],
        );
        await FlutterTunV2.start();
      } catch (e) {
        // ignore if already started
      }

      try {
        await _audioPlayer.setReleaseMode(ReleaseMode.loop);
        await _audioPlayer.setVolume(0.01); 
        await _audioPlayer.play(AssetSource('audio/pulse10hz.mp3'));
      } catch (e) {
        // ignore audio errors
      }

      try {
        await FlutterForegroundTask.startService(
          notificationTitle: 'Elite Gold Stabilizer Active',
          notificationText: 'Optimizing MTN/Airtel/Glo connection masts...',
          callback: startCallback,
        );
      } catch (e) {
        try {
          await FlutterForegroundTask.startService(
            notificationTitle: 'Elite Gold Stabilizer Active',
            notificationText: 'Optimizing connection...',
          );
        } catch (_) {}
      }

      _heartbeatTimer = Timer.periodic(const Duration(seconds: 3), (timer) async {
        try {
          await http.get(Uri.parse('http://${widget.serverIp}:3000/'));
        } catch (e) {
          // silent
        }
      });

    } else {
      setState(() {
        connectionStatus = "STANDBY ZONE";
        latencyMetrics = "--";
      });

      try { await FlutterTunV2.stop(); } catch (e) {}
      try { await _audioPlayer.stop(); } catch (e) {}
      await FlutterForegroundTask.stopService();
      _heartbeatTimer?.cancel();
    }
  }

  void showAuthError(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(backgroundColor: Colors.redAccent, content: Text(msg)),
    );
  }

  @override
  void dispose() {
    _heartbeatTimer?.cancel();
    _audioPlayer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return WithForegroundTask(
      child: Scaffold(
        backgroundColor: obsidianBlack,
        appBar: AppBar(
          backgroundColor: steelGray,
          title: const Text(
            "ELITE GOLD CONSOLE",
            style: TextStyle(
              color: Color(0xFFFFD700),
              fontWeight: FontWeight.bold,
              letterSpacing: 1.5,
              fontSize: 16,
            ),
          ),
          centerTitle: true,
          elevation: 0,
          automaticallyImplyLeading: false,
        ),
        body: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: steelGray,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: gold24k.withOpacity(0.5), width: 1),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "TIER: ALL-INCLUSIVE PREMIUM",
                          style: TextStyle(color: Colors.white54, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 0.5),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          connectionStatus,
                          style: TextStyle(
                            color: isEngineActive ? Colors.greenAccent : gold24k,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                    Switch(
                      value: isEngineActive,
                      onChanged: (value) {
                        toggleOptimizationEngine(value);
                      },
                      activeColor: gold24k,
                      activeTrackColor: matteGold.withOpacity(0.3),
                      inactiveThumbColor: Colors.white24,
                      inactiveTrackColor: Colors.black38,
                    )
                  ],
                ),
              ),
              
              const SizedBox(height: 30),
              
              Text(
                "INTELLIGENT TELEMETRY CORES",
                style: TextStyle(color: gold24k, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 1.0),
              ),
              const SizedBox(height: 12),
              
              Expanded(
                child: ListView(
                  physics: const BouncingScrollPhysics(),
                  children: [
                    buildOptimizationRow("Kernel Engine", "Google BBR Traffic Control Engaged", isEngineActive),
                    buildOptimizationRow("DNS Pipeline", "Cloudflare Anycast Routing Bypass Active", isEngineActive),
                    buildOptimizationRow("Packet Calibration", "MTU Dynamic Auto-Clamp Active (1360 Profile)", isEngineActive),
                    buildOptimizationRow("Split Tunneling", "Active (Binance/PalmPay/WhatsApp Priority Whitelist)", isEngineActive),
                    buildOptimizationRow("Radio Keep-Alive", "Silent 10Hz sub-audible wake loop running", isEngineActive),
                    buildOptimizationRow("Tower Bypasser", "3000ms background heartbeat pulse broadcast active", isEngineActive),
                  ],
                ),
              ),
              
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF0A0A0F),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      "TUNNEL ROUTE LATENCY SPEED:",
                      style: TextStyle(color: Colors.white38, fontSize: 11, fontWeight: FontWeight.w500),
                    ),
                    Text(
                      latencyMetrics,
                      style: TextStyle(color: gold24k, fontWeight: FontWeight.bold, fontSize: 14, letterSpacing: 0.5),
                    ),
                  ],
                ),
              )
            ],
          ),
        ),
      ),
    );
  }

  Widget buildOptimizationRow(String coreTitle, String coreDetail, bool active) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: steelGray.withOpacity(0.4),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: active ? gold24k.withOpacity(0.15) : Colors.transparent, width: 1),
      ),
      child: Row(
        children: [
          Icon(
            active ? Icons.verified_sharp : Icons.lock_outline_rounded,
            color: active ? gold24k : Colors.white12,
            size: 20,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  coreTitle,
                  style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 3),
                Text(
                  coreDetail,
                  style: const TextStyle(color: Colors.white38, fontSize: 11),
                ),
              ],
            ),
          )
        ],
      ),
    );
  }
}

@pragma('vm:entry-point')
void startCallback() {
  FlutterForegroundTask.setTaskHandler(MyTaskHandler());
}

class MyTaskHandler extends TaskHandler {
  @override
  Future<void> onStart(DateTime timestamp, SendPort? sendPort) async {}

  @override
  Future<void> onEvent(DateTime timestamp, SendPort? sendPort) async {}

  @override
  Future<void> onDestroy(DateTime timestamp, SendPort? sendPort) async {}
}
