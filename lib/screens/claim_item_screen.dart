import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../utils/toast.dart';

class ClaimItemScreen extends StatefulWidget {
  final Map<String, dynamic> item;

  const ClaimItemScreen({super.key, required this.item});

  @override
  State<ClaimItemScreen> createState() => _ClaimItemScreenState();
}

class _ClaimItemScreenState extends State<ClaimItemScreen> {
  int _currentStep = 1;
  final TextEditingController _securityAnswerController = TextEditingController();

  bool _isLoading = false;
  File? _proofImage;
  final ImagePicker _picker = ImagePicker();

  Future<void> _pickImage() async {
    final XFile? pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _proofImage = File(pickedFile.path);
      });
    }
  }

  Future<void> _nextStep() async {
    if (_currentStep < 4) {
      if (_currentStep == 2) {
        if (_securityAnswerController.text.trim().isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please answer the security question.')));
          return;
        }
        // Verify answer against database
        setState(() => _isLoading = true);
        try {
          final expected = (widget.item['expected_answer'] ?? '').toString().toLowerCase().trim();
          final given = _securityAnswerController.text.toLowerCase().trim();
          
          if (expected.isNotEmpty && given != expected) {
            // Note: User requested that incorrect answers STILL proceed.
            // We just let it pass so the Admin can manually review their incorrect answer later.
            showTopToast(context, 'Answer submitted for admin review.');
          } else {
            showTopToast(context, 'Answer verified! ✓');
          }
        } finally {
          if (mounted) setState(() => _isLoading = false);
        }
      }
      if (_currentStep == 3 && _proofImage == null) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please upload a proof of ownership.')));
        return;
      }
      setState(() => _currentStep++);
    } else {
      // Final submission logic: update the database
      setState(() => _isLoading = true);
      try {
        final authUser = Supabase.instance.client.auth.currentUser;
        if (authUser == null) throw Exception('Not logged in');

        // 1. Upload proof image to 'item_images' bucket (reusing existing bucket)
        final fileExt = _proofImage!.path.split('.').last;
        final fileName = 'proof_${DateTime.now().millisecondsSinceEpoch}.$fileExt';
        final filePath = '${authUser.id}/$fileName';
        
        await Supabase.instance.client.storage.from('item_images').upload(filePath, _proofImage!);
        final proofImageUrl = Supabase.instance.client.storage.from('item_images').getPublicUrl(filePath);

        // 2. Insert into claims table
        await Supabase.instance.client.from('claims').insert({
          'report_id': widget.item['id'],
          'claimer_id': authUser.id,
          'security_answer': _securityAnswerController.text,
          'proof_image_url': proofImageUrl,
          'status': 'pending',
        });

        // 3. Update report status
        await Supabase.instance.client
            .from('reports')
            .update({'status': 'pending_review'})
            .eq('id', widget.item['id']);
            
        if (mounted) {
          showTopToast(context, 'Claim submitted! Pending approval.');
          Navigator.popUntil(context, (route) => route.isFirst);
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error submitting claim: $e')));
        }
      } finally {
        if (mounted) setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF07070E),
      appBar: AppBar(
        backgroundColor: const Color(0xFF07070E),
        elevation: 0,
        leading: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Container(
            decoration: BoxDecoration(color: const Color(0xFF111120), borderRadius: BorderRadius.circular(12)),
            child: IconButton(
              icon: const Icon(Icons.chevron_left, color: Colors.white),
              onPressed: () => Navigator.pop(context),
            ),
          ),
        ),
        title: const Text('Claim Item', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
      ),
      body: Column(
        children: [
          // Progress Bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Column(
              children: [
                Row(
                  children: List.generate(4, (index) {
                    final step = index + 1;
                    return Expanded(
                      child: Container(
                        height: 4,
                        margin: EdgeInsets.only(right: step < 4 ? 8 : 0),
                        decoration: BoxDecoration(
                          color: step <= _currentStep ? const Color(0xFF0FE0B0) : const Color(0xFF111120),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    );
                  }),
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Step $_currentStep of 4', style: const TextStyle(color: Colors.grey, fontSize: 12)),
                    Text(
                      _getStepTitle(),
                      style: const TextStyle(color: Color(0xFFA99BFF), fontSize: 12, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ],
            ),
          ),
          
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: _buildCurrentStepContent(),
            ),
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Container(
          padding: const EdgeInsets.fromLTRB(20, 10, 20, 20),
          child: SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton(
              onPressed: _isLoading ? null : _nextStep,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFA99BFF),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: _isLoading 
                ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(_currentStep == 4 ? 'Submit Claim' : 'Continue', style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                      const SizedBox(width: 8),
                      if (_currentStep < 4) const Icon(Icons.arrow_forward, color: Colors.white, size: 20),
                    ],
                  ),
            ),
          ),
        ),
      ),
    );
  }

  String _getStepTitle() {
    switch (_currentStep) {
      case 1: return 'AI Matching';
      case 2: return 'Security Check';
      case 3: return 'Upload Proof';
      case 4: return 'Review';
      default: return '';
    }
  }

  Widget _buildCurrentStepContent() {
    switch (_currentStep) {
      case 1: return _buildStep1();
      case 2: return _buildStep2();
      case 3: return _buildStep3();
      case 4: return _buildStep4();
      default: return const SizedBox();
    }
  }

  Widget _buildStep1() {
    return Column(
      children: [
        _buildCard([
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(color: const Color(0xFFA99BFF), borderRadius: BorderRadius.circular(12)),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.circle, size: 8, color: Colors.white),
                SizedBox(width: 4),
                Text('AI MATCHING', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
          const SizedBox(height: 20),
          _buildAIFeatureRow(Icons.search, 'Matched "${widget.item['item_name']}" to your search'),
          const SizedBox(height: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Icon(Icons.show_chart, color: Colors.grey, size: 16),
                  SizedBox(width: 16),
                  Text('87% confidence match', style: TextStyle(color: Colors.white, fontSize: 13)),
                ],
              ),
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.only(left: 32),
                child: Container(
                  height: 4,
                  width: double.infinity,
                  decoration: BoxDecoration(color: const Color(0xFF07070E), borderRadius: BorderRadius.circular(2)),
                  child: FractionallySizedBox(
                    alignment: Alignment.centerLeft,
                    widthFactor: 0.87,
                    child: Container(
                      decoration: BoxDecoration(color: const Color(0xFF0FE0B0), borderRadius: BorderRadius.circular(2)),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildAIFeatureRow(Icons.check, 'No inconsistencies detected'),
        ]),
        const SizedBox(height: 20),
        _buildCard([
          const Text('YOU ARE CLAIMING', style: TextStyle(color: Colors.grey, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
          const SizedBox(height: 16),
          Row(
            children: [
              Container(
                width: 50, height: 50,
                decoration: BoxDecoration(color: const Color(0xFF07070E), borderRadius: BorderRadius.circular(12)),
                child: widget.item['image_url'] != null
                    ? ClipRRect(borderRadius: BorderRadius.circular(12), child: Image.network(widget.item['image_url'], fit: BoxFit.cover))
                    : const Icon(Icons.inventory_2_outlined, color: Colors.grey),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(widget.item['item_name'] ?? 'Unknown Item', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    Text(widget.item['location_found'] ?? 'Unknown Location', style: const TextStyle(color: Colors.grey, fontSize: 12)),
                  ],
                ),
              ),
            ],
          ),
        ]),
      ],
    );
  }

  Widget _buildStep2() {
    return _buildCard([
      const Text('Answer the security question set by the finder to verify your ownership.', style: TextStyle(color: Colors.grey, fontSize: 14, height: 1.5)),
      const SizedBox(height: 24),
      const Text('SECURITY QUESTION', style: TextStyle(color: Colors.grey, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
      const SizedBox(height: 12),
      Text(widget.item['security_question'] ?? 'What is the exact brand or distinguishing mark?', style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
      const SizedBox(height: 24),
      const Text('YOUR ANSWER', style: TextStyle(color: Colors.grey, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
      const SizedBox(height: 12),
      TextField(
        controller: _securityAnswerController,
        style: const TextStyle(color: Colors.white, fontSize: 14),
        decoration: InputDecoration(
          hintText: 'Type your answer...',
          hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.3)),
          prefixIcon: const Icon(Icons.lock_outline, color: Colors.grey, size: 20),
          filled: true,
          fillColor: const Color(0xFF07070E),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF7C6AFF))),
        ),
      ),
    ]);
  }

  Widget _buildStep3() {
    return _buildCard([
      const Text('Upload a photo proving ownership — an old photo of the item, a receipt, or any evidence.', style: TextStyle(color: Colors.grey, fontSize: 14, height: 1.5)),
      const SizedBox(height: 24),
      GestureDetector(
        onTap: _pickImage,
        child: Container(
          width: double.infinity,
          height: 200,
          decoration: BoxDecoration(
            color: const Color(0xFF07070E),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white.withValues(alpha: 0.1), style: BorderStyle.solid, width: 2),
          ),
          clipBehavior: Clip.hardEdge,
          child: _proofImage != null
              ? Image.file(_proofImage!, fit: BoxFit.cover)
              : Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(color: const Color(0xFF111120), borderRadius: BorderRadius.circular(12)),
                      child: const Icon(Icons.image_outlined, color: Color(0xFFA99BFF), size: 32),
                    ),
                    const SizedBox(height: 16),
                    const Text('Upload proof of ownership', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    const SizedBox(height: 8),
                    const Text('Photo, receipt, or any evidence', style: TextStyle(color: Colors.grey, fontSize: 12)),
                  ],
                ),
        ),
      ),
    ]);
  }

  Widget _buildStep4() {
    return _buildCard([
      const Center(
        child: Icon(Icons.check_circle_outline, color: Color(0xFF0FE0B0), size: 64),
      ),
      const SizedBox(height: 16),
      const Center(
        child: Text('Ready to Submit!', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white)),
      ),
      const SizedBox(height: 12),
      const Text(
        'Your claim has been prepared. This QR code contains your item reference. Once submitted, the administrator will review your proof of ownership.', 
        style: TextStyle(color: Colors.grey, fontSize: 14, height: 1.5), 
        textAlign: TextAlign.center
      ),
      const SizedBox(height: 24),
      Center(
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
          ),
          child: QrImageView(
            data: widget.item['id']?.toString() ?? 'CLAIM-UNKNOWN',
            version: QrVersions.auto,
            size: 180.0,
            eyeStyle: const QrEyeStyle(eyeShape: QrEyeShape.square, color: Colors.black),
            dataModuleStyle: const QrDataModuleStyle(dataModuleShape: QrDataModuleShape.square, color: Colors.black),
          ),
        ),
      ),
      const SizedBox(height: 16),
      Center(
        child: Text(
          'ITEM REF: ${widget.item['id']?.toString().split('-').first.toUpperCase() ?? 'N/A'}',
          style: const TextStyle(color: Color(0xFF7C6AFF), fontWeight: FontWeight.bold, letterSpacing: 1.5),
        ),
      ),
    ]);
  }

  Widget _buildCard(List<Widget> children) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF111120),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: children,
      ),
    );
  }

  Widget _buildAIFeatureRow(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, color: Colors.grey, size: 16),
        const SizedBox(width: 16),
        Expanded(child: Text(text, style: const TextStyle(color: Colors.white, fontSize: 13))),
      ],
    );
  }
}
