import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:lottie/lottie.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:qr_identity/models/scan_record.dart';
import 'package:qr_identity/models/user_profile.dart';
import 'package:qr_identity/services/db_service.dart';

class ScannerPage extends StatefulWidget {
  static const route = '/scan';
  const ScannerPage({super.key});

  @override
  State<ScannerPage> createState() => _ScannerPageState();
}

class _ScannerPageState extends State<ScannerPage> {
  MobileScannerController controller = MobileScannerController();
  bool _processed = false;

  bool get _isMobile {
    if (kIsWeb) return false;
    return defaultTargetPlatform == TargetPlatform.android || defaultTargetPlatform == TargetPlatform.iOS;
  }

  @override
  void initState() {
    super.initState();
    Future.microtask(_ensurePermission);
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  Future<void> _ensurePermission() async {
    if (!_isMobile) return;
    final status = await Permission.camera.request();
    if (!status.isGranted) {
      Fluttertoast.showToast(msg: 'Permission caméra refusée');
      if (mounted) Navigator.of(context).pop();
    }
  }

  Future<void> _handleCode(String code) async {
    if (_processed) return;
    _processed = true;
    try {
      final map = jsonDecode(code) as Map<String, dynamic>;
      final profile = UserProfile.fromJson(map);
      final record = ScanRecord(profile: profile, scannedAt: DateTime.now());
      await DBService.instance.insertScan(record);
      if (!mounted) return;
      Fluttertoast.showToast(msg: 'Scan enregistré');
      if (!mounted) return;
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
        builder: (ctx) => _ScanResultSheet(profile: profile),
      ).whenComplete(() {
        _processed = false;
      });
    } catch (e) {
      _processed = false;
      Fluttertoast.showToast(msg: 'QR invalide');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Scanner')),
      body: !_isMobile
          ? const Center(
              child: Padding(
                padding: EdgeInsets.all(24.0),
                child: Text('Le scanner de QR est disponible uniquement sur Android et iOS.'),
              ),
            )
          : Column(
              children: [
                Expanded(
                  flex: 3,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      MobileScanner(
                        controller: controller,
                        onDetect: (capture) {
                          final barcodes = capture.barcodes;
                          if (barcodes.isNotEmpty) {
                            final code = barcodes.first.rawValue;
                            if (code != null) _handleCode(code);
                          }
                        },
                      ),
                      Align(
                        alignment: Alignment.topCenter,
                        child: Padding(
                          padding: const EdgeInsets.only(top: 16.0),
                          child: Lottie.network(
                            'https://assets3.lottiefiles.com/packages/lf20_jbrw3hcz.json',
                            height: 80,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                const Padding(
                  padding: EdgeInsets.all(12.0),
                  child: Text('Cadrez le QR dans la zone pour scanner'),
                ),
              ],
            ),
    );
  }
}

class _ScanResultSheet extends StatelessWidget {
  final UserProfile profile;
  const _ScanResultSheet({required this.profile});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 28,
                  backgroundImage: profile.photoBase64 != null ? MemoryImage(base64Decode(profile.photoBase64!)) : null,
                  child: profile.photoBase64 == null ? const Icon(Icons.person) : null,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(profile.fullName, style: Theme.of(context).textTheme.titleLarge),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _info('Pays', '${profile.pays} (+${profile.dialCode})'),
            _info('Téléphone', profile.telephone),
            _info('Email', profile.email),
            _info('Naissance', profile.dateNaissance),
            if (profile.note != null) _info('Note', profile.note!),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }

  Widget _info(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        children: [
          SizedBox(width: 120, child: Text(label, style: const TextStyle(color: Colors.black54))),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
}
