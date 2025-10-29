import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:qr_identity/models/scan_record.dart';
import 'package:qr_identity/services/db_service.dart';

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
    await DBService.instance.clearAll();
    await _reload();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Historique'),
        actions: [
          IconButton(onPressed: _clearAll, icon: const Icon(Icons.delete_forever))
        ],
      ),
      body: FutureBuilder<List<ScanRecord>>(
        future: _future,
        builder: (context, snap) {
          if (!snap.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final items = snap.data!;
          if (items.isEmpty) {
            return const Center(child: Text('Aucun scan pour le moment'));
          }
          return ListView.separated(
            itemCount: items.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final r = items[index];
              final p = r.profile;
              final date = DateFormat('dd MMM yyyy, HH:mm').format(r.scannedAt);
              return Dismissible(
                key: ValueKey(r.id ?? index),
                direction: DismissDirection.endToStart,
                background: Container(
                  color: Colors.red,
                  alignment: Alignment.centerRight,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: const Icon(Icons.delete, color: Colors.white),
                ),
                onDismissed: (_) async {
                  if (r.id != null) await DBService.instance.deleteScan(r.id!);
                  await _reload();
                },
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundImage: p.photoBase64 != null ? MemoryImage(base64Decode(p.photoBase64!)) : null,
                    child: p.photoBase64 == null ? const Icon(Icons.person) : null,
                  ),
                  title: Text(p.fullName),
                  subtitle: Text('${p.pays}  •  ${p.telephone}\n$date'),
                  isThreeLine: true,
                  onTap: () => _openDetails(p),
                ),
              );
            },
          );
        },
      ),
    );
  }

  void _openDetails(profile) {
    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: Text(profile.fullName),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _row('Pays', '${profile.pays} (+${profile.dialCode})'),
              _row('Téléphone', profile.telephone),
              _row('Email', profile.email),
              _row('Naissance', profile.dateNaissance),
              if (profile.note != null) _row('Note', profile.note),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('Fermer')),
          ],
        );
      },
    );
  }

  Widget _row(String k, String v) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        children: [
          SizedBox(width: 110, child: Text(k, style: const TextStyle(color: Colors.black54))),
          Expanded(child: Text(v)),
        ],
      ),
    );
  }
}
