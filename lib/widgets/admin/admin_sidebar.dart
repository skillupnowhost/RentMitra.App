import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';

class AdminSidebar extends StatelessWidget {
  const AdminSidebar({
    super.key,
    required this.compact,
    this.onNavigate,
  });

  final bool compact;
  final VoidCallback? onNavigate;

  String _currentPath(BuildContext context) {
    return GoRouterState.of(context).uri.path;
  }

  bool _isSelected(String currentPath, String route) {
    if (route == '/admin') {
      return currentPath == '/admin';
    }

    return currentPath == route || currentPath.startsWith('$route/');
  }

  void _navigate(BuildContext context, String route) {
    onNavigate?.call();

    final currentPath = _currentPath(context);

    if (currentPath != route) {
      context.go(route);
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentPath = _currentPath(context);

    return Material(
      color: Colors.white,
      child: SafeArea(
        child: Column(
          children: [
            _buildLogo(),
            const SizedBox(height: 18),
            Expanded(
              child: ListView(
                padding: EdgeInsets.symmetric(
                  horizontal: compact ? 7 : 14,
                ),
                children: [
                  _buildNavItem(
                    context: context,
                    icon: Icons.dashboard_outlined,
                    label: 'Dashboard',
                    route: '/admin',
                    selected: _isSelected(currentPath, '/admin'),
                  ),
                  _buildNavItem(
                    context: context,
                    icon: Icons.receipt_long_outlined,
                    label: 'Orders',
                    route: '/admin/orders',
                    selected: _isSelected(currentPath, '/admin/orders'),
                  ),
                  _buildNavItem(
                    context: context,
                    icon: Icons.people_outline_rounded,
                    label: 'Customers',
                    route: '/admin/customers',
                    selected: _isSelected(currentPath, '/admin/customers'),
                  ),
                  _buildNavItem(
                    context: context,
                    icon: Icons.inventory_2_outlined,
                    label: 'Products',
                    route: '/admin/products',
                    selected: _isSelected(currentPath, '/admin/products'),
                  ),
                  _buildNavItem(
                    context: context,
                    icon: Icons.category_outlined,
                    label: 'Variants',
                    route: '/admin/variants',
                    selected: _isSelected(currentPath, '/admin/variants'),
                  ),
                  _buildNavItem(
                    context: context,
                    icon: Icons.payments_outlined,
                    label: 'Payments',
                    route: '/admin/payments',
                    selected: _isSelected(currentPath, '/admin/payments'),
                  ),
                  _buildNavItem(
                    context: context,
                    icon: Icons.home_work_outlined,
                    label: 'Rentals',
                    route: '/admin/rentals',
                    selected: _isSelected(currentPath, '/admin/rentals'),
                  ),
                  _buildNavItem(
                    context: context,
                    icon: Icons.build_outlined,
                    label: 'Installations',
                    route: '/admin/installations',
                    selected: _isSelected(
                      currentPath,
                      '/admin/installations',
                    ),
                  ),
                  _buildNavItem(
                    context: context,
                    icon: Icons.location_on_outlined,
                    label: 'Addresses',
                    route: '/admin/addresses',
                    selected: _isSelected(currentPath, '/admin/addresses'),
                  ),
                ],
              ),
            ),
            _buildFooter(),
          ],
        ),
      ),
    );
  }

  Widget _buildLogo() {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        compact ? 8 : 20,
        8,
        compact ? 8 : 20,
        0,
      ),
      child: SizedBox(
        height: 42,
        child: compact
            ? Center(
                child: Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: AppColors.ctaPurple,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.home_work_rounded,
                    color: Colors.white,
                    size: 19,
                  ),
                ),
              )
            : Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: AppColors.ctaPurple,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.home_work_rounded,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    'RentMitra',
                    style: AppTextStyles.of(
                      figmaSize: 17,
                      weight: FontWeight.w800,
                      color: AppColors.navy,
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildNavItem({
    required BuildContext context,
    required IconData icon,
    required String label,
    required String route,
    required bool selected,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Material(
        color: selected
            ? AppColors.ctaPurple.withValues(alpha: 0.08)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(10),
        child: InkWell(
          borderRadius: BorderRadius.circular(10),
          onTap: () => _navigate(context, route),
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: compact ? 11 : 14,
              vertical: 12,
            ),
            child: compact
                ? Center(
                    child: Icon(
                      icon,
                      size: 21,
                      color: selected
                          ? AppColors.ctaPurple
                          : AppColors.textGray,
                    ),
                  )
                : Row(
                    children: [
                      Icon(
                        icon,
                        size: 20,
                        color: selected
                            ? AppColors.ctaPurple
                            : AppColors.textGray,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          label,
                          style: AppTextStyles.of(
                            figmaSize: 13,
                            weight: selected
                                ? FontWeight.w700
                                : FontWeight.w500,
                            color: selected
                                ? AppColors.ctaPurple
                                : AppColors.navy,
                          ),
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }

  Widget _buildFooter() {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        compact ? 8 : 20,
        10,
        compact ? 8 : 20,
        16,
      ),
      child: compact
          ? const Icon(
              Icons.more_horiz,
              color: AppColors.textGraySoft,
            )
          : Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'rentmitra.app',
                style: AppTextStyles.of(
                  figmaSize: 11,
                  weight: FontWeight.w500,
                  color: AppColors.textGraySoft,
                ),
              ),
            ),
    );
  }
}
