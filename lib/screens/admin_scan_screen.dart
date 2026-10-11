import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'item_details_screen.dart';
import '../utils/toast.dart';

class AdminScanScreen extends StatefulWidget {
  const AdminScanScreen({super.key});

  @override
  State<AdminScanScreen> createState() => _AdminScanScreenState();
}

class _AdminScanScreenState extends State<AdminScanScreen> {
  final MobileScannerController controller = MobileScannerController();
  bool _isProcessing = false;
  bool _hasPermission = false;

  @override
  void initState() {
    super.initState();
    _checkPermission();
  }

  Future<void> _checkPermission() async {
    final status = await Permission.camera.request();
    if (mounted) {
      setState(() {
        _hasPermission = status.isGranted;
      });
    }
  }

  void _onDetect(BarcodeCapture capture) async {
    if (_isProcessing) return;
    final List<Barcode> barcodes = capture.barcodes;
    if (barcodes.isNotEmpty) {
      final String code = barcodes.first.rawValue ?? '';
      if (code.isNotEmpty) {
        setState(() => _isProcessing = true);
        controller.stop();
        
        try {
          final parsedId = int.tryParse(code);
          
          if (parsedId != null) {
            final res = await Supabase.instance.client.from('reports').select('*').eq('id', parsedId).maybeSingle();
            if (res != null) {
              if (mounted) {
                showTopToast(context, 'Item Found!');
                Navigator.push(context, MaterialPageRoute(builder: (context) => ItemDetailsScreen(item: res))).then((_) {
                  if (mounted) {
                    setState(() => _isProcessing = false);
                    controller.start();
                  }
                });
              }
            } else {
              _showError('Item not found in database.');
            }
          } else {
            final res = await Supabase.instance.client.from('profiles').select('*').eq('id', code).maybeSingle();
            if (res != null) {
              if (mounted) {
                showTopToast(context, 'Scanned User: ${res['full_name'] ?? res['email']}');
                Future.delayed(const Duration(seconds: 2), () {
                  if (mounted) {
                    setState(() => _isProcessing = false);
                    controller.start();
                  }
                });
              }
            } else {
              _showError('Invalid QR Code.');
            }
          }
        } catch (e) {
          _showError('Error reading QR Code.');
        }
      }
    }
  }

  void _showError(String msg) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg), backgroundColor: Colors.red));
      Future.delayed(const Duration(seconds: 2), () {
        if (mounted) {
          setState(() => _isProcessing = false);
          controller.start();
        }
      });
    }
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_hasPermission) {
      return Scaffold(
        backgroundColor: Colors.black,
        appBar: AppBar(title: const Text('Scan to Claim')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.camera_alt_outlined, size: 64, color: Colors.grey),
              const SizedBox(height: 16),
              const Text('Camera permission is required', style: TextStyle(color: Colors.white)),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _checkPermission,
                child: const Text('Request Permission'),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(title: const Text('Scan to Claim'), automaticallyImplyLeading: false),
      body: Stack(
        children: [
          MobileScanner(
            controller: controller,
            onDetect: _onDetect,
          ),
          if (_isProcessing)
            const Center(
              child: CircularProgressIndicator(color: Color(0xFF0FE0B0)),
            ),
          Center(
            child: Container(
              width: 250,
              height: 250,
              decoration: BoxDecoration(
                border: Border.all(color: const Color(0xFF0FE0B0), width: 3),
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ),
          Positioned(
            bottom: 40,
            left: 0,
            right: 0,
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.black54,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text('Point camera at QR Code', style: TextStyle(color: Colors.white)),
              ),
            ),
          )
        ],
      ),
    );
  }
}
