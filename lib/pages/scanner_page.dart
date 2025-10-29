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
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';

class ScannerPage extends StatefulWidget {
  static const route = '/scan';
  const ScannerPage({super.key});

  @override
  State<ScannerPage> createState() => _ScannerPageState();
}

class _ScannerPageState extends State<ScannerPage> {
  MobileScannerController controller = MobileScannerController();
  bool _processed = false;
  bool _isLoading = false;
  bool _isTorchOn = false;
  bool _isScanning = true;

  bool get _isMobile {
    if (kIsWeb) return false;
    return defaultTargetPlatform == TargetPlatform.android || defaultTargetPlatform == TargetPlatform.iOS;
  }

  @override
  void initState() {
    super.initState();
    _isScanning = true;
    Future.microtask(_ensurePermission);
  }

  @override
  void dispose() {
    controller.dispose();
    _isScanning = false;
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

    setState(() {
      _processed = true;
      _isLoading = true;
      _isScanning = false;
    });

    try {
      final map = jsonDecode(code) as Map<String, dynamic>;

      // DEBUG: Vérifier les données reçues
      print("QR Code Data: $map");

      // Utiliser une méthode qui gère les différents formats de clés
      final processedMap = _normalizeJsonKeys(map);
      final profile = UserProfile.fromJson(processedMap);

      final record = ScanRecord(profile: profile, scannedAt: DateTime.now());
      await DBService.instance.insertScan(record);

      if (!mounted) return;

      setState(() {
        _isLoading = false;
      });

      Fluttertoast.showToast(
        msg: 'Profil scanné avec succès',
        backgroundColor: Color(0xFF4A6FA5),
        textColor: Colors.white,
      );

      if (!mounted) return;

      await showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (ctx) => _ScanResultSheet(profile: profile),
      );

    } catch (e) {
      print("Erreur scan: $e");
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
      _processed = false;
      Fluttertoast.showToast(
        msg: 'QR code invalide: ${e.toString()}',
        backgroundColor: Colors.red,
        textColor: Colors.white,
      );
    } finally {
      if (mounted) {
        setState(() {
          _processed = false;
          _isScanning = true;
        });
      }
    }
  }

  // Méthode pour normaliser les clés JSON (support ancien et nouveau format)
  Map<String, dynamic> _normalizeJsonKeys(Map<String, dynamic> map) {
    return {
      'photo': map['photo'] ?? map['photoBase64'],
      'nom': map['nom'] ?? map['n'] ?? '',
      'prenom': map['prenom'] ?? map['p'] ?? '',
      'pays': map['pays'] ?? map['c'] ?? '',
      'iso': map['iso'] ?? map['isoCode'] ?? map['i'] ?? '',
      'dial_code': map['dial_code'] ?? map['dialCode'] ?? map['d'] ?? '',
      'telephone': map['telephone'] ?? map['tel'] ?? map['t'] ?? '',
      'email': map['email'] ?? map['e'] ?? '',
      'date_naissance': map['date_naissance'] ?? map['dateNaissance'] ?? map['dn'] ?? '',
      'note': map['note'] ?? map['nt'],
    };
  }

  void _toggleTorch() {
    setState(() {
      _isTorchOn = !_isTorchOn;
    });
    controller.toggleTorch();
  }

  void _switchCamera() {
    controller.switchCamera();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Text(
          'Scanner QR Code',
          style: GoogleFonts.poppins(
            color: Color(0xFF4A6FA5),
            fontWeight: FontWeight.w600,
          ),
        ),
        leading: IconButton(
          icon: Icon(LucideIcons.arrowLeft, color: Color(0xFF4A6FA5)),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: !_isMobile
          ? Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                LucideIcons.qrCode,
                size: 80,
                color: Colors.grey[300],
              ),
              SizedBox(height: 16),
              Text(
                'Scanner non disponible',
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  color: Color(0xFF4A6FA5),
                  fontWeight: FontWeight.w600,
                ),
              ),
              SizedBox(height: 8),
              Text(
                'Le scanner de QR code est disponible uniquement sur Android et iOS.',
                style: GoogleFonts.poppins(
                  color: Colors.grey[600],
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      )
          : Stack(
        children: [
          Column(
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

                    Container(
                      decoration: BoxDecoration(
                        gradient: RadialGradient(
                          radius: 0.8,
                          colors: [
                            Colors.transparent,
                            Colors.black.withOpacity(0.4),
                          ],
                        ),
                      ),
                    ),

                    Align(
                      alignment: Alignment.topCenter,
                      child: Padding(
                        padding: const EdgeInsets.only(top: 32.0),
                        child: Lottie.asset(
                          'assets/animations/loading.json',
                          height: 120,
                          fit: BoxFit.contain,
                          animate: _isScanning,
                        ),
                      ),
                    ),

                    Center(
                      child: Container(
                        width: 250,
                        height: 250,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: Colors.white.withOpacity(0.8),
                            width: 2,
                          ),
                        ),
                        child: CustomPaint(
                          painter: _ScannerCornersPainter(),
                        ),
                      ),
                    ),

                    Positioned(
                      top: 16,
                      right: 16,
                      child: Column(
                        children: [
                          _ControlButton(
                            icon: _isTorchOn ? LucideIcons.flashlightOff : LucideIcons.flashlight,
                            onPressed: _toggleTorch,
                            tooltip: _isTorchOn ? 'Éteindre le flash' : 'Allumer le flash',
                          ),
                          SizedBox(height: 12),
                          _ControlButton(
                            icon: LucideIcons.rotateCw,
                            onPressed: _switchCamera,
                            tooltip: 'Inverser la caméra',
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              Container(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
                color: Colors.white,
                child: Column(
                  children: [
                    Text(
                      'Positionnez le QR code dans le cadre',
                      style: GoogleFonts.poppins(
                        color: Color(0xFF4A6FA5),
                        fontWeight: FontWeight.w500,
                        fontSize: 16,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Le scan se fera automatiquement',
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

          if (_isLoading)
            Container(
              color: Colors.black.withOpacity(0.7),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          CircularProgressIndicator(color: Color(0xFF8B5FBF)),
                          SizedBox(height: 16),
                          Text(
                            'Traitement du scan...',
                            style: GoogleFonts.poppins(
                              color: Color(0xFF4A6FA5),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _ControlButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onPressed;
  final String tooltip;

  const _ControlButton({
    required this.icon,
    required this.onPressed,
    required this.tooltip,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 50,
      height: 50,
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.6),
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 8,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: IconButton(
        onPressed: onPressed,
        icon: Icon(icon, color: Colors.white, size: 22),
        tooltip: tooltip,
      ),
    );
  }
}

class _ScannerCornersPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Color(0xFF8B5FBF)
      ..strokeWidth = 4;

    const cornerSize = 20.0;

    canvas.drawLine(Offset.zero, Offset(cornerSize, 0), paint);
    canvas.drawLine(Offset.zero, Offset(0, cornerSize), paint);

    canvas.drawLine(Offset(size.width, 0), Offset(size.width - cornerSize, 0), paint);
    canvas.drawLine(Offset(size.width, 0), Offset(size.width, cornerSize), paint);

    canvas.drawLine(Offset(0, size.height), Offset(cornerSize, size.height), paint);
    canvas.drawLine(Offset(0, size.height), Offset(0, size.height - cornerSize), paint);

    canvas.drawLine(Offset(size.width, size.height), Offset(size.width - cornerSize, size.height), paint);
    canvas.drawLine(Offset(size.width, size.height), Offset(size.width, size.height - cornerSize), paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _ScanResultSheet extends StatelessWidget {
  final UserProfile profile;
  const _ScanResultSheet({required this.profile});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 24),

            Row(
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
                          fontSize: 20,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF4A6FA5),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        profile.email.isNotEmpty ? profile.email : 'Aucun email',
                        style: GoogleFonts.poppins(
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            _buildInfoRow(LucideIcons.phone, 'Téléphone', profile.telephone.isNotEmpty ? profile.telephone : 'Non renseigné'),
            _buildInfoRow(LucideIcons.mail, 'Email', profile.email.isNotEmpty ? profile.email : 'Non renseigné'),
            _buildInfoRow(LucideIcons.globe, 'Pays', profile.pays.isNotEmpty ? '${profile.pays} (+${profile.dialCode})' : 'Non renseigné'),
            _buildInfoRow(LucideIcons.cake, 'Date de naissance', profile.dateNaissance.isNotEmpty ? profile.dateNaissance : 'Non renseignée'),
            if (profile.note != null && profile.note!.isNotEmpty)
              _buildInfoRow(LucideIcons.pencil, 'Note', profile.note!),

            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () => Navigator.of(context).pop(),
                style: FilledButton.styleFrom(
                  backgroundColor: Color(0xFF4A6FA5),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  'Fermer',
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: Color(0xFF8B5FBF), size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: GoogleFonts.poppins(
                    color: Colors.grey[600],
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: GoogleFonts.poppins(
                    color: Color(0xFF4A6FA5),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}