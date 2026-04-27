class UserModel {
  final String id;
  final String name;
  final String nim;
  final String email;
  final String passwordHash;
  final String role;
  final String departmentId;
  final bool isActive;
  final bool isSuspended;
  final int streakCount;
  final DateTime createdAt;

  UserModel({
    required this.id,
    required this.name,
    required this.nim,
    required this.email,
    required this.passwordHash,
    required this.role,
    required this.departmentId,
    required this.isActive,
    required this.isSuspended,
    required this.streakCount,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() => {
    '_id': id,
    'name': name,
    'nim': nim,
    'email': email,
    'passwordHash': passwordHash,
    'role': role,
    'departmentId': departmentId,
    'isActive': isActive,
    'isSuspended': isSuspended,
    'streakCount': streakCount,
    'createdAt': createdAt.toIso8601String(),
  };

  factory UserModel.fromMap(Map<String, dynamic> map) => UserModel(
    id: map['_id'].toString(),
    name: map['name'],
    nim: map['nim'],
    email: map['email'],
    passwordHash: map['passwordHash'],
    role: map['role'],
    departmentId: map['departmentId'],
    isActive: map['isActive'],
    isSuspended: map['isSuspended'],
    streakCount: map['streakCount'],
    createdAt: DateTime.parse(map['createdAt']),
  );
}