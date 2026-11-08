class SupplierListItem {
  final int id;
  final String supplierName;
  final String companyName;
  final String email;
  final String phone;
  final String address;
  final String status;
  final String? createdAt;

  SupplierListItem({
    required this.id,
    required this.supplierName,
    this.companyName = '—',
    this.email = '—',
    this.phone = '—',
    this.address = '—',
    this.status = 'active',
    this.createdAt,
  });

  factory SupplierListItem.fromJson(Map<String, dynamic> json) {
    return SupplierListItem(
      id: json['id'] as int? ?? 0,
      supplierName: json['supplierName'] as String? ?? json['supplier_name'] as String? ?? '—',
      companyName: json['companyName'] as String? ?? json['company_name'] as String? ?? '—',
      email: json['email'] as String? ?? '—',
      phone: json['phone'] as String? ?? '—',
      address: json['address'] as String? ?? '—',
      status: json['status'] as String? ?? 'active',
      createdAt: json['createdAt'] as String? ?? json['created_at'] as String?,
    );
  }
}
