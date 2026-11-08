import 'package:flutter/material.dart';
import 'package:supermarket_manager_system/data/services/category_api_service.dart';
import 'package:supermarket_manager_system/models/category_list_item.dart';
import 'package:supermarket_manager_system/views/widgets/dashboard_header.dart';

class ListCategoryScreen extends StatefulWidget {
  const ListCategoryScreen({
    super.key,
    required this.fullName,
    required this.isCompact,
    required this.currentTimeText,
    required this.onProfileTap,
  });

  final String fullName;
  final bool isCompact;
  final String currentTimeText;
  final VoidCallback onProfileTap;

  @override
  State<ListCategoryScreen> createState() => _ListCategoryScreenState();
}

class _ListCategoryScreenState extends State<ListCategoryScreen> {
  final _api = CategoryApiService();

  late Future<List<CategoryListItem>> _categoriesFuture;
  int? _selectedCategoryId;
  Future<CategoryListItem>? _selectedCategoryFuture;
  bool _isUpdatingStatus = false;

  @override
  void initState() {
    super.initState();
    _categoriesFuture = _api.getCategories();
  }

  void _reloadCategories() {
    setState(() {
      _categoriesFuture = _api.getCategories();
    });
  }

  void _openCategoryDetail(CategoryListItem c) {
    setState(() {
      _selectedCategoryId = c.id;
      _selectedCategoryFuture = _api.getCategoryById(c.id);
    });
  }

  void _closeCategoryDetail() {
    setState(() {
      _selectedCategoryId = null;
      _selectedCategoryFuture = null;
      _isUpdatingStatus = false;
    });
    _reloadCategories();
  }

  Future<void> _openAddCategoryDialog() async {
    final created = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => AddCategoryScreen(api: _api),
    );

