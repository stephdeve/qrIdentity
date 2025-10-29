import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:path_provider/path_provider.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:share_plus/share_plus.dart';
import 'package:qr_identity/services/prefs_service.dart';
import 'package:qr_identity/models/user_profile.dart';
import 'package:qr_identity/pages/scanner_page.dart';
import 'package:qr_identity/pages/history_page.dart';

class MyQrPage extends StatefulWidget {
  static const route = '/my-qr';
  const MyQrPage({super.key});

  @override
  State<MyQrPage> createState() => _MyQrPageState();
}

class _MyQrPageState extends State<MyQrPage> {
  final GlobalKey _qrKey = GlobalKey();
  UserProfile? _profile;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final p = await PrefsService.getProfile();
    setState(() {
      _profile = p;
    });
  }

  Future<void> _shareQr() async {
    final boundary = _qrKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
    if (boundary == null) return;
    final ui.Image image = await boundary.toImage(pixelRatio: 3.0);
    final ByteData? byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    if (byteData == null) return;
    final Uint8List pngBytes = byteData.buffer.asUint8List();
    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/my_qr.png');
    await file.writeAsBytes(pngBytes);
    await SharePlus.instance.share(
      ShareParams(
        files: [XFile(file.path)],
        text: 'Mon QR Identity',
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final profile = _profile;
    if (profile == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mon QR'),
        actions: [
          IconButton(
            tooltip: 'Historique',
            onPressed: () => Navigator.of(context).pushNamed(HistoryPage.route),
            icon: const Icon(Icons.history),
          )
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
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
                    child: Text(
                      profile.fullName,
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Expanded(
                child: Center(
                  child: RepaintBoundary(
                    key: _qrKey,
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 12)]),
                      child: QrImageView(
                        data: profile.toJsonString(),
                        version: QrVersions.auto,
                        size: 240,
                        gapless: true,
                      ),
                    ),
                  ),
                ),
              ),
              Row(
                children: [
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: _shareQr,
                      icon: const Icon(Icons.share),
                      label: const Text('Partager mon QR'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => Navigator.of(context).pushNamed(ScannerPage.route),
                      icon: const Icon(Icons.qr_code_scanner),
                      label: const Text('Scanner un QR'),
                    ),
                  ),
                ],
              )
            ],
          ),
        ),
      ),
    );
  }
}
