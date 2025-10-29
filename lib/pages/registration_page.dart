import 'dart:convert';

import 'package:country_picker/country_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:glassmorphism_ui/glassmorphism_ui.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:lottie/lottie.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:motion_toast/motion_toast.dart';
import 'package:qr_identity/models/user_profile.dart';
import 'package:qr_identity/services/prefs_service.dart';
import 'package:qr_identity/theme/app_theme.dart';

class RegistrationPage extends StatefulWidget {
  static const route = '/register';
  const RegistrationPage({super.key});

  @override
  State<RegistrationPage> createState() => _RegistrationPageState();
}

class _RegistrationPageState extends State<RegistrationPage> {
  final _formKey = GlobalKey<FormState>();
  final _nomCtrl = TextEditingController();
  final _prenomCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _noteCtrl = TextEditingController();

  String? _birthIso;
  Country? _country;
  String? _photoBase64;
  bool _isSubmitting = false;

  @override
  void dispose() {
    _nomCtrl.dispose();
    _prenomCtrl.dispose();
    _phoneCtrl.dispose();
    _emailCtrl.dispose();
    _noteCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickImage(bool camera) async {
    final picker = ImagePicker();
    final XFile? file = await (camera
        ? picker.pickImage(source: ImageSource.camera, imageQuality: 80)
        : picker.pickImage(source: ImageSource.gallery, imageQuality: 80));
    if (file == null) return;
    final bytes = await file.readAsBytes();
    setState(() {
      _photoBase64 = base64Encode(bytes);
    });
  }

  void _selectCountry() {
    showCountryPicker(
      context: context,
      showPhoneCode: true,
      onSelect: (c) {
        final old = _country?.phoneCode;
        setState(() {
          _country = c;
          if (_phoneCtrl.text.isEmpty || _phoneCtrl.text.startsWith('+${old ?? ''}')) {
            _phoneCtrl.text = '+${c.phoneCode}';
          }
        });
      },
    );
  }

  Future<void> _selectBirthDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      firstDate: DateTime(1900),
      lastDate: now,
      initialDate: DateTime(now.year - 18, now.month, now.day),
      helpText: 'Date de naissance',
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: ColorScheme.light(
            primary: AppTheme.lightTheme.colorScheme.primary,
            onPrimary: Colors.white,
            surface: AppTheme.lightTheme.colorScheme.surface,
            onSurface: AppTheme.lightTheme.colorScheme.onSurface,
          ),
          dialogBackgroundColor: Colors.white,
        ),
        child: child!,
      ),
    );
    if (picked != null) {
      setState(() {
        _birthIso = DateFormat('yyyy-MM-dd').format(picked);
      });
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_country == null) {
      MotionToast.warning(
        title: const Text('Pays manquant'),
        description: const Text('Veuillez sélectionner un pays'),
      ).show(context);
      return;
    }
    if (_birthIso == null) {
      MotionToast.warning(
        title: const Text('Date manquante'),
        description: const Text('Veuillez sélectionner une date de naissance'),
      ).show(context);
      return;
    }

    setState(() => _isSubmitting = true);

    final profile = UserProfile(
      photoBase64: _photoBase64,
      nom: _nomCtrl.text.trim(),
      prenom: _prenomCtrl.text.trim(),
      pays: _country!.name,
      isoCode: _country!.countryCode,
      dialCode: _country!.phoneCode,
      telephone: _phoneCtrl.text.trim(),
      email: _emailCtrl.text.trim(),
      dateNaissance: _birthIso!,
      note: _noteCtrl.text.trim().isEmpty ? null : _noteCtrl.text.trim(),
    );

    await Future.delayed(1.seconds); // Simulate processing
    await PrefsService.saveProfile(profile);

    if (!mounted) return;
    setState(() => _isSubmitting = false);

    MotionToast.success(
      title: const Text('Profil enregistré'),
      description: const Text('Votre QR code a été généré avec succès'),
    ).show(context);

    // Navigate to My QR page
    Navigator.of(context).pushReplacementNamed('/');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: AppTheme.mainGradient,
        ),
        child: SafeArea(
          child: Stack(
            children: [
              SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: 12),
                    Text(
                      'QR Identity',
                      style: GoogleFonts.poppins(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                      textAlign: TextAlign.center,
                    ).animate().fadeIn().slideY(),
                    const SizedBox(height: 8),
                    Text(
                      'Créer votre identité numérique',
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        color: Colors.white70,
                      ),
                      textAlign: TextAlign.center,
                    ).animate().fadeIn().slideY(delay: 100.ms),
                    const SizedBox(height: 16),
                    Center(
                      child: Stack(
                        children: [
                          CircleAvatar(
                            radius: 48,
                            backgroundColor: Colors.white24,
                            backgroundImage: _photoBase64 != null
                                ? MemoryImage(base64Decode(_photoBase64!))
                                : null,
                            child: _photoBase64 == null
                                ? const Icon(LucideIcons.user, 
                                    color: Colors.white, size: 48)
                                : null,
                          ).animate().scale(),
                          Positioned(
                            right: 0,
                            bottom: 0,
                            child: PopupMenuButton<int>(
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                              color: Colors.white,
                              onSelected: (i) => _pickImage(i == 0),
                              itemBuilder: (ctx) => [
                                PopupMenuItem(
                                  value: 0,
                                  child: Row(
                                    children: [
                                      const Icon(LucideIcons.camera),
                                      const SizedBox(width: 8),
                                      Text('Appareil photo',
                                          style: GoogleFonts.poppins()),
                                    ],
                                  ),
                                ),
                                PopupMenuItem(
                                  value: 1,
                                  child: Row(
                                    children: [
                                      const Icon(LucideIcons.image),
                                      const SizedBox(width: 8),
                                      Text('Galerie',
                                          style: GoogleFonts.poppins()),
                                    ],
                                  ),
                                ),
                              ],
                              child: Container(
                                padding: const EdgeInsets.all(8),
                                decoration: const BoxDecoration(
                                  color: Colors.white,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(LucideIcons.pencil, 
                                    color: Colors.black87),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    GlassContainer(
                      blur: 10,
                      opacity: 0.2,
                      borderRadius: BorderRadius.circular(24),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Form(
                          key: _formKey,
                          child: Column(
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: TextFormField(
                                      controller: _prenomCtrl,
                                      style: GoogleFonts.poppins(),
                                      decoration: const InputDecoration(
                                        labelText: 'Prénom',
                                        prefixIcon: Icon(LucideIcons.user),
                                      ),
                                      validator: (v) =>
                                          (v == null || v.trim().isEmpty)
                                              ? 'Obligatoire'
                                              : null,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: TextFormField(
                                      controller: _nomCtrl,
                                      style: GoogleFonts.poppins(),
                                      decoration: const InputDecoration(
                                        labelText: 'Nom',
                                      ),
                                      validator: (v) =>
                                          (v == null || v.trim().isEmpty)
                                              ? 'Obligatoire'
                                              : null,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              InkWell(
                                onTap: _selectCountry,
                                child: InputDecorator(
                                  decoration: const InputDecoration(
                                    labelText: 'Pays',
                                    prefixIcon: Icon(LucideIcons.globe),
                                  ),
                                  child: Row(
                                    children: [
                                      Text(
                                        _country?.flagEmoji ?? '🌍',
                                        style: const TextStyle(fontSize: 20),
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                          child: Text(
                                              _country?.name ??
                                                  'Sélectionner un pays',
                                              style: GoogleFonts.poppins())),
                                      if (_country != null)
                                        Text('+${_country!.phoneCode}',
                                            style: GoogleFonts.poppins(
                                                color: Colors.black54)),
                                    ],
                                  ),
                                ),
                              ),
                              const SizedBox(height: 12),
                              TextFormField(
                                controller: _phoneCtrl,
                                style: GoogleFonts.poppins(),
                                keyboardType: TextInputType.phone,
                                decoration: const InputDecoration(
                                  labelText: 'Téléphone',
                                  prefixIcon: Icon(LucideIcons.phone),
                                ),
                                validator: (v) =>
                                    (v == null || v.trim().isEmpty)
                                        ? 'Obligatoire'
                                        : null,
                              ),
                              const SizedBox(height: 12),
                              TextFormField(
                                controller: _emailCtrl,
                                style: GoogleFonts.poppins(),
                                keyboardType: TextInputType.emailAddress,
                                decoration: const InputDecoration(
                                  labelText: 'Email',
                                  prefixIcon: Icon(LucideIcons.mail),
                                ),
                                validator: (v) => (v == null || !v.contains('@'))
                                    ? 'Email invalide'
                                    : null,
                              ),
                              const SizedBox(height: 12),
                              InkWell(
                                onTap: _selectBirthDate,
                                child: InputDecorator(
                                  decoration: const InputDecoration(
                                    labelText: 'Date de naissance',
                                    prefixIcon: Icon(LucideIcons.calendar),
                                  ),
                                  child: Text(
                                    _birthIso ?? 'Sélectionner une date',
                                    style: GoogleFonts.poppins(),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 12),
                              TextFormField(
                                controller: _noteCtrl,
                                style: GoogleFonts.poppins(),
                                maxLines: 3,
                                decoration: const InputDecoration(
                                  labelText: 'Note (facultatif)',
                                  prefixIcon: Icon(LucideIcons.pencil),
                                ),
                              ),
                              const SizedBox(height: 16),
                              SizedBox(
                                width: double.infinity,
                                child: FilledButton(
                                  onPressed: _isSubmitting ? null : _submit,
                                  style: FilledButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(vertical: 14),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    backgroundColor: AppTheme.lightTheme.colorScheme.primary,
                                  ),
                                  child: _isSubmitting
                                      ? const CircularProgressIndicator(
                                          color: Colors.white,
                                        )
                                      : Text(
                                          'Générer mon code QR',
                                          style: GoogleFonts.poppins(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 16,
                                          ),
                                        ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ).animate().fadeIn(delay: 200.ms).slideY(),
                  ],
                ),
              ),
              if (_isSubmitting)
                Center(
                  child: GlassContainer(
                    blur: 20,
                    opacity: 0.7,
                    borderRadius: BorderRadius.circular(24),
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Lottie.asset(
                            'assets/animations/loading.json',
                            width: 120,
                            height: 120,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Création de votre QR...',
                            style: GoogleFonts.poppins(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
