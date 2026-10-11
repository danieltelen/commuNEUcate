import 'package:flutter/material.dart';

import 'admin_dashboard_screen.dart';
import 'admin_approvals_screen.dart';
import 'admin_scan_screen.dart';
import 'admin_disputes_screen.dart';
import 'admin_profile_screen.dart';

class AdminLayout extends StatefulWidget {
  const AdminLayout({super.key});

  @override
  State<AdminLayout> createState() => _AdminLayoutState();
}

class _AdminLayoutState extends State<AdminLayout> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    // If the screen width is 800 or more, treat it as Desktop/Web layout
    final isDesktop = MediaQuery.of(context).size.width >= 800;

    if (isDesktop) {
      return Scaffold(
        backgroundColor: const Color(0xFF07070E),
        body: Row(
          children: [
            _buildSidebar(),
            Expanded(
              child: _buildBody(),
            ),
          ],
        ),
      );
    } else {
      return _buildMobileLayout();
    }
  }

  Widget _buildSidebar() {
    return Container(
      width: 260,
      color: const Color(0xFF111120),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(24, 40, 24, 32),
            child: Text(
              'CommuNEUcate\nAdmin Portal',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.white,
                height: 1.3,
              ),
            ),
          ),
          Expanded(
            child: ListView(
              children: [
                _buildSidebarItem(Icons.dashboard_outlined, Icons.dashboard, 'Dashboard', 0),
                _buildSidebarItem(Icons.verified_outlined, Icons.verified, 'Approvals', 1),
                _buildSidebarItem(Icons.qr_code_scanner, Icons.qr_code_scanner, 'Scan QR', 2),
                _buildSidebarItem(Icons.gavel_outlined, Icons.gavel, 'Disputes', 3),
                _buildSidebarItem(Icons.admin_panel_settings_outlined, Icons.admin_panel_settings, 'Settings', 4),
              ],
            ),
          ),
          const Padding(
            padding: EdgeInsets.all(24.0),
            child: Text(
              'Version 1.0 (Web)',
              style: TextStyle(color: Colors.grey, fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSidebarItem(IconData iconOutlined, IconData iconFilled, String label, int index) {
    final isSelected = _currentIndex == index;
    return InkWell(
      onTap: () => setState(() => _currentIndex = index),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF0FE0B0).withValues(alpha: 0.1) : Colors.transparent,
          border: Border(
            left: BorderSide(
              color: isSelected ? const Color(0xFF0FE0B0) : Colors.transparent,
              width: 4,
            ),
          ),
        ),
        child: Row(
          children: [
            Icon(
              isSelected ? iconFilled : iconOutlined,
              color: isSelected ? const Color(0xFF0FE0B0) : Colors.grey,
              size: 24,
            ),
            const SizedBox(width: 16),
            Text(
              label,
              style: TextStyle(
                fontSize: 16,
                color: isSelected ? const Color(0xFF0FE0B0) : Colors.grey,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMobileLayout() {
    return Scaffold(
      body: _buildBody(),
      bottomNavigationBar: BottomAppBar(
        color: const Color(0xFF111120),
        shape: const CircularNotchedRectangle(),
        notchMargin: 8,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildNavItem(Icons.dashboard_outlined, Icons.dashboard, 'Dashboard', 0),
              _buildNavItem(Icons.verified_outlined, Icons.verified, 'Approvals', 1),
              const SizedBox(width: 48), // Space for FAB
              _buildNavItem(Icons.gavel_outlined, Icons.gavel, 'Disputes', 3),
              _buildNavItem(Icons.admin_panel_settings_outlined, Icons.admin_panel_settings, 'Settings', 4),
            ],
          ),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      floatingActionButton: Transform.translate(
        offset: const Offset(0, 15), // Lowers the FAB by 15 pixels
        child: FloatingActionButton(
          backgroundColor: const Color(0xFF0FE0B0),
          onPressed: () => setState(() => _currentIndex = 2),
          elevation: 0,
          child: const Icon(Icons.qr_code_scanner, color: Color(0xFF07070E), size: 28),
        ),
      ),
    );
  }

  Widget _buildNavItem(IconData iconOutlined, IconData iconFilled, String label, int index) {
    final isSelected = _currentIndex == index;
    return InkWell(
      onTap: () => setState(() => _currentIndex = index),
      customBorder: const CircleBorder(),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4.0, vertical: 2.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isSelected ? iconFilled : iconOutlined,
              color: isSelected ? const Color(0xFF0FE0B0) : Colors.grey,
              size: 24,
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                color: isSelected ? const Color(0xFF0FE0B0) : Colors.grey,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBody() {
    switch (_currentIndex) {
      case 0:
        return const AdminDashboardScreen();
      case 1:
        return AdminApprovalsScreen(
          onNavigate: (index) {
            setState(() {
              _currentIndex = index;
            });
          },
        );
      case 2:
        return const AdminScanScreen();
      case 3:
        return AdminDisputesScreen(
          onNavigate: (index) {
            setState(() {
              _currentIndex = index;
            });
          },
        );
      case 4:
        return const AdminProfileScreen();
      default:
        return const SizedBox();
    }
  }
}
