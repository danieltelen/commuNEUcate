import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ReportScreen extends StatefulWidget {
  final Function(int)? onNavigate;

  const ReportScreen({super.key, this.onNavigate});

  @override
  State<ReportScreen> createState() => _ReportScreenState();
}

class _ReportScreenState extends State<ReportScreen> {
  int _currentStep = 0;

  // Step 1
  File? _image;
  final ImagePicker _picker = ImagePicker();

  // Step 2
  final _itemNameController = TextEditingController();
  String? _selectedCategory;
  bool _isCategoryExpanded = false;
  final _locationController = TextEditingController();
  final _dateController = TextEditingController();

  // Step 3
  final _descController = TextEditingController();
  final _tagsController = TextEditingController();

  // Step 4
  final _securityQController = TextEditingController();
  final _securityAController = TextEditingController();

  final List<String> _categories = [
    'Electronics',
    'Accessories',
    'Documents',
    'Clothing',
    'Others',
  ];

  final List<String> _stepTitles = [
    'Upload Photo',
    'Item Details',
    'Description',
    'Security',
    'Review',
    'Finish',
  ];

  // Custom Dropdown Variables
  final LayerLink _layerLink = LayerLink();
  OverlayEntry? _overlayEntry;
  final GlobalKey _categoryKey = GlobalKey();

  @override
  void dispose() {
    _removeOverlay();
    _itemNameController.dispose();
    _locationController.dispose();
    _dateController.dispose();
    _descController.dispose();
    _tagsController.dispose();
    _securityQController.dispose();
    _securityAController.dispose();
    super.dispose();
  }

  void _removeOverlay() {
    if (_overlayEntry != null) {
      _overlayEntry!.remove();
      _overlayEntry = null;
      if (mounted) setState(() => _isCategoryExpanded = false);
    }
  }

  void _toggleDropdown() {
    if (_isCategoryExpanded) {
      _removeOverlay();
    } else {
      _overlayEntry = _createOverlayEntry();
      Overlay.of(context).insert(_overlayEntry!);
      setState(() => _isCategoryExpanded = true);
    }
  }

