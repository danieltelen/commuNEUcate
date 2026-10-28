import 'dart:io';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:image_picker/image_picker.dart';
import '../utils/toast.dart';

class EditReportScreen extends StatefulWidget {
  final Map<String, dynamic> item;

  const EditReportScreen({super.key, required this.item});

  @override
  State<EditReportScreen> createState() => _EditReportScreenState();
}

class _EditReportScreenState extends State<EditReportScreen> {
  late TextEditingController _nameController;
  late TextEditingController _locationController;
  late TextEditingController _descController;
  late TextEditingController _tagsController;
  late TextEditingController _securityQuestionController;
  late TextEditingController _expectedAnswerController;
  String? _selectedCategory;
  bool _isLoading = false;
  bool _isLoadingSecret = true;
  File? _image;
  final ImagePicker _picker = ImagePicker();

  final List<String> _categories = [
    'Electronics',
    'Accessories',
    'Documents',
    'Clothing',
    'Others',
  ];

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.item['item_name']);
    _locationController = TextEditingController(text: widget.item['location_found']);
    _descController = TextEditingController(text: widget.item['description']);
    _tagsController = TextEditingController(text: widget.item['tags']);
    _securityQuestionController = TextEditingController(text: widget.item['security_question']);
    _expectedAnswerController = TextEditingController();
    _selectedCategory = widget.item['category'];
    _loadExpectedAnswer();
  }

  Future<void> _loadExpectedAnswer() async {
    try {
      final secret = await Supabase.instance.client
          .from('report_secrets')
          .select('expected_answer')
          .eq('report_id', widget.item['id'])
          .maybeSingle();
      if (mounted && secret != null) {
        _expectedAnswerController.text = secret['expected_answer']?.toString() ?? '';
      }
    } catch (_) {
      // Keep the field editable if the existing report has no secret row.
    } finally {
      if (mounted) setState(() => _isLoadingSecret = false);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _locationController.dispose();
    _descController.dispose();
    _tagsController.dispose();
    _securityQuestionController.dispose();
    _expectedAnswerController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final XFile? pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _image = File(pickedFile.path);
      });
    }
  }

  Future<void> _updateReport() async {
    if (_nameController.text.trim().isEmpty) {
      showTopToast(context, 'Item name is required');
      return;
    }

    setState(() => _isLoading = true);
    try {
      String? newImageUrl;
      if (_image != null) {
        final authUser = Supabase.instance.client.auth.currentUser;
        if (authUser != null) {
          final fileExt = _image!.path.split('.').last;
          final fileName = 'edited_${DateTime.now().millisecondsSinceEpoch}.$fileExt';
          final filePath = '${authUser.id}/$fileName';
          
          await Supabase.instance.client.storage.from('item_images').upload(filePath, _image!);
          newImageUrl = Supabase.instance.client.storage.from('item_images').getPublicUrl(filePath);
        }
      }

      final isRevalidation = widget.item['status'] == 'rejected';
      final Map<String, dynamic> updateData = {
        'item_name': _nameController.text.trim(),
        'location_found': _locationController.text.trim(),
        'description': _descController.text.trim(),
        'tags': _tagsController.text.trim(),
        'security_question': _securityQuestionController.text.trim(),
        'category': _selectedCategory,
      };

      if (isRevalidation) {
        updateData.addAll({
          'status': 'pending_review',
          'revalidation_count': ((widget.item['revalidation_count'] as num?)?.toInt() ?? 0) + 1,
          'review_note': null,
          'reviewed_at': null,
          'reviewed_by': null,
        });
      }

      if (newImageUrl != null) {
        updateData['image_url'] = newImageUrl;
      }

      await Supabase.instance.client.from('report_secrets').upsert({
        'report_id': widget.item['id'],
        'expected_answer': _expectedAnswerController.text.trim(),
      });
      await Supabase.instance.client.from('reports').update(updateData).eq('id', widget.item['id']);

      if (mounted) {
        showTopToast(context, isRevalidation ? 'Report resubmitted for review.' : 'Edit successfully!');
        Navigator.pop(context, true); // Return true to indicate success
      }
    } catch (e) {
      if (mounted) {
        showTopToast(context, 'Failed to edit report: $e');
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
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
        title: Text(widget.item['status'] == 'rejected' ? 'Update & Resubmit' : 'Edit Report', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
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
                  GestureDetector(
                    onTap: _pickImage,
                    child: Container(
                      width: double.infinity,
                      height: 200,
                      margin: const EdgeInsets.only(bottom: 24),
                      decoration: BoxDecoration(
                        color: const Color(0xFF07070E),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
                        image: _image != null
                            ? DecorationImage(image: FileImage(_image!), fit: BoxFit.cover)
                            : (widget.item['image_url'] != null
                                ? DecorationImage(image: NetworkImage(widget.item['image_url']), fit: BoxFit.cover)
                                : null),
                      ),
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          if (_image == null && widget.item['image_url'] == null)
                            const Icon(Icons.add_a_photo_outlined, color: Colors.grey, size: 48),
                          Positioned(
                            bottom: 12,
                            right: 12,
                            child: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: const Color(0xFF7C6AFF),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Icon(Icons.edit, color: Colors.white, size: 16),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  _buildTextField('ITEM NAME', _nameController),
                  const Text('CATEGORY', style: TextStyle(color: Colors.grey, fontSize: 12, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                      color: const Color(0xFF07070E),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: _selectedCategory,
                        dropdownColor: const Color(0xFF111120),
                        isExpanded: true,
                        icon: const Icon(Icons.keyboard_arrow_down, color: Colors.grey),
                        style: const TextStyle(color: Colors.white, fontSize: 16),
                        onChanged: (String? newValue) {
                          setState(() {
                            _selectedCategory = newValue;
                          });
                        },
                        items: _categories.map<DropdownMenuItem<String>>((String value) {
                          return DropdownMenuItem<String>(
                            value: value,
                            child: Text(value),
                          );
                        }).toList(),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  _buildTextField('LOCATION FOUND', _locationController),
                  _buildTextField('DESCRIPTION', _descController, maxLines: 4),
                  _buildTextField('SECURITY QUESTION (e.g. What is the wallpaper?)', _securityQuestionController),
                  _buildTextField('EXPECTED ANSWER', _expectedAnswerController),
                  _buildTextField('TAGS (Comma separated)', _tagsController),
                ],
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Container(
          padding: const EdgeInsets.fromLTRB(20, 10, 20, 20),
          child: SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton(
              onPressed: _isLoading ? null : _updateReport,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0FE0B0),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: _isLoading || _isLoadingSecret
                  ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Color(0xFF07070E), strokeWidth: 2))
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(widget.item['status'] == 'rejected' ? 'Resubmit for Review' : 'Save Changes', style: const TextStyle(color: Color(0xFF07070E), fontSize: 16, fontWeight: FontWeight.bold)),
                        const SizedBox(width: 8),
                        const Icon(Icons.save, color: Color(0xFF07070E), size: 20),
                      ],
                    ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(String label, TextEditingController controller, {int maxLines = 1}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(color: Colors.grey, fontSize: 12, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          TextField(
            controller: controller,
            maxLines: maxLines,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              filled: true,
              fillColor: const Color(0xFF07070E),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Color(0xFF7C6AFF)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
