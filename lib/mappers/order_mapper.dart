import 'package:supermarket_manager_system/dto/order_dto.dart';
import 'package:supermarket_manager_system/models/order_detail.dart';
import 'package:supermarket_manager_system/models/order_list_item.dart';

class OrderMapper {
  static OrderDto fromRow(Map<String, dynamic> row) => OrderDto.fromJson(row);

  static OrderDto fromModel(OrderListItem item) {
    return OrderDto(
      id: item.id,
      orderNo: item.orderNo,
      orderDateTime: item.orderDateTime,
      customerName: item.customerName,
      customerPhone: item.customerPhone,
      total: item.total,
      discountPercent: item.discountPercent,
      payable: item.payable,
      paid: item.paid,
      paymentMethod: item.paymentMethod,
      status: item.status,
      cashierName: item.cashierName,
      createdAt: item.createdAt,
    );
  }

  static OrderDetailDto fromDetailModel(OrderDetail detail) {
    return OrderDetailDto(
      id: detail.id,
      orderNo: detail.orderNo,
      customerPhone: detail.customerPhone,
      cashierName: detail.cashierName,
      subtotal: detail.subtotal,
      discountPercent: detail.discountPercent,
      discountAmount: detail.discountAmount,
      totalPayment: detail.totalPayment,
      items: detail.items
          .map((item) => OrderDetailItemDto(
                productName: item.productName,
                unitPrice: item.unitPrice,
                qty: item.qty,
                amount: item.amount,
              ))
          .toList(),
    );
  }
}
