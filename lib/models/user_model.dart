class UserModel {
  String name;
  String phone;
  String note;
  bool isPrimary;
  bool isBlocked;

  UserModel({
    required this.name,
    required this.phone,
    this.note = '',
    this.isPrimary = false,
    this.isBlocked = false,
  });
}
