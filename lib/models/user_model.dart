class UserModel {
  final int? id;
  final String name;
  final String phone;
  final String email;
  final String password;
  final String role; // "User" or "Guardian"
  final bool isLoggedIn;

  UserModel({
    this.id,
    required this.name,
    required this.phone,
    required this.email,
    required this.password,
    this.role = 'User',
    this.isLoggedIn = false,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'phone': phone,
      'email': email,
      'password': password,
      'role': role,
      'isLoggedIn': isLoggedIn ? 1 : 0,
    };
  }

  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      id: map['id'],
      name: map['name'],
      phone: map['phone'],
      email: map['email'],
      password: map['password'],
      role: map['role'],
      isLoggedIn: map['isLoggedIn'] == 1,
    );
  }
}
