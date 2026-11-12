import 'package:flutter/material.dart';
import '../../core/config/app_config.dart';
import '../../core/services/supabase_service.dart';
import '../../shared/widgets/blood_group_badge.dart';

class ScanDonorIdScreen extends StatefulWidget {
  const ScanDonorIdScreen({super.key});

  @override
  State<ScanDonorIdScreen> createState() => _ScanDonorIdScreenState();
}

class _ScanDonorIdScreenState extends State<ScanDonorIdScreen> {
  final _idInputController = TextEditingController();
  Map<String, dynamic>? _verifiedDonor;
  bool _isLoading = false;
  String? _errorMessage;

  Future<void> _verifyId(String rawId) async {
    // If QR contains full URL, extract last path segment
    String idNumber = rawId.trim();
    if (idNumber.contains('/')) {
      idNumber = idNumber.split('/').last;
    }

    if (idNumber.isEmpty) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _verifiedDonor = null;
    });

    try {
      final res = await SupabaseService.verifyDonorId(idNumber);
      setState(() {
        _isLoading = false;
        if (res != null) {
          _verifiedDonor = res;
        } else {
          _errorMessage = 'No verified donor found matching "$idNumber".';
        }
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Verification error: $e';
      });
    }
  }

  @override
  void dispose() {
    _idInputController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Verify Donor ID')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'National Donor Credential Check',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 6),
            Text(
              'Enter the Digital Donor ID number (e.g. BB-CTG-000001) or scan their digital card QR code.',
              style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
            ),
            const SizedBox(height: 20),

            // ID Input Field
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _idInputController,
                    textCapitalization: TextCapitalization.characters,
                    decoration: const InputDecoration(
                      labelText: 'Donor ID Number',
                      hintText: 'BB-DHA-000001',
                      prefixIcon: Icon(Icons.badge_outlined),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                ElevatedButton(
                  onPressed: _isLoading ? null : () => _verifyId(_idInputController.text),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppConfig.primaryColor,
                    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
                  ),
                  child: const Text('Verify'),
                ),
              ],
            ),

            const SizedBox(height: 24),

            if (_isLoading) ...[
              const Center(child: CircularProgressIndicator()),
            ] else if (_errorMessage != null) ...[
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFFEE2E2),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFFCA5A5)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.cancel, color: Color(0xFFDC2626), size: 24),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        _errorMessage!,
                        style: const TextStyle(color: Color(0xFF991B1B), fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ),
              ),
            ] else if (_verifiedDonor != null) ...[
              // Verified Card Display
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0xFF16A34A), width: 2),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.green.withOpacity(0.1),
                      blurRadius: 16,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Row(
                          children: [
                            Icon(Icons.verified, color: Color(0xFF16A34A), size: 24),
                            SizedBox(width: 8),
                            Text(
                              'VERIFIED VOLUNTARY DONOR',
                              style: TextStyle(
                                color: Color(0xFF16A34A),
                                fontWeight: FontWeight.w800,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                        BloodGroupBadge(
                          bloodGroup: _verifiedDonor!['blood_group'] ?? 'O+',
                          isLarge: true,
                        ),
                      ],
                    ),
                    const Divider(height: 24),
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(
                        _verifiedDonor!['full_name'] ?? 'Donor',
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
                      ),
                      subtitle: Text(
                        'ID: ${_verifiedDonor!['donor_id_number']}',
                        style: const TextStyle(fontWeight: FontWeight.w700, color: Color(0xFF0D1B2A)),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF8FAFC),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('Total Verified', style: TextStyle(fontSize: 11, color: Colors.grey)),
                                Text(
                                  '${_verifiedDonor!['total_verified_donations'] ?? 0} Donations',
                                  style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF8FAFC),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('District', style: TextStyle(fontSize: 11, color: Colors.grey)),
                                Text(
                                  _verifiedDonor!['district'] ?? 'Bangladesh',
                                  style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
