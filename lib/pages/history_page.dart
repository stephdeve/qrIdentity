import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:qr_identity/models/scan_record.dart';
import 'package:qr_identity/services/db_service.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';

class HistoryPage extends StatefulWidget {
  static const route = '/history';
  const HistoryPage({super.key});

  @override
  State<HistoryPage> createState() => _HistoryPageState();
}

class _HistoryPageState extends State<HistoryPage> {
  late Future<List<ScanRecord>> _future;

  @override
  void initState() {
    super.initState();
    _future = DBService.instance.getScans();
  }

  Future<void> _reload() async {
    setState(() {
      _future = DBService.instance.getScans();
    });
  }

  Future<void> _clearAll() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Supprimer l\'historique',
          style: GoogleFonts.poppins(
            color: Color(0xFF4A6FA5),
            fontWeight: FontWeight.w600,
          ),
        ),
        content: Text(
          'Êtes-vous sûr de vouloir supprimer tout l\'historique ? Cette action est irréversible.',
          style: GoogleFonts.poppins(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(
              'Annuler',
              style: GoogleFonts.poppins(
                color: Colors.grey[600],
              ),
            ),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: FilledButton.styleFrom(
              backgroundColor: Color(0xFF8B5FBF),
            ),
            child: Text(
              'Supprimer',
              style: GoogleFonts.poppins(
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await DBService.instance.clearAll();
      await _reload();

      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Historique supprimé',
            style: GoogleFonts.poppins(),
          ),
          backgroundColor: Color(0xFF4A6FA5),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Text(
          'Historique des scans',
          style: GoogleFonts.poppins(
            color: Color(0xFF4A6FA5),
            fontWeight: FontWeight.w600,
          ),
        ),
        actions: [
          IconButton(
            onPressed: _clearAll,
            icon: Icon(LucideIcons.trash2, color: Color(0xFF8B5FBF)),
            tooltip: 'Supprimer tout l\'historique',
          )
        ],
      ),
      body: FutureBuilder<List<ScanRecord>>(
        future: _future,
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(color: Color(0xFF8B5FBF)),
                  SizedBox(height: 16),
                  Text(
                    'Chargement de l\'historique...',
                    style: GoogleFonts.poppins(
                      color: Color(0xFF4A6FA5),
                    ),
                  ),
                ],
              ),
            );
          }

          if (!snap.hasData || snap.data!.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    LucideIcons.scan,
                    size: 80,
                    color: Colors.grey[300],
                  ),
                  SizedBox(height: 16),
                  Text(
                    'Aucun scan pour le moment',
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      color: Colors.grey[600],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Les QR codes scannés apparaîtront ici',
                    style: GoogleFonts.poppins(
                      color: Colors.grey[500],
                    ),
                  ),
                  SizedBox(height: 24),
                  FilledButton.icon(
                    onPressed: () => Navigator.of(context).pop(),
                    style: FilledButton.styleFrom(
                      backgroundColor: Color(0xFF4A6FA5),
                    ),
                    icon: Icon(LucideIcons.qrCode, size: 18),
                    label: Text('Scanner un QR code'),
                  ),
                ],
              ),
            );
          }

          final items = snap.data!;
          return Column(
            children: [
              // Header avec compteur
              Container(
                padding: const EdgeInsets.all(16),
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: Color(0xFF4A6FA5).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Color(0xFF4A6FA5).withOpacity(0.2),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(LucideIcons.history, color: Color(0xFF4A6FA5), size: 20),
                    SizedBox(width: 12),
                    Text(
                      '${items.length} scan${items.length > 1 ? 's' : ''}',
                      style: GoogleFonts.poppins(
                        color: Color(0xFF4A6FA5),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: ListView.separated(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  itemCount: items.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final r = items[index];
                    final p = r.profile;
                    final date = DateFormat('dd MMM yyyy, HH:mm').format(r.scannedAt);
                    return _buildScanItem(r, p, date, index);
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildScanItem(ScanRecord record, profile, String date, int index) {
    return Dismissible(
      key: ValueKey(record.id ?? index),
      direction: DismissDirection.endToStart,
      background: Container(
        decoration: BoxDecoration(
          color: Color(0xFF8B5FBF),
          borderRadius: BorderRadius.circular(12),
        ),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: const Icon(LucideIcons.trash2, color: Colors.white, size: 24),
      ),
      confirmDismiss: (direction) async {
        final confirmed = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: Text(
              'Supprimer le scan',
              style: GoogleFonts.poppins(
                color: Color(0xFF4A6FA5),
                fontWeight: FontWeight.w600,
              ),
            ),
            content: Text(
              'Supprimer le scan de ${profile.fullName} ?',
              style: GoogleFonts.poppins(),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: Text(
                  'Annuler',
                  style: GoogleFonts.poppins(
                    color: Colors.grey[600],
                  ),
                ),
              ),
              FilledButton(
                onPressed: () => Navigator.of(context).pop(true),
                style: FilledButton.styleFrom(
                  backgroundColor: Color(0xFF8B5FBF),
                ),
                child: Text(
                  'Supprimer',
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        );
        return confirmed ?? false;
      },
      onDismissed: (_) async {
        if (record.id != null) await DBService.instance.deleteScan(record.id!);
        await _reload();

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Scan supprimé',
              style: GoogleFonts.poppins(),
            ),
            backgroundColor: Color(0xFF4A6FA5),
          ),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
          border: Border.all(
            color: Colors.grey.withOpacity(0.1),
          ),
        ),
        child: ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          leading: Container(
            width: 50,
            height: 50,
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
                size: 20,
              )
                  : null,
            ),
          ),
          title: Text(
            profile.fullName,
            style: GoogleFonts.poppins(
              fontWeight: FontWeight.w600,
              color: Color(0xFF4A6FA5),
            ),
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 4),
              Row(
                children: [
                  Icon(LucideIcons.globe, size: 12, color: Colors.grey[600]),
                  SizedBox(width: 4),
                  Text(
                    '${profile.pays} • +${profile.dialCode}',
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
              SizedBox(height: 2),
              Row(
                children: [
                  Icon(LucideIcons.phone, size: 12, color: Colors.grey[600]),
                  SizedBox(width: 4),
                  Text(
                    profile.telephone,
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
              SizedBox(height: 4),
              Row(
                children: [
                  Icon(LucideIcons.calendar, size: 12, color: Colors.grey[600]),
                  SizedBox(width: 4),
                  Text(
                    date,
                    style: GoogleFonts.poppins(
                      fontSize: 11,
                      color: Colors.grey[500],
                    ),
                  ),
                ],
              ),
            ],
          ),
          trailing: Icon(
            LucideIcons.chevronRight,
            color: Color(0xFF8B5FBF),
            size: 20,
          ),
          onTap: () => _openDetails(profile),
        ),
      ),
    );
  }

  void _openDetails(profile) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
      ),
      isScrollControlled: true,
      builder: (ctx) {
        return Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Center(
                child: Container(
                  width: 60,
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
                          profile.email,
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

              // Informations détaillées
              _detailRow(LucideIcons.phone, 'Téléphone', profile.telephone),
              _detailRow(LucideIcons.mail, 'Email', profile.email),
              _detailRow(LucideIcons.globe, 'Pays', '${profile.pays} (+${profile.dialCode})'),
              _detailRow(LucideIcons.cake, 'Date de naissance', profile.dateNaissance),
              if (profile.note != null && profile.note!.isNotEmpty)
                _detailRow(LucideIcons.pencil, 'Note', profile.note!),

              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () => Navigator.of(ctx).pop(),
                  style: FilledButton.styleFrom(
                    backgroundColor: Color(0xFF4A6FA5),
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
        );
      },
    );
  }

  Widget _detailRow(IconData icon, String label, String value) {
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