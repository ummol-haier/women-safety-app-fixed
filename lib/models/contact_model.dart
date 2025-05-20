class ContactModel {
  final int? id;
  final String name;
  final String phone;
  final String note;
  final bool isPriority;
  final bool isBlocked;

  ContactModel({
    this.id,
    required this.name,
    required this.phone,
    this.note = '',
    this.isPriority = false,
    this.isBlocked = false,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'phone': phone,
      'note': note,
      'isPriority': isPriority ? 1 : 0,
      'isBlocked': isBlocked ? 1 : 0,
    };
  }

  factory ContactModel.fromMap(Map<String, dynamic> map) {
    return ContactModel(
      id: map['id'],
      name: map['name'],
      phone: map['phone'],
      note: map['note'] ?? '',
      isPriority: map['isPriority'] == 1,
      isBlocked: map['isBlocked'] == 1,
    );
  }
}
