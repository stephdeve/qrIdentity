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
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';

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
        text: 'Mon QR Identity - ${_profile?.fullName}',
      ),
    );
  }

  String _getQrData(UserProfile profile) {
    // Créer une version simplifiée pour éviter l'erreur "Input too long"
    final data = {
      'n': profile.nom,
      'p': profile.prenom,
      't': profile.telephone,
      'e': profile.email,
      'c': profile.isoCode,
      'd': profile.dateNaissance,
      'note': profile.note,
    };

    // Supprimer les valeurs null
    data.removeWhere((key, value) => value == null || value == '');

    final jsonString = jsonEncode(data);

    // Vérifier la longueur et tronquer si nécessaire
    if (jsonString.length > 1200) {
      final truncatedData = Map.from(data);
      if (truncatedData['note'] != null) {
        final note = truncatedData['note'] as String;
        if (note.length > 200) {
          truncatedData['note'] = note.substring(0, 200) + '...';
        }
      }
      return jsonEncode(truncatedData);
    }

    return jsonString;
  }

  @override
  Widget build(BuildContext context) {
    final profile = _profile;
    if (profile == null) {
      return Scaffold(
        backgroundColor: Colors.white,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(color: Color(0xFF8B5FBF)),
              SizedBox(height: 16),
              Text(
                'Chargement...',
                style: GoogleFonts.poppins(
                  color: Color(0xFF4A6FA5),
                  fontSize: 16,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Text(
          'Mon QR Code',
          style: GoogleFonts.poppins(
            color: Color(0xFF4A6FA5),
            fontWeight: FontWeight.w600,
          ),
        ),
        actions: [
          IconButton(
            tooltip: 'Historique',
            onPressed: () => Navigator.of(context).pushNamed(HistoryPage.route),
            icon: Icon(LucideIcons.history, color: Color(0xFF8B5FBF)),
          )
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            children: [
              // Header avec photo et infos
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.1),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                  border: Border.all(
                    color: Color(0xFF8B5FBF).withOpacity(0.1),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: const LinearGradient(
                          colors: [
                            Color(0xFF8B5FBF),
                            Color(0xFF4A6FA5),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                      ),
                      padding: const EdgeInsets.all(2),
                      child: CircleAvatar(
                        backgroundColor: Colors.white,
                        backgroundImage: profile.photoBase64 != null
                            ? MemoryImage(base64Decode(profile.photoBase64!))
                            : null,
                        child: profile.photoBase64 == null
                            ? Icon(
                          LucideIcons.user,
                          color: Color(0xFF8B5FBF),
                          size: 28,
                        )
                            : null,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            profile.fullName,
                            style: GoogleFonts.poppins(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF4A6FA5),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            profile.telephone,
                            style: GoogleFonts.poppins(
                              color: Colors.grey[600],
                              fontSize: 14,
                            ),
                          ),
                          Text(
                            profile.email,
                            style: GoogleFonts.poppins(
                              color: Colors.grey[600],
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),

              // QR Code
              Expanded(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Mon QR Code Identity',
                        style: GoogleFonts.poppins(
                          fontSize: 20,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF4A6FA5),
                        ),
                      ),
                      const SizedBox(height: 16),
                      RepaintBoundary(
                        key: _qrKey,
                        child: Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.grey.withOpacity(0.2),
                                blurRadius: 15,
                                offset: const Offset(0, 8),
                              ),
                            ],
                            border: Border.all(
                              color: Color(0xFF8B5FBF).withOpacity(0.2),
                            ),
                          ),
                          child: QrImageView(
                            data: _getQrData(profile),
                            version: QrVersions.auto,
                            size: 220,
                            gapless: true,
                            eyeStyle: const QrEyeStyle(
                              eyeShape: QrEyeShape.square,
                              color: Color(0xFF4A6FA5),
                            ),
                            dataModuleStyle: const QrDataModuleStyle(
                              dataModuleShape: QrDataModuleShape.square,
                              color: Color(0xFF1F2937),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Scannez ce QR code pour partager mes informations',
                        style: GoogleFonts.poppins(
                          color: Colors.grey[600],
                          fontSize: 10,
                        ),
                        textAlign: TextAlign.center
                      ),
                    ],
                  ),
                ),
              ),

              // Boutons d'action
              const SizedBox(height: 32),
              Row(
                children: [
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: _shareQr,
                      style: FilledButton.styleFrom(
                        backgroundColor: Color(0xFF4A6FA5),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      icon: const Icon(LucideIcons.share2, size: 20),
                      label: Text(
                        'Partager',
                        style: GoogleFonts.poppins(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => Navigator.of(context).pushNamed(ScannerPage.route),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Color(0xFF8B5FBF),
                        side: BorderSide(color: Color(0xFF8B5FBF)),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      icon: const Icon(LucideIcons.scan, size: 20),
                      label: Text(
                        'Scanner',
                        style: GoogleFonts.poppins(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}