import 'package:flutter/material.dart';

import '../../services/api_service.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import 'admin_orders_style_shell.dart';

class AdminAddressesScreen extends StatefulWidget {
  const AdminAddressesScreen({super.key});

  @override
  State<AdminAddressesScreen> createState() =>
      _AdminAddressesScreenState();
}

class _AdminAddressesScreenState
    extends State<AdminAddressesScreen> {
  // ============================================================
  // STATE
  // ============================================================

  bool _isLoading = true;
  String? _errorMessage;

  List<Map<String, dynamic>> _addresses = [];
  List<Map<String, dynamic>> _filteredAddresses = [];

  final TextEditingController _searchController =
      TextEditingController();

  final TextEditingController _pincodeController =
      TextEditingController();

  String _selectedCity = 'All Cities';

  // ============================================================
  // INIT
  // ============================================================

  @override
  void initState() {
    super.initState();

    _searchController.addListener(_applyFilters);
    _pincodeController.addListener(_applyFilters);

    _loadAddresses();
  }

  // ============================================================
  // DISPOSE
  // ============================================================

  @override
  void dispose() {
    _searchController.dispose();
    _pincodeController.dispose();

    super.dispose();
  }

  // ============================================================
  // LOAD ADDRESSES
  // ============================================================

  Future<void> _loadAddresses() async {
    if (!mounted) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final addresses =
          await ApiService.getAdminAddresses();

      if (!mounted) return;

      setState(() {
        _addresses =
            List<Map<String, dynamic>>.from(
          addresses,
        );

        _filteredAddresses =
            List<Map<String, dynamic>>.from(
          addresses,
        );

        _isLoading = false;
      });

      _applyFilters();
    } catch (error) {
      if (!mounted) return;

      setState(() {
        _isLoading = false;
        _errorMessage = error.toString();
      });
    }
  }

  // ============================================================
  // FILTERS
  // ============================================================

  void _applyFilters() {
    final search =
        _searchController.text
            .trim()
            .toLowerCase();

    final pincode =
        _pincodeController.text
            .trim()
            .toLowerCase();

    final filtered =
        _addresses.where((address) {
      final addressId =
          _value(
        address['address_id'],
      ).toLowerCase();

      final customerName =
          _value(
        address['customer_name'],
      ).toLowerCase();

      final customerMobile =
          _value(
        address['customer_mobile'],
      ).toLowerCase();

      final city =
          _value(
        address['city'],
      ).toLowerCase();

      final addressPincode =
          _value(
        address['pincode'],
      ).toLowerCase();

      final matchesSearch =
          search.isEmpty ||
          addressId.contains(search) ||
          customerName.contains(search) ||
          customerMobile.contains(search) ||
          city.contains(search);

      final matchesCity =
          _selectedCity == 'All Cities' ||
          city ==
              _selectedCity.toLowerCase();

      final matchesPincode =
          pincode.isEmpty ||
          addressPincode.contains(pincode);

      return matchesSearch &&
          matchesCity &&
          matchesPincode;
    }).toList();

    if (!mounted) return;

    setState(() {
      _filteredAddresses = filtered;
    });
  }

  void _clearFilters() {
    _searchController.clear();
    _pincodeController.clear();

    setState(() {
      _selectedCity = 'All Cities';
    });

    _applyFilters();
  }

  // ============================================================
  // VALUE HELPERS
  // ============================================================

  String _value(dynamic value) {
    if (value == null) {
      return '';
    }

    return value.toString().trim();
  }

  String _displayValue(
    dynamic value, {
    String fallback = '-',
  }) {
    final text = _value(value);

    if (text.isEmpty) {
      return fallback;
    }

    return text;
  }

  // ============================================================
  // BUILD FULL ADDRESS
  // ============================================================

  String _buildAddress(
    Map<String, dynamic> address,
  ) {
    final parts = <String>[];

    final house =
        _value(
      address['house_flat_number'],
    );

    final apartment =
        _value(
      address['apartment_name'],
    );

    final street =
        _value(
      address['street_area'],
    );

    final landmark =
        _value(
      address['landmark'],
    );

    if (house.isNotEmpty) {
      parts.add(house);
    }

    if (apartment.isNotEmpty) {
      parts.add(apartment);
    }

    if (street.isNotEmpty) {
      parts.add(street);
    }

    if (landmark.isNotEmpty) {
      parts.add(
        'Near $landmark',
      );
    }

    if (parts.isEmpty) {
      return 'Address not available';
    }

    return parts.join(', ');
  }

  // ============================================================
  // CITIES
  // ============================================================

  List<String> _getCities() {
    final cities = <String>{};

    for (final address in _addresses) {
      final city =
          _value(address['city']);

      if (city.isNotEmpty) {
        cities.add(city);
      }
    }

    final result = cities.toList();

    result.sort(
      (a, b) => a
          .toLowerCase()
          .compareTo(
            b.toLowerCase(),
          ),
    );

    return result;
  }

  // ============================================================
  // STATISTICS
  // ============================================================

  int get _uniqueCustomers {
    final customers = <String>{};

    for (final address in _addresses) {
      final customerId =
          _value(
        address['customer_id'],
      );

      if (customerId.isNotEmpty) {
        customers.add(customerId);
      }
    }

    return customers.length;
  }

  int get _chennaiAddresses {
    return _addresses.where(
      (address) {
        final city =
            _value(
          address['city'],
        ).toLowerCase();

        return city == 'chennai';
      },
    ).length;
  }

  int get _otherCityAddresses {
    return _addresses.length -
        _chennaiAddresses;
  }

  // ============================================================
  // DATE
  // ============================================================

  String _formatDate(dynamic value) {
    final raw = _value(value);

    if (raw.isEmpty) {
      return '-';
    }

    final date =
        DateTime.tryParse(raw);

    if (date == null) {
      return raw;
    }

    final local =
        date.toLocal();

    final day =
        local.day
            .toString()
            .padLeft(2, '0');

    final month =
        local.month
            .toString()
            .padLeft(2, '0');

    final year =
        local.year.toString();

    return '$day/$month/$year';
  }

  // ============================================================
  // DATE + TIME
  // ============================================================

  String _formatDateTime(dynamic value) {
    final raw = _value(value);

    if (raw.isEmpty) {
      return '-';
    }

    final date =
        DateTime.tryParse(raw);

    if (date == null) {
      return raw;
    }

    final local =
        date.toLocal();

    final day =
        local.day
            .toString()
            .padLeft(2, '0');

    final month =
        local.month
            .toString()
            .padLeft(2, '0');

    final year =
        local.year.toString();

    int hour = local.hour;

    final minute =
        local.minute
            .toString()
            .padLeft(2, '0');

    final period =
        hour >= 12 ? 'PM' : 'AM';

    hour = hour % 12;

    if (hour == 0) {
      hour = 12;
    }

    return '$day/$month/$year '
        '$hour:$minute $period';
  }

  // ============================================================
  // STATS
  // ============================================================

  List<AdminOrdersStyleStat>
      _ordersStyleAddressStats() {
    return [
      AdminOrdersStyleStat(
        title: 'Total Addresses',
        value:
            '${_addresses.length}',
        icon:
            Icons.location_on_outlined,
        iconBackground:
            const Color(0xFFEDEAFF),
        iconColor:
            AppColors.ctaPurple,
      ),

      AdminOrdersStyleStat(
        title: 'Unique Customers',
        value:
            '$_uniqueCustomers',
        icon:
            Icons.people_outline,
        iconBackground:
            const Color(0xFFE7F7ED),
        iconColor:
            Colors.green,
      ),

      AdminOrdersStyleStat(
        title: 'Chennai',
        value:
            '$_chennaiAddresses',
        icon:
            Icons.location_city_outlined,
        iconBackground:
            const Color(0xFFE9F2FF),
        iconColor:
            Colors.blue,
      ),

      AdminOrdersStyleStat(
        title: 'Other Cities',
        value:
            '$_otherCityAddresses',
        icon:
            Icons.public_outlined,
        iconBackground:
            const Color(0xFFFFF1DE),
        iconColor:
            Colors.orange,
      ),
    ];
  }

  // ============================================================
  // FILTER UI
  // ============================================================

  Widget _ordersStyleAddressFilters() {
    final cities = [
      'All Cities',
      ..._getCities(),
    ];

    return Column(
      crossAxisAlignment:
          CrossAxisAlignment.stretch,
      children: [
        AdminOrdersStyleFilterRow(
          controller:
              _searchController,
          hintText:
              'Search address, customer or mobile...',
          selectedValue:
              _selectedCity,
          values: cities,
          onChanged: (value) {
            if (value == null) {
              return;
            }

            setState(() {
              _selectedCity = value;
            });

            _applyFilters();
          },
          onSearchChanged: (_) {
            _applyFilters();
          },
          onClear: () {
            _searchController.clear();
            _applyFilters();
          },
        ),

        const SizedBox(height: 12),

        Align(
          alignment:
              Alignment.centerLeft,
          child: SizedBox(
            width: 220,
            child: TextField(
              controller:
                  _pincodeController,
              keyboardType:
                  TextInputType.number,
              style:
                  AppTextStyles.of(
                figmaSize: 14,
                weight:
                    FontWeight.w400,
                color:
                    AppColors.navy,
              ),
              decoration:
                  InputDecoration(
                hintText:
                    'Search pincode',
                hintStyle:
                    TextStyle(
                  color:
                      Colors.grey.shade500,
                  fontSize: 14,
                ),
                prefixIcon:
                    Icon(
                  Icons
                      .pin_drop_outlined,
                  color:
                      Colors.grey.shade600,
                ),
                filled: true,
                fillColor:
                    Colors.white,
                contentPadding:
                    const EdgeInsets
                        .symmetric(
                  horizontal: 16,
                  vertical: 15,
                ),
                border:
                    OutlineInputBorder(
                  borderRadius:
                      BorderRadius
                          .circular(13),
                  borderSide:
                      BorderSide(
                    color:
                        Colors.grey.shade200,
                  ),
                ),
                enabledBorder:
                    OutlineInputBorder(
                  borderRadius:
                      BorderRadius
                          .circular(13),
                  borderSide:
                      BorderSide(
                    color:
                        Colors.grey.shade200,
                  ),
                ),
                focusedBorder:
                    OutlineInputBorder(
                  borderRadius:
                      BorderRadius
                          .circular(13),
                  borderSide:
                      const BorderSide(
                    color:
                        AppColors.ctaPurple,
                    width: 1.4,
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ============================================================
  // CONTENT
  // ============================================================

  Widget _ordersStyleAddressContent() {
    if (_isLoading) {
      return const SizedBox(
        height: 180,
        child: Center(
          child:
              CircularProgressIndicator(
            color:
                AppColors.ctaPurple,
          ),
        ),
      );
    }

    if (_errorMessage != null) {
      return _buildErrorState();
    }

    if (_filteredAddresses.isEmpty) {
      return _buildEmptyState();
    }

    return LayoutBuilder(
      builder:
          (context, constraints) {
        if (constraints.maxWidth >=
            900) {
          return _buildDesktopTable();
        }

        return Column(
          children:
              _filteredAddresses
                  .map(
                    _buildMobileAddressCard,
                  )
                  .toList(),
        );
      },
    );
  }

  // ============================================================
  // MAIN BUILD
  // ============================================================

  @override
  Widget build(
    BuildContext context,
  ) {
    return AdminOrdersStyleShell(
      title: 'Addresses',
      subtitle:
          'Manage customer addresses and locations',
      refresh:
          _loadAddresses,
      stats:
          _ordersStyleAddressStats(),
      filters:
          _ordersStyleAddressFilters(),
      content:
          _ordersStyleAddressContent(),
    );
  }

  // ============================================================
  // DESKTOP TABLE
  // ============================================================

  Widget _buildDesktopTable() {
    return Container(
      decoration:
          BoxDecoration(
        color: Colors.white,
        borderRadius:
            BorderRadius.circular(16),
        border: Border.all(
          color:
              Colors.grey.shade200,
        ),
      ),
      child: ClipRRect(
        borderRadius:
            BorderRadius.circular(16),
        child:
            SingleChildScrollView(
          scrollDirection:
              Axis.horizontal,
          child:
              ConstrainedBox(
            constraints:
                const BoxConstraints(
              minWidth: 1100,
            ),
            child: DataTable(
              headingRowHeight:
                  52,
              dataRowMinHeight:
                  72,
              dataRowMaxHeight:
                  82,
              horizontalMargin:
                  20,
              columnSpacing:
                  28,
              headingRowColor:
                  WidgetStateProperty
                      .all(
                const Color(
                    0xFFFAFAFD),
              ),
              columns: [
                _tableColumn(
                    'Address'),
                _tableColumn(
                    'Customer'),
                _tableColumn(
                    'Mobile'),
                _tableColumn(
                    'Location'),
                _tableColumn(
                    'Pincode'),
                _tableColumn(
                    'Updated'),

                // Empty header for arrow.
                const DataColumn(
                  label:
                      SizedBox(
                    width: 38,
                  ),
                ),
              ],
              rows:
                  _filteredAddresses
                      .map(
                (address) {
                  return DataRow(
                    cells: [
                      // ADDRESS
                      DataCell(
                        SizedBox(
                          width: 300,
                          child:
                              _buildAddressCell(
                            address,
                          ),
                        ),
                      ),

                      // CUSTOMER
                      DataCell(
                        SizedBox(
                          width: 150,
                          child:
                              Text(
                            _displayValue(
                              address[
                                  'customer_name'],
                            ),
                            maxLines: 1,
                            overflow:
                                TextOverflow
                                    .ellipsis,
                            style:
                                AppTextStyles
                                    .of(
                              figmaSize:
                                  22.5,
                              weight:
                                  FontWeight
                                      .w600,
                              color:
                                  AppColors
                                      .navy,
                            ),
                          ),
                        ),
                      ),

                      // MOBILE
                      DataCell(
                        Text(
                          _displayValue(
                            address[
                                'customer_mobile'],
                          ),
                          style:
                              AppTextStyles
                                  .of(
                            figmaSize:
                                22.5,
                            weight:
                                FontWeight
                                    .w400,
                            color:
                                Colors
                                    .grey
                                    .shade600,
                          ),
                        ),
                      ),

                      // LOCATION
                      DataCell(
                        Text(
                          _displayValue(
                            address[
                                'city'],
                          ),
                          style:
                              AppTextStyles
                                  .of(
                            figmaSize:
                                22.5,
                            weight:
                                FontWeight
                                    .w600,
                            color:
                                AppColors
                                    .navy,
                          ),
                        ),
                      ),

                      // PINCODE
                      DataCell(
                        _buildPincodeBadge(
                          _displayValue(
                            address[
                                'pincode'],
                          ),
                        ),
                      ),

                      // UPDATED
                      DataCell(
                        Text(
                          _formatDate(
                            address[
                                'updated_at'],
                          ),
                          style:
                              AppTextStyles
                                  .of(
                            figmaSize:
                                22.5,
                            weight:
                                FontWeight
                                    .w400,
                            color:
                                Colors
                                    .grey
                                    .shade600,
                          ),
                        ),
                      ),

                      // ARROW
                      DataCell(
                        _buildArrowAction(
                          address,
                        ),
                      ),
                    ],
                  );
                },
              ).toList(),
            ),
          ),
        ),
      ),
    );
  }

  // ============================================================
  // TABLE HEADER
  // ============================================================

  DataColumn _tableColumn(
    String title,
  ) {
    return DataColumn(
      label: Text(
        title,
        style:
            AppTextStyles.of(
          figmaSize: 22,
          weight:
              FontWeight.w700,
          color:
              Colors.grey.shade600,
        ),
      ),
    );
  }

  // ============================================================
  // ARROW
  // ============================================================

  Widget _buildArrowAction(
    Map<String, dynamic> address,
  ) {
    return InkWell(
      borderRadius:
          BorderRadius.circular(20),
      onTap: () {
        _showAddressDetailsDialog(
          address,
        );
      },
      child: const Padding(
        padding:
            EdgeInsets.all(6),
        child: Icon(
          Icons.chevron_right_rounded,
          size: 30,
          color:
              Color(0xFF777B91),
        ),
      ),
    );
  }

  // ============================================================
  // ADDRESS CELL
  // ============================================================

  Widget _buildAddressCell(
    Map<String, dynamic> address,
  ) {
    return Row(
      crossAxisAlignment:
          CrossAxisAlignment.center,
      children: [
        Container(
          width: 42,
          height: 42,
          decoration:
              BoxDecoration(
            color:
                const Color(0xFFEDEAFF),
            borderRadius:
                BorderRadius.circular(
              13,
            ),
          ),
          child:
              const Center(
            child: Icon(
              Icons.home_outlined,
              color:
                  AppColors.ctaPurple,
              size: 21,
            ),
          ),
        ),

        const SizedBox(width: 12),

        Expanded(
          child: Column(
            crossAxisAlignment:
                CrossAxisAlignment
                    .start,
            mainAxisAlignment:
                MainAxisAlignment
                    .center,
            children: [
              Text(
                'Address #${_displayValue(address['address_id'])}',
                maxLines: 1,
                overflow:
                    TextOverflow
                        .ellipsis,
                style:
                    AppTextStyles.of(
                  figmaSize: 22.5,
                  weight:
                      FontWeight.w700,
                  color:
                      AppColors.navy,
                ),
              ),

              const SizedBox(
                  height: 4),

              Text(
                _buildAddress(
                  address,
                ),
                maxLines: 2,
                overflow:
                    TextOverflow
                        .ellipsis,
                style:
                    AppTextStyles.of(
                  figmaSize: 22.5,
                  weight:
                      FontWeight.w400,
                  color:
                      Colors.grey
                          .shade600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ============================================================
  // PINCODE
  // ============================================================

  Widget _buildPincodeBadge(
    String pincode,
  ) {
    return Container(
      padding:
          const EdgeInsets.symmetric(
        horizontal: 10,
        vertical: 7,
      ),
      decoration:
          BoxDecoration(
        color:
            const Color(0xFFEDEAFF),
        borderRadius:
            BorderRadius.circular(
          8,
        ),
      ),
      child: Text(
        pincode,
        style:
            AppTextStyles.of(
          figmaSize: 22.5,
          weight:
              FontWeight.w700,
          color:
              AppColors.navy,
        ),
      ),
    );
  }

  // ============================================================
  // MOBILE CARD
  // ============================================================

  Widget _buildMobileAddressCard(
    Map<String, dynamic> address,
  ) {
    return Container(
      margin:
          const EdgeInsets.only(
        bottom: 12,
      ),
      padding:
          const EdgeInsets.all(16),
      decoration:
          BoxDecoration(
        color: Colors.white,
        borderRadius:
            BorderRadius.circular(16),
        border: Border.all(
          color:
              Colors.grey.shade200,
        ),
      ),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment
                .start,
        children: [
          Row(
            crossAxisAlignment:
                CrossAxisAlignment
                    .center,
            children: [
              Container(
                width: 42,
                height: 42,
                decoration:
                    BoxDecoration(
                  color:
                      const Color(
                    0xFFEDEAFF,
                  ),
                  borderRadius:
                      BorderRadius.circular(
                    13,
                  ),
                ),
                child:
                    const Center(
                  child: Icon(
                    Icons.home_outlined,
                    color:
                        AppColors
                            .ctaPurple,
                    size: 21,
                  ),
                ),
              ),

              const SizedBox(
                  width: 11),

              Expanded(
                child:
                    Column(
                  crossAxisAlignment:
                      CrossAxisAlignment
                          .start,
                  children: [
                    Text(
                      'Address #${_displayValue(address['address_id'])}',
                      style:
                          AppTextStyles
                              .of(
                        figmaSize: 20,
                        weight:
                            FontWeight
                                .w700,
                        color:
                            AppColors
                                .navy,
                      ),
                    ),
                    const SizedBox(
                        height: 3),
                    Text(
                      _displayValue(
                        address[
                            'customer_name'],
                      ),
                      style:
                          AppTextStyles
                              .of(
                        figmaSize: 17,
                        weight:
                            FontWeight
                                .w600,
                        color:
                            AppColors
                                .navy,
                      ),
                    ),
                  ],
                ),
              ),

              _buildArrowAction(
                address,
              ),
            ],
          ),

          const SizedBox(
              height: 15),

          Container(
            width:
                double.infinity,
            padding:
                const EdgeInsets.all(
              12,
            ),
            decoration:
                BoxDecoration(
              color:
                  const Color(
                0xFFFAFAFD,
              ),
              borderRadius:
                  BorderRadius.circular(
                11,
              ),
            ),
            child: Text(
              _buildAddress(
                address,
              ),
              style:
                  AppTextStyles.of(
                figmaSize: 16,
                weight:
                    FontWeight.w400,
                color:
                    AppColors.navy,
                height: 1.35,
              ),
            ),
          ),

          const SizedBox(
              height: 14),

          Row(
            children: [
              Expanded(
                child:
                    _buildInfoItem(
                  Icons
                      .phone_outlined,
                  _displayValue(
                    address[
                        'customer_mobile'],
                  ),
                ),
              ),

              const SizedBox(
                  width: 10),

              Expanded(
                child:
                    _buildInfoItem(
                  Icons
                      .location_city_outlined,
                  _displayValue(
                    address[
                        'city'],
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(
              height: 10),

          Row(
            children: [
              Expanded(
                child:
                    _buildInfoItem(
                  Icons
                      .person_outline_rounded,
                  'Customer #${_displayValue(address['customer_id'])}',
                ),
              ),

              const SizedBox(
                  width: 10),

              Expanded(
                child:
                    _buildInfoItem(
                  Icons
                      .update_rounded,
                  _formatDate(
                    address[
                        'updated_at'],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ============================================================
  // MOBILE INFO ITEM
  // ============================================================

  Widget _buildInfoItem(
    IconData icon,
    String value,
  ) {
    return Row(
      crossAxisAlignment:
          CrossAxisAlignment
              .start,
      children: [
        Icon(
          icon,
          size: 18,
          color:
              AppColors.ctaPurple,
        ),

        const SizedBox(
            width: 6),

        Expanded(
          child: Text(
            value,
            maxLines: 2,
            overflow:
                TextOverflow.ellipsis,
            style:
                AppTextStyles.of(
              figmaSize: 14,
              weight:
                  FontWeight.w400,
              color:
                  Colors.grey.shade600,
            ),
          ),
        ),
      ],
    );
  }

  // ============================================================
  // ADDRESS DETAILS POPUP
  // ============================================================

  void _showAddressDetailsDialog(
    Map<String, dynamic> address,
  ) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (dialogContext) {
        return Dialog(
          insetPadding:
              const EdgeInsets.symmetric(
            horizontal: 32,
            vertical: 28,
          ),
          backgroundColor:
              Colors.white,
          shape:
              RoundedRectangleBorder(
            borderRadius:
                BorderRadius.circular(
              26,
            ),
          ),
          child: ConstrainedBox(
            constraints:
                const BoxConstraints(
              maxWidth: 850,
              maxHeight: 720,
            ),
            child: Column(
              children: [
                // ==================================================
                // HEADER
                // ==================================================

                Container(
                  padding:
                      const EdgeInsets.fromLTRB(
                    24,
                    18,
                    18,
                    18,
                  ),
                  decoration:
                      BoxDecoration(
                    color:
                        Colors.white,
                    borderRadius:
                        const BorderRadius
                            .vertical(
                      top:
                          Radius.circular(
                        26,
                      ),
                    ),
                    border:
                        Border(
                      bottom:
                          BorderSide(
                        color:
                            Colors.grey
                                .shade200,
                      ),
                    ),
                  ),
                  child: Row(
                    children: [
                      // ICON
                      Container(
                        width: 54,
                        height: 54,
                        decoration:
                            BoxDecoration(
                          color:
                              const Color(
                            0xFFEDE7FF,
                          ),
                          borderRadius:
                              BorderRadius
                                  .circular(
                            16,
                          ),
                        ),
                        child:
                            const Icon(
                          Icons
                              .location_on_outlined,
                          color:
                              AppColors
                                  .ctaPurple,
                          size: 29,
                        ),
                      ),

                      const SizedBox(
                          width: 14),

                      // TITLE
                      Expanded(
                        child:
                            Column(
                          crossAxisAlignment:
                              CrossAxisAlignment
                                  .start,
                          children: [
                            Text(
                              'Address #${_displayValue(address['address_id'])}',
                              style:
                                  AppTextStyles
                                      .of(
                                figmaSize:
                                    22,
                                weight:
                                    FontWeight
                                        .w800,
                                color:
                                    AppColors
                                        .navy,
                              ),
                            ),

                            const SizedBox(
                                height: 4),

                            Text(
                              _displayValue(
                                address[
                                    'customer_name'],
                              ),
                              style:
                                  AppTextStyles
                                      .of(
                                figmaSize:
                                    14,
                                weight:
                                    FontWeight
                                        .w400,
                                color:
                                    Colors
                                        .grey
                                        .shade600,
                              ),
                            ),
                          ],
                        ),
                      ),

                      // CLOSE
                      Material(
                        color:
                            const Color(
                          0xFFF7F6FC,
                        ),
                        shape:
                            const CircleBorder(),
                        child:
                            InkWell(
                          customBorder:
                              const CircleBorder(),
                          onTap: () {
                            Navigator
                                .pop(
                              dialogContext,
                            );
                          },
                          child:
                              const SizedBox(
                            width: 52,
                            height: 52,
                            child:
                                Icon(
                              Icons
                                  .close_rounded,
                              size: 27,
                              color:
                                  AppColors
                                      .navy,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // ==================================================
                // SCROLLABLE CONTENT
                // ==================================================

                Expanded(
                  child:
                      SingleChildScrollView(
                    padding:
                        const EdgeInsets
                            .fromLTRB(
                      24,
                      20,
                      24,
                      20,
                    ),
                    child:
                        Column(
                      crossAxisAlignment:
                          CrossAxisAlignment
                              .start,
                      children: [
                        // CUSTOMER
                        _addressPopupSectionTitle(
                          'Customer Details',
                        ),

                        const SizedBox(
                            height: 10),

                        _addressPopupCard(
                          icon: Icons
                              .person_outline_rounded,
                          label:
                              'Customer Name',
                          value:
                              _displayValue(
                            address[
                                'customer_name'],
                          ),
                        ),

                        const SizedBox(
                            height: 10),

                        _addressPopupCard(
                          icon: Icons
                              .phone_outlined,
                          label:
                              'Mobile',
                          value:
                              _displayValue(
                            address[
                                'customer_mobile'],
                          ),
                        ),

                        const SizedBox(
                            height: 10),

                        _addressPopupCard(
                          icon: Icons
                              .email_outlined,
                          label:
                              'Email',
                          value:
                              _displayValue(
                            address[
                                'customer_email'],
                          ),
                        ),

                        const SizedBox(
                            height: 22),

                        // ADDRESS
                        _addressPopupSectionTitle(
                          'Address Details',
                        ),

                        const SizedBox(
                            height: 10),

                        _addressPopupCard(
                          icon: Icons
                              .home_outlined,
                          label:
                              'House / Flat Number',
                          value:
                              _displayValue(
                            address[
                                'house_flat_number'],
                          ),
                        ),

                        const SizedBox(
                            height: 10),

                        _addressPopupCard(
                          icon: Icons
                              .apartment_outlined,
                          label:
                              'Apartment Name',
                          value:
                              _displayValue(
                            address[
                                'apartment_name'],
                          ),
                        ),

                        const SizedBox(
                            height: 10),

                        _addressPopupCard(
                          icon: Icons
                              .signpost_outlined,
                          label:
                              'Street / Area',
                          value:
                              _displayValue(
                            address[
                                'street_area'],
                          ),
                        ),

                        const SizedBox(
                            height: 10),

                        _addressPopupCard(
                          icon: Icons
                              .location_on_outlined,
                          label:
                              'Landmark',
                          value:
                              _displayValue(
                            address[
                                'landmark'],
                          ),
                        ),

                        const SizedBox(
                            height: 22),

                        // LOCATION
                        _addressPopupSectionTitle(
                          'Location',
                        ),

                        const SizedBox(
                            height: 10),

                        Row(
                          children: [
                            Expanded(
                              child:
                                  _addressPopupCard(
                                icon: Icons
                                    .location_city_outlined,
                                label:
                                    'City',
                                value:
                                    _displayValue(
                                  address[
                                      'city'],
                                ),
                              ),
                            ),

                            const SizedBox(
                                width: 12),

                            Expanded(
                              child:
                                  _addressPopupCard(
                                icon: Icons
                                    .pin_drop_outlined,
                                label:
                                    'Pincode',
                                value:
                                    _displayValue(
                                  address[
                                      'pincode'],
                                ),
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(
                            height: 22),

                        // INFORMATION
                        _addressPopupSectionTitle(
                          'Address Information',
                        ),

                        const SizedBox(
                            height: 10),

                        _addressPopupCard(
                          icon: Icons
                              .update_outlined,
                          label:
                              'Last Updated',
                          value:
                              _formatDateTime(
                            address[
                                'updated_at'],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // ==================================================
                // BOTTOM ACTIONS
                // ==================================================

                Container(
                  padding:
                      const EdgeInsets
                          .fromLTRB(
                    24,
                    14,
                    24,
                    18,
                  ),
                  decoration:
                      BoxDecoration(
                    color:
                        Colors.white,
                    borderRadius:
                        const BorderRadius
                            .vertical(
                      bottom:
                          Radius.circular(
                        26,
                      ),
                    ),
                    border:
                        Border(
                      top:
                          BorderSide(
                        color:
                            Colors.grey
                                .shade200,
                      ),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment:
                        MainAxisAlignment
                            .end,
                    children: [
                      // CLOSE
                      OutlinedButton(
                        onPressed: () {
                          Navigator
                              .pop(
                            dialogContext,
                          );
                        },
                        style:
                            OutlinedButton
                                .styleFrom(
                          foregroundColor:
                              AppColors
                                  .navy,
                          side:
                              BorderSide(
                            color:
                                Colors
                                    .grey
                                    .shade300,
                          ),
                          padding:
                              const EdgeInsets
                                  .symmetric(
                            horizontal:
                                24,
                            vertical:
                                13,
                          ),
                          shape:
                              RoundedRectangleBorder(
                            borderRadius:
                                BorderRadius
                                    .circular(
                              10,
                            ),
                          ),
                        ),
                        child:
                            const Text(
                          'Close',
                        ),
                      ),

                      const SizedBox(
                          width: 10),

                      // EDIT
                      ElevatedButton.icon(
                        onPressed: () {
                          Navigator
                              .pop(
                            dialogContext,
                          );

                          _showEditAddressDialog(
                            address,
                          );
                        },
                        icon:
                            const Icon(
                          Icons
                              .edit_outlined,
                          size: 18,
                        ),
                        label:
                            const Text(
                          'Edit Address',
                        ),
                        style:
                            ElevatedButton
                                .styleFrom(
                          backgroundColor:
                              AppColors
                                  .ctaPurple,
                          foregroundColor:
                              Colors.white,
                          elevation:
                              0,
                          padding:
                              const EdgeInsets
                                  .symmetric(
                            horizontal:
                                20,
                            vertical:
                                13,
                          ),
                          shape:
                              RoundedRectangleBorder(
                            borderRadius:
                                BorderRadius
                                    .circular(
                              10,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // ============================================================
  // POPUP SECTION TITLE
  // ============================================================

  Widget _addressPopupSectionTitle(
    String title,
  ) {
    return Text(
      title,
      style:
          AppTextStyles.of(
        figmaSize: 16,
        weight:
            FontWeight.w700,
        color:
            AppColors.navy,
      ),
    );
  }

  // ============================================================
  // POPUP DETAIL CARD
  // ============================================================

  Widget _addressPopupCard({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Container(
      width:
          double.infinity,
      padding:
          const EdgeInsets.all(
        14,
      ),
      decoration:
          BoxDecoration(
        color: Colors.white,
        borderRadius:
            BorderRadius.circular(
          14,
        ),
        border: Border.all(
          color:
              Colors.grey.shade200,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration:
                BoxDecoration(
              color:
                  const Color(
                0xFFEDE7FF,
              ),
              borderRadius:
                  BorderRadius.circular(
                12,
              ),
            ),
            child: Icon(
              icon,
              color:
                  AppColors.ctaPurple,
              size: 21,
            ),
          ),

          const SizedBox(
              width: 12),

          Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment
                      .start,
              children: [
                Text(
                  label,
                  style:
                      AppTextStyles
                          .of(
                    figmaSize:
                        12,
                    weight:
                        FontWeight
                            .w500,
                    color:
                        Colors
                            .grey
                            .shade600,
                  ),
                ),

                const SizedBox(
                    height: 4),

                Text(
                  value,
                  maxLines: 2,
                  overflow:
                      TextOverflow
                          .ellipsis,
                  style:
                      AppTextStyles
                          .of(
                    figmaSize:
                        15,
                    weight:
                        FontWeight
                            .w600,
                    color:
                        AppColors
                            .navy,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // EDIT ADDRESS POPUP
  // ============================================================

  void _showEditAddressDialog(
    Map<String, dynamic> address,
  ) {
    final houseController =
        TextEditingController(
      text:
          _value(
        address[
            'house_flat_number'],
      ),
    );

    final apartmentController =
        TextEditingController(
      text:
          _value(
        address[
            'apartment_name'],
      ),
    );

    final streetController =
        TextEditingController(
      text:
          _value(
        address[
            'street_area'],
      ),
    );

    final landmarkController =
        TextEditingController(
      text:
          _value(
        address['landmark'],
      ),
    );

    final cityController =
        TextEditingController(
      text:
          _value(
        address['city'],
      ),
    );

    final pincodeController =
        TextEditingController(
      text:
          _value(
        address['pincode'],
      ),
    );

    showDialog(
      context: context,
      builder: (dialogContext) {
        return Dialog(
          insetPadding:
              const EdgeInsets.symmetric(
            horizontal: 32,
            vertical: 28,
          ),
          backgroundColor:
              Colors.white,
          shape:
              RoundedRectangleBorder(
            borderRadius:
                BorderRadius.circular(
              26,
            ),
          ),
          child: ConstrainedBox(
            constraints:
                const BoxConstraints(
              maxWidth: 650,
              maxHeight: 720,
            ),
            child: Column(
              children: [
                // HEADER
                Container(
                  padding:
                      const EdgeInsets
                          .fromLTRB(
                    24,
                    18,
                    18,
                    18,
                  ),
                  decoration:
                      BoxDecoration(
                    border:
                        Border(
                      bottom:
                          BorderSide(
                        color:
                            Colors
                                .grey
                                .shade200,
                      ),
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 54,
                        height: 54,
                        decoration:
                            BoxDecoration(
                          color:
                              const Color(
                            0xFFEDE7FF,
                          ),
                          borderRadius:
                              BorderRadius
                                  .circular(
                            16,
                          ),
                        ),
                        child:
                            const Icon(
                          Icons
                              .edit_outlined,
                          color:
                              AppColors
                                  .ctaPurple,
                          size: 27,
                        ),
                      ),

                      const SizedBox(
                          width: 14),

                      Expanded(
                        child:
                            Column(
                          crossAxisAlignment:
                              CrossAxisAlignment
                                  .start,
                          children: [
                            Text(
                              'Edit Address',
                              style:
                                  AppTextStyles
                                      .of(
                                figmaSize:
                                    22,
                                weight:
                                    FontWeight
                                        .w800,
                                color:
                                    AppColors
                                        .navy,
                              ),
                            ),
                            const SizedBox(
                                height: 4),
                            Text(
                              'Address #${_displayValue(address['address_id'])}',
                              style:
                                  AppTextStyles
                                      .of(
                                figmaSize:
                                    14,
                                weight:
                                    FontWeight
                                        .w400,
                                color:
                                    Colors
                                        .grey
                                        .shade600,
                              ),
                            ),
                          ],
                        ),
                      ),

                      Material(
                        color:
                            const Color(
                          0xFFF7F6FC,
                        ),
                        shape:
                            const CircleBorder(),
                        child:
                            InkWell(
                          customBorder:
                              const CircleBorder(),
                          onTap: () {
                            Navigator
                                .pop(
                              dialogContext,
                            );
                          },
                          child:
                              const SizedBox(
                            width: 52,
                            height: 52,
                            child:
                                Icon(
                              Icons
                                  .close_rounded,
                              size: 27,
                              color:
                                  AppColors
                                      .navy,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // FORM
                Expanded(
                  child:
                      SingleChildScrollView(
                    padding:
                        const EdgeInsets
                            .fromLTRB(
                      24,
                      20,
                      24,
                      20,
                    ),
                    child:
                        Column(
                      crossAxisAlignment:
                          CrossAxisAlignment
                              .start,
                      children: [
                        Text(
                          'Customer Details',
                          style:
                              AppTextStyles
                                  .of(
                            figmaSize:
                                16,
                            weight:
                                FontWeight
                                    .w700,
                            color:
                                AppColors
                                    .navy,
                          ),
                        ),

                        const SizedBox(
                            height: 10),

                        Container(
                          width:
                              double.infinity,
                          padding:
                              const EdgeInsets
                                  .all(
                            14,
                          ),
                          decoration:
                              BoxDecoration(
                            color:
                                const Color(
                              0xFFFAFAFD,
                            ),
                            borderRadius:
                                BorderRadius
                                    .circular(
                              14,
                            ),
                          ),
                          child:
                              Column(
                            crossAxisAlignment:
                                CrossAxisAlignment
                                    .start,
                            children: [
                              Text(
                                _displayValue(
                                  address[
                                      'customer_name'],
                                ),
                                style:
                                    AppTextStyles
                                        .of(
                                  figmaSize:
                                      16,
                                  weight:
                                      FontWeight
                                          .w700,
                                  color:
                                      AppColors
                                          .navy,
                                ),
                              ),
                              const SizedBox(
                                  height: 4),
                              Text(
                                _displayValue(
                                  address[
                                      'customer_mobile'],
                                ),
                                style:
                                    AppTextStyles
                                        .of(
                                  figmaSize:
                                      13,
                                  weight:
                                      FontWeight
                                          .w400,
                                  color:
                                      Colors
                                          .grey
                                          .shade600,
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(
                            height: 22),

                        Text(
                          'Address Details',
                          style:
                              AppTextStyles
                                  .of(
                            figmaSize:
                                16,
                            weight:
                                FontWeight
                                    .w700,
                            color:
                                AppColors
                                    .navy,
                          ),
                        ),

                        const SizedBox(
                            height: 10),

                        _editField(
                          'House / Flat Number',
                          houseController,
                        ),

                        _editField(
                          'Apartment Name',
                          apartmentController,
                        ),

                        _editField(
                          'Street / Area',
                          streetController,
                        ),

                        _editField(
                          'Landmark',
                          landmarkController,
                        ),

                        const SizedBox(
                            height: 8),

                        Text(
                          'Location',
                          style:
                              AppTextStyles
                                  .of(
                            figmaSize:
                                16,
                            weight:
                                FontWeight
                                    .w700,
                            color:
                                AppColors
                                    .navy,
                          ),
                        ),

                        const SizedBox(
                            height: 10),

                        _editField(
                          'City',
                          cityController,
                        ),

                        _editField(
                          'Pincode',
                          pincodeController,
                          keyboardType:
                              TextInputType
                                  .number,
                        ),
                      ],
                    ),
                  ),
                ),

                // BOTTOM ACTIONS
                Container(
                  padding:
                      const EdgeInsets
                          .fromLTRB(
                    24,
                    14,
                    24,
                    18,
                  ),
                  decoration:
                      BoxDecoration(
                    border:
                        Border(
                      top:
                          BorderSide(
                        color:
                            Colors
                                .grey
                                .shade200,
                      ),
                    ),
                  ),
                  child:
                      Row(
                    mainAxisAlignment:
                        MainAxisAlignment
                            .end,
                    children: [
                      OutlinedButton(
                        onPressed: () {
                          Navigator
                              .pop(
                            dialogContext,
                          );
                        },
                        style:
                            OutlinedButton
                                .styleFrom(
                          foregroundColor:
                              AppColors
                                  .navy,
                          side:
                              BorderSide(
                            color:
                                Colors
                                    .grey
                                    .shade300,
                          ),
                          padding:
                              const EdgeInsets
                                  .symmetric(
                            horizontal:
                                24,
                            vertical:
                                13,
                          ),
                          shape:
                              RoundedRectangleBorder(
                            borderRadius:
                                BorderRadius
                                    .circular(
                              10,
                            ),
                          ),
                        ),
                        child:
                            const Text(
                          'Cancel',
                        ),
                      ),

                      const SizedBox(
                          width: 10),

                      ElevatedButton.icon(
                        onPressed: () {
                          _saveAddressLocally(
                            address:
                                address,
                            house:
                                houseController
                                    .text,
                            apartment:
                                apartmentController
                                    .text,
                            street:
                                streetController
                                    .text,
                            landmark:
                                landmarkController
                                    .text,
                            city:
                                cityController
                                    .text,
                            pincode:
                                pincodeController
                                    .text,
                          );

                          Navigator
                              .pop(
                            dialogContext,
                          );
                        },
                        icon:
                            const Icon(
                          Icons
                              .save_outlined,
                          size: 18,
                        ),
                        label:
                            const Text(
                          'Save Changes',
                        ),
                        style:
                            ElevatedButton
                                .styleFrom(
                          backgroundColor:
                              AppColors
                                  .ctaPurple,
                          foregroundColor:
                              Colors.white,
                          elevation:
                              0,
                          padding:
                              const EdgeInsets
                                  .symmetric(
                            horizontal:
                                20,
                            vertical:
                                13,
                          ),
                          shape:
                              RoundedRectangleBorder(
                            borderRadius:
                                BorderRadius
                                    .circular(
                              10,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // ============================================================
  // EDIT FIELD
  // ============================================================

  Widget _editField(
    String label,
    TextEditingController controller, {
    TextInputType? keyboardType,
  }) {
    return Padding(
      padding:
          const EdgeInsets.only(
        bottom: 14,
      ),
      child: TextField(
        controller:
            controller,
        keyboardType:
            keyboardType,
        style:
            AppTextStyles.of(
          figmaSize: 14,
          weight:
              FontWeight.w500,
          color:
              AppColors.navy,
        ),
        decoration:
            InputDecoration(
          labelText:
              label,
          labelStyle:
              TextStyle(
            color:
                Colors.grey.shade600,
            fontSize: 13,
          ),
          filled: true,
          fillColor:
              const Color(
            0xFFFAFAFD,
          ),
          contentPadding:
              const EdgeInsets
                  .symmetric(
            horizontal: 14,
            vertical: 14,
          ),
          border:
              OutlineInputBorder(
            borderRadius:
                BorderRadius.circular(
              11,
            ),
            borderSide:
                BorderSide(
              color:
                  Colors.grey.shade200,
            ),
          ),
          enabledBorder:
              OutlineInputBorder(
            borderRadius:
                BorderRadius.circular(
              11,
            ),
            borderSide:
                BorderSide(
              color:
                  Colors.grey.shade200,
            ),
          ),
          focusedBorder:
              OutlineInputBorder(
            borderRadius:
                BorderRadius.circular(
              11,
            ),
            borderSide:
                const BorderSide(
              color:
                  AppColors.ctaPurple,
              width: 1.4,
            ),
          ),
        ),
      ),
    );
  }

  // ============================================================
  // SAVE LOCALLY
  // ============================================================

  void _saveAddressLocally({
    required Map<String, dynamic>
        address,
    required String house,
    required String apartment,
    required String street,
    required String landmark,
    required String city,
    required String pincode,
  }) {
    final addressId =
        _value(
      address['address_id'],
    );

    final index =
        _addresses.indexWhere(
      (item) =>
          _value(
            item['address_id'],
          ) ==
          addressId,
    );

    if (index == -1) {
      return;
    }

    setState(() {
      _addresses[index]
          ['house_flat_number'] =
          house.trim();

      _addresses[index]
          ['apartment_name'] =
          apartment.trim();

      _addresses[index]
          ['street_area'] =
          street.trim();

      _addresses[index]
          ['landmark'] =
          landmark.trim();

      _addresses[index]
          ['city'] =
          city.trim();

      _addresses[index]
          ['pincode'] =
          pincode.trim();
    });

    _applyFilters();

    ScaffoldMessenger.of(context)
        .showSnackBar(
      const SnackBar(
        content: Text(
          'Address updated in the current view.',
        ),
        behavior:
            SnackBarBehavior.floating,
      ),
    );
  }

  // ============================================================
  // ERROR STATE
  // ============================================================

  Widget _buildErrorState() {
    return Container(
      padding:
          const EdgeInsets.all(
        28,
      ),
      decoration:
          BoxDecoration(
        color: Colors.white,
        borderRadius:
            BorderRadius.circular(
          16,
        ),
        border: Border.all(
          color:
              Colors.grey.shade200,
        ),
      ),
      child:
          Column(
        mainAxisSize:
            MainAxisSize.min,
        children: [
          const Icon(
            Icons.cloud_off_rounded,
            size: 46,
            color:
                Colors.redAccent,
          ),

          const SizedBox(
              height: 14),

          Text(
            'Unable to load addresses',
            style:
                AppTextStyles.of(
              figmaSize: 27,
              weight:
                  FontWeight.w700,
              color:
                  AppColors.navy,
            ),
          ),

          const SizedBox(
              height: 7),

          Text(
            _errorMessage ??
                'Something went wrong.',
            textAlign:
                TextAlign.center,
            style:
                AppTextStyles.of(
              figmaSize: 20.5,
              weight:
                  FontWeight.w400,
              color:
                  Colors.grey.shade600,
            ),
          ),

          const SizedBox(
              height: 18),

          ElevatedButton.icon(
            onPressed:
                _loadAddresses,
            icon:
                const Icon(
              Icons
                  .refresh_rounded,
            ),
            label:
                const Text(
              'Try Again',
            ),
            style:
                ElevatedButton
                    .styleFrom(
              backgroundColor:
                  AppColors
                      .ctaPurple,
              foregroundColor:
                  Colors.white,
              elevation: 0,
              padding:
                  const EdgeInsets
                      .symmetric(
                horizontal: 20,
                vertical: 13,
              ),
              shape:
                  RoundedRectangleBorder(
                borderRadius:
                    BorderRadius.circular(
                  11,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // EMPTY STATE
  // ============================================================

  Widget _buildEmptyState() {
    return Container(
      padding:
          const EdgeInsets
              .symmetric(
        horizontal: 20,
        vertical: 60,
      ),
      decoration:
          BoxDecoration(
        color: Colors.white,
        borderRadius:
            BorderRadius.circular(
          16,
        ),
        border: Border.all(
          color:
              Colors.grey.shade200,
        ),
      ),
      child:
          Column(
        mainAxisSize:
            MainAxisSize.min,
        children: [
          Container(
            width: 68,
            height: 68,
            decoration:
                BoxDecoration(
              color:
                  const Color(
                0xFFEDEAFF,
              ),
              borderRadius:
                  BorderRadius.circular(
                20,
              ),
            ),
            child:
                const Icon(
              Icons
                  .location_off_outlined,
              color:
                  AppColors.ctaPurple,
              size: 32,
            ),
          ),

          const SizedBox(
              height: 16),

          Text(
            'No addresses found',
            style:
                AppTextStyles.of(
              figmaSize: 27,
              weight:
                  FontWeight.w700,
              color:
                  AppColors.navy,
            ),
          ),

          const SizedBox(
              height: 7),

          Text(
            'Try changing your search or filter.',
            textAlign:
                TextAlign.center,
            style:
                AppTextStyles.of(
              figmaSize: 22.5,
              weight:
                  FontWeight.w400,
              color:
                  Colors.grey.shade600,
            ),
          ),

          const SizedBox(
              height: 18),

          OutlinedButton(
            onPressed:
                _clearFilters,
            child:
                const Text(
              'Clear Filters',
            ),
          ),
        ],
      ),
    );
  }
}