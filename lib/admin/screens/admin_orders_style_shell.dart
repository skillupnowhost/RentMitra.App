import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import '../../widgets/admin/admin_sidebar.dart';

/// Shared visual shell used by Orders, Payments, Rentals, Installations and
/// Addresses. It intentionally owns only presentation/layout; each screen
/// keeps its own API, filtering and table/card logic.
class AdminOrdersStyleShell extends StatelessWidget {
  const AdminOrdersStyleShell({
    super.key,
    required this.title,
    required this.subtitle,
    required this.refresh,
    required this.stats,
    required this.filters,
    required this.content,
  });

  final String title;
  final String subtitle;
  final VoidCallback refresh;
  final List<AdminOrdersStyleStat> stats;
  final Widget filters;
  final Widget content;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final mobile = width < 700;
        final tablet = width >= 700 && width < 1100;

        final main = Column(
          children: [
            _topBar(context, mobile: mobile),
            Expanded(
              child: RefreshIndicator(
                onRefresh: () async => refresh(),
                color: AppColors.ctaPurple,
                child: ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: EdgeInsets.fromLTRB(
                    mobile ? 16 : tablet ? 24 : 32,
                    18,
                    mobile ? 16 : tablet ? 24 : 32,
                    32,
                  ),
                  children: [
                    _header(mobile),
                    const SizedBox(height: 20),
                    _stats(mobile),
                    const SizedBox(height: 24),
                    filters,
                    const SizedBox(height: 18),
                    content,
                  ],
                ),
              ),
            ),
          ],
        );

        return Scaffold(
          backgroundColor: AppColors.background,
          drawer: mobile
              ? Drawer(
                  width: 280,
                  backgroundColor: Colors.white,
                  child: AdminSidebar(
                    compact: false,
                    onNavigate: () => Navigator.of(context).pop(),
                  ),
                )
              : null,
          body: SafeArea(
            top: true,
            bottom: false,
            child: Row(
              children: [
                if (!mobile)
                  SizedBox(
                    width: tablet ? 82 : 250,
                    child: AdminSidebar(compact: tablet),
                  ),
                Expanded(child: main),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _topBar(BuildContext context, {required bool mobile}) {
    return Container(
      height: 70,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          bottom: BorderSide(color: Colors.grey.shade200),
        ),
      ),
      child: Row(
        children: [
          if (mobile)
            Builder(
              builder: (context) => IconButton(
                onPressed: () => Scaffold.of(context).openDrawer(),
                icon: const Icon(Icons.menu_rounded),
                color: AppColors.navy,
              ),
            )
          else
            const Icon(
              Icons.receipt_long_rounded,
              color: AppColors.ctaPurple,
              size: 26,
            ),
          if (mobile) const SizedBox(width: 4),
          if (!mobile) const SizedBox(width: 12),
          Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTextStyles.of(
              figmaSize: 30,
              weight: FontWeight.w700,
              color: AppColors.navy,
            ),
          ),
          const Spacer(),
          IconButton(
            onPressed: refresh,
            tooltip: 'Refresh',
            icon: const Icon(Icons.refresh_rounded, size: 22),
          ),
          const SizedBox(width: 4),
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: const Color(0xFFEDEAFF),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.person_rounded,
              color: AppColors.ctaPurple,
              size: 21,
            ),
          ),
        ],
      ),
    );
  }

  Widget _header(bool mobile) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: AppTextStyles.of(
            figmaSize: 42,
            weight: FontWeight.w800,
            color: AppColors.navy,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          subtitle,
          maxLines: mobile ? 2 : 1,
          overflow: TextOverflow.ellipsis,
          style: AppTextStyles.of(
            figmaSize: 21,
            weight: FontWeight.w400,
            color: Colors.grey.shade600,
          ),
        ),
      ],
    );
  }

  Widget _stats(bool mobile) {
    if (stats.isEmpty) return const SizedBox.shrink();

    if (stats.length == 4) {
      return LayoutBuilder(
        builder: (context, constraints) {
          if (constraints.maxWidth >= 900) {
            return Row(
              children: _withGaps(stats, 14),
            );
          }
          if (constraints.maxWidth >= 500) {
            return GridView.count(
              crossAxisCount: 2,
              crossAxisSpacing: 14,
              mainAxisSpacing: 14,
              childAspectRatio: 2.3,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              children: stats.map((s) => _statCard(s)).toList(),
            );
          }
          return Column(
            children: [
              Row(children: _withGaps(stats.take(2).toList(), 12)),
              const SizedBox(height: 12),
              Row(children: _withGaps(stats.skip(2).toList(), 12)),
            ],
          );
        },
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth >= 900) {
          return Row(children: _withGaps(stats, 14));
        }
        if (constraints.maxWidth >= 500) {
          return GridView.count(
            crossAxisCount: 2,
            crossAxisSpacing: 14,
            mainAxisSpacing: 14,
            childAspectRatio: 2.3,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            children: stats.map((s) => _statCard(s)).toList(),
          );
        }
        return Column(
          children: stats
              .map(
                (s) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _statCard(s),
                ),
              )
              .toList(),
        );
      },
    );
  }

  List<Widget> _withGaps(List<AdminOrdersStyleStat> items, double gap) {
    return [
      for (var i = 0; i < items.length; i++) ...[
        if (i > 0) SizedBox(width: gap),
        Expanded(child: _statCard(items[i])),
      ],
    ];
  }

  Widget _statCard(AdminOrdersStyleStat stat) {
    return Container(
      constraints: const BoxConstraints(minHeight: 112),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: stat.iconBackground,
              borderRadius: BorderRadius.circular(13),
            ),
            child: Icon(stat.icon, color: stat.iconColor, size: 22),
          ),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  stat.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.of(
                    figmaSize: 18,
                    weight: FontWeight.w500,
                    color: Colors.grey.shade600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  stat.value,
                  style: AppTextStyles.of(
                    figmaSize: 33,
                    weight: FontWeight.w800,
                    color: AppColors.navy,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class AdminOrdersStyleStat {
  const AdminOrdersStyleStat({
    required this.title,
    required this.value,
    required this.icon,
    required this.iconBackground,
    required this.iconColor,
  });

  final String title;
  final String value;
  final IconData icon;
  final Color iconBackground;
  final Color iconColor;
}

/// Orders-style search + dropdown row. The actual filter values and callback
/// remain owned by the screen using it.
class AdminOrdersStyleFilterRow extends StatelessWidget {
  const AdminOrdersStyleFilterRow({
    super.key,
    required this.controller,
    required this.hintText,
    required this.selectedValue,
    required this.values,
    required this.onChanged,
    this.onSearchChanged,
    this.onClear,
  });

  final TextEditingController controller;
  final String hintText;
  final String selectedValue;
  final List<String> values;
  final ValueChanged<String?> onChanged;
  final ValueChanged<String>? onSearchChanged;
  final VoidCallback? onClear;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final mobile = constraints.maxWidth < 650;
        final search = _search();
        final dropdown = _dropdown();

        if (mobile) {
          return Column(
            children: [
              search,
              const SizedBox(height: 12),
              dropdown,
            ],
          );
        }

        return Row(
          children: [
            Expanded(child: search),
            const SizedBox(width: 12),
            SizedBox(width: 220, child: dropdown),
          ],
        );
      },
    );
  }

  Widget _search() {
    return TextField(
      controller: controller,
      onChanged: onSearchChanged,
      style: AppTextStyles.of(
        figmaSize: 14,
        weight: FontWeight.w400,
        color: AppColors.navy,
      ),
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle: TextStyle(
          color: Colors.grey.shade500,
          fontSize: 14,
        ),
        prefixIcon: Icon(Icons.search_rounded, color: Colors.grey.shade600),
        suffixIcon: controller.text.isNotEmpty && onClear != null
            ? IconButton(
                onPressed: onClear,
                icon: const Icon(Icons.close_rounded),
              )
            : null,
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(13),
          borderSide: BorderSide(color: Colors.grey.shade200),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(13),
          borderSide: BorderSide(color: Colors.grey.shade200),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(13),
          borderSide: const BorderSide(color: AppColors.ctaPurple, width: 1.4),
        ),
      ),
    );
  }

  Widget _dropdown() {
    return Container(
      height: 54,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(13),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: values.contains(selectedValue) ? selectedValue : values.first,
          isExpanded: true,
          icon: const Icon(Icons.keyboard_arrow_down_rounded),
          items: values
              .map(
                (value) => DropdownMenuItem<String>(
                  value: value,
                  child: Text(
                    value,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.of(
                      figmaSize: 21,
                      weight: FontWeight.w400,
                      color: AppColors.navy,
                    ),
                  ),
                ),
              )
              .toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }
}