    if (!mounted) return;
    if (created == true) {
      _reloadCategories();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Category created successfully')),
      );
    }
  }

  Future<void> _openUpdateCategoryDialog(CategoryListItem c) async {
    final updated = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => UpdateCategoryScreen(
        api: _api,
        initial: c,
      ),
    );

    if (!mounted) return;
    if (updated == true) {
      _reloadCategories();
      if (_selectedCategoryId == c.id) {
        _selectedCategoryFuture = _api.getCategoryById(c.id);
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Category updated successfully')),
      );
    }
  }

  Future<void> _openDeleteCategoryPopup(CategoryListItem c) async {
    final confirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => DeleteCategoryScreen(category: c),
    );

    if (!mounted || confirmed != true) return;

    try {
      await _api.deleteCategory(c.id);
      if (!mounted) return;
      if (_selectedCategoryId == c.id) {
        _closeCategoryDetail();
      } else {
        _reloadCategories();
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Category deleted successfully')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceFirst('Exception: ', '')),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _setCategoryStatus(CategoryListItem c, String newStatus) async {
    setState(() => _isUpdatingStatus = true);
    try {
      await _api.updateCategory(
        id: c.id,
        name: c.name,
        status: newStatus,
      );
      if (!mounted) return;

      if (_selectedCategoryId == c.id) {
        _selectedCategoryFuture = _api.getCategoryById(c.id);
      }
      _reloadCategories();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Status updated to ${newStatus.toUpperCase()}'),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceFirst('Exception: ', '')),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) setState(() => _isUpdatingStatus = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFFF0F2F5),
      child: Column(
        children: [
          DashboardHeader(
            fullName: widget.fullName,
            roleLabel: 'Manager',
            currentTimeText: widget.currentTimeText,
            isCompact: widget.isCompact,
            onProfileTap: widget.onProfileTap,
            title: null,
            timeChipColor: const Color(0xFF667EEA),
            avatarColor: const Color(0xFF667EEA),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        _selectedCategoryId == null
                            ? 'List Category'
                            : 'Category Detail',
                        style: const TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      if (_selectedCategoryId == null)
                        DecoratedBox(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(10),
                            gradient: const LinearGradient(
                              colors: [Color(0xFF667EEA), Color(0xFF764BA2)],
                            ),
                          ),
                          child: TextButton(
                            onPressed: _openAddCategoryDialog,
                            child: const Text(
                              '+ Add Category',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Expanded(
                    child: _selectedCategoryId == null
                        ? FutureBuilder<List<CategoryListItem>>(
                            future: _categoriesFuture,
                            builder: (context, snapshot) {
                              if (snapshot.connectionState ==
                                  ConnectionState.waiting) {
                                return const Center(
                                  child: CircularProgressIndicator(),
                                );
                              }
                              if (snapshot.hasError) {
                                return Center(
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        'Cannot load categories: ${snapshot.error}',
                                        textAlign: TextAlign.center,
                                      ),
                                      const SizedBox(height: 12),
                                      ElevatedButton(
                                        onPressed: _reloadCategories,
                                        child: const Text('Retry'),
                                      ),
                                    ],
                                  ),
                                );
                              }

                              final categories = snapshot.data ?? [];
                              return Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(12),
                                  border:
                                      Border.all(color: const Color(0xFFE8EAED)),
                                ),
                                child: categories.isEmpty
                                    ? Center(
                                        child: Padding(
                                          padding: const EdgeInsets.all(24),
                                          child: Column(
                                            mainAxisSize: MainAxisSize.min,
                                            children: const [
                                              Text(
                                                'No categories found',
                                                style: TextStyle(
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.w700,
                                                ),
                                              ),
                                              SizedBox(height: 10),
                                              Text(
                                                'Tap `+ Add Category` để tạo mới.',
                                                textAlign: TextAlign.center,
                                              ),
                                            ],
                                          ),
                                        ),
                                      )
                                    : ListView.separated(
                                        itemCount: categories.length,
                                        separatorBuilder: (_, _) =>
                                            const SizedBox(height: 12),
                                        itemBuilder: (context, idx) {
                                          final c = categories[idx];
                                          final normalizedStatus =
                                              c.status.toLowerCase();
                                          final isActive =
                                              normalizedStatus == 'active';

                                          return InkWell(
                                            onTap: () => _openCategoryDetail(c),
                                            borderRadius:
                                                BorderRadius.circular(14),
                                            child: Container(
                                              padding:
                                                  const EdgeInsets.all(14),
                                              decoration: BoxDecoration(
                                                color: Colors.white,
                                                borderRadius:
                                                    BorderRadius.circular(14),
                                                border: Border.all(
                                                  color: const Color(
                                                      0xFFE8EAED),
                                                ),
                                              ),
                                              child: Row(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  Expanded(
                                                    child: Column(
                                                      mainAxisSize:
                                                          MainAxisSize.min,
                                                      crossAxisAlignment:
                                                          CrossAxisAlignment
                                                              .start,
                                                      children: [
                                                        Text(
                                                          c.name.isEmpty
                                                              ? '—'
                                                              : c.name,
                                                          style: const TextStyle(
                                                            fontWeight:
                                                                FontWeight.w800,
                                                            fontSize: 14,
                                                          ),
                                                          maxLines: 1,
                                                          overflow: TextOverflow
                                                              .ellipsis,
                                                        ),
                                                        const SizedBox(height: 6),
                                                        _StatusChip(status: c.status),
                                                      ],
                                                    ),
                                                  ),
                                                  Icon(
                                                    isActive
                                                        ? Icons
                                                            .keyboard_arrow_right_rounded
                                                        : Icons.arrow_right_alt_rounded,
                                                    size: 20,
                                                    color: const Color(
                                                        0xFF667EEA),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          );
                                        },
                                      ),
                              );
                            },
                          )
                        : FutureBuilder<CategoryListItem>(
                            future: _selectedCategoryFuture,
                            builder: (context, snapshot) {
                              if (snapshot.connectionState ==
                                  ConnectionState.waiting) {
                                return const Center(
                                  child: CircularProgressIndicator(),
                                );
                              }
                              if (snapshot.hasError) {
                                return Center(
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        'Cannot load category detail: ${snapshot.error}',
                                        textAlign: TextAlign.center,
                                      ),
                                      const SizedBox(height: 12),
                                      ElevatedButton(
                                        onPressed: _closeCategoryDetail,
                                        child: const Text('Back'),
                                      ),
                                    ],
                                  ),
                                );
                              }

                              final c = snapshot.data!;
                              final normalizedStatus = c.status.toLowerCase();
                              final canDelete = normalizedStatus != 'deactive';

                              return Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(12),
                                  border:
                                      Border.all(color: const Color(0xFFE8EAED)),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.stretch,
                                  children: [
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Row(
                                          children: [
                                            IconButton(
                                              onPressed: _closeCategoryDetail,
                                              icon: const Icon(Icons.arrow_back),
                                              tooltip: 'Back',
                                            ),
                                            const SizedBox(width: 6),
                                            Text(
                                              c.name.isEmpty ? '—' : c.name,
                                              style: const TextStyle(
                                                fontSize: 22,
                                                fontWeight: FontWeight.w800,
                                              ),
                                            ),
                                          ],
                                        ),
                                        _StatusChip(status: c.status),
                                      ],
                                    ),
                                    const SizedBox(height: 10),
                                    const Divider(
                                      color: Color(0xFFE8EAED),
                                      thickness: 1,
                                    ),
                                    const SizedBox(height: 14),
                                    _DetailLine(
                                      label: 'Created',
                                      value: c.createdAt ?? '—',
                                    ),
                                    const SizedBox(height: 18),
                                    Wrap(
                                      spacing: 12,
                                      runSpacing: 12,
                                      children: [
                                        OutlinedButton.icon(
                                          onPressed: () =>
                                              _openUpdateCategoryDialog(c),
                                          icon: const Icon(Icons.edit_outlined),
                                          label: const Text('Edit'),
                                          style: OutlinedButton.styleFrom(
                                            foregroundColor:
                                                const Color(0xFF667EEA),
                                            side: const BorderSide(
                                              color: Color(0xFF667EEA),
                                            ),
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 14,
                                              vertical: 10,
                                            ),
                                          ),
                                        ),
                                        OutlinedButton.icon(
                                          onPressed: _isUpdatingStatus
                                              ? null
                                              : () {
                                                  final targetActive =
                                                      normalizedStatus != 'active';
                                                  _setCategoryStatus(
                                                    c,
                                                    targetActive ? 'active' : 'deactive',
                                                  );
                                                },
                                          icon: Icon(
                                            normalizedStatus == 'active'
                                                ? Icons.toggle_off_outlined
                                                : Icons.toggle_on_outlined,
                                          ),
                                          label: Text(
                                            normalizedStatus == 'active'
                                                ? 'Set Deactive'
                                                : 'Set Active',
                                          ),
                                          style: OutlinedButton.styleFrom(
                                            foregroundColor:
                                                const Color(0xFF667EEA),
                                            side: const BorderSide(
                                              color: Color(0xFF667EEA),
                                            ),
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 14,
                                              vertical: 10,
                                            ),
                                          ),
                                        ),
                                        if (canDelete)
                                          OutlinedButton.icon(
                                            onPressed: () => _openDeleteCategoryPopup(c),
                                            icon: const Icon(Icons.delete_outline),
                                            label: const Text('Delete'),
                                            style: OutlinedButton.styleFrom(
                                              foregroundColor: Colors.red,
                                              side: const BorderSide(
                                                color: Colors.red,
                                              ),
                                              padding: const EdgeInsets.symmetric(
                                                horizontal: 14,
                                                vertical: 10,
                                              ),
                                            ),
                                          ),
                                      ],
                                    ),
                                  ],
                                ),
                              );
                            },
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
}

