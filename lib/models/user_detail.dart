class UserScheduleItem {
  const UserScheduleItem({
    required this.day,
    required this.loginTime,
    required this.logoutTime,
    required this.shiftRevenue,
  });

  final String day;
  final String loginTime;
  final String logoutTime;
  final String shiftRevenue;

  factory UserScheduleItem.fromJson(Map<String, dynamic> json) {
    return UserScheduleItem(
      day: json['day'] as String? ?? '—',
      loginTime: json['loginTime'] as String? ?? '—',
      logoutTime: json['logoutTime'] as String? ?? '—',
      shiftRevenue: json['shiftRevenue'] as String? ?? '—',
    );
  }
}

class UserDetail {
  const UserDetail({
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
  final List<UserScheduleItem> schedule;

  factory UserDetail.fromJson(Map<String, dynamic> json) {
    final rawSchedule = json['schedule'];
    return UserDetail(
      id: json['id'] as int? ?? 0,
      fullname: json['fullname'] as String? ?? '—',
      username: json['username'] as String? ?? '—',
      email: json['email'] as String? ?? '—',
      role: json['role'] as String? ?? '—',
      idCard: json['idCard'] as String? ?? '—',
      phone: json['phone'] as String? ?? '',
      address: json['address'] as String? ?? '',
      status: json['status'] as String? ?? '—',
      avatar: json['avatar'] as String? ?? '',
      lastLogin: json['lastLogin'] as String? ?? '—',
      dob: json['dob'] as String? ?? '',
      schedule: rawSchedule is List
          ? rawSchedule
              .whereType<Map<String, dynamic>>()
              .map(UserScheduleItem.fromJson)
              .toList()
          : const [],
    );
  }
}
