class SupplierOption {
  final int id;
  final String supplierName;

  const SupplierOption({
    required this.id,
    required this.supplierName,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SupplierOption &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;
}
