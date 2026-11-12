import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/config/app_config.dart';
import '../../core/services/supabase_service.dart';

class OrganizationsDirectoryScreen extends StatefulWidget {
  const OrganizationsDirectoryScreen({super.key});

  @override
  State<OrganizationsDirectoryScreen> createState() => _OrganizationsDirectoryScreenState();
}

class _OrganizationsDirectoryScreenState extends State<OrganizationsDirectoryScreen> {
  List<Map<String, dynamic>> _orgs = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchOrgs();
  }

  Future<void> _fetchOrgs() async {
    try {
      final res = await SupabaseService.client
          .from('organizations')
          .select()
          .order('name');
      setState(() {
        _orgs = (res as List<dynamic>).map((e) => Map<String, dynamic>.from(e as Map)).toList();
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Blood Banks & Organizations')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _orgs.length,
              itemBuilder: (context, index) {
                final org = _orgs[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: AppConfig.primaryColor.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Icon(Icons.local_hospital, color: Color(0xFFC62828)),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Flexible(
                                        child: Text(
                                          org['name'] ?? '',
                                          style: const TextStyle(
                                            fontWeight: FontWeight.w800,
                                            fontSize: 15,
                                          ),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                      if (org['is_verified'] == true) ...[
                                        const SizedBox(width: 4),
                                        const Icon(Icons.verified, color: Color(0xFF16A34A), size: 16),
                                      ],
                                    ],
                                  ),
                                  Text(
                                    '${org['district'] ?? ''}, Bangladesh',
                                    style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        if (org['address'] != null) ...[
                          const SizedBox(height: 10),
                          Text(
                            org['address'],
                            style: TextStyle(color: Colors.grey.shade700, fontSize: 13),
                          ),
                        ],
                        const SizedBox(height: 12),
                        if (org['contact_phone'] != null) ...[
                          SizedBox(
                            width: double.infinity,
                            child: OutlinedButton.icon(
                              onPressed: () => launchUrl(Uri.parse('tel:${org['contact_phone']}')),
                              icon: const Icon(Icons.call, size: 16),
                              label: Text('Call ${org['contact_phone']}'),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}
