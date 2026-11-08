class ExpirationStats {
  const ExpirationStats({
    required this.expiresToday,
    required this.expiresIn7Days,
    required this.expiresIn3Months,
    required this.expiresIn6Months,
  });

  final int expiresToday;
  final int expiresIn7Days;
  final int expiresIn3Months;
  final int expiresIn6Months;

  factory ExpirationStats.fromJson(Map<String, dynamic> json) {
    return ExpirationStats(
      expiresToday: (json['expiresToday'] as num?)?.toInt() ?? 0,
      expiresIn7Days: (json['expiresIn7Days'] as num?)?.toInt() ?? 0,
      expiresIn3Months: (json['expiresIn3Months'] as num?)?.toInt() ?? 0,
      expiresIn6Months: (json['expiresIn6Months'] as num?)?.toInt() ?? 0,
    );
  }
}
