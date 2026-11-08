import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supermarket_manager_system/models/product_detail.dart';
import 'package:supermarket_manager_system/models/update_product_request.dart';
import 'package:supermarket_manager_system/viewmodels/product_viewmodel.dart';

class UpdateProductDialog extends ConsumerStatefulWidget {
  const UpdateProductDialog({
    super.key,
    required this.product,
  });

  final ProductDetail product;

  @override
  ConsumerState<UpdateProductDialog> createState() => _UpdateProductDialogState();
}

class _UpdateProductDialogState extends ConsumerState<UpdateProductDialog> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _nameController;
  late TextEditingController _batchController;
  late TextEditingController _descController;
  late TextEditingController _costPriceController;
  late TextEditingController _sellingPriceController;
  late TextEditingController _cartonsController;
  late TextEditingController _qtyCartonsController;
  late TextEditingController _mftDateController;
  late TextEditingController _expiryDateController;
  late TextEditingController _imageUrlController;

  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    final p = widget.product;
    _nameController = TextEditingController(text: p.productName);
    _batchController = TextEditingController(text: p.productBatch);
    _descController = TextEditingController(text: p.description);
    _costPriceController =
        TextEditingController(text: (p.costPrice ?? 0).toString());
    _sellingPriceController =
        TextEditingController(text: p.sellingPrice.toString());
    _cartonsController =
        TextEditingController(text: (p.qtyCartons ?? 1).toString());
    _qtyCartonsController =
        TextEditingController(text: p.inStock.toString());
    _mftDateController = TextEditingController(text: p.mftDate);
    _expiryDateController = TextEditingController(text: p.expiryDate);
    _imageUrlController = TextEditingController(text: p.imageUrl);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _batchController.dispose();
    _descController.dispose();
    _costPriceController.dispose();
    _sellingPriceController.dispose();
    _cartonsController.dispose();
    _qtyCartonsController.dispose();
    _mftDateController.dispose();
    _expiryDateController.dispose();
    _imageUrlController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);
    try {
      final request = UpdateProductRequest(
        productBatch: _batchController.text.trim(),
        productName: _nameController.text.trim(),
        description: _descController.text.trim(),
        costPrice: double.tryParse(_costPriceController.text.trim()) ?? 0.0,
        sellingPrice: double.tryParse(_sellingPriceController.text.trim()) ?? 0.0,
        cartons: int.tryParse(_cartonsController.text.trim()) ?? 1,
        qtyCartons: int.tryParse(_qtyCartonsController.text.trim()) ?? 0,
        supplierId: 1, // Default fallback supplier
        categoryId: 1, // Default fallback category
        mftDate: _mftDateController.text.trim().isEmpty
            ? DateTime.now().toIso8601String().substring(0, 10)
            : _mftDateController.text.trim(),
        expiryDate: _expiryDateController.text.trim().isEmpty
            ? DateTime.now().add(const Duration(days: 365)).toIso8601String().substring(0, 10)
            : _expiryDateController.text.trim(),
        imageUrl: _imageUrlController.text.trim(),
      );

      await ref
          .read(productViewModelProvider.notifier)
          .updateProduct(widget.product.id, request);

      if (mounted) {
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Cập nhật thất bại: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Cập nhật sản phẩm: ${widget.product.productName}'),
      content: SizedBox(
        width: 500,
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(labelText: 'Tên sản phẩm *'),
                  validator: (v) =>
                      v == null || v.trim().isEmpty ? 'Vui lòng nhập tên sản phẩm' : null,
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _sellingPriceController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(labelText: 'Giá bán *'),
                        validator: (v) =>
                            v == null || v.trim().isEmpty ? 'Nhập giá bán' : null,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextFormField(
                        controller: _costPriceController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(labelText: 'Giá nhập'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _qtyCartonsController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(labelText: 'Số lượng tồn *'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextFormField(
                        controller: _batchController,
                        decoration: const InputDecoration(labelText: 'Số lô (Batch)'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _mftDateController,
                        decoration: const InputDecoration(labelText: 'NSX (YYYY-MM-DD)'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextFormField(
                        controller: _expiryDateController,
                        decoration: const InputDecoration(labelText: 'HSD (YYYY-MM-DD)'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _descController,
                  maxLines: 2,
                  decoration: const InputDecoration(labelText: 'Mô tả chi tiết'),
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isSaving ? null : () => Navigator.of(context).pop(false),
          child: const Text('Hủy'),
        ),
        ElevatedButton(
          onPressed: _isSaving ? null : _submit,
          child: _isSaving
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Lưu thay đổi'),
        ),
      ],
    );
  }
}