class DeleteCategoryScreen extends StatelessWidget {
  const DeleteCategoryScreen({super.key, required this.category});

  final CategoryListItem category;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Delete Category'),
      content: Text(
        'Are you sure you want to delete "${category.name.isEmpty ? "this category" : category.name}"? This action cannot be undone.',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(true),
          style: TextButton.styleFrom(foregroundColor: Colors.red),
          child: const Text('Delete'),
        ),
      ],
    );
  }
}

class AddCategoryScreen extends StatefulWidget {
  const AddCategoryScreen({super.key, required this.api});

  final CategoryApiService api;

  @override
  State<AddCategoryScreen> createState() => _AddCategoryScreenState();
}

class _AddCategoryScreenState extends State<AddCategoryScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  String _status = 'active';
  bool _isSubmitting = false;
  String? _errorText;

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_formKey.currentState == null || !_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isSubmitting = true;
      _errorText = null;
    });

    try {
      await widget.api.createCategory(
        name: _nameController.text.trim(),
        status: _status,
      );
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorText = e.toString().replaceFirst('Exception: ', '');
      });
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 520),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
          ),
          child: SingleChildScrollView(
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                    'Add Category',
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 20),
                  TextFormField(
                    controller: _nameController,
                    decoration: const InputDecoration(
                      labelText: 'Name *',
                      border: OutlineInputBorder(),
                    ),
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) {
                        return 'Category name is required';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    initialValue: _status,
                    decoration: const InputDecoration(
                      labelText: 'Status',
                      border: OutlineInputBorder(),
                    ),
                    items: const [
                      DropdownMenuItem(value: 'active', child: Text('Active')),
                      DropdownMenuItem(value: 'deactive', child: Text('Deactive')),
                    ],
                    onChanged: _isSubmitting ? null : (v) => setState(() => _status = v ?? 'active'),
                  ),
                  if (_errorText != null) ...[
                    const SizedBox(height: 12),
                    Text(
                      _errorText!,
                      style: const TextStyle(color: Colors.red, fontSize: 13),
                    ),
                  ],
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: _isSubmitting ? null : () => Navigator.of(context).pop(false),
                        child: const Text('Cancel'),
                      ),
                      const SizedBox(width: 12),
                      ElevatedButton(
                        onPressed: _isSubmitting ? null : _submit,
                        child: _isSubmitting
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Text('Add'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class UpdateCategoryScreen extends StatefulWidget {
  const UpdateCategoryScreen({
    super.key,
    required this.api,
    required this.initial,
  });

  final CategoryApiService api;
  final CategoryListItem initial;

  @override
  State<UpdateCategoryScreen> createState() => _UpdateCategoryScreenState();
}

class _UpdateCategoryScreenState extends State<UpdateCategoryScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late String _status;
  bool _isSubmitting = false;
  String? _errorText;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.initial.name);
    _status = widget.initial.status.isEmpty ? 'active' : widget.initial.status;
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_formKey.currentState == null || !_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isSubmitting = true;
      _errorText = null;
    });

    try {
      await widget.api.updateCategory(
        id: widget.initial.id,
        name: _nameController.text.trim(),
        status: _status,
      );
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorText = e.toString().replaceFirst('Exception: ', '');
      });
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 520),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
          ),
          child: SingleChildScrollView(
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                    'Update Category',
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 20),
                  TextFormField(
                    controller: _nameController,
                    decoration: const InputDecoration(
                      labelText: 'Name *',
                      border: OutlineInputBorder(),
                    ),
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) {
                        return 'Category name is required';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    initialValue: _status,
                    decoration: const InputDecoration(
                      labelText: 'Status',
                      border: OutlineInputBorder(),
                    ),
                    items: const [
                      DropdownMenuItem(value: 'active', child: Text('Active')),
                      DropdownMenuItem(value: 'deactive', child: Text('Deactive')),
                    ],
                    onChanged: _isSubmitting ? null : (v) => setState(() => _status = v ?? 'active'),
                  ),
                  if (_errorText != null) ...[
                    const SizedBox(height: 12),
                    Text(
                      _errorText!,
                      style: const TextStyle(color: Colors.red, fontSize: 13),
                    ),
                  ],
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: _isSubmitting ? null : () => Navigator.of(context).pop(false),
                        child: const Text('Cancel'),
                      ),
                      const SizedBox(width: 12),
                      ElevatedButton(
                        onPressed: _isSubmitting ? null : _submit,
                        child: _isSubmitting
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Text('Update'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.status});

  final String status;

  @override
  Widget build(BuildContext context) {
    final normalized = status.toLowerCase();
    final isActive = normalized == 'active';
    final bg = isActive ? const Color(0xFFD1FAE5) : const Color(0xFFFEE2E2);
    final fg = isActive ? const Color(0xFF065F46) : const Color(0xFF991B1B);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: bg,
      ),
      child: Text(
        status.isEmpty ? '-' : status,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: fg,
        ),
      ),
    );
  }
}

class _DetailLine extends StatelessWidget {
  const _DetailLine({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: Color(0xFF6B7280),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              value.trim().isEmpty ? '—' : value,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Color(0xFF0F172A),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

