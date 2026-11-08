import 'package:supermarket_manager_system/dto/user_dto.dart';

class UserMapper {
  static UserDto fromRow(Map<String, dynamic> row) => UserDto.fromJson(row);

  static UserDetailDto fromDetailRow(
    Map<String, dynamic> row,
    List<Map<String, dynamic>> schedules,
  ) {
    return UserDetailDto.fromJson({
      ...row,
      'schedule': schedules,
    });
  }
}
