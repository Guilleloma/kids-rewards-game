class UserModel {
  final String id;
  final String name;
  final String email;
  final String childName;
  final String? profileImage;
  final DateTime createdAt;

  UserModel({
    required this.id,
    required this.name,
    required this.email,
    required this.childName,
    this.profileImage,
    required this.createdAt,
  });

  // Convertir de Firestore a UserModel
  factory UserModel.fromJson(Map<String, dynamic> json, String id) {
    return UserModel(
      id: id,
      name: json['name'] ?? '',
      email: json['email'] ?? '',
      childName: json['childName'] ?? '',
      profileImage: json['profileImage'],
      createdAt: (json['createdAt'] as dynamic)?.toDate() ?? DateTime.now(),
    );
  }

  // Convertir a formato Firestore
  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'email': email,
      'childName': childName,
      'profileImage': profileImage,
      'createdAt': createdAt,
    };
  }

  // Crear una copia del objeto con algunos campos modificados
  UserModel copyWith({
    String? name,
    String? email,
    String? childName,
    String? profileImage,
  }) {
    return UserModel(
      id: id,
      name: name ?? this.name,
      email: email ?? this.email,
      childName: childName ?? this.childName,
      profileImage: profileImage ?? this.profileImage,
      createdAt: createdAt,
    );
  }
}
