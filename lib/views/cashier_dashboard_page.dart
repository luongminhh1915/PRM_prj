import 'dart:async';

import 'package:flutter/material.dart';
import 'package:supermarket_manager_system/data/services/customer_api_service.dart';
import 'package:supermarket_manager_system/data/services/order_api_service.dart';
import 'package:supermarket_manager_system/data/services/product_api_service.dart';
import 'package:supermarket_manager_system/models/checkout_invoice.dart';
import 'package:supermarket_manager_system/models/product_list_item.dart';
import 'package:supermarket_manager_system/views/widgets/cashier_product_search_dialog.dart';
import 'package:supermarket_manager_system/models/customer_list_item.dart';
import 'package:supermarket_manager_system/models/order_detail.dart';
import 'package:supermarket_manager_system/models/order_list_item.dart';
import 'package:supermarket_manager_system/models/user_detail.dart';
import 'package:supermarket_manager_system/views/profile_content_page.dart';
import 'package:supermarket_manager_system/views/widgets/order_detail_card.dart';
import 'package:supermarket_manager_system/utils/app_session.dart';

enum _CashierTab {
  scanner,
  customers,
  customerHistory,
  orderDetail,
  profile,
  profileEdit,
}

class CashierDashboardPage extends StatefulWidget {
  const CashierDashboardPage({
    super.key,
    required this.fullName,
    required this.userId,
    required this.initialTabKey,
    required this.initialPhone,
    required this.initialOrderId,
    required this.onNavigatePath,
    required this.onLogoutRequested,
  });

  final String fullName;
  final int userId;
  final String initialTabKey;
  final String initialPhone;
  final int? initialOrderId;
  final void Function(String path) onNavigatePath;
  final VoidCallback onLogoutRequested;

  @override
  State<CashierDashboardPage> createState() => _CashierDashboardPageState();
}

class _CashierDashboardPageState extends State<CashierDashboardPage> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final _customerApiService = CustomerApiService();
  final _orderApiService = OrderApiService();
  final _productApiService = ProductApiService();
  final TextEditingController _totalCashEndController = TextEditingController();
  /// Barcode scanner (desktop) — customer + cart total for "Add customer for points".
  final TextEditingController _scannerCustomerNameController =
      TextEditingController();
  final TextEditingController _scannerCustomerPhoneController =
      TextEditingController();
  /// Grand total for current sale; updated from cart lines.
  double _scannerGrandTotal = 0;
  final TextEditingController _scannerBarcodeController =
      TextEditingController();
  final TextEditingController _scannerSearchQueryController =
      TextEditingController();
  List<ProductListItem> _productCatalog = [];
  bool _loadingProductCatalog = false;
  final List<_ScannerCartLine> _scannerCart = [];
  String? _paymentMethod;
  final TextEditingController _amountTenderController = TextEditingController();
  CustomerListItem? _scannerMatchedCustomer;
  Timer? _phoneLookupDebounce;
  bool _creatingInvoice = false;
  bool _formattingTender = false;

  late DateTime _now;
  Timer? _clockTimer;
  late _CashierTab _selectedTab;
  String _selectedPhone = '';
  int? _selectedOrderId;

  List<CustomerListItem> _customers = [];
  bool _isLoadingCustomers = true;
  String? _customersError;

  List<OrderListItem> _historyOrders = const [];
  bool _isLoadingHistory = false;
  String? _historyError;
  bool _isLoadingOrderDetail = false;
  String? _orderDetailError;
  OrderDetail? _orderDetail;
  UserDetail? _editingProfile;

  @override
  void initState() {
    super.initState();
    _selectedTab = _tabFromKey(widget.initialTabKey);
    _selectedPhone = widget.initialPhone;
    _selectedOrderId = widget.initialOrderId;
    _now = DateTime.now();
    _clockTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) {
        setState(() => _now = DateTime.now());
      }
    });
    _loadCustomers();
    if (_selectedTab == _CashierTab.customerHistory &&
        _selectedPhone.isNotEmpty) {
      _loadHistory();
    }
    if (_selectedTab == _CashierTab.orderDetail && _selectedOrderId != null) {
      _loadOrderDetail(_selectedOrderId!);
    }
    _scannerCustomerPhoneController.addListener(_scheduleScannerPhoneLookup);
  }

  @override
  void didUpdateWidget(covariant CashierDashboardPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    final newTab = _tabFromKey(widget.initialTabKey);
    if (newTab != _selectedTab ||
        widget.initialPhone != _selectedPhone ||
        widget.initialOrderId != _selectedOrderId) {
      setState(() {
        _selectedTab = newTab;
        _selectedPhone = widget.initialPhone;
        _selectedOrderId = widget.initialOrderId;
      });
      if (newTab == _CashierTab.customerHistory &&
          widget.initialPhone.isNotEmpty) {
        _loadHistory();
      }
      if (newTab == _CashierTab.orderDetail && widget.initialOrderId != null) {
        _loadOrderDetail(widget.initialOrderId!);
      }
    }
  }

  @override
  void dispose() {
    _clockTimer?.cancel();
    _phoneLookupDebounce?.cancel();
    _totalCashEndController.dispose();
    _scannerCustomerNameController.dispose();
    _scannerCustomerPhoneController.removeListener(_scheduleScannerPhoneLookup);
    _scannerCustomerPhoneController.dispose();
    _scannerBarcodeController.dispose();
    _scannerSearchQueryController.dispose();
    _amountTenderController.dispose();
    super.dispose();
  }

  _CashierTab _tabFromKey(String key) {
    switch (key) {
      case 'customers':
        return _CashierTab.customers;
      case 'customer-history':
        return _CashierTab.customerHistory;
      case 'order-detail':
        return _CashierTab.orderDetail;
      case 'profile':
        return _CashierTab.profile;
      case 'profile-edit':
        return _CashierTab.profileEdit;
      case 'scanner':
      default:
        return _CashierTab.scanner;
    }
  }

  void _closeDrawerIfNeeded() {
    final isCompact = MediaQuery.sizeOf(context).width < 1024;
    if (isCompact) {
      Navigator.of(context).maybePop();
    }
  }

  void _navigateToTab(_CashierTab tab, {String? phone}) {
    if (tab == _CashierTab.scanner) {
      widget.onNavigatePath('/cashier/barcode-scanner');
      _closeDrawerIfNeeded();
      return;
    }
    if (tab == _CashierTab.customers) {
      widget.onNavigatePath('/cashier/customers');
      _closeDrawerIfNeeded();
      return;
    }
    if (tab == _CashierTab.profile) {
      widget.onNavigatePath('/cashier/profile');
      _closeDrawerIfNeeded();
      return;
    }
    if (tab == _CashierTab.profileEdit) {
      widget.onNavigatePath('/cashier/profile/edit');
      _closeDrawerIfNeeded();
      return;
    }
    if (tab == _CashierTab.customerHistory) {
      final targetPhone = (phone ?? _selectedPhone).trim();
      widget.onNavigatePath(
        '/cashier/customers/history?phone=${Uri.encodeComponent(targetPhone)}',
      );
      _closeDrawerIfNeeded();
      return;
    }
    final orderId = _selectedOrderId;
    if (orderId != null) {
      final targetPhone = (phone ?? _selectedPhone).trim();
      widget.onNavigatePath(
        '/cashier/orders/detail?orderId=$orderId&phone=${Uri.encodeComponent(targetPhone)}',
      );
      _closeDrawerIfNeeded();
    }
  }

  Future<void> _loadCustomers() async {
    setState(() {
      _isLoadingCustomers = true;
      _customersError = null;
    });
    try {
      final data = await _customerApiService.getCustomers();
      if (!mounted) {
        return;
      }
      setState(() {
        _customers = data;
        _isLoadingCustomers = false;
      });
      _syncScannerCustomerByPhoneLocal();
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _customersError = error.toString().replaceFirst('Exception: ', '');
        _isLoadingCustomers = false;
      });
    }
  }

  Future<void> _loadHistory() async {
    if (_selectedPhone.isEmpty) {
      setState(() {
        _historyOrders = const [];
        _historyError = null;
        _isLoadingHistory = false;
      });
      return;
    }
    setState(() {
      _isLoadingHistory = true;
      _historyError = null;
    });
    try {
      final allOrders = await _orderApiService.getOrders();
      final filtered = allOrders
          .where((o) => o.customerPhone.trim() == _selectedPhone.trim())
          .toList();
      if (!mounted) {
        return;
      }
      setState(() {
        _historyOrders = filtered;
        _isLoadingHistory = false;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _historyError = error.toString().replaceFirst('Exception: ', '');
        _isLoadingHistory = false;
      });
    }
  }

  Future<void> _loadOrderDetail(int orderId) async {
    setState(() {
      _isLoadingOrderDetail = true;
      _orderDetailError = null;
    });
    try {
      final detail = await _orderApiService.getOrderDetail(orderId);
      if (!mounted) {
        return;
      }
      setState(() {
        _orderDetail = detail;
        _isLoadingOrderDetail = false;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _orderDetailError = error.toString().replaceFirst('Exception: ', '');
        _isLoadingOrderDetail = false;
      });
    }
  }

  void _openProfileEdit(UserDetail detail) {
    setState(() {
      _editingProfile = detail;
      _selectedTab = _CashierTab.profileEdit;
    });
    _navigateToTab(_CashierTab.profileEdit);
  }

  void _onProfileUpdated(UserDetail detail) {
    setState(() {
      _editingProfile = detail;
      _selectedTab = _CashierTab.profile;
    });
    _navigateToTab(_CashierTab.profile);
  }

  String _two(int n) => n.toString().padLeft(2, '0');
  String _timeText() =>
      '${_two(_now.hour)}:${_two(_now.minute)}:${_two(_now.second)}';
  String _money(double amount) => '${amount.toStringAsFixed(0)}đ';
  String _discountText(double p) => p <= 0 ? '—' : '${p.toStringAsFixed(0)}%';
  String _formatTenderDisplay(double amount) => formatVndPrice(amount);

  void _formatAmountTenderInput() {
    if (_formattingTender) {
      return;
    }
    final digits = _amountTenderController.text.replaceAll(RegExp(r'[^\d]'), '');
    if (digits.isEmpty) {
      _formattingTender = true;
      _amountTenderController.value = const TextEditingValue(text: '');
      _formattingTender = false;
      return;
    }
    final value = double.tryParse(digits) ?? 0;
    final formatted = _formatTenderDisplay(value);
    _formattingTender = true;
    _amountTenderController.value = TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
    _formattingTender = false;
  }

  String _normalizePhone(String raw) => raw.replaceAll(RegExp(r'[^\d]'), '');

  void _syncScannerCustomerByPhoneLocal() {
    final normalized = _normalizePhone(_scannerCustomerPhoneController.text);
    CustomerListItem? matched;
    if (normalized.isNotEmpty) {
      for (final c in _customers) {
        if (_normalizePhone(c.phone) == normalized) {
          matched = c;
          break;
        }
      }
    }
    if (!mounted) {
      return;
    }
    setState(() {
      _scannerMatchedCustomer = matched;
    });
  }

  void _scheduleScannerPhoneLookup() {
    _syncScannerCustomerByPhoneLocal();
    _phoneLookupDebounce?.cancel();
    final phone = _scannerCustomerPhoneController.text.trim();
    if (_normalizePhone(phone).length < 8) {
      return;
    }
    _phoneLookupDebounce = Timer(const Duration(milliseconds: 350), () {
      _lookupCustomerByPhoneRemote(phone);
    });
  }

  Future<void> _lookupCustomerByPhoneRemote(String phoneSnapshot) async {
    try {
      final customer = await _customerApiService.getCustomerByPhone(phoneSnapshot);
      if (!mounted) {
        return;
      }
      final currentNormalized = _normalizePhone(
        _scannerCustomerPhoneController.text,
      );
      if (currentNormalized != _normalizePhone(phoneSnapshot)) {
        return;
      }
      setState(() {
        _scannerMatchedCustomer = customer;
      });
      _syncAmountTenderWithPayable();
      if (_scannerCustomerNameController.text.trim().isEmpty) {
        _scannerCustomerNameController.text = customer.name;
      }
    } catch (_) {
      // Keep local match result; API 404 is expected for unknown phone.
    }
  }

  int get _scannerLoyaltyPoints => _scannerMatchedCustomer?.points ?? 0;
  void _recalcScannerGrandTotal() {
    _scannerGrandTotal = _scannerCart.fold<double>(
      0,
      (sum, line) => sum + _scannerLineSubtotal(line),
    );
  }

  double _scannerLineKg(_ScannerCartLine line) => line.kg > 0 ? line.kg : 1;

  double _scannerLineSubtotal(_ScannerCartLine line) =>
      line.product.sellingPrice * line.quantity * _scannerLineKg(line);

  double get _scannerPayableTotal => _scannerGrandTotal;

  void _syncAmountTenderWithPayable() {
    final payable = _scannerPayableTotal;
    _amountTenderController.text =
        payable > 0 ? _formatTenderDisplay(payable) : '';
  }

  Future<void> _onGenerateInvoice() async {
    if (_scannerCart.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Cart is empty.')),
      );
      return;
    }
    if (_paymentMethod == null || _paymentMethod!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a payment method.')),
      );
      return;
    }
    final tenderDigits = _amountTenderController.text
        .trim()
        .replaceAll(RegExp(r'[^\d]'), '');
    final tender = double.tryParse(tenderDigits);
    final payable = _scannerPayableTotal;
    final billableLines = _scannerCart.where((l) => _scannerLineKg(l) > 0).toList();
    if (billableLines.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter Kg (>0) for at least one product.')),
      );
      return;
    }
    if (tender == null || tender < payable) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Amount tender must be at least ${payable.toStringAsFixed(0)}đ.',
          ),
        ),
      );
      return;
    }
    if (_creatingInvoice) {
      return;
    }

    setState(() => _creatingInvoice = true);
    try {
      final cashierId = AppSession.instance.userId ?? widget.userId;
      final invoice = await _orderApiService.checkout(
        cashierId: cashierId,
        customerName: _scannerCustomerNameController.text.trim(),
        customerPhone: _scannerCustomerPhoneController.text.trim(),
        paymentMethod: _paymentMethod!,
        paid: tender,
        discountPercent: 0,
        discountId: null,
        items: _scannerCart
            .where((l) => _scannerLineKg(l) > 0)
            .map(
              (l) => {
                'productId': l.product.id,
                'qty': l.quantity,
                'kg': _scannerLineKg(l),
              },
            )
            .toList(),
      );
      if (!mounted) {
        return;
      }
      await _loadCustomers();
      if (!mounted) {
        return;
      }
      await showDialog<void>(
        context: context,
        barrierColor: Colors.black54,
        builder: (_) => _InvoicePreviewDialog(invoice: invoice),
      );
      if (!mounted) {
        return;
      }
      _resetScannerForNewInvoice();
      await _refreshProductCatalog();
    } catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            error.toString().replaceFirst('Exception: ', ''),
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _creatingInvoice = false);
      }
    }
  }

  Future<bool> _ensureProductCatalogLoaded() async {
    if (_productCatalog.isNotEmpty) {
      return true;
    }
    setState(() => _loadingProductCatalog = true);
    try {
      final list = await _productApiService.getProducts();
      if (!mounted) {
        return false;
      }
      setState(() {
        _productCatalog = list;
        _loadingProductCatalog = false;
      });
      return true;
    } catch (error) {
      if (!mounted) {
        return false;
      }
      setState(() => _loadingProductCatalog = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            error.toString().replaceFirst('Exception: ', ''),
          ),
        ),
      );
      return false;
    }
  }

  Future<void> _refreshProductCatalog() async {
    try {
      final list = await _productApiService.getProducts();
      if (!mounted) {
        return;
      }
      setState(() {
        _productCatalog = list;
      });
    } catch (_) {
      // Keep current cache if refresh fails.
    }
  }

  void _resetScannerForNewInvoice() {
    setState(() {
      _scannerCart.clear();
      _scannerGrandTotal = 0;
      _paymentMethod = null;
      _scannerMatchedCustomer = null;
      _amountTenderController.clear();
      _scannerBarcodeController.clear();
      _scannerSearchQueryController.clear();
      _scannerCustomerNameController.clear();
      _scannerCustomerPhoneController.clear();
    });
  }

  List<ProductListItem> _filterProductsForScanner() {
    final bc = _scannerBarcodeController.text.trim().toLowerCase();
    final nq = _scannerSearchQueryController.text.trim().toLowerCase();
    if (bc.isEmpty && nq.isEmpty) {
      return List<ProductListItem>.from(_productCatalog);
    }
    return _productCatalog.where((p) {
      final code = p.barcode.toLowerCase();
      final name = p.productName.toLowerCase();
      if (bc.isNotEmpty && nq.isNotEmpty) {
        final matchBarcodeField =
            code.contains(bc) || name.contains(bc);
        final matchNameField = name.contains(nq) || code.contains(nq);
        return matchBarcodeField || matchNameField;
      }
      if (bc.isNotEmpty) {
        return code.contains(bc) || name.contains(bc);
      }
      return name.contains(nq) || code.contains(nq);
    }).toList();
  }

  /// [requireQuery]: true = user must type barcode or name (Search). false = allow showing all products (Add to cart).
  Future<void> _openScannerProductPicker({required bool requireQuery}) async {
    final bc = _scannerBarcodeController.text.trim();
    final nq = _scannerSearchQueryController.text.trim();
    if (requireQuery && bc.isEmpty && nq.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Enter a barcode or product name to search.'),
        ),
      );
      return;
    }
    if (_loadingProductCatalog) {
      return;
    }
    final ok = await _ensureProductCatalogLoaded();
    if (!ok || !mounted) {
      return;
    }
    final filtered = _filterProductsForScanner();
    final title = requireQuery && (bc.isNotEmpty || nq.isNotEmpty)
        ? 'Search results (${filtered.length})'
        : 'Products (${filtered.length})';
    final picked = await showCashierProductSearchDialog(
      context,
      products: filtered,
      title: title,
    );
    if (picked != null && mounted) {
      _addProductToScannerCart(picked);
    }
  }

  void _addProductToScannerCart(ProductListItem p) {
    if (p.inStock <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Product is out of stock.')),
      );
      return;
    }
    final idx = _scannerCart.indexWhere((l) => l.product.id == p.id);
    if (idx >= 0) {
      final line = _scannerCart[idx];
      if (line.quantity >= p.inStock) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Maximum in stock for this product is ${p.inStock}.',
            ),
          ),
        );
        return;
      }
      setState(() {
        line.quantity++;
        _recalcScannerGrandTotal();
        _syncAmountTenderWithPayable();
      });
    } else {
      setState(() {
        _scannerCart.add(_ScannerCartLine(product: p, quantity: 1));
        _recalcScannerGrandTotal();
        _syncAmountTenderWithPayable();
      });
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Added: ${p.productName}')),
    );
  }

  void _changeScannerCartQty(int index, int delta) {
    if (index < 0 || index >= _scannerCart.length) {
      return;
    }
    final line = _scannerCart[index];
    final maxQ = line.product.inStock;
    final next = line.quantity + delta;
    if (next < 1) {
      setState(() {
        _scannerCart.removeAt(index);
        _recalcScannerGrandTotal();
        _syncAmountTenderWithPayable();
      });
      return;
    }
    if (next > maxQ) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Maximum in stock is $maxQ.'),
        ),
      );
      return;
    }
    setState(() {
      line.quantity = next;
      _recalcScannerGrandTotal();
      _syncAmountTenderWithPayable();
    });
  }

  void _removeScannerCartLine(int index) {
    if (index < 0 || index >= _scannerCart.length) {
      return;
    }
    setState(() {
      _scannerCart.removeAt(index);
      _recalcScannerGrandTotal();
      _syncAmountTenderWithPayable();
    });
  }

  void _updateScannerCartKg(int index, String raw) {
    if (index < 0 || index >= _scannerCart.length) {
      return;
    }
    final normalized = raw.replaceAll(',', '.').trim();
    final double kg = normalized.isEmpty
        ? 1
        : (double.tryParse(normalized) ?? 1);
    setState(() {
      _scannerCart[index].kg = kg > 0 ? kg : 1;
      _recalcScannerGrandTotal();
      _syncAmountTenderWithPayable();
    });
  }

  Future<void> _openAddCustomerForPointsDialog() async {
    final nameCtrl = TextEditingController(
      text: _scannerCustomerNameController.text.trim(),
    );
    final phoneCtrl = TextEditingController(
      text: _scannerCustomerPhoneController.text.trim(),
    );
    final payable = _scannerPayableTotal;
    final amountCtrl = TextEditingController(
      text: payable > 0 ? payable.toStringAsFixed(0) : '',
    );

    try {
      await showDialog<void>(
        context: context,
        barrierColor: Colors.black54,
        builder: (dialogContext) {
          return Dialog(
            backgroundColor: Colors.transparent,
            insetPadding: const EdgeInsets.symmetric(
              horizontal: 24,
              vertical: 24,
            ),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Material(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                clipBehavior: Clip.antiAlias,
                elevation: 8,
                shadowColor: Colors.black26,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Container(
                      padding: const EdgeInsets.fromLTRB(20, 16, 12, 16),
                      decoration: const BoxDecoration(
                        color: Color(0xFFFAFBFC),
                        border: Border(
                          bottom: BorderSide(color: Color(0xFFE8EAED)),
                        ),
                      ),
                      child: Row(
                        children: [
                          const Expanded(
                            child: Text(
                              'Add Customer',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF1A1D21),
                              ),
                            ),
                          ),
                          IconButton(
                            onPressed: () =>
                                Navigator.of(dialogContext).pop(),
                            style: IconButton.styleFrom(
                              backgroundColor: const Color(0xFFF3F4F6),
                              foregroundColor: const Color(0xFF6B7280),
                            ),
                            icon: const Icon(Icons.close),
                          ),
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _addCustomerField(
                            label: 'Name',
                            controller: nameCtrl,
                            hint: 'Customer name',
                          ),
                          const SizedBox(height: 16),
                          _addCustomerField(
                            label: 'Phone',
                            controller: phoneCtrl,
                            hint: 'e.g. 0901234567',
                            keyboardType: TextInputType.phone,
                          ),
                          const SizedBox(height: 16),
                          _addCustomerField(
                            label: 'Amount',
                            controller: amountCtrl,
                            hint: 'e.g. 1000000',
                            keyboardType: TextInputType.number,
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
                      decoration: const BoxDecoration(
                        border: Border(
                          top: BorderSide(color: Color(0xFFE8EAED)),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          TextButton(
                            onPressed: () =>
                                Navigator.of(dialogContext).pop(),
                            style: TextButton.styleFrom(
                              backgroundColor: const Color(0xFFDC2626),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 18,
                                vertical: 12,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            child: const Text(
                              'Cancel',
                              style: TextStyle(fontWeight: FontWeight.w600),
                            ),
                          ),
                          const SizedBox(width: 10),
                          TextButton(
                            onPressed: () async {
                              final name = nameCtrl.text.trim();
                              final phone = phoneCtrl.text.trim();
                              final amount = double.tryParse(
                                amountCtrl.text
                                    .trim()
                                    .replaceAll(',', '')
                                    .replaceAll('đ', ''),
                              );
                              if (phone.isEmpty || amount == null || amount < 0) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                      'Phone and a valid Amount are required.',
                                    ),
                                  ),
                                );
                                return;
                              }
                              try {
                                final normalizedPhone = _normalizePhone(phone);
                                CustomerListItem? existing;
                                for (final c in _customers) {
                                  if (_normalizePhone(c.phone) == normalizedPhone) {
                                    existing = c;
                                    break;
                                  }
                                }
                                final earnedPoints = (amount / 1000).floor();
                                if (existing != null) {
                                  await _customerApiService.updateCustomer(
                                    customerId: existing.id,
                                    name: name.isEmpty ? existing.name : name,
                                    phone: existing.phone,
                                    totalAmount: existing.totalAmount + amount,
                                  );
                                } else {
                                  if (name.isEmpty) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text(
                                          'Name is required for a new customer.',
                                        ),
                                      ),
                                    );
                                    return;
                                  }
                                  await _customerApiService.createCustomer(
                                    name: name,
                                    phone: phone,
                                    totalAmount: amount,
                                  );
                                }
                                if (!mounted) return;
                                if (dialogContext.mounted) {
                                  Navigator.of(dialogContext).pop();
                                }
                                if (name.isNotEmpty) {
                                  _scannerCustomerNameController.text = name;
                                }
                                _scannerCustomerPhoneController.text = phone;
                                await _loadCustomers();
                                if (!mounted) return;
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      existing != null
                                          ? 'Added +$earnedPoints points to ${existing.phone}.'
                                          : 'Customer created and +$earnedPoints points added.',
                                    ),
                                  ),
                                );
                              } catch (error) {
                                if (!mounted) return;
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      error
                                          .toString()
                                          .replaceFirst('Exception: ', ''),
                                    ),
                                  ),
                                );
                              }
                            },
                            style: TextButton.styleFrom(
                              backgroundColor: const Color(0xFF16A34A),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 18,
                                vertical: 12,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            child: const Text(
                              'Submit',
                              style: TextStyle(fontWeight: FontWeight.w600),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      );
    } finally {
      nameCtrl.dispose();
      phoneCtrl.dispose();
      amountCtrl.dispose();
    }
  }

  Widget _addCustomerField({
    required String label,
    required TextEditingController controller,
    required String hint,
    TextInputType? keyboardType,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: Color(0xFF374151),
          ),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          keyboardType: keyboardType,
          decoration: InputDecoration(
            hintText: hint,
            filled: true,
            fillColor: Colors.white,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 12,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Color(0xFFD1D5DB)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Color(0xFFD1D5DB)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Color(0xFF667EEA), width: 1),
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _openCloseShiftDialog() async {
    final fullName = widget.fullName.isEmpty ? 'Cashier' : widget.fullName;
    _totalCashEndController.clear();
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => Dialog(
        insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
        backgroundColor: Colors.transparent,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFE8EAED)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 18,
                  ),
                  decoration: const BoxDecoration(
                    borderRadius: BorderRadius.vertical(
                      top: Radius.circular(12),
                    ),
                    gradient: LinearGradient(
                      colors: [Color(0xFF0D9488), Color(0xFF0F766E)],
                    ),
                  ),
                  child: Row(
                    children: [
                      const Expanded(
                        child: Text(
                          'Close Shift',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      InkWell(
                        onTap: () => Navigator.of(dialogContext).pop(),
                        child: const Icon(Icons.close, color: Colors.white),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Text('Employee name'),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 12,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF9FAFB),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: const Color(0xFFE5E7EB)),
                        ),
                        child: Text(fullName),
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: _totalCashEndController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          hintText: 'Enter total cash after shift',
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(24),
                  child: ElevatedButton(
                    onPressed: () {
                      final amount = double.tryParse(
                        _totalCashEndController.text.trim().replaceAll(',', ''),
                      );
                      if (amount == null || amount < 0) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                              'Please enter a valid total cash amount.',
                            ),
                          ),
                        );
                        return;
                      }
                      Navigator.of(dialogContext).pop();
                      widget.onLogoutRequested();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0D9488),
                    ),
                    child: const Text(
                      'Confirm & close shift',
                      style: TextStyle(color: Colors.white),
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

  Future<void> _openUpdateCustomerDialog(CustomerListItem customer) async {
    final index = _customers.indexWhere((c) => c.id == customer.id);
    if (index < 0) return;
    final nameController = TextEditingController(text: customer.name);
    final phoneController = TextEditingController(text: customer.phone);
    final amountController = TextEditingController(
      text: customer.totalAmount.toStringAsFixed(0),
    );

    await showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (dialogContext) => Dialog(
        insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    const Expanded(
                      child: Text(
                        'Update Customer',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.of(dialogContext).pop(),
                      icon: const Icon(Icons.close),
                    ),
                  ],
                ),
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(labelText: 'Name'),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: phoneController,
                  decoration: const InputDecoration(labelText: 'Phone'),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: amountController,
                  decoration: const InputDecoration(labelText: 'Amount'),
                ),
                const SizedBox(height: 14),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.of(dialogContext).pop(),
                      child: const Text('Cancel'),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: () async {
                        final dialogNavigator = Navigator.of(dialogContext);
                        final name = nameController.text.trim();
                        final phone = phoneController.text.trim();
                        final amount = double.tryParse(
                          amountController.text
                              .trim()
                              .replaceAll(',', '')
                              .replaceAll('đ', ''),
                        );
                        if (name.isEmpty ||
                            phone.isEmpty ||
                            amount == null ||
                            amount < 0) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                'Name, Phone, and Amount are required.',
                              ),
                            ),
                          );
                          return;
                        }
                        try {
                          final updated = await _customerApiService
                              .updateCustomer(
                                customerId: customer.id,
                                name: name,
                                phone: phone,
                                totalAmount: amount,
                              );
                          if (!mounted) return;
                          setState(() => _customers[index] = updated);
                          dialogNavigator.pop();
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Customer updated successfully.'),
                            ),
                          );
                        } catch (error) {
                          if (!mounted) return;
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                error.toString().replaceFirst(
                                  'Exception: ',
                                  '',
                                ),
                              ),
                            ),
                          );
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF16A34A),
                      ),
                      child: const Text(
                        'Update',
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
    nameController.dispose();
    phoneController.dispose();
    amountController.dispose();
  }

  Widget _buildScannerCheckoutSection() {
    final points = _scannerLoyaltyPoints;
    final matchedPhone = _scannerMatchedCustomer?.phone ?? '—';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const Text(
              'Grand Total',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: Color(0xFF1A1D21),
              ),
            ),
            const SizedBox(width: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              constraints: const BoxConstraints(minWidth: 140),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFFD1D5DB)),
              ),
              child: Text(
                formatVndPrice(_scannerGrandTotal),
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF1A1D21),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        Wrap(
          spacing: 12,
          runSpacing: 8,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            SizedBox(
              width: 240,
              child: TextField(
                controller: _scannerCustomerPhoneController,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(
                  labelText: 'Buyer Phone',
                  hintText: 'Enter customer phone',
                  isDense: true,
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(),
                ),
              ),
            ),
            Text(
              'Points: $points',
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: Color(0xFF1A1D21),
              ),
            ),
            Text(
              'Matched: $matchedPhone',
              style: const TextStyle(
                fontSize: 13,
                color: Color(0xFF64748B),
              ),
            ),
          ],
        ),
        const SizedBox(height: 18),
        LayoutBuilder(
          builder: (context, constraints) {
            final wide = constraints.maxWidth >= 900;
            final paymentField = SizedBox(
              width: wide ? 200 : double.infinity,
              child: InputDecorator(
                decoration: const InputDecoration(
                  labelText: 'Payment Method',
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(),
                  isDense: true,
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _paymentMethod,
                    hint: const Text('Select...'),
                    isExpanded: true,
                    items: const [
                      DropdownMenuItem(value: 'Cash', child: Text('Cash')),
                      DropdownMenuItem(value: 'Card', child: Text('Card')),
                      DropdownMenuItem(
                        value: 'Transfer',
                        child: Text('Transfer'),
                      ),
                      DropdownMenuItem(
                        value: 'E-wallet',
                        child: Text('E-wallet'),
                      ),
                    ],
                    onChanged: (v) => setState(() => _paymentMethod = v),
                  ),
                ),
              ),
            );
            final tenderField = SizedBox(
              width: wide ? 220 : double.infinity,
              child: TextField(
                controller: _amountTenderController,
                keyboardType: TextInputType.number,
                onChanged: (_) => _formatAmountTenderInput(),
                decoration: const InputDecoration(
                  labelText: 'Amount Tender',
                  hintText: 'Enter amount paid',
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(),
                  isDense: true,
                ),
              ),
            );
            final invoiceBtn = ElevatedButton(
              onPressed: _creatingInvoice ? null : _onGenerateInvoice,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1E3A5F),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 28,
                  vertical: 16,
                ),
              ),
              child: _creatingInvoice
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Text(
                      'Generate Invoice',
                      style: TextStyle(fontWeight: FontWeight.w700),
                    ),
            );
            if (wide) {
              return Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  paymentField,
                  const SizedBox(width: 12),
                  tenderField,
                  const Spacer(),
                  invoiceBtn,
                ],
              );
            }
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                paymentField,
                const SizedBox(height: 10),
                tenderField,
                const SizedBox(height: 12),
                invoiceBtn,
              ],
            );
          },
        ),
        const SizedBox(height: 24),
        Center(
          child: Text(
            'POINT OF SALES SYSTEM BY KODEMAGAZY',
            style: TextStyle(
              fontSize: 12,
              color: const Color(0xFF1A1D21).withValues(alpha: 0.08),
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBody({required bool isCompact}) {
    switch (_selectedTab) {
      case _CashierTab.scanner:
        return SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  _scannerInputBox(
                    label: 'Customer Name',
                    hint: 'Optional [Required for credit sales]',
                    controller: _scannerCustomerNameController,
                  ),
                  _scannerInputBox(
                    label: 'Phone',
                    hint: 'Optional [Required for credit sales]',
                    controller: _scannerCustomerPhoneController,
                  ),
                  ElevatedButton(
                    onPressed: _openAddCustomerForPointsDialog,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0D9488),
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('Add customer for points'),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  ElevatedButton(
                    onPressed: _loadingProductCatalog
                        ? null
                        : () => _openScannerProductPicker(requireQuery: false),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF16A34A),
                      foregroundColor: Colors.white,
                    ),
                    child: _loadingProductCatalog
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Text('+ Add To Cart'),
                  ),
                  ElevatedButton(
                    onPressed: _loadingProductCatalog
                        ? null
                        : () => _openScannerProductPicker(requireQuery: true),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0D9488),
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('Scan product barcode'),
                  ),
                  SizedBox(
                    width: 220,
                    child: TextField(
                      controller: _scannerBarcodeController,
                      decoration: const InputDecoration(
                        hintText: 'Scan or enter barcode...',
                        isDense: true,
                        border: OutlineInputBorder(),
                      ),
                      textInputAction: TextInputAction.search,
                      onSubmitted: (_) => _openScannerProductPicker(
                        requireQuery: true,
                      ),
                    ),
                  ),
                  SizedBox(
                    width: 260,
                    child: TextField(
                      controller: _scannerSearchQueryController,
                      decoration: const InputDecoration(
                        hintText: 'Search by name or code...',
                        isDense: true,
                        border: OutlineInputBorder(),
                      ),
                      textInputAction: TextInputAction.search,
                      onSubmitted: (_) => _openScannerProductPicker(
                        requireQuery: true,
                      ),
                    ),
                  ),
                  OutlinedButton.icon(
                    onPressed: _loadingProductCatalog
                        ? null
                        : () => _openScannerProductPicker(requireQuery: true),
                    icon: const Icon(Icons.search, size: 18),
                    label: const Text('Search'),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFE8EAED)),
                ),
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: DataTable(
                    headingRowColor: const WidgetStatePropertyAll(
                      Color(0xFF7DD3FC),
                    ),
                    columns: const [
                      DataColumn(label: Text('Product Name')),
                      DataColumn(label: Text('Stock Qty')),
                      DataColumn(label: Text('Unit Price')),
                      DataColumn(
                        label: Center(
                          child: Text(
                            'Qty',
                            style: TextStyle(fontWeight: FontWeight.w600),
                          ),
                        ),
                      ),
                      DataColumn(label: Text('Kg')),
                      DataColumn(label: Text('Subtotal')),
                      DataColumn(label: Text('')),
                    ],
                    rows: _scannerCart.isEmpty
                        ? const [
                            DataRow(
                              cells: [
                                DataCell(
                                  Text(
                                    'No products. Scan barcode or search to add.',
                                  ),
                                ),
                                DataCell(Text('-')),
                                DataCell(Text('-')),
                                DataCell(Text('-')),
                                DataCell(Text('-')),
                                DataCell(Text('-')),
                                DataCell(Text('-')),
                              ],
                            ),
                          ]
                        : _scannerCart.asMap().entries.map((entry) {
                            final index = entry.key;
                            final line = entry.value;
                            final p = line.product;
                            final sub = _scannerLineSubtotal(line);
                            return DataRow(
                              cells: [
                                DataCell(Text(p.productName)),
                                DataCell(Text('${p.inStock}')),
                                DataCell(Text(formatVndPrice(p.sellingPrice))),
                                DataCell(
                                  Align(
                                    alignment: Alignment.center,
                                    child: SizedBox(
                                      width: 128,
                                      height: 40,
                                      child: Row(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.center,
                                        children: [
                                          SizedBox(
                                            width: 40,
                                            height: 40,
                                            child: IconButton(
                                              padding: EdgeInsets.zero,
                                              constraints: const BoxConstraints(
                                                minWidth: 40,
                                                minHeight: 40,
                                                maxWidth: 40,
                                                maxHeight: 40,
                                              ),
                                              style: IconButton.styleFrom(
                                                tapTargetSize: MaterialTapTargetSize
                                                    .shrinkWrap,
                                              ),
                                              onPressed: () =>
                                                  _changeScannerCartQty(
                                                    index,
                                                    -1,
                                                  ),
                                              icon: const Icon(
                                                Icons.remove_circle_outline,
                                                size: 24,
                                              ),
                                            ),
                                          ),
                                          Expanded(
                                            child: Center(
                                              child: Text(
                                                '${line.quantity}',
                                                textAlign: TextAlign.center,
                                                style: const TextStyle(
                                                  fontSize: 15,
                                                  fontWeight: FontWeight.w700,
                                                  height: 1,
                                                ),
                                              ),
                                            ),
                                          ),
                                          SizedBox(
                                            width: 40,
                                            height: 40,
                                            child: IconButton(
                                              padding: EdgeInsets.zero,
                                              constraints: const BoxConstraints(
                                                minWidth: 40,
                                                minHeight: 40,
                                                maxWidth: 40,
                                                maxHeight: 40,
                                              ),
                                              style: IconButton.styleFrom(
                                                tapTargetSize: MaterialTapTargetSize
                                                    .shrinkWrap,
                                              ),
                                              onPressed: () =>
                                                  _changeScannerCartQty(
                                                    index,
                                                    1,
                                                  ),
                                              icon: const Icon(
                                                Icons.add_circle_outline,
                                                size: 24,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                                DataCell(
                                  SizedBox(
                                    width: 74,
                                    child: TextFormField(
                                      key: ValueKey('kg_${line.product.id}_$index'),
                                      initialValue: line.kg > 0
                                          ? line.kg.toStringAsFixed(
                                              line.kg % 1 == 0 ? 0 : 2,
                                            )
                                          : '',
                                      keyboardType:
                                          const TextInputType.numberWithOptions(
                                            decimal: true,
                                          ),
                                      textAlign: TextAlign.center,
                                      decoration: const InputDecoration(
                                        hintText: 'Kg',
                                        isDense: true,
                                        contentPadding: EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 8,
                                        ),
                                        border: OutlineInputBorder(),
                                      ),
                                      onChanged: (v) =>
                                          _updateScannerCartKg(index, v),
                                    ),
                                  ),
                                ),
                                DataCell(Text(formatVndPrice(sub))),
                                DataCell(
                                  IconButton(
                                    onPressed: () =>
                                        _removeScannerCartLine(index),
                                    icon: const Icon(
                                      Icons.delete_outline,
                                      color: Color(0xFFDC2626),
                                    ),
                                    tooltip: 'Remove',
                                  ),
                                ),
                              ],
                            );
                          }).toList(),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              _buildScannerCheckoutSection(),
            ],
          ),
        );
      case _CashierTab.customers:
        return Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Customer List',
                style: TextStyle(fontSize: 30, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: _isLoadingCustomers
                    ? const Center(child: CircularProgressIndicator())
                    : _customersError != null
                    ? Center(
                        child: Text('Cannot load customers: $_customersError'),
                      )
                    : Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFFE8EAED)),
                        ),
                        child: SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: DataTable(
                            columns: const [
                              DataColumn(label: Text('S/N')),
                              DataColumn(label: Text('CUSTOMER')),
                              DataColumn(label: Text('PHONE')),
                              DataColumn(label: Text('POINTS')),
                              DataColumn(label: Text('PURCHASES')),
                              DataColumn(label: Text('TOTAL AMOUNT')),
                              DataColumn(label: Text('DISCOUNT')),
                              DataColumn(label: Text('ACTIONS')),
                            ],
                            rows: _customers.asMap().entries.map((entry) {
                              final c = entry.value;
                              return DataRow(
                                cells: [
                                  DataCell(Text('${entry.key + 1}')),
                                  DataCell(Text(c.name)),
                                  DataCell(
                                    InkWell(
                                      onTap: () {
                                        setState(
                                          () => _selectedPhone = c.phone,
                                        );
                                        _navigateToTab(
                                          _CashierTab.customerHistory,
                                          phone: c.phone,
                                        );
                                      },
                                      child: Text(
                                        c.phone,
                                        style: const TextStyle(
                                          color: Color(0xFF3B82F6),
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                  ),
                                  DataCell(Text('${c.points}')),
                                  DataCell(Text('${c.totalPurchases}')),
                                  DataCell(Text(_money(c.totalAmount))),
                                  DataCell(
                                    Text(_discountText(c.discountPercent)),
                                  ),
                                  DataCell(
                                    TextButton(
                                      onPressed: () =>
                                          _openUpdateCustomerDialog(c),
                                      child: const Text('Edit'),
                                    ),
                                  ),
                                ],
                              );
                            }).toList(),
                          ),
                        ),
                      ),
              ),
            ],
          ),
        );
      case _CashierTab.customerHistory:
        return Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextButton.icon(
                onPressed: () => _navigateToTab(_CashierTab.customers),
                icon: const Icon(Icons.arrow_back),
                label: const Text('Back to Customer List'),
                style: TextButton.styleFrom(alignment: Alignment.centerLeft),
              ),
              Text(
                'Customer Order History - ${_selectedPhone.isEmpty ? '—' : _selectedPhone}',
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: _isLoadingHistory
                    ? const Center(child: CircularProgressIndicator())
                    : _historyError != null
                    ? Center(child: Text('Cannot load history: $_historyError'))
                    : Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFFE8EAED)),
                        ),
                        child: _historyOrders.isEmpty
                            ? const Center(
                                child: Text(
                                  'No orders found for this phone number.',
                                ),
                              )
                            : SingleChildScrollView(
                                scrollDirection: Axis.horizontal,
                                child: DataTable(
                                  columns: const [
                                    DataColumn(label: Text('ORDER ID')),
                                    DataColumn(label: Text('DATE/TIME')),
                                    DataColumn(label: Text('TOTAL')),
                                    DataColumn(label: Text('DISCOUNT (%)')),
                                    DataColumn(label: Text('PAYABLE')),
                                    DataColumn(label: Text('PAYMENT')),
                                    DataColumn(label: Text('STATUS')),
                                    DataColumn(label: Text('ACTION')),
                                  ],
                                  rows: _historyOrders
                                      .map(
                                        (o) => DataRow(
                                          cells: [
                                            DataCell(Text(o.orderNo)),
                                            DataCell(Text(o.orderDateTime)),
                                            DataCell(Text(_money(o.total))),
                                            DataCell(
                                              Text(
                                                o.discountPercent
                                                    .toStringAsFixed(0),
                                              ),
                                            ),
                                            DataCell(Text(_money(o.payable))),
                                            DataCell(Text(o.paymentMethod)),
                                            DataCell(Text(o.status)),
                                            DataCell(
                                              TextButton(
                                                onPressed: () {
                                                  setState(() {
                                                    _selectedOrderId = o.id;
                                                  });
                                                  _navigateToTab(
                                                    _CashierTab.orderDetail,
                                                    phone: _selectedPhone,
                                                  );
                                                },
                                                child: const Text('View'),
                                              ),
                                            ),
                                          ],
                                        ),
                                      )
                                      .toList(),
                                ),
                              ),
                      ),
              ),
            ],
          ),
        );
      case _CashierTab.orderDetail:
        return Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextButton.icon(
                onPressed: () => _navigateToTab(_CashierTab.customerHistory),
                icon: const Icon(Icons.arrow_back),
                label: const Text('Back to Customer Order History'),
                style: TextButton.styleFrom(alignment: Alignment.centerLeft),
              ),
              const SizedBox(height: 8),
              if (_isLoadingOrderDetail)
                const Expanded(
                  child: Center(child: CircularProgressIndicator()),
                )
              else if (_orderDetailError != null)
                Expanded(
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text('Cannot load order detail: $_orderDetailError'),
                        const SizedBox(height: 10),
                        ElevatedButton(
                          onPressed: () {
                            if (_selectedOrderId != null) {
                              _loadOrderDetail(_selectedOrderId!);
                            }
                          },
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  ),
                )
              else if (_orderDetail == null)
                const Expanded(
                  child: Center(child: Text('Order detail not found.')),
                )
              else
                Expanded(
                  child: SingleChildScrollView(
                    child: OrderDetailCard(
                      detail: _orderDetail!,
                      moneyFormatter: _money,
                    ),
                  ),
                ),
            ],
          ),
        );
      case _CashierTab.profile:
        return ProfileViewContent(
          fullName: widget.fullName,
          userId: widget.userId,
          isCompact: isCompact,
          currentTimeText: _timeText(),
          onEditProfile: _openProfileEdit,
        );
      case _CashierTab.profileEdit:
        return ProfileEditContent(
          userId: widget.userId,
          initialDetail: _editingProfile,
          isCompact: isCompact,
          currentTimeText: _timeText(),
          onSaved: _onProfileUpdated,
          onCancel: () => _navigateToTab(_CashierTab.profile),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final fullName = widget.fullName.isEmpty ? 'Cashier' : widget.fullName;
        final isCompact = constraints.maxWidth < 1024;
        final hideShellHeader =
            _selectedTab == _CashierTab.profile ||
            _selectedTab == _CashierTab.profileEdit;
        final sidebar = _CashierSidebar(
          selectedTab: _selectedTab,
          onScannerTap: () => _navigateToTab(_CashierTab.scanner),
          onCustomersTap: () => _navigateToTab(_CashierTab.customers),
          onLogoutTap: _openCloseShiftDialog,
        );

        return Scaffold(
          key: _scaffoldKey,
          backgroundColor: const Color(0xFFF0F2F5),
          drawer: isCompact ? Drawer(width: 250, child: sidebar) : null,
          body: SafeArea(
            child: Row(
              children: [
                if (!isCompact) SizedBox(width: 240, child: sidebar),
                Expanded(
                  child: Column(
                    children: [
                      if (!hideShellHeader)
                        Container(
                          height: 72,
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          decoration: const BoxDecoration(
                            color: Colors.white,
                            border: Border(
                              bottom: BorderSide(color: Color(0xFFE8EAED)),
                            ),
                          ),
                          child: isCompact
                              ? Row(
                                  children: [
                                    IconButton(
                                      onPressed: () => _scaffoldKey.currentState
                                          ?.openDrawer(),
                                      icon: const Icon(Icons.menu),
                                      tooltip: 'Open menu',
                                    ),
                                    const Spacer(),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 10,
                                        vertical: 7,
                                      ),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFF667EEA),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Text(
                                        _timeText(),
                                        style: const TextStyle(
                                          color: Colors.white,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    InkWell(
                                      onTap: () =>
                                          _navigateToTab(_CashierTab.profile),
                                      borderRadius: BorderRadius.circular(10),
                                      child: Container(
                                        width: 40,
                                        height: 40,
                                        alignment: Alignment.center,
                                        decoration: BoxDecoration(
                                          color: const Color(0xFF1E293B),
                                          borderRadius: BorderRadius.circular(
                                            10,
                                          ),
                                        ),
                                        child: Text(
                                          fullName.isNotEmpty
                                              ? fullName[0].toUpperCase()
                                              : 'C',
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                )
                              : Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    const SizedBox(width: 48),
                                    Row(
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 12,
                                            vertical: 8,
                                          ),
                                          decoration: BoxDecoration(
                                            color: const Color(0xFF667EEA),
                                            borderRadius: BorderRadius.circular(
                                              8,
                                            ),
                                          ),
                                          child: Text(
                                            _timeText(),
                                            style: const TextStyle(
                                              color: Colors.white,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 14),
                                        Column(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          crossAxisAlignment:
                                              CrossAxisAlignment.end,
                                          children: [
                                            Text(fullName),
                                            const Text(
                                              'Cashier',
                                              style: TextStyle(
                                                fontSize: 12,
                                                color: Color(0xFF6B7280),
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(width: 12),
                                        InkWell(
                                          onTap: () => _navigateToTab(
                                            _CashierTab.profile,
                                          ),
                                          borderRadius: BorderRadius.circular(
                                            10,
                                          ),
                                          child: Container(
                                            width: 40,
                                            height: 40,
                                            alignment: Alignment.center,
                                            decoration: BoxDecoration(
                                              color: const Color(0xFF1E293B),
                                              borderRadius:
                                                  BorderRadius.circular(10),
                                            ),
                                            child: Text(
                                              fullName.isNotEmpty
                                                  ? fullName[0].toUpperCase()
                                                  : 'C',
                                              style: const TextStyle(
                                                color: Colors.white,
                                                fontWeight: FontWeight.w700,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                        ),
                      Expanded(child: _buildBody(isCompact: isCompact)),
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

  Widget _scannerInputBox({
    required String label,
    required String hint,
    required TextEditingController controller,
  }) {
    return SizedBox(
      width: 280,
      child: TextField(
        controller: controller,
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          border: const OutlineInputBorder(),
          isDense: true,
        ),
      ),
    );
  }
}

class _ScannerCartLine {
  _ScannerCartLine({required this.product, this.quantity = 1}) : kg = 1;

  final ProductListItem product;
  int quantity;
  double kg;
}

class _InvoicePreviewDialog extends StatelessWidget {
  const _InvoicePreviewDialog({required this.invoice});

  final CheckoutInvoice invoice;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      backgroundColor: Colors.transparent,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 520),
        child: Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: const Color(0xFFE5E7EB)),
          ),
          child: DefaultTextStyle(
            style: const TextStyle(
              fontFamily: 'monospace',
              color: Color(0xFF1A1D21),
              fontSize: 13,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    const Expanded(
                      child: Text(
                        'Sales Invoice',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.close),
                    ),
                  ],
                ),
                Flexible(
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const Center(
                          child: Text(
                            'KODEMADEEAZY',
                            style: TextStyle(fontWeight: FontWeight.w700),
                          ),
                        ),
                        const SizedBox(height: 6),
                        const Center(
                          child: Text(
                            'SMS SYSTEM',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        const SizedBox(height: 14),
                        const Center(
                          child: Text(
                            'SALES INVOICE',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        const SizedBox(height: 14),
                        _InvoiceInfoRow(label: 'SALES POINT', value: invoice.salesPoint),
                        _InvoiceInfoRow(label: 'CASHIER', value: invoice.cashierName),
                        _InvoiceInfoRow(label: 'INVOICE NO', value: invoice.orderNo),
                        _InvoiceInfoRow(label: 'CUSTOMER', value: invoice.customerName),
                        _InvoiceInfoRow(label: 'PHONE', value: invoice.customerPhone),
                        _InvoiceInfoRow(label: 'DATE', value: invoice.orderDate),
                        _InvoiceInfoRow(label: 'TIME', value: invoice.orderTime),
                        const Divider(height: 22),
                        const Row(
                          children: [
                            Expanded(
                              flex: 6,
                              child: Text('ITEM', style: TextStyle(fontWeight: FontWeight.w700)),
                            ),
                            Expanded(
                              flex: 2,
                              child: Text(
                                'QTY',
                                textAlign: TextAlign.center,
                                style: TextStyle(fontWeight: FontWeight.w700),
                              ),
                            ),
                            Expanded(
                              flex: 4,
                              child: Text(
                                'AMOUNT',
                                textAlign: TextAlign.right,
                                style: TextStyle(fontWeight: FontWeight.w700),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        ...invoice.items.map(
                          (it) => Padding(
                            padding: const EdgeInsets.symmetric(vertical: 4),
                            child: Row(
                              children: [
                                Expanded(
                                  flex: 6,
                                  child: Text(
                                    '${it.productName}\nUnit: ${formatVndPrice(it.unitPrice)}',
                                    style: const TextStyle(fontSize: 12),
                                  ),
                                ),
                                Expanded(
                                  flex: 2,
                                  child: Text(
                                    '${it.qty}',
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                                Expanded(
                                  flex: 4,
                                  child: Text(
                                    formatVndPrice(it.amount),
                                    textAlign: TextAlign.right,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const Divider(height: 22),
                        _InvoiceInfoRow(label: 'TOTAL', value: formatVndPrice(invoice.subtotal)),
                        _InvoiceInfoRow(
                          label: 'DISCOUNT (${invoice.discountPercent.toStringAsFixed(0)}%)',
                          value: formatVndPrice(invoice.discountAmount),
                        ),
                        _InvoiceInfoRow(
                          label: 'PAYABLE',
                          value: formatVndPrice(invoice.totalPayable),
                          bold: true,
                        ),
                        _InvoiceInfoRow(label: 'PAID', value: formatVndPrice(invoice.paid)),
                        _InvoiceInfoRow(label: 'BALANCE', value: formatVndPrice(invoice.balance)),
                        _InvoiceInfoRow(label: 'PAID VIA', value: invoice.paymentMethod),
                        const SizedBox(height: 16),
                        const Center(
                          child: Text(
                            'Copyright © 2023 KODE MADE EAZY POS',
                            style: TextStyle(fontSize: 11, color: Color(0xFF6B7280)),
                          ),
                        ),
                      ],
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
}

class _InvoiceInfoRow extends StatelessWidget {
  const _InvoiceInfoRow({
    required this.label,
    required this.value,
    this.bold = false,
  });

  final String label;
  final String value;
  final bool bold;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          Expanded(
            flex: 4,
            child: Text('$label: ', style: const TextStyle(fontWeight: FontWeight.w600)),
          ),
          Expanded(
            flex: 6,
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: TextStyle(fontWeight: bold ? FontWeight.w700 : FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }
}

class _CashierSidebar extends StatelessWidget {
  const _CashierSidebar({
    required this.selectedTab,
    required this.onScannerTap,
    required this.onCustomersTap,
    required this.onLogoutTap,
  });

  final _CashierTab selectedTab;
  final VoidCallback onScannerTap;
  final VoidCallback onCustomersTap;
  final VoidCallback onLogoutTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF667EEA), Color(0xFF764BA2)],
        ),
      ),
      child: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 22),
            color: const Color.fromRGBO(0, 0, 0, 0.12),
            child: const Row(
              children: [
                CircleAvatar(
                  radius: 18,
                  backgroundColor: Colors.white,
                  child: Text('P', style: TextStyle(color: Color(0xFF667EEA))),
                ),
                SizedBox(width: 10),
                Text('SMS SYSTEM', style: TextStyle(color: Colors.white)),
              ],
            ),
          ),
          const SizedBox(height: 8),
          _MenuItem(
            label: 'Barcode Scanner',
            active: selectedTab == _CashierTab.scanner,
            onTap: onScannerTap,
          ),
          _MenuItem(
            label: 'Customer',
            active:
                selectedTab == _CashierTab.customers ||
                selectedTab == _CashierTab.customerHistory,
            onTap: onCustomersTap,
          ),
          const Spacer(),
          const Divider(color: Color.fromRGBO(255, 255, 255, 0.25), height: 1),
          SafeArea(
            top: false,
            minimum: const EdgeInsets.only(bottom: 10),
            child: _MenuItem(
              label: 'Logout',
              active: false,
              onTap: onLogoutTap,
            ),
          ),
        ],
      ),
    );
  }
}

class _MenuItem extends StatelessWidget {
  const _MenuItem({required this.label, required this.active, this.onTap});

  final String label;
  final bool active;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: active
          ? const Color.fromRGBO(255, 255, 255, 0.2)
          : Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
          child: Text(
            label,
            style: TextStyle(
              color: Colors.white,
              fontWeight: active ? FontWeight.w700 : FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }
}
