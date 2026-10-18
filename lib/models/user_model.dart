class UserModel {
  final int? id;
  final String? backendId;
  final String name;
  final String email;
  final String role; // 'user' or 'admin'
  final String plan; // 'free' or 'paid'
  final String status; // 'active' or 'inactive'
  final String? phone;
  final String? country;
  final String? avatarUrl;
  final bool emailVerified;
  final String currency;
  final bool darkMode;

  UserModel({
    this.id,
    this.backendId,
    required this.name,
    this.email = '',
    required this.role,
    required this.plan,
    required this.status,
    this.phone,
    this.country,
    this.avatarUrl,
    this.emailVerified = false,
    this.currency = 'USD',
    this.darkMode = false,
  });

  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      id: map['id'] is int ? map['id'] as int : int.tryParse(map['id']?.toString() ?? ''),
      backendId: map['backendId']?.toString() ?? (map['id'] is String ? map['id'] as String : null),
      name: (map['name'] ?? map['displayName'] ?? '').toString(),
      email: (map['email'] ?? '').toString(),
      role: (map['role'] ?? 'user').toString(),
      plan: (map['plan'] ?? 'free').toString(),
      status: (map['status'] ?? 'active').toString(),
      phone: map['phone']?.toString(),
      country: map['country']?.toString(),
      avatarUrl: map['avatarUrl']?.toString(),
      emailVerified: map['emailVerified'] == true,
      currency: (map['preferences'] is Map ? map['preferences']['currency'] : map['currency'])?.toString() ?? 'USD',
      darkMode: map['darkMode'] == true,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'name': name,
      'role': role,
      'plan': plan,
      'status': status,
    };
  }

  UserModel copyWith({
    int? id,
    String? backendId,
    String? name,
    String? email,
    String? role,
    String? plan,
    String? status,
    String? phone,
    String? country,
    String? avatarUrl,
    bool? emailVerified,
    String? currency,
    bool? darkMode,
  }) {
    return UserModel(
      id: id ?? this.id,
      backendId: backendId ?? this.backendId,
      name: name ?? this.name,
      email: email ?? this.email,
      role: role ?? this.role,
      plan: plan ?? this.plan,
      status: status ?? this.status,
      phone: phone ?? this.phone,
      country: country ?? this.country,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      emailVerified: emailVerified ?? this.emailVerified,
      currency: currency ?? this.currency,
      darkMode: darkMode ?? this.darkMode,
    );
  }

  bool get isAdmin => role == 'admin';
  bool get isPaid => plan == 'paid';
  bool get isActive => status == 'active';
}
