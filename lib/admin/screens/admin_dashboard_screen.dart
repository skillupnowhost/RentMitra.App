import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../services/api_service.dart';
import '../../theme/app_colors.dart';
import '../../widgets/admin/admin_sidebar.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  bool _isLoading = true;
  String? _errorMessage;

  // ============================================================
  // DASHBOARD KPI VALUES
  // ============================================================

  int _totalOrders = 0;
  int _totalCustomers = 0;
  int _totalPayments = 0;
  int _activeRentals = 0;

  // ============================================================
  // ORDER PIPELINE VALUES
  // ============================================================

  int _newOrders = 0;
  int _paymentVerified = 0;
  int _deliveryAssigned = 0;
  int _installationScheduled = 0;
  int _delivered = 0;
  int _activeRental = 0;

  @override
  void initState() {
    super.initState();
    _loadDashboard();
  }

  // ============================================================
  // LOAD DASHBOARD DATA
  // ============================================================

  Future<void> _loadDashboard() async {
    if (mounted) {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });
    }

    try {
      final response = await ApiService.getAdminDashboard();

      if (!mounted) return;

      setState(() {
        // ======================================================
        // MAIN KPI VALUES
        // ======================================================

        _totalOrders = _parseInt(response['total_orders']);
        _totalCustomers = _parseInt(response['total_customers']);
        _totalPayments = _parseInt(response['total_payments']);
        _activeRentals = _parseInt(response['active_rentals']);

        // ======================================================
        // ORDER PIPELINE VALUES FROM BACKEND
        // ======================================================

        _newOrders = _parseInt(response['new_orders']);
        _paymentVerified = _parseInt(response['payment_verified']);
        _deliveryAssigned = _parseInt(response['delivery_assigned']);
        _installationScheduled =
            _parseInt(response['installation_scheduled']);
        _delivered = _parseInt(response['delivered']);
        _activeRental = _parseInt(response['active_rental']);

        _isLoading = false;
      });
    } catch (error) {
      if (!mounted) return;

      setState(() {
        _isLoading = false;
        _errorMessage = _cleanErrorMessage(error);
      });
    }
  }

  // ============================================================
  // PARSE INTEGER
  // ============================================================

  int _parseInt(dynamic value) {
    if (value == null) return 0;

    if (value is int) {
      return value;
    }

    if (value is double) {
      return value.toInt();
    }

    return int.tryParse(value.toString()) ?? 0;
  }

  // ============================================================
  // CLEAN ERROR MESSAGE
  // ============================================================

  String _cleanErrorMessage(Object error) {
    final message = error.toString();

    if (message.startsWith('Exception: ')) {
      return message.substring(11);
    }

    return message;
  }

  // ============================================================
  // ADMIN LOGOUT
  // ============================================================

  Future<void> _logout() async {
    final shouldLogout = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Logout'),
          content: const Text(
            'Are you sure you want to logout from the admin account?',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop(false);
              },
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(dialogContext).pop(true);
              },
              child: const Text('Logout'),
            ),
          ],
        );
      },
    );

    if (shouldLogout != true) {
      return;
    }

    try {
      await FirebaseAuth.instance.signOut();

      if (!mounted) {
        return;
      }

      context.go('/admin-login');
    } catch (error) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(
            content: Text('Unable to logout. Please try again.'),
            behavior: SnackBarBehavior.floating,
          ),
        );
    }
  }

  // ============================================================
  // MAIN BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      drawer: Drawer(
        width: 280,
        backgroundColor: Colors.white,
        child: AdminSidebar(
          compact: false,
          onNavigate: () => Navigator.of(context).pop(),
        ),
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final width = constraints.maxWidth;

          if (width >= 1100) {
            return _buildDesktopLayout();
          }

          if (width >= 700) {
            return _buildTabletLayout();
          }

          return _buildMobileLayout();
        },
      ),
    );
  }

  // ============================================================
  // DESKTOP
  // ============================================================

  Widget _buildDesktopLayout() {
    return Row(
      children: [
        const SizedBox(
          width: 250,
          child: AdminSidebar(compact: false),
        ),
        Expanded(
          child: _buildMainContent(
            showMobileMenu: false,
            horizontalPadding: 32,
          ),
        ),
      ],
    );
  }

  // ============================================================
  // TABLET
  // ============================================================

  Widget _buildTabletLayout() {
    return Row(
      children: [
        const SizedBox(
          width: 82,
          child: AdminSidebar(compact: true),
        ),
        Expanded(
          child: _buildMainContent(
            showMobileMenu: false,
            horizontalPadding: 24,
          ),
        ),
      ],
    );
  }

  // ============================================================
  // MOBILE
  // ============================================================

  Widget _buildMobileLayout() {
    return Builder(
      builder: (context) {
        return _buildMainContent(
          showMobileMenu: true,
          horizontalPadding: 16,
          onMenuTap: () {
            Scaffold.of(context).openDrawer();
          },
        );
      },
    );
  }

  // ============================================================
  // MAIN CONTENT
  // ============================================================

  Widget _buildMainContent({
    required bool showMobileMenu,
    required double horizontalPadding,
    VoidCallback? onMenuTap,
  }) {
    return SafeArea(
      child: Column(
        children: [
          _buildHeader(
            showMobileMenu: showMobileMenu,
            onMenuTap: onMenuTap,
          ),
          Expanded(
            child: RefreshIndicator(
              color: AppColors.ctaPurple,
              onRefresh: _loadDashboard,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: EdgeInsets.fromLTRB(
                  horizontalPadding,
                  20,
                  horizontalPadding,
                  40,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildWelcomeCard(),

                    const SizedBox(height: 24),

                    _buildKpiSection(),

                    const SizedBox(height: 30),

                    _buildOrderPipeline(),

                    const SizedBox(height: 30),

                    _buildQuickActions(),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // HEADER
  // ============================================================

  Widget _buildHeader({
    required bool showMobileMenu,
    VoidCallback? onMenuTap,
  }) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (showMobileMenu) ...[
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: const Color(0xFFE8E7EE),
                ),
              ),
              child: IconButton(
                onPressed: onMenuTap,
                icon: const Icon(Icons.menu_rounded),
                color: AppColors.navy,
              ),
            ),
            const SizedBox(width: 16),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Admin Dashboard',
                  style: GoogleFonts.inter(
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    color: AppColors.navyDeep,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Manage your rental operations\nfrom one place',
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    height: 1.45,
                    color: AppColors.textGray,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          _buildNotificationButton(),
          const SizedBox(width: 10),
          _buildAdminAvatar(),
        ],
      ),
    );
  }

  // ============================================================
  // NOTIFICATION BUTTON
  // ============================================================

  Widget _buildNotificationButton() {
    return PopupMenuButton<String>(
      tooltip: 'Notifications',
      onSelected: (value) {
        // Notification actions can be added here later.
      },
      offset: const Offset(-260, 58),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
      ),
      constraints: const BoxConstraints(
        minWidth: 300,
        maxWidth: 340,
      ),
      itemBuilder: (context) => [
        PopupMenuItem<String>(
          enabled: false,
          padding: const EdgeInsets.fromLTRB(18, 16, 18, 8),
          child: Row(
            children: [
              Icon(
                Icons.notifications_outlined,
                size: 21,
                color: AppColors.brandIndigo,
              ),
              const SizedBox(width: 10),
              Text(
                'Notifications',
                style: GoogleFonts.inter(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: AppColors.navyDeep,
                ),
              ),
            ],
          ),
        ),
        PopupMenuItem<String>(
          enabled: false,
          padding: const EdgeInsets.fromLTRB(18, 8, 18, 16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: const Color(0xFFF0E9FF),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.notifications_none_rounded,
                  size: 19,
                  color: AppColors.ctaPurple,
                ),
              ),
              const SizedBox(width: 11),
              Expanded(
                child: Text(
                  'No new notifications',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: AppColors.textGray,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
      child: Container(
        width: 52,
        height: 52,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: const Color(0xFFE8E7EE),
          ),
        ),
        child: const Icon(
          Icons.notifications_none_rounded,
          color: AppColors.navy,
        ),
      ),
    );
  }

  // ============================================================
  // ADMIN AVATAR
  // ============================================================

  Widget _buildAdminAvatar() {
    final adminEmail = FirebaseAuth.instance.currentUser?.email ??
        'Admin account';

    return PopupMenuButton<String>(
      tooltip: 'Admin Profile',
      onSelected: (value) {
        if (value == 'logout') {
          _logout();
        }
      },
      position: PopupMenuPosition.under,
      offset: const Offset(0, 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
      ),
      constraints: const BoxConstraints(
        minWidth: 280,
        maxWidth: 320,
      ),
      itemBuilder: (context) => [
        PopupMenuItem<String>(
          enabled: false,
          padding: const EdgeInsets.fromLTRB(18, 16, 18, 14),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: const Color(0xFFEDE4FF),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: const Color(0xFFD9C6FF),
                  ),
                ),
                alignment: Alignment.center,
                child: Text(
                  'A',
                  style: GoogleFonts.inter(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: AppColors.brandIndigo,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Admin',
                      style: GoogleFonts.inter(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: AppColors.navyDeep,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      adminEmail,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        color: AppColors.textGray,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const PopupMenuDivider(),
        PopupMenuItem<String>(
          value: 'profile',
          enabled: false,
          padding: const EdgeInsets.symmetric(
            horizontal: 18,
            vertical: 10,
          ),
          child: Row(
            children: [
              Icon(
                Icons.person_outline_rounded,
                size: 20,
                color: AppColors.navy,
              ),
              const SizedBox(width: 12),
              Text(
                'Admin Profile',
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.navy,
                ),
              ),
            ],
          ),
        ),
        PopupMenuItem<String>(
          value: 'logout',
          padding: const EdgeInsets.symmetric(
            horizontal: 18,
            vertical: 10,
          ),
          child: Row(
            children: [
              const Icon(
                Icons.logout_rounded,
                size: 20,
                color: Colors.redAccent,
              ),
              const SizedBox(width: 12),
              Text(
                'Logout',
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: Colors.redAccent,
                ),
              ),
            ],
          ),
        ),
      ],
      child: Container(
        width: 52,
        height: 52,
        decoration: BoxDecoration(
          color: const Color(0xFFEDE4FF),
          shape: BoxShape.circle,
          border: Border.all(
            color: const Color(0xFFD9C6FF),
          ),
        ),
        alignment: Alignment.center,
        child: Text(
          'A',
          style: GoogleFonts.inter(
            fontSize: 20,
            fontWeight: FontWeight.w800,
            color: AppColors.brandIndigo,
          ),
        ),
      ),
    );
  }

  // ============================================================
  // WELCOME CARD
  // ============================================================

  Widget _buildWelcomeCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(18, 18, 16, 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: const Color(0xFFE5E4EC),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.025),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  'Welcome back, Admin',
                  style: GoogleFonts.inter(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: AppColors.navyDeep,
                  ),
                ),
              ),

              // REFRESH BUTTON
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: const Color(0xFFF8F7FC),
                  borderRadius: BorderRadius.circular(11),
                  border: Border.all(
                    color: const Color(0xFFE8E6EE),
                  ),
                ),
                child: IconButton(
                  tooltip: 'Refresh dashboard',
                  padding: EdgeInsets.zero,
                  onPressed: _isLoading ? null : _loadDashboard,
                  icon: const Icon(
                    Icons.refresh_rounded,
                    size: 21,
                  ),
                  color: AppColors.navy,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'Here is what is happening across RentMitra today.',
            style: GoogleFonts.inter(
              fontSize: 13,
              color: AppColors.textGray,
              height: 1.4,
            ),
          ),
          if (_errorMessage != null) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                const Icon(
                  Icons.error_outline_rounded,
                  size: 16,
                  color: Colors.redAccent,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    _errorMessage!,
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      color: Colors.redAccent,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  // ============================================================
  // KPI SECTION
  // ============================================================

  Widget _buildKpiSection() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;

        final cards = [
          _buildKpiCard(
            title: 'TOTAL ORDERS',
            value: _isLoading ? '—' : '$_totalOrders',
            description: 'All orders',
            icon: Icons.receipt_long_outlined,
            iconColor: AppColors.ctaPurple,
            iconBackground: const Color(0xFFF0E9FF),
            accentColor: AppColors.ctaPurple,
          ),
          _buildKpiCard(
            title: 'CUSTOMERS',
            value: _isLoading ? '—' : '$_totalCustomers',
            description: 'Registered customers',
            icon: Icons.people_alt_outlined,
            iconColor: AppColors.brandIndigo,
            iconBackground: const Color(0xFFEEF0FF),
            accentColor: const Color(0xFF6251D8),
          ),
          _buildKpiCard(
            title: 'PAYMENTS',
            value: _isLoading ? '—' : '$_totalPayments',
            description: 'Payment records',
            icon: Icons.payments_outlined,
            iconColor: const Color(0xFFEF9300),
            iconBackground: const Color(0xFFFFF5E6),
            accentColor: const Color(0xFFF39A00),
          ),
          _buildKpiCard(
            title: 'ACTIVE RENTALS',
            value: _isLoading ? '—' : '$_activeRentals',
            description: 'Currently active',
            icon: Icons.home_work_outlined,
            iconColor: const Color(0xFF16A34A),
            iconBackground: const Color(0xFFEAF8EF),
            accentColor: const Color(0xFF16A34A),
          ),
        ];

        // MOBILE / TABLET
        // 2 x 2 matrix
        if (width < 1100) {
          return Wrap(
            spacing: 12,
            runSpacing: 12,
            children: cards
                .map(
                  (card) => SizedBox(
                    width: (width - 12) / 2,
                    child: card,
                  ),
                )
                .toList(),
          );
        }

        // DESKTOP
        // 4 in one row
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: cards
              .map(
                (card) => Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(right: 12),
                    child: card,
                  ),
                ),
              )
              .toList(),
        );
      },
    );
  }

  // ============================================================
  // KPI CARD
  // ============================================================

  Widget _buildKpiCard({
    required String title,
    required String value,
    required String description,
    required IconData icon,
    required Color iconColor,
    required Color iconBackground,
    required Color accentColor,
  }) {
    return Container(
      width: double.infinity,
      constraints: const BoxConstraints(
        minHeight: 156,
      ),
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(17),
        border: Border.all(
          color: const Color(0xFFE5E4EC),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.018),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: iconBackground,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icon,
                  color: iconColor,
                  size: 21,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.inter(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.4,
                    color: AppColors.textGray,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 22),
          Text(
            value,
            style: GoogleFonts.inter(
              fontSize: 34,
              height: 1,
              fontWeight: FontWeight.w800,
              color: AppColors.navyDeep,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            description,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.inter(
              fontSize: 11,
              color: AppColors.textGray,
            ),
          ),
          const SizedBox(height: 12),

          // Accent line — no dot
          Container(
            width: 32,
            height: 3,
            decoration: BoxDecoration(
              color: accentColor,
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // ORDER PIPELINE
  // ============================================================

  Widget _buildOrderPipeline() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: const Color(0xFFE5E4EC),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Order Pipeline',
            style: GoogleFonts.inter(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: AppColors.navyDeep,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            'Track orders through each stage of the rental journey.',
            style: GoogleFonts.inter(
              fontSize: 12,
              color: AppColors.textGray,
            ),
          ),
          const SizedBox(height: 22),

          // ======================================================
          // NEW ORDER
          // ======================================================

          _buildPipelineItem(
            title: 'New Order',
            subtitle: 'Newly placed',
            count: _isLoading ? 0 : _newOrders,
            icon: Icons.shopping_bag_outlined,
            iconColor: AppColors.ctaPurple,
            iconBackground: const Color(0xFFF1EAFE),
            countBackground: const Color(0xFFF2ECFF),
            countColor: AppColors.ctaPurple,
            showLine: true,
          ),

          // ======================================================
          // PAYMENT VERIFIED
          // ======================================================

          _buildPipelineItem(
            title: 'Payment Verified',
            subtitle: 'Payment confirmed',
            count: _isLoading ? 0 : _paymentVerified,
            icon: Icons.verified_outlined,
            iconColor: const Color(0xFF6954D8),
            iconBackground: const Color(0xFFF1F0FF),
            countBackground: const Color(0xFFF2F0FF),
            countColor: const Color(0xFF6954D8),
            showLine: true,
          ),

          // ======================================================
          // DELIVERY ASSIGNED
          // ======================================================

          _buildPipelineItem(
            title: 'Delivery Assigned',
            subtitle: 'Delivery in progress',
            count: _isLoading ? 0 : _deliveryAssigned,
            icon: Icons.local_shipping_outlined,
            iconColor: const Color(0xFFED9200),
            iconBackground: const Color(0xFFFFF6E8),
            countBackground: const Color(0xFFFFF7E9),
            countColor: const Color(0xFFDD8500),
            showLine: true,
          ),

          // ======================================================
          // INSTALLATION
          // ======================================================

          _buildPipelineItem(
            title: 'Installation',
            subtitle: 'Installation scheduled',
            count: _isLoading ? 0 : _installationScheduled,
            icon: Icons.build_outlined,
            iconColor: const Color(0xFF7558D8),
            iconBackground: const Color(0xFFF1EEFF),
            countBackground: const Color(0xFFF2EEFF),
            countColor: const Color(0xFF7558D8),
            showLine: true,
          ),

          // ======================================================
          // DELIVERED
          // ======================================================

          _buildPipelineItem(
            title: 'Delivered',
            subtitle: 'Successfully delivered',
            count: _isLoading ? 0 : _delivered,
            icon: Icons.inventory_2_outlined,
            iconColor: const Color(0xFF20A45A),
            iconBackground: const Color(0xFFEAF8EF),
            countBackground: const Color(0xFFEAF8EF),
            countColor: const Color(0xFF19924D),
            showLine: true,
          ),

          // ======================================================
          // ACTIVE RENTAL
          // ======================================================

          _buildPipelineItem(
            title: 'Active Rental',
            subtitle: 'Currently rented',
            count: _isLoading ? 0 : _activeRental,
            icon: Icons.home_work_outlined,
            iconColor: const Color(0xFF15994C),
            iconBackground: const Color(0xFFEAF8EF),
            countBackground: const Color(0xFFEAF8EF),
            countColor: const Color(0xFF15994C),
            showLine: false,
          ),
        ],
      ),
    );
  }

  // ============================================================
  // PIPELINE ITEM
  // ============================================================

  Widget _buildPipelineItem({
    required String title,
    required String subtitle,
    required int count,
    required IconData icon,
    required Color iconColor,
    required Color iconBackground,
    required Color countBackground,
    required Color countColor,
    required bool showLine,
  }) {
    return SizedBox(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 48,
            child: Column(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: iconBackground,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: iconColor.withValues(alpha: 0.15),
                    ),
                  ),
                  child: Icon(
                    icon,
                    color: iconColor,
                    size: 20,
                  ),
                ),
                if (showLine)
                  Container(
                    width: 1,
                    height: 42,
                    margin: const EdgeInsets.only(top: 1),
                    color: const Color(0xFFE3E3EA),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(
                top: 3,
                bottom: 20,
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: AppColors.navy,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          subtitle,
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            color: AppColors.textGray,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    constraints: const BoxConstraints(
                      minWidth: 36,
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 7,
                    ),
                    decoration: BoxDecoration(
                      color: countBackground,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '$count',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        color: countColor,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // QUICK ACTIONS
  // ============================================================

  Widget _buildQuickActions() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(18, 20, 18, 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: const Color(0xFFE5E4EC),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Quick Actions',
            style: GoogleFonts.inter(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: AppColors.navyDeep,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            'Frequently used admin operations.',
            style: GoogleFonts.inter(
              fontSize: 12,
              color: AppColors.textGray,
            ),
          ),
          const SizedBox(height: 20),

          // ======================================================
          // ADD PRODUCT
          // ======================================================

          _buildQuickAction(
            title: 'Add Product',
            subtitle: 'Create a new product',
            icon: Icons.add_box_outlined,
            iconColor: AppColors.ctaPurple,
            iconBackground: const Color(0xFFF0E9FF),
            onTap: () {
              context.go('/admin/products');
            },
          ),

          const SizedBox(height: 10),

          // ======================================================
          // VIEW ORDERS
          // ======================================================

          _buildQuickAction(
            title: 'View Orders',
            subtitle: 'Manage customer orders',
            icon: Icons.receipt_long_outlined,
            iconColor: const Color(0xFF6251D8),
            iconBackground: const Color(0xFFF0EFFF),
            onTap: () {
              context.go('/admin/orders');
            },
          ),

          const SizedBox(height: 10),

          // ======================================================
          // VIEW INSTALLATION
          // ======================================================

          _buildQuickAction(
            title: 'View Installation',
            subtitle: 'Manage installations',
            icon: Icons.event_available_outlined,
            iconColor: const Color(0xFF15994C),
            iconBackground: const Color(0xFFEAF8EF),
            onTap: () {
              context.go('/admin/installations');
            },
          ),

          const SizedBox(height: 10),

          // ======================================================
          // VIEW CUSTOMERS
          // ======================================================

          _buildQuickAction(
            title: 'View Customers',
            subtitle: 'Manage customers',
            icon: Icons.people_alt_outlined,
            iconColor: const Color(0xFFEF9300),
            iconBackground: const Color(0xFFFFF5E6),
            onTap: () => context.go('/admin/customers'),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // QUICK ACTION ITEM
  // ============================================================

  Widget _buildQuickAction({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color iconColor,
    required Color iconBackground,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 11,
          ),
          decoration: BoxDecoration(
            color: const Color(0xFFFCFCFE),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: const Color(0xFFE9E8EF),
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: iconBackground,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  icon,
                  color: iconColor,
                  size: 20,
                ),
              ),
              const SizedBox(width: 11),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: AppColors.navy,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      subtitle,
                      style: GoogleFonts.inter(
                        fontSize: 10,
                        color: AppColors.textGray,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.chevron_right_rounded,
                size: 20,
                color: AppColors.textGray,
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ============================================================
  // SIDEBAR
  // ============================================================

  // Sidebar navigation is provided by AdminSidebar so every admin
  // screen uses the same width, spacing, selected state and routes.
}