  OverlayEntry _createOverlayEntry() {
    RenderBox renderBox =
        _categoryKey.currentContext!.findRenderObject() as RenderBox;
    var size = renderBox.size;

    return OverlayEntry(
      builder: (context) => Stack(
        children: [
          // Background detector to close dropdown when tapping outside
          Positioned.fill(
            child: GestureDetector(
              behavior: HitTestBehavior.translucent,
              onTap: _removeOverlay,
              child: Container(color: Colors.transparent),
            ),
          ),
          Positioned(
            width: size.width,
            child: CompositedTransformFollower(
              link: _layerLink,
              showWhenUnlinked: false,
              offset: Offset(0.0, size.height), // Directly below the header
              child: Material(
                elevation: 0,
                color: Colors.transparent,
                child: Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFF111120),
                    borderRadius: const BorderRadius.vertical(
                      bottom: Radius.circular(12),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.3),
                        blurRadius: 10,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: _categories.map((category) {
                      bool isSelected = _selectedCategory == category;
                      return InkWell(
                        onTap: () {
                          setState(() {
                            _selectedCategory = category;
                          });
                          _removeOverlay();
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 14,
                          ),
                          color: isSelected
                              ? const Color(0xFF7C6AFF).withValues(alpha: 0.1)
                              : Colors.transparent,
                          child: Text(
                            category,
                            style: TextStyle(
                              color: isSelected
                                  ? const Color(0xFF7C6AFF)
                                  : Colors.grey[300],
                              fontSize: 15,
                              fontWeight: isSelected
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _pickImage() async {
    final XFile? pickedFile = await _picker.pickImage(
      source: ImageSource.gallery,
    );
    if (pickedFile != null) {
      setState(() {
        _image = File(pickedFile.path);
      });
    }
  }

  bool _isSubmitting = false;
  String _generatedReportId = 'RPT-5271'; // Default placeholder

  Future<void> _submitReport() async {
    if (_image == null ||
        _itemNameController.text.isEmpty ||
        _selectedCategory == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please upload an image and fill required fields'),
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);
    try {
      final authUser = Supabase.instance.client.auth.currentUser;
      if (authUser == null) throw Exception('Not logged in');

      // 1. Upload image to storage
      final fileExt = _image!.path.split('.').last;
      final fileName = '${DateTime.now().millisecondsSinceEpoch}.$fileExt';
      final filePath = '${authUser.id}/$fileName';

      await Supabase.instance.client.storage
          .from('item_images')
          .upload(filePath, _image!);
      final imageUrl = Supabase.instance.client.storage
          .from('item_images')
          .getPublicUrl(filePath);

      // 2. Insert record into reports table
      // Parse date loosely or fallback to today
      String parsedDate = DateTime.now().toIso8601String().split('T').first;
      try {
        if (_dateController.text.isNotEmpty) {
          // If they typed mm/dd/yyyy we can't blindly pass it to postgres.
          // For safety, fallback to now.
          parsedDate = DateTime.now().toIso8601String().split('T').first;
        }
      } catch (_) {}

      final response = await Supabase.instance.client
          .from('reports')
          .insert({
            'reporter_id': authUser.id,
            'item_name': _itemNameController.text,
            'category': _selectedCategory,
            'location_found': _locationController.text,
            'date_found': parsedDate,
            'description': _descController.text,
            'tags': _tagsController.text,
            'security_question': _securityQController.text,
            'image_url': imageUrl,
            'status': 'pending_review',
          })
          .select()
          .single();

      try {
        await Supabase.instance.client.from('report_secrets').insert({
          'report_id': response['id'],
          'expected_answer': _securityAController.text.trim(),
        });
      } catch (_) {
        await Supabase.instance.client.from('reports').delete().eq('id', response['id']);
        rethrow;
      }

      final reportIdRaw = response['id']
          .toString()
          .split('-')
          .first
          .toUpperCase();

      if (mounted) {
        setState(() {
          _generatedReportId = 'RPT-$reportIdRaw';
          _currentStep++;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to submit: $e')));
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  void _nextStep() {
    _removeOverlay();

    if (_currentStep == 4) {
      _submitReport();
      return;
    }

    if (_currentStep < 5) {
      setState(() {
        _currentStep++;
      });
    } else {
      // Reset form and go back to Step 1 when "Done" is clicked
      setState(() {
        _currentStep = 0;
        _image = null;
        _itemNameController.clear();
        _locationController.clear();
        _dateController.clear();
        _descController.clear();
        _tagsController.clear();
        _securityQController.clear();
        _securityAController.clear();
        _selectedCategory = null;
      });
      // Automatically jump to the Browse Tab!
      widget.onNavigate?.call(1);
    }
  }

  void _prevStep() {
    _removeOverlay();
    if (_currentStep > 0 && _currentStep < 5) {
      // Disable back button on Done screen
      setState(() {
        _currentStep--;
      });
    }
  }

  Widget _buildTextField(
    String label,
    String hint,
    TextEditingController controller, {
    int maxLines = 1,
    IconData? prefixIcon,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Colors.grey,
            fontSize: 12,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          maxLines: maxLines,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(color: Colors.grey.withValues(alpha: 0.5)),
            filled: true,
            fillColor: const Color(0xFF111120),
            prefixIcon: prefixIcon != null
                ? Icon(prefixIcon, color: Colors.grey, size: 20)
                : null,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFF7C6AFF)),
            ),
          ),
        ),
        const SizedBox(height: 20),
      ],
    );
  }

  Widget _buildStep1() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        GestureDetector(
          onTap: _pickImage,
          child: Container(
            height: 220,
            decoration: BoxDecoration(
              color: const Color(0xFF111120),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.1),
                style: BorderStyle.solid,
              ),
            ),
            clipBehavior: Clip.hardEdge,
            child: _image != null
                ? Image.file(_image!, fit: BoxFit.cover)
                : Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFF7C6AFF).withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.camera_alt_outlined,
                          size: 32,
                          color: Color(0xFF7C6AFF),
                        ),
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Take or Upload Photo',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'A clear photo helps identify the item faster',
                        style: TextStyle(color: Colors.grey, fontSize: 12),
                      ),
                    ],
                  ),
          ),
        ),
        const SizedBox(height: 24),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: const Color(0xFF111120),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFF7C6AFF),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.auto_awesome, size: 14, color: Colors.white),
                    SizedBox(width: 4),
                    Text(
                      'AI ASSIST',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              _buildListTile(
                Icons.search,
                'Will analyze physical aspects from photo',
              ),
              const Divider(color: Colors.white10, height: 24),
              _buildListTile(
                Icons.image_outlined,
                'Auto-suggests item description',
              ),
              const Divider(color: Colors.white10, height: 24),
              _buildListTile(Icons.bolt, 'Flags potential matches instantly'),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildListTile(IconData icon, String text) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: const Color(0xFF7C6AFF).withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: const Color(0xFF7C6AFF), size: 18),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(color: Colors.white, fontSize: 13),
          ),
        ),
      ],
    );
  }

  Widget _buildStep2() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: const Color(0xFF07070E),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildTextField(
                'ITEM NAME / TYPE',
                'e.g. iPhone 15, Black Wallet...',
                _itemNameController,
              ),
              const Text(
                'CATEGORY',
                style: TextStyle(
                  color: Colors.grey,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              CompositedTransformTarget(
                link: _layerLink,
                child: Container(
                  key: _categoryKey,
                  decoration: BoxDecoration(
                    color: const Color(0xFF111120),
                    borderRadius: _isCategoryExpanded
                        ? const BorderRadius.vertical(top: Radius.circular(12))
                        : BorderRadius.circular(12),
                  ),
                  child: InkWell(
                    onTap: _toggleDropdown,
                    borderRadius: _isCategoryExpanded
                        ? const BorderRadius.vertical(top: Radius.circular(12))
                        : BorderRadius.circular(12),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 16,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            _selectedCategory ?? 'Select category',
                            style: TextStyle(
                              color: _selectedCategory == null
                                  ? Colors.grey.withValues(alpha: 0.5)
                                  : Colors.white,
                              fontSize: 16,
                            ),
                          ),
                          Icon(
                            _isCategoryExpanded
                                ? Icons.keyboard_arrow_up_rounded
                                : Icons.keyboard_arrow_down_rounded,
                            color: Colors.grey,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              _buildTextField(
                'WHERE DID YOU FIND IT?',
                'Building, area, landmark...',
                _locationController,
                prefixIcon: Icons.location_on_outlined,
              ),
              _buildTextField(
                'DATE FOUND',
                '02/05/2026',
                _dateController,
                prefixIcon: Icons.calendar_today_outlined,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStep3() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: const Color(0xFF07070E),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'These details will be publicly visible to help owners identify the item.',
                style: TextStyle(color: Colors.grey, fontSize: 13),
              ),
              const SizedBox(height: 24),
              _buildTextField(
                'BRIEF DESCRIPTION',
                'Color, brand, condition, notable features...',
                _descController,
                maxLines: 4,
              ),
              _buildTextField('TAGS', 'Add tags, press Enter', _tagsController),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStep4() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: const Color(0xFF07070E),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Set a secret question that only the real owner can answer — this protects against false claims.',
                style: TextStyle(color: Colors.grey, fontSize: 13, height: 1.5),
              ),
              const SizedBox(height: 24),
              _buildTextField(
                'SECURITY QUESTION',
                'e.g. What color is the phone case?',
                _securityQController,
              ),
              _buildTextField(
                'EXPECTED ANSWER',
                'The correct answer...',
                _securityAController,
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: const Color(0xFF111120),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFF7C6AFF),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Text(
                  'AI TIP',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: 20),
              _buildListTile(
                Icons.help_outline,
                'Ask something only the true owner would know',
              ),
              const Divider(color: Colors.white10, height: 24),
              _buildListTile(
                Icons.lock_outline,
                'Avoid obvious or guessable answers',
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStep5() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFF111120),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'REVIEW YOUR REPORT',
            style: TextStyle(
              color: Colors.grey,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 24),
          _buildReviewRow(
            'Item',
            _itemNameController.text.isEmpty ? 'N/A' : _itemNameController.text,
          ),
          const Divider(color: Colors.white10, height: 24),
          _buildReviewRow('Category', _selectedCategory ?? 'N/A'),
          const Divider(color: Colors.white10, height: 24),
          _buildReviewRow(
            'Location',
            _locationController.text.isEmpty ? 'N/A' : _locationController.text,
          ),
          const Divider(color: Colors.white10, height: 24),
          _buildReviewRow(
            'Date',
            _dateController.text.isEmpty ? 'N/A' : _dateController.text,
          ),
          const Divider(color: Colors.white10, height: 24),
          _buildReviewRow(
            'Tags',
            _tagsController.text.isEmpty ? 'None' : _tagsController.text,
          ),
          const Divider(color: Colors.white10, height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Status',
                style: TextStyle(color: Colors.grey, fontSize: 14),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: Colors.orange.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text(
                  'Pending Review',
                  style: TextStyle(
                    color: Colors.orange,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildReviewRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: Colors.grey, fontSize: 14)),
        const SizedBox(width: 16),
        Expanded(
          child: Text(
            value,
            textAlign: TextAlign.end,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStep6() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const SizedBox(height: 40),
        Container(
          width: 140,
          height: 140,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: const Color(0xFF0FE0B0).withValues(alpha: 0.1),
          ),
          child: Center(
            child: Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF0FE0B0).withValues(alpha: 0.2),
              ),
              child: Center(
                child: Container(
                  width: 70,
                  height: 70,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: Color(0xFF0FE0B0),
                  ),
                  child: const Icon(
                    Icons.check,
                    color: Color(0xFF07070E),
                    size: 40,
                  ),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 32),
        const Text(
          'Submitted to QRAS!',
          style: TextStyle(
            color: Colors.white,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        const Text(
          'Your report is live. The rightful owner will be notified when they search for this item.',
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.grey, fontSize: 14, height: 1.5),
        ),
        const SizedBox(height: 40),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
          decoration: BoxDecoration(
            color: const Color(0xFF111120),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
          ),
          child: Column(
            children: [
              const Text(
                'REPORT ID',
                style: TextStyle(
                  color: Colors.grey,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _generatedReportId,
                style: const TextStyle(
                  color: Color(0xFF7C6AFF),
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.2,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF07070E),

      body: SafeArea(
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  if (_currentStep < 5) // Hide back button on Done screen
                    InkWell(
                      onTap: _prevStep,
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: const Color(0xFF111120),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.chevron_left,
                          color: Colors.white,
                          size: 24,
                        ),
                      ),
                    )
                  else
                    const SizedBox(
                      width: 44,
                    ), // Placeholder to keep title centered if desired, or just space
                  const SizedBox(width: 16),
                  const Text(
                    'Report Found Item',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),

            // Progress Bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              child: Column(
                children: [
                  Row(
                    children: List.generate(6, (index) {
                      Color boxColor = const Color(0xFF111120);
                      if (index < _currentStep) {
                        boxColor = const Color(0xFF7C6AFF);
                      } else if (index == _currentStep) {
                        boxColor = const Color(0xFF0FE0B0);
                      }

                      return Expanded(
                        child: Container(
                          margin: const EdgeInsets.symmetric(horizontal: 2),
                          height: 4,
                          decoration: BoxDecoration(
                            color: boxColor,
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
                      Text(
                        'Step ${_currentStep + 1} of 6',
                        style: const TextStyle(
                          color: Colors.grey,
                          fontSize: 12,
                        ),
                      ),
                      Text(
                        _stepTitles[_currentStep],
                        style: const TextStyle(
                          color: Color(0xFFA99BFF),
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: _currentStep == 0
                    ? _buildStep1()
                    : _currentStep == 1
                    ? _buildStep2()
                    : _currentStep == 2
                    ? _buildStep3()
                    : _currentStep == 3
                    ? _buildStep4()
                    : _currentStep == 4
                    ? _buildStep5()
                    : _buildStep6(),
              ),
            ),

            // Bottom Button
            Padding(
              padding: const EdgeInsets.all(20),
              child: ElevatedButton(
                onPressed: _isSubmitting ? null : _nextStep,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF7C6AFF),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                ),
                child: _isSubmitting
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            _currentStep == 4
                                ? 'Submit Report'
                                : _currentStep == 5
                                ? 'Done'
                                : 'Continue',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(width: 8),
                          if (_currentStep < 5)
                            const Icon(
                              Icons.arrow_forward,
                              color: Colors.white,
                              size: 20,
                            ),
                        ],
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
