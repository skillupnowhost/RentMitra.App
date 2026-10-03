import 'package:flutter/material.dart';

import '../../services/api_service.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import '../../widgets/admin/admin_sidebar.dart';
import 'admin_orders_style_shell.dart';

class AdminDeliveryPartnersScreen extends StatefulWidget {
  const AdminDeliveryPartnersScreen({super.key});

  @override
  State<AdminDeliveryPartnersScreen> createState() =>
      _AdminDeliveryPartnersScreenState();
}

class _AdminDeliveryPartnersScreenState
    extends State<AdminDeliveryPartnersScreen> {
  final TextEditingController _searchController = TextEditingController();

  List<Map<String, dynamic>> _partners = [];
  List<Map<String, dynamic>> _filteredPartners = [];

  String _selectedStatus = 'All';
  bool _isLoading = true;
  bool _isSaving = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadPartners();
    _searchController.addListener(_applyFilters);
  }

  @override
  void dispose() {
    _searchController.removeListener(_applyFilters);
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadPartners() async {
    if (mounted) {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });
    }

    try {
      final partners = await ApiService.getAdminDeliveryPartners();

      if (!mounted) return;

      setState(() {
        _partners = partners;
        _isLoading = false;
      });
      _applyFilters();
    } catch (error) {
      if (!mounted) return;

      setState(() {
        _isLoading = false;
        _errorMessage = _cleanError(error);
      });
    }
  }

  void _applyFilters() {
    final query = _searchController.text.trim().toLowerCase();

    final result = _partners.where((partner) {
      final name = _value(partner['partner_name']).toLowerCase();
      final contact = _value(partner['contact_person']).toLowerCase();
      final mobile = _value(partner['mobile']).toLowerCase();
      final email = _value(partner['email']).toLowerCase();
      final city = _value(partner['city']).toLowerCase();
      final status = _value(partner['partner_status']);

      final matchesSearch = query.isEmpty ||
          name.contains(query) ||
          contact.contains(query) ||
          mobile.contains(query) ||
          email.contains(query) ||
          city.contains(query);

      final matchesStatus = _selectedStatus == 'All' ||
          status.toLowerCase() == _selectedStatus.toLowerCase();

      return matchesSearch && matchesStatus;
    }).toList();

    if (!mounted) return;
    setState(() => _filteredPartners = result);
  }

  String _value(dynamic value) {
    final text = value?.toString().trim() ?? '';
    return text.isEmpty || text.toLowerCase() == 'null' ? '-' : text;
  }

  String? _nullable(dynamic value) {
    final text = value?.toString().trim() ?? '';
    return text.isEmpty || text == '-' ? null : text;
  }

  String _cleanError(Object error) {
    final message = error.toString();
    return message.startsWith('Exception: ')
        ? message.substring('Exception: '.length)
        : message;
  }

  int get _activeCount => _partners.where((p) =>
      _value(p['partner_status']).toLowerCase() == 'active').length;

  int get _inactiveCount => _partners.where((p) =>
      _value(p['partner_status']).toLowerCase() == 'inactive').length;

  Future<void> _showPartnerForm({Map<String, dynamic>? partner}) async {
    final isEdit = partner != null;
    final formKey = GlobalKey<FormState>();

    final nameController = TextEditingController(
      text: isEdit ? _value(partner['partner_name']) : '',
    );
    final contactController = TextEditingController(
      text: isEdit ? _value(partner['contact_person']) : '',
    );
    final mobileController = TextEditingController(
      text: isEdit ? _value(partner['mobile']) : '',
    );
    final emailController = TextEditingController(
      text: isEdit ? _value(partner['email']) : '',
    );
    final addressController = TextEditingController(
      text: isEdit ? _value(partner['address']) : '',
    );
    final cityController = TextEditingController(
      text: isEdit ? _value(partner['city']) : '',
    );
    final pincodeController = TextEditingController(
      text: isEdit ? _value(partner['pincode']) : '',
    );
    final notesController = TextEditingController(
      text: isEdit ? _value(partner['notes']) : '',
    );

    String status = isEdit ? _value(partner['partner_status']) : 'Active';
    if (!['Active', 'Inactive'].contains(status)) status = 'Active';

    try {
      await showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (dialogContext) {
          return StatefulBuilder(
            builder: (context, setDialogState) {
              return AlertDialog(
                title: Text(isEdit ? 'Edit Delivery Partner' : 'Add Delivery Partner'),
                content: SizedBox(
                  width: 560,
                  child: Form(
                    key: formKey,
                    child: SingleChildScrollView(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _formField(nameController, 'Partner Name *', Icons.business_outlined,
                              validator: (v) => v!.trim().isEmpty ? 'Partner name is required' : null),
                          const SizedBox(height: 12),
                          _formField(contactController, 'Contact Person', Icons.person_outline),
                          const SizedBox(height: 12),
                          _formField(mobileController, 'Mobile', Icons.phone_outlined,
                              keyboardType: TextInputType.phone,
                              validator: (v) {
                                final value = v!.trim();
                                if (value.isNotEmpty && !RegExp(r'^\d{10}$').hasMatch(value)) {
                                  return 'Enter a valid 10-digit mobile number';
                                }
                                return null;
                              }),
                          const SizedBox(height: 12),
                          _formField(emailController, 'Email', Icons.email_outlined,
                              keyboardType: TextInputType.emailAddress,
                              validator: (v) {
                                final value = v!.trim();
                                if (value.isNotEmpty && !RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(value)) {
                                  return 'Enter a valid email address';
                                }
                                return null;
                              }),
                          const SizedBox(height: 12),
                          _formField(addressController, 'Address', Icons.location_on_outlined, maxLines: 2),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(child: _formField(cityController, 'City', Icons.location_city_outlined)),
                              const SizedBox(width: 12),
                              Expanded(child: _formField(pincodeController, 'Pincode', Icons.pin_drop_outlined,
                                  keyboardType: TextInputType.number,
                                  validator: (v) {
                                    final value = v!.trim();
                                    if (value.isNotEmpty && !RegExp(r'^\d{6}$').hasMatch(value)) {
                                      return '6 digits';
                                    }
                                    return null;
                                  })),
                            ],
                          ),
                          const SizedBox(height: 12),
                          DropdownButtonFormField<String>(
                            value: status,
                            decoration: const InputDecoration(
                              labelText: 'Status',
                              border: OutlineInputBorder(),
                            ),
                            items: const [
                              DropdownMenuItem(value: 'Active', child: Text('Active')),
                              DropdownMenuItem(value: 'Inactive', child: Text('Inactive')),
                            ],
                            onChanged: (value) {
                              if (value != null) setDialogState(() => status = value);
                            },
                          ),
                          const SizedBox(height: 12),
                          _formField(notesController, 'Notes', Icons.notes_outlined, maxLines: 3),
                        ],
                      ),
                    ),
                  ),
                ),
                actions: [
                  TextButton(
                    onPressed: _isSaving ? null : () => Navigator.of(dialogContext).pop(),
                    child: const Text('Cancel'),
                  ),
                  ElevatedButton(
                    onPressed: _isSaving
                        ? null
                        : () async {
                            if (!formKey.currentState!.validate()) return;
                            setState(() => _isSaving = true);
                            try {
                              if (isEdit) {
                                final id = int.tryParse(partner!['delivery_partner_id'].toString());
                                if (id == null) throw Exception('Invalid delivery partner ID.');
                                await ApiService.updateDeliveryPartner(
                                  deliveryPartnerId: id,
                                  partnerName: nameController.text,
                                  contactPerson: contactController.text,
                                  mobile: mobileController.text,
                                  email: emailController.text,
                                  address: addressController.text,
                                  city: cityController.text,
                                  pincode: pincodeController.text,
                                  partnerStatus: status,
                                  notes: notesController.text,
                                );
                              } else {
                                await ApiService.createDeliveryPartner(
                                  partnerName: nameController.text,
                                  contactPerson: contactController.text,
                                  mobile: mobileController.text,
                                  email: emailController.text,
                                  address: addressController.text,
                                  city: cityController.text,
                                  pincode: pincodeController.text,
                                  partnerStatus: status,
                                  notes: notesController.text,
                                );
                              }

                              if (!mounted) return;
                              Navigator.of(dialogContext).pop();
                              await _loadPartners();
                              if (!mounted) return;
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(isEdit
                                      ? 'Delivery partner updated successfully.'
                                      : 'Delivery partner added successfully.'),
                                  backgroundColor: Colors.green.shade700,
                                  behavior: SnackBarBehavior.floating,
                                ),
                              );
                            } catch (error) {
                              if (!mounted) return;
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(_cleanError(error)),
                                  backgroundColor: Colors.red.shade700,
                                  behavior: SnackBarBehavior.floating,
                                ),
                              );
                            } finally {
                              if (mounted) setState(() => _isSaving = false);
                            }
                          },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.ctaPurple,
                      foregroundColor: Colors.white,
                    ),
                    child: Text(isEdit ? 'Save Changes' : 'Add Partner'),
                  ),
                ],
              );
            },
          );
        },
      );
    } finally {
      nameController.dispose();
      contactController.dispose();
      mobileController.dispose();
      emailController.dispose();
      addressController.dispose();
      cityController.dispose();
      pincodeController.dispose();
      notesController.dispose();
    }
  }

  Widget _formField(
    TextEditingController controller,
    String label,
    IconData icon, {
    TextInputType? keyboardType,
    int maxLines = 1,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      maxLines: maxLines,
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, size: 20),
        border: const OutlineInputBorder(),
      ),
    );
  }

  Future<void> _toggleStatus(Map<String, dynamic> partner) async {
    final id = int.tryParse(partner['delivery_partner_id']?.toString() ?? '');
    if (id == null) return;

    final current = _value(partner['partner_status']);
    final newStatus = current.toLowerCase() == 'active' ? 'Inactive' : 'Active';

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('$newStatus Delivery Partner?'),
        content: Text('Change ${_value(partner['partner_name'])} to $newStatus?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext, false), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.ctaPurple, foregroundColor: Colors.white),
            child: Text(newStatus),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      await ApiService.updateDeliveryPartner(
        deliveryPartnerId: id,
        partnerName: _value(partner['partner_name']),
        contactPerson: _nullable(partner['contact_person']),
        mobile: _nullable(partner['mobile']),
        email: _nullable(partner['email']),
        address: _nullable(partner['address']),
        city: _nullable(partner['city']),
        pincode: _nullable(partner['pincode']),
        partnerStatus: newStatus,
        notes: _nullable(partner['notes']),
      );
      await _loadPartners();
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_cleanError(error)), backgroundColor: Colors.red.shade700),
      );
    }
  }

  void _showDetails(Map<String, dynamic> partner) {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(_value(partner['partner_name'])),
        content: SizedBox(
          width: 520,
          child: SingleChildScrollView(
            child: Column(
              children: [
                _detail('Contact Person', partner['contact_person']),
                _detail('Mobile', partner['mobile']),
                _detail('Email', partner['email']),
                _detail('Address', partner['address']),
                _detail('City', partner['city']),
                _detail('Pincode', partner['pincode']),
                _detail('Status', partner['partner_status']),
                _detail('Notes', partner['notes']),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Close')),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.pop(context);
              _showPartnerForm(partner: partner);
            },
            icon: const Icon(Icons.edit_outlined, size: 18),
            label: const Text('Edit'),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.ctaPurple, foregroundColor: Colors.white),
          ),
        ],
      ),
    );
  }

  Widget _detail(String label, dynamic value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 9),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 145, child: Text(label, style: const TextStyle(fontWeight: FontWeight.w700))),
          Expanded(child: Text(_value(value))),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F8FC),
      drawer: Drawer(
        width: 280,
        child: AdminSidebar(compact: false, onNavigate: () => Navigator.of(context).pop()),
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final width = constraints.maxWidth;
            if (width >= 1100) {
              return Row(
                children: [
                  SizedBox(width: 250, child: AdminSidebar(compact: false)),
                  Expanded(child: _buildContent(context, false, 32)),
                ],
              );
            }
            return _buildContent(context, true, width >= 700 ? 28 : 16);
          },
        ),
      ),
    );
  }

  Widget _buildContent(BuildContext context, bool showMenu, double horizontalPadding) {
    return Column(
      children: [
        Container(
          height: 70,
          padding: const EdgeInsets.symmetric(horizontal: 20),
          decoration: BoxDecoration(color: Colors.white, border: Border(bottom: BorderSide(color: Colors.grey.shade200))),
          child: Row(
            children: [
              if (showMenu)
                Builder(builder: (context) => IconButton(onPressed: () => Scaffold.of(context).openDrawer(), icon: const Icon(Icons.menu_rounded))),
              const Icon(Icons.local_shipping_outlined, color: AppColors.ctaPurple, size: 26),
              const SizedBox(width: 12),
              Text('Delivery Partners', style: AppTextStyles.of(figmaSize: 30, weight: FontWeight.w700, color: AppColors.navy)),
              const Spacer(),
              IconButton(onPressed: _loadPartners, icon: const Icon(Icons.refresh_rounded)),
            ],
          ),
        ),
        Expanded(
          child: SingleChildScrollView(
            padding: EdgeInsets.fromLTRB(horizontalPadding, 28, horizontalPadding, 40),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Delivery Partners', style: AppTextStyles.of(figmaSize: 42, weight: FontWeight.w800, color: AppColors.navy)),
                          const SizedBox(height: 6),
                          Text('Manage delivery partners and their availability', style: AppTextStyles.of(figmaSize: 21, weight: FontWeight.w400, color: Colors.grey.shade600)),
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),
                    ElevatedButton.icon(
                      onPressed: () => _showPartnerForm(),
                      icon: const Icon(Icons.add_rounded),
                      label: const Text('Add Partner'),
                      style: ElevatedButton.styleFrom(backgroundColor: AppColors.ctaPurple, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 15)),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                _buildStats(),
                const SizedBox(height: 22),
                _buildFilters(),
                const SizedBox(height: 18),
                if (_isLoading) const Center(child: Padding(padding: EdgeInsets.all(50), child: CircularProgressIndicator(color: AppColors.ctaPurple)))
                else if (_errorMessage != null) _buildError()
                else if (_filteredPartners.isEmpty) _buildEmpty()
                else _buildList(),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStats() {
    return LayoutBuilder(builder: (context, constraints) {
      final cards = [
        _stat('Total Partners', _partners.length.toString(), Icons.groups_outlined, AppColors.ctaPurple),
        _stat('Active', _activeCount.toString(), Icons.check_circle_outline, Colors.green),
        _stat('Inactive', _inactiveCount.toString(), Icons.pause_circle_outline, Colors.orange),
      ];
      if (constraints.maxWidth < 700) return Column(children: cards.map((e) => Padding(padding: const EdgeInsets.only(bottom: 10), child: e)).toList());
      return Row(children: [for (int i = 0; i < cards.length; i++) ...[Expanded(child: cards[i]), if (i < cards.length - 1) const SizedBox(width: 14)]]);
    });
  }

  Widget _stat(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.grey.shade200)),
      child: Row(children: [
        Container(width: 48, height: 48, decoration: BoxDecoration(color: color.withValues(alpha: .09), borderRadius: BorderRadius.circular(13)), child: Icon(icon, color: color, size: 25)),
        const SizedBox(width: 13),
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(title, style: AppTextStyles.of(figmaSize: 18, weight: FontWeight.w500, color: Colors.grey.shade600)), const SizedBox(height: 3), Text(value, style: AppTextStyles.of(figmaSize: 28, weight: FontWeight.w800, color: AppColors.navy))]),
      ]),
    );
  }

  Widget _buildFilters() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.grey.shade200)),
      child: LayoutBuilder(builder: (context, constraints) {
        final search = SizedBox(
          height: 50,
          child: TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Search partner, contact, mobile, email or city...',
              prefixIcon: const Icon(Icons.search_rounded),
              suffixIcon: _searchController.text.isEmpty ? null : IconButton(onPressed: _searchController.clear, icon: const Icon(Icons.close_rounded)),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(11), borderSide: BorderSide(color: Colors.grey.shade300)),
            ),
          ),
        );
        final filter = SizedBox(
          height: 50,
          child: DropdownButtonFormField<String>(
            value: _selectedStatus,
            decoration: InputDecoration(labelText: 'Status', border: OutlineInputBorder(borderRadius: BorderRadius.circular(11))),
            items: const [
              DropdownMenuItem(value: 'All', child: Text('All')),
              DropdownMenuItem(value: 'Active', child: Text('Active')),
              DropdownMenuItem(value: 'Inactive', child: Text('Inactive')),
            ],
            onChanged: (value) {
              if (value == null) return;
              setState(() => _selectedStatus = value);
              _applyFilters();
            },
          ),
        );
        if (constraints.maxWidth < 700) return Column(children: [search, const SizedBox(height: 12), filter]);
        return Row(children: [Expanded(child: search), const SizedBox(width: 14), SizedBox(width: 190, child: filter)]);
      }),
    );
  }

  Widget _buildList() {
    return LayoutBuilder(builder: (context, constraints) {
      if (constraints.maxWidth < 850) {
        return Column(children: _filteredPartners.map(_buildMobileCard).toList());
      }
      return Container(
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.grey.shade200)),
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: DataTable(
            columnSpacing: 28,
            headingRowHeight: 54,
            dataRowMinHeight: 68,
            dataRowMaxHeight: 82,
            columns: const [
              DataColumn(label: Text('Partner')),
              DataColumn(label: Text('Contact')),
              DataColumn(label: Text('Mobile')),
              DataColumn(label: Text('City')),
              DataColumn(label: Text('Status')),
              DataColumn(label: Text('Actions')),
            ],
            rows: _filteredPartners.map((partner) => DataRow(cells: [
              DataCell(Text(_value(partner['partner_name']), style: const TextStyle(fontWeight: FontWeight.w700))),
              DataCell(Text(_value(partner['contact_person']))),
              DataCell(Text(_value(partner['mobile']))),
              DataCell(Text(_value(partner['city']))),
              DataCell(_statusBadge(_value(partner['partner_status']))),
              DataCell(Row(children: [
                IconButton(tooltip: 'View', onPressed: () => _showDetails(partner), icon: const Icon(Icons.visibility_outlined, size: 20)),
                IconButton(tooltip: 'Edit', onPressed: () => _showPartnerForm(partner: partner), icon: const Icon(Icons.edit_outlined, size: 20)),
                IconButton(tooltip: 'Change status', onPressed: () => _toggleStatus(partner), icon: Icon(Icons.power_settings_new_rounded, size: 20, color: _value(partner['partner_status']).toLowerCase() == 'active' ? Colors.red : Colors.green)),
              ])),
            ])).toList(),
          ),
        ),
      );
    });
  }

  Widget _buildMobileCard(Map<String, dynamic> partner) {
    final active = _value(partner['partner_status']).toLowerCase() == 'active';
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.grey.shade200)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Expanded(child: Text(_value(partner['partner_name']), style: AppTextStyles.of(figmaSize: 22, weight: FontWeight.w800, color: AppColors.navy))),
          _statusBadge(_value(partner['partner_status'])),
        ]),
        const SizedBox(height: 12),
        Text(_value(partner['contact_person']), style: const TextStyle(fontWeight: FontWeight.w600)),
        const SizedBox(height: 6),
        Text(_value(partner['mobile'])),
        const SizedBox(height: 4),
        Text(_value(partner['city'])),
        const SizedBox(height: 14),
        Row(children: [
          OutlinedButton.icon(onPressed: () => _showDetails(partner), icon: const Icon(Icons.visibility_outlined, size: 18), label: const Text('View')),
          const SizedBox(width: 8),
          OutlinedButton.icon(onPressed: () => _showPartnerForm(partner: partner), icon: const Icon(Icons.edit_outlined, size: 18), label: const Text('Edit')),
          const Spacer(),
          IconButton(onPressed: () => _toggleStatus(partner), icon: Icon(Icons.power_settings_new_rounded, color: active ? Colors.red : Colors.green)),
        ]),
      ]),
    );
  }

  Widget _statusBadge(String status) {
    final active = status.toLowerCase() == 'active';
    final color = active ? Colors.green : Colors.orange;
    return Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6), decoration: BoxDecoration(color: color.withValues(alpha: .09), borderRadius: BorderRadius.circular(8)), child: Text(status, style: TextStyle(fontWeight: FontWeight.w700, color: color)));
  }

  Widget _buildError() => Container(padding: const EdgeInsets.all(30), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)), child: Column(children: [const Icon(Icons.cloud_off_rounded, size: 42, color: Colors.redAccent), const SizedBox(height: 12), Text(_errorMessage ?? 'Unable to load delivery partners.'), const SizedBox(height: 16), ElevatedButton(onPressed: _loadPartners, child: const Text('Try Again'))]));

  Widget _buildEmpty() => Container(width: double.infinity, padding: const EdgeInsets.symmetric(vertical: 55), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.grey.shade200)), child: Column(children: [const Icon(Icons.local_shipping_outlined, size: 50, color: AppColors.ctaPurple), const SizedBox(height: 12), Text('No delivery partners found', style: AppTextStyles.of(figmaSize: 24, weight: FontWeight.w700, color: AppColors.navy)), const SizedBox(height: 6), const Text('Add a delivery partner or change your filters.') ]));
}
