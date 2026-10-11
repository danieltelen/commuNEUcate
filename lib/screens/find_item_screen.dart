import 'package:flutter/material.dart';
import 'browse_screen.dart';

class FindItemScreen extends StatefulWidget {
  const FindItemScreen({super.key});

  @override
  State<FindItemScreen> createState() => _FindItemScreenState();
}

class _FindItemScreenState extends State<FindItemScreen> {
  final TextEditingController _whatController = TextEditingController();
  final TextEditingController _tagsController = TextEditingController();
  final TextEditingController _whereController = TextEditingController();
  final TextEditingController _whenController = TextEditingController();

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
            decoration: BoxDecoration(
              color: const Color(0xFF111120),
              borderRadius: BorderRadius.circular(12),
            ),
            child: IconButton(
              icon: const Icon(Icons.chevron_left, color: Colors.white),
              onPressed: () => Navigator.pop(context),
            ),
          ),
        ),
        title: const Text('Find My Item', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // Form Card
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFF111120),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Describe what you lost and our AI will find matches from the database.',
                    style: TextStyle(color: Colors.grey, fontSize: 14, height: 1.5),
                  ),
                  const SizedBox(height: 24),
                  _buildInputLabel('WHAT DID YOU LOSE?'),
                  _buildTextField(_whatController, 'e.g. Wallet, Keys', Icons.search),
                  const SizedBox(height: 20),
                  _buildInputLabel('ADD TAGS'),
                  _buildTextField(_tagsController, 'e.g. blue, leather', null),
                  const SizedBox(height: 20),
                  _buildInputLabel('WHERE DID YOU LOSE IT?'),
                  _buildTextField(_whereController, 'e.g. Library, Cafeteria', Icons.location_on_outlined),
                  const SizedBox(height: 20),
                  _buildInputLabel('WHEN DID YOU LOSE IT?'),
                  _buildTextField(_whenController, 'DD/MM/YYYY', Icons.calendar_today_outlined, readOnly: true, onTap: () async {
                    DateTime? picked = await showDatePicker(
                      context: context,
                      initialDate: DateTime.now(),
                      firstDate: DateTime(2000),
                      lastDate: DateTime(2100),
                    );
                    if (picked != null) {
                      setState(() {
                        _whenController.text = "${picked.day.toString().padLeft(2, '0')}/${picked.month.toString().padLeft(2, '0')}/${picked.year}";
                      });
                    }
                  }),
                ],
              ),
            ),
            const SizedBox(height: 20),
            // AI Assist Card
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFF111120),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFFA99BFF),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.circle, size: 8, color: Colors.white),
                        SizedBox(width: 4),
                        Text('AI ASSIST', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  _buildAIFeature(Icons.search, 'Matching with unclaimed items in database'),
                  const Divider(color: Colors.white10, height: 32),
                  _buildAIFeature(Icons.generating_tokens_outlined, 'Suggesting likely matches by description'),
                  const Divider(color: Colors.white10, height: 32),
                  _buildAIFeature(Icons.warning_amber_rounded, 'Flagging inconsistencies automatically'),
                ],
              ),
            ),
            const SizedBox(height: 100), // Space for bottom button
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Container(
          color: const Color(0xFF07070E),
          padding: const EdgeInsets.fromLTRB(20, 10, 20, 20),
          child: SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton(
              onPressed: () {
                final queryParts = <String>[];
                if (_whatController.text.isNotEmpty) queryParts.add(_whatController.text.trim());
                if (_tagsController.text.isNotEmpty) queryParts.add(_tagsController.text.trim());
                if (_whereController.text.isNotEmpty) queryParts.add(_whereController.text.trim());
                
                final searchQuery = queryParts.join(' ');
                
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (context) => BrowseScreen(
                      initialSearchQuery: searchQuery,
                      isStandalone: true,
                    ),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFA99BFF),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.search, color: Colors.white),
                  SizedBox(width: 8),
                  Text('Search Items', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInputLabel(String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        label,
        style: const TextStyle(color: Colors.grey, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1.2),
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String hint, IconData? prefixIcon, {bool readOnly = false, VoidCallback? onTap}) {
    return TextField(
      controller: controller,
      readOnly: readOnly,
      onTap: onTap,
      style: const TextStyle(color: Colors.white, fontSize: 14),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.3)),
        prefixIcon: prefixIcon != null ? Icon(prefixIcon, color: Colors.grey, size: 20) : null,
        filled: true,
        fillColor: const Color(0xFF07070E),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF7C6AFF))),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      ),
    );
  }

  Widget _buildAIFeature(IconData icon, String text) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: const Color(0xFF07070E),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: const Color(0xFFA99BFF), size: 20),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Text(text, style: const TextStyle(color: Colors.white, fontSize: 13)),
        ),
      ],
    );
  }
}
