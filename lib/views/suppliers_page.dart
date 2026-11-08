import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supermarket_manager_system/viewmodels/supplier_viewmodel.dart';
import 'package:supermarket_manager_system/models/supplier_list_item.dart';
import 'package:supermarket_manager_system/views/supplier_detail_page.dart';
import 'package:supermarket_manager_system/views/widgets/dashboard_header.dart';

class SuppliersPage extends ConsumerStatefulWidget {
  const SuppliersPage({
    super.key,
    required this.fullName,
    required this.isCompact,
    required this.currentTimeText,
  });

  final String fullName;
  final bool isCompact;
  final String currentTimeText;

  @override
  ConsumerState<SuppliersPage> createState() => _SuppliersPageState();
}

class _SuppliersPageState extends ConsumerState<SuppliersPage> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(supplierViewModelProvider.notifier).loadSuppliers();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _openSupplierDetail(SupplierListItem supplier) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => SupplierDetailPage(supplierId: supplier.id),
      ),
    );
  }

  void _showAddOrEditDialog({SupplierListItem? supplier}) {
    final isEdit = supplier != null;
    final nameController = TextEditingController(text: supplier?.supplierName ?? '');
    final companyController = TextEditingController(text: supplier?.companyName == '—' ? '' : supplier?.companyName);
    final emailController = TextEditingController(text: supplier?.email == '—' ? '' : supplier?.email);
    final phoneController = TextEditingController(text: supplier?.phone == '—' ? '' : supplier?.phone);
    final addressController = TextEditingController(text: supplier?.address == '—' ? '' : supplier?.address);
    String status = supplier?.status ?? 'active';

    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              title: Text(
                isEdit ? 'Chỉnh Sửa Nhà Cung Cấp' : 'Thêm Nhà Cung Cấp Mới',
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
              content: SingleChildScrollView(
                child: SizedBox(
                  width: 480,
                  child: Form(
                    key: formKey,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        TextFormField(
                          controller: nameController,
                          decoration: const InputDecoration(
                            labelText: 'Tên Nhà Cung Cấp *',
                            border: OutlineInputBorder(),
                          ),
                          validator: (val) => (val == null || val.trim().isEmpty) ? 'Vui lòng nhập tên' : null,
                        ),
                        const SizedBox(height: 14),
                        TextFormField(
                          controller: companyController,
                          decoration: const InputDecoration(
                            labelText: 'Tên Công Ty',
                            border: OutlineInputBorder(),
                          ),
                        ),
                        const SizedBox(height: 14),
                        TextFormField(
                          controller: emailController,
                          decoration: const InputDecoration(
                            labelText: 'Email',
                            border: OutlineInputBorder(),
                          ),
                        ),
                        const SizedBox(height: 14),
                        TextFormField(
                          controller: phoneController,
                          decoration: const InputDecoration(
                            labelText: 'Số Điện Thoại',
                            border: OutlineInputBorder(),
                          ),
                        ),
                        const SizedBox(height: 14),
                        TextFormField(
                          controller: addressController,
                          decoration: const InputDecoration(
                            labelText: 'Địa Chỉ',
                            border: OutlineInputBorder(),
                          ),
                          maxLines: 2,
                        ),
                        const SizedBox(height: 14),
                        DropdownButtonFormField<String>(
                          value: status,
                          decoration: const InputDecoration(
                            labelText: 'Trạng Thái',
                            border: OutlineInputBorder(),
                          ),
                          items: const [
                            DropdownMenuItem(value: 'active', child: Text('Hoạt động (active)')),
                            DropdownMenuItem(value: 'deactive', child: Text('Tạm ngưng (deactive)')),
                          ],
                          onChanged: (val) {
                            if (val != null) setDialogState(() => status = val);
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(),
                  child: const Text('Hủy'),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0F172A),
                    foregroundColor: Colors.white,
                  ),
                  onPressed: () async {
                    if (!formKey.currentState!.validate()) return;
                    final notifier = ref.read(supplierViewModelProvider.notifier);

                    try {
                      if (isEdit) {
                        await notifier.updateSupplier(
                          id: supplier.id,
                          supplierName: nameController.text,
                          companyName: companyController.text,
                          email: emailController.text,
                          phone: phoneController.text,
                          address: addressController.text,
                          status: status,
                        );
                      } else {
                        await notifier.createSupplier(
                          supplierName: nameController.text,
                          companyName: companyController.text,
                          email: emailController.text,
                          phone: phoneController.text,
                          address: addressController.text,
                          status: status,
                        );
                      }
                      if (mounted) Navigator.of(dialogContext).pop();
                    } catch (e) {
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Lỗi: $e')),
                        );
                      }
                    }
                  },
                  child: Text(isEdit ? 'Cập Nhật' : 'Tạo Mới'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _confirmDelete(SupplierListItem supplier) {
    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Xác Nhận Xóa'),
          content: Text('Bạn có chắc chắn muốn xóa nhà cung cấp "${supplier.supplierName}"?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Hủy'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFDC2626)),
              onPressed: () async {
                final notifier = ref.read(supplierViewModelProvider.notifier);
                try {
                  await notifier.deleteSupplier(supplier.id);
                  if (mounted) Navigator.of(dialogContext).pop();
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Lỗi: $e')),
                    );
                  }
                }
              },
              child: const Text('Xóa', style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(supplierViewModelProvider);
    final notifier = ref.read(supplierViewModelProvider.notifier);

    return Container(
      color: const Color(0xFFF8FAFC),
      child: Column(
        children: [
          DashboardHeader(
            title: 'Quản Lý Nhà Cung Cấp & Đối Tác',
            fullName: widget.fullName,
            roleLabel: 'Nhà Cung Cấp',
            currentTimeText: widget.currentTimeText,
            isCompact: widget.isCompact,
            timeChipColor: const Color(0xFF9333EA),
            avatarColor: const Color(0xFF0F172A),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Action bar
                  _buildActionBar(context, state, notifier),
                  const SizedBox(height: 20),

                  if (state.isLoading)
                    const Padding(
                      padding: EdgeInsets.all(60),
                      child: Center(child: CircularProgressIndicator()),
                    )
                  else if (state.errorMessage != null)
                    _buildErrorCard(state.errorMessage!, notifier)
                  else
                    _buildSuppliersTable(state.filteredSuppliers),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionBar(
    BuildContext context,
    SupplierListState state,
    SupplierViewModel notifier,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Wrap(
        spacing: 12,
        runSpacing: 12,
        crossAxisAlignment: WrapCrossAlignment.center,
        alignment: WrapAlignment.spaceBetween,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: 260,
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Tìm kiếm NCC, SĐT, Email...',
                    prefixIcon: const Icon(Icons.search, size: 20),
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  onChanged: (val) => notifier.setSearchQuery(val),
                ),
              ),
              const SizedBox(width: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFFCBD5E1)),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: state.statusFilter,
                    items: const [
                      DropdownMenuItem(value: 'All', child: Text('Tất cả trạng thái')),
                      DropdownMenuItem(value: 'active', child: Text('Hoạt động')),
                      DropdownMenuItem(value: 'deactive', child: Text('Tạm ngưng')),
                    ],
                    onChanged: (val) {
                      if (val != null) notifier.setStatusFilter(val);
                    },
                  ),
                ),
              ),
            ],
          ),
          ElevatedButton.icon(
            onPressed: () => _showAddOrEditDialog(),
            icon: const Icon(Icons.add, size: 20),
            label: const Text('Thêm Nhà Cung Cấp'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF16A34A),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSuppliersTable(List<SupplierListItem> suppliers) {
    if (suppliers.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(40),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: const Center(
          child: Text('Không tìm thấy nhà cung cấp nào'),
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          headingRowColor: WidgetStateProperty.all(const Color(0xFFF8FAFC)),
          columns: const [
            DataColumn(label: Text('ID', style: TextStyle(fontWeight: FontWeight.w700))),
            DataColumn(label: Text('Tên Nhà Cung Cấp', style: TextStyle(fontWeight: FontWeight.w700))),
            DataColumn(label: Text('Tên Công Ty', style: TextStyle(fontWeight: FontWeight.w700))),
            DataColumn(label: Text('Email', style: TextStyle(fontWeight: FontWeight.w700))),
            DataColumn(label: Text('Số Điện Thoại', style: TextStyle(fontWeight: FontWeight.w700))),
            DataColumn(label: Text('Trạng Thái', style: TextStyle(fontWeight: FontWeight.w700))),
            DataColumn(label: Text('Thao Tác', style: TextStyle(fontWeight: FontWeight.w700))),
          ],
          rows: suppliers.map((supplier) {
            final isActive = supplier.status.toLowerCase() == 'active';
            return DataRow(
              cells: [
                DataCell(Text('#${supplier.id}', style: const TextStyle(fontWeight: FontWeight.w600))),
                DataCell(
                  InkWell(
                    onTap: () => _openSupplierDetail(supplier),
                    child: Text(
                      supplier.supplierName,
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF2563EB),
                      ),
                    ),
                  ),
                ),
                DataCell(Text(supplier.companyName)),
                DataCell(Text(supplier.email)),
                DataCell(Text(supplier.phone)),
                DataCell(
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: isActive ? const Color(0xFFDCFCE7) : const Color(0xFFFEE2E2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      isActive ? 'Hoạt động' : 'Tạm ngưng',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: isActive ? const Color(0xFF15803D) : const Color(0xFFB91C1C),
                      ),
                    ),
                  ),
                ),
                DataCell(
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.visibility_outlined, color: Color(0xFF2563EB), size: 20),
                        onPressed: () => _openSupplierDetail(supplier),
                        tooltip: 'Chi tiết',
                      ),
                      IconButton(
                        icon: const Icon(Icons.edit_outlined, color: Color(0xFFD97706), size: 20),
                        onPressed: () => _showAddOrEditDialog(supplier: supplier),
                        tooltip: 'Chỉnh sửa',
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete_outline, color: Color(0xFFDC2626), size: 20),
                        onPressed: () => _confirmDelete(supplier),
                        tooltip: 'Xóa',
                      ),
                    ],
                  ),
                ),
              ],
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildErrorCard(String error, SupplierViewModel notifier) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFFECACA)),
      ),
      child: Column(
        children: [
          const Icon(Icons.error_outline, color: Color(0xFFDC2626), size: 40),
          const SizedBox(height: 12),
          Text(error, style: const TextStyle(color: Color(0xFFB91C1C))),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () => notifier.loadSuppliers(),
            child: const Text('Thử lại'),
          ),
        ],
      ),
    );
  }
}
