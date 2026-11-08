import 'package:supermarket_manager_system/dto/customer_dto.dart';
import 'package:supermarket_manager_system/models/customer_detail.dart';
import 'package:supermarket_manager_system/models/customer_list_item.dart';

class CustomerMapper {
  static CustomerDto fromRow(Map<String, dynamic> row) => CustomerDto.fromJson(row);

  static CustomerDto fromModel(CustomerListItem item) {
    return CustomerDto(
      id: item.id,
      name: item.name,
      phone: item.phone,
      points: item.points,
      totalPurchases: item.totalPurchases,
      totalAmount: item.totalAmount,
      discountPercent: item.discountPercent,
    );
  }

  static CustomerDetailDto fromDetailModel(CustomerDetail detail) {
    return CustomerDetailDto(
      id: detail.id,
      name: detail.name,
      phone: detail.phone,
      points: detail.points,
      totalPurchases: detail.totalPurchases,
      totalAmount: detail.totalAmount,
      discountId: detail.discountId,
      discountName: detail.discountName,
      createdAt: detail.createdAt != null ? DateTime.tryParse(detail.createdAt!) : null,
      updatedAt: detail.updatedAt != null ? DateTime.tryParse(detail.updatedAt!) : null,
    );
  }
}
