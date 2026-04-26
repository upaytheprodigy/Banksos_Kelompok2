class DepartmentModel {
  final String id;
  final String name;
  final String code;
  final bool isActive;

  DepartmentModel({
    required this.id,
    required this.name,
    required this.code,
    required this.isActive,
  });

  Map<String, dynamic> toMap() => {
    '_id': id,
    'name': name,
    'code': code,
    'isActive': isActive,
  };

  factory DepartmentModel.fromMap(Map<String, dynamic> map) => DepartmentModel(
    id: map['_id'].toString(),
    name: map['name'],
    code: map['code'],
    isActive: map['isActive'],
  );
}