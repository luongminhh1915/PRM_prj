import 'dart:math';

import 'package:flutter/material.dart';
import 'package:supermarket_manager_system/data/services/product_api_service.dart';
import 'package:supermarket_manager_system/models/category_option.dart';
import 'package:supermarket_manager_system/models/create_product_request.dart';
import 'package:supermarket_manager_system/models/supplier_option.dart';

class AddProductPage extends StatefulWidget {
  const AddProductPage({
    super.key,
    required this.basePath,
    required this.fullName,
  });

  final String basePath;
  final String fullName;

  @override
  State<AddProductPage> createState() => _AddProductPageState();
}

class _AddProductPageState extends State<AddProductPage> {
  final _formKey = GlobalKey<FormState>();
  final _productApiService = ProductApiService();

  final _barcodeController = TextEditingController();
  final _productBatchController = TextEditingController();
  final _productNameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _costPriceController = TextEditingController();
  final _sellingPriceController = TextEditingController();
  final _cartonsController = TextEditingController();
  final _qtyCartonsController = TextEditingController();
  final _mftDateController = TextEditingController();
  final _expiryDateController = TextEditingController();
  final _imageUrlController = TextEditingController();

  List<SupplierOption> _suppliers = [];
  List<CategoryOption> _categories = [];
  int? _selectedSupplierId;
  int? _selectedCategoryId;
  bool _isLoading = false;
  bool _isLoadingOptions = true;

  @override
  void initState() {
    super.initState();
    _loadOptions();
  }

  @override
  void dispose() {
    _barcodeController.dispose();
    _productBatchController.dispose();
    _productNameController.dispose();
    _descriptionController.dispose();
    _costPriceController.dispose();
    _sellingPriceController.dispose();
    _cartonsController.dispose();
    _qtyCartonsController.dispose();
    _mftDateController.dispose();
    _expiryDateController.dispose();
    _imageUrlController.dispose();
    super.dispose();
  }

  Future<void> _loadOptions() async {
    try {
      final suppliers = await _productApiService.getSupplierOptions();
      final categories = await _productApiService.getCategoryOptions();
      setState(() {
        _suppliers = suppliers;
        _categories = categories;
        _isLoadingOptions = false;
      });
    } catch (e) {
      setState(() => _isLoadingOptions = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load options: $e')),
        );
      }
    }
  }

  void _generateBarcode() {
    final random = Random();
    final barcode = '${random.nextInt(900000000) + 100000000}';
    _barcodeController.text = barcode;
  }

  Future<void> _selectDate(TextEditingController controller) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      controller.text = picked.toIso8601String().split('T')[0];
    }
  }

  Future<void> _saveProduct() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_selectedSupplierId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a supplier')),
      );
      return;
    }

    if (_selectedCategoryId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a category')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final request = CreateProductRequest(
        barcode: _barcodeController.text.trim(),
        productBatch: _productBatchController.text.trim(),
        productName: _productNameController.text.trim(),
        description: _descriptionController.text.trim().isEmpty
            ? null
            : _descriptionController.text.trim(),
        costPrice: double.parse(_costPriceController.text.trim()),
        sellingPrice: double.parse(_sellingPriceController.text.trim()),
        cartons: int.parse(_cartonsController.text.trim()),
        qtyCartons: int.parse(_qtyCartonsController.text.trim()),
        supplierId: _selectedSupplierId!,
        categoryId: _selectedCategoryId!,
        mftDate: _mftDateController.text.trim(),
        expiryDate: _expiryDateController.text.trim(),
        imageUrl: _imageUrlController.text.trim().isEmpty
            ? null
            : _imageUrlController.text.trim(),
      );

      await _productApiService.createProduct(request);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Product created successfully'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to create product: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F2F5),
      body: Column(
        children: [
          _buildHeader(),
          Expanded(
            child: _isLoadingOptions
                ? const Center(child: CircularProgressIndicator())
                : SingleChildScrollView(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        InkWell(
                          onTap: () => Navigator.of(context).pop(),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.arrow_back, color: Color(0xFF3B82F6)),
                              SizedBox(width: 6),
                              Text(
                                'Back to Stock Inventory',
                                style: TextStyle(
                                  color: Color(0xFF3B82F6),
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'Add New Product',
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 20),
                        _buildForm(),
                      ],
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      height: 72,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Color(0xFFE8EAED))),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                widget.fullName.isEmpty ? 'User' : widget.fullName,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              Text(
                widget.basePath == 'manager' ? 'Manager' : 'Administrator',
                style: const TextStyle(
                  color: Color(0xFF6B7280),
                  fontSize: 12,
                ),
              ),
            ],
          ),
          const SizedBox(width: 12),
          Container(
            width: 40,
            height: 40,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: const Color(0xFF1E293B),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              widget.fullName.isNotEmpty ? widget.fullName[0].toUpperCase() : 'U',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildForm() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE8EAED)),
      ),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildBarcodeField(),
            const SizedBox(height: 16),
            _buildTextField(
              label: 'Product Batch',
              controller: _productBatchController,
              required: true,
            ),
            const SizedBox(height: 16),
            _buildTextField(
              label: 'Product Name',
              controller: _productNameController,
              required: true,
            ),
            const SizedBox(height: 16),
            _buildTextField(
              label: 'Product Description',
              controller: _descriptionController,
              required: false,
              maxLines: 3,
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildTextField(
                    label: 'Cost Price',
                    controller: _costPriceController,
                    required: true,
                    keyboardType: TextInputType.number,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildTextField(
                    label: 'Selling Price',
                    controller: _sellingPriceController,
                    required: true,
                    keyboardType: TextInputType.number,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildTextField(
                    label: 'Cartons',
                    controller: _cartonsController,
                    required: true,
                    keyboardType: TextInputType.number,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildTextField(
                    label: 'In Stock',
                    controller: _qtyCartonsController,
                    required: true,
                    keyboardType: TextInputType.number,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(child: _buildSupplierDropdown()),
                const SizedBox(width: 16),
                Expanded(child: _buildCategoryDropdown()),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(child: _buildDateField('MFT Date', _mftDateController)),
                const SizedBox(width: 16),
                Expanded(child: _buildDateField('Expiry Date', _expiryDateController)),
              ],
            ),
            const SizedBox(height: 16),
            _buildTextField(
              label: 'Product Image URL',
              controller: _imageUrlController,
              required: false,
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                OutlinedButton(
                  onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                  ),
                  child: const Text('Cancel'),
                ),
                const SizedBox(width: 12),
                ElevatedButton(
                  onPressed: _isLoading ? null : _saveProduct,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF93C5FD),
                    foregroundColor: const Color(0xFF1E40AF),
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Save'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBarcodeField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Barcode',
          style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: _barcodeController,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  hintText: 'Enter barcode',
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Barcode is required';
                  }
                  return null;
                },
              ),
            ),
            const SizedBox(width: 8),
            OutlinedButton(
              onPressed: _generateBarcode,
              child: const Text('Auto Generate'),
            ),
          ],
        ),
        const SizedBox(height: 4),
        const Text(
          'Scan with device or click Auto Generate for products without barcode (e.g., vegetables).',
          style: TextStyle(fontSize: 12, color: Color(0xFF6B7280)),
        ),
      ],
    );
  }

  Widget _buildTextField({
    required String label,
    required TextEditingController controller,
    required bool required,
    int maxLines = 1,
    TextInputType? keyboardType,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          maxLines: maxLines,
          keyboardType: keyboardType,
          decoration: InputDecoration(
            border: const OutlineInputBorder(),
            hintText: 'Enter $label',
          ),
          validator: (value) {
            if (required && (value == null || value.trim().isEmpty)) {
              return '$label is required';
            }
            
            // Validate numeric fields
            if (value != null && value.trim().isNotEmpty && keyboardType == TextInputType.number) {
              final numValue = double.tryParse(value.trim());
              if (numValue == null) {
                return 'Please enter a valid number';
              }
              if (numValue < 0) {
                return '$label must be greater than or equal to 0';
              }
              // For integer fields (Cartons, In Stock)
              if (label == 'Cartons' || label == 'In Stock') {
                if (numValue != numValue.toInt()) {
                  return '$label must be a whole number';
                }
              }
            }
            
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildSupplierDropdown() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Supplier',
          style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<int>(
          initialValue: _selectedSupplierId,
          isExpanded: true,
          decoration: const InputDecoration(
            border: OutlineInputBorder(),
            hintText: 'Choose...',
          ),
          validator: (value) {
            if (value == null) {
              return 'Supplier is required';
            }
            return null;
          },
          selectedItemBuilder: (context) {
            return _suppliers
                .map(
                  (s) => Text(
                    s.supplierName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                )
                .toList();
          },
          items: _suppliers
              .map((s) => DropdownMenuItem(
                    value: s.id,
                    child: Text(s.supplierName),
                  ))
              .toList(),
          onChanged: (value) => setState(() => _selectedSupplierId = value),
        ),
      ],
    );
  }

  Widget _buildCategoryDropdown() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Category',
          style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<int>(
          initialValue: _selectedCategoryId,
          decoration: const InputDecoration(
            border: OutlineInputBorder(),
            hintText: 'Choose...',
          ),
          validator: (value) {
            if (value == null) {
              return 'Category is required';
            }
            return null;
          },
          items: _categories
              .map((c) => DropdownMenuItem(
                    value: c.id,
                    child: Text(c.name),
                  ))
              .toList(),
          onChanged: (value) => setState(() => _selectedCategoryId = value),
        ),
      ],
    );
  }

  Widget _buildDateField(String label, TextEditingController controller) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          readOnly: true,
          decoration: InputDecoration(
            border: const OutlineInputBorder(),
            hintText: 'Select date',
            suffixIcon: const Icon(Icons.calendar_today),
          ),
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return '$label is required';
            }
            return null;
          },
          onTap: () => _selectDate(controller),
        ),
      ],
    );
  }
}
