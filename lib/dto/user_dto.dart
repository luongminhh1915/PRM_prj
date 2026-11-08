class UserDto {
  const UserDto({
    required this.id,
    required this.fullname,
    required this.username,
    required this.email,
    required this.role,
    required this.status,
    required this.idCard,
  });

  final int id;
  final String fullname;
  final String username;
  final String email;
  final String role;
  final String status;
  final String idCard;

  factory UserDto.fromJson(Map<String, dynamic> json) {
    return UserDto(
      id: (json['id'] as num?)?.toInt() ?? 0,
      fullname: json['fullname'] as String? ?? '—',
      username: json['username'] as String? ?? '—',
      email: json['email'] as String? ?? '—',
      role: json['role'] as String? ?? json['role_name'] as String? ?? '—',
      status: json['status'] as String? ?? 'active',
      idCard: json['id_card'] as String? ?? json['idCard'] as String? ?? '—',
    );
  }
}

class UserScheduleDto {
  const UserScheduleDto({
    required this.day,
    required this.loginTime,
    required this.logoutTime,
    required this.shiftRevenue,
  });

  final String day;
  final String loginTime;
  final String logoutTime;
  final String shiftRevenue;

  factory UserScheduleDto.fromJson(Map<String, dynamic> json) {
    return UserScheduleDto(
      day: json['day'] as String? ?? 'Shift',
      loginTime: json['loginTime'] as String? ?? '—',
      logoutTime: json['logoutTime'] as String? ?? '—',
      shiftRevenue: json['shiftRevenue'] as String? ?? '—',
    );
  }
}

class UserDetailDto {
  const UserDetailDto({
    required this.id,
    required this.fullname,
    required this.username,
    required this.email,
    required this.role,
    required this.idCard,
    required this.phone,
    required this.address,
    required this.status,
    required this.avatar,
    required this.lastLogin,
    required this.dob,
    required this.schedule,
  });

  final int id;
  final String fullname;
  final String username;
  final String email;
  final String role;
  final String idCard;
  final String phone;
  final String address;
  final String status;
  final String avatar;
  final String lastLogin;
  final String dob;
  final List<UserScheduleDto> schedule;

  factory UserDetailDto.fromJson(Map<String, dynamic> json) {
    final rawSchedule = json['schedule'];
    return UserDetailDto(
      id: (json['id'] as num?)?.toInt() ?? 0,
      fullname: json['fullname'] as String? ?? '—',
      username: json['username'] as String? ?? '—',
      email: json['email'] as String? ?? '—',
      role: json['role'] as String? ?? json['role_name'] as String? ?? '—',
      idCard: json['id_card'] as String? ?? json['idCard'] as String? ?? '—',
      phone: json['phone'] as String? ?? '',
      address: json['address'] as String? ?? '',
      status: json['status'] as String? ?? 'active',
      avatar: json['avatar'] as String? ?? '',
      lastLogin: json['last_login'] as String? ?? json['lastLogin'] as String? ?? '—',
      dob: json['dob'] as String? ?? '',
      schedule: rawSchedule is List
          ? rawSchedule
              .whereType<Map<String, dynamic>>()
              .map(UserScheduleDto.fromJson)
              .toList()
          : const [],
    );
  }
}
