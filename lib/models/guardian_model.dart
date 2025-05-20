class GuardianModel {
  final int? id;
  final String name;
  final String phone;
  final String email;
  final String password;
  final String note;
  final bool isBlocked;
  final bool isPrimary;

  GuardianModel({
    this.id,
    required this.name,
    required this.phone,
    required this.email,
    required this.password,
    this.note = '',
    this.isBlocked = false,
    this.isPrimary = false,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'phone': phone,
      'email': email,
      'password': password,
      'note': note,
      'isBlocked': isBlocked ? 1 : 0,
      'isPrimary': isPrimary ? 1 : 0,
    };
  }

  factory GuardianModel.fromMap(Map<String, dynamic> map) {
    return GuardianModel(
      id: map['id'],
      name: map['name'],
      phone: map['phone'],
      email: map['email'],
      password: map['password'],
      note: map['note'] ?? '',
      isBlocked: map['isBlocked'] == 1,
      isPrimary: map['isPrimary'] == 1,
    );
  }
}
