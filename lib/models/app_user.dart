class AppUser {
  const AppUser({required this.id, required this.name, required this.email});

  factory AppUser.fromJson(Map<String, dynamic> json) => AppUser(
    id: json['id'].toString(),
    name: json['name'] as String,
    email: json['email'] as String,
  );

  final String id;
  final String name;
  final String email;

  Map<String, dynamic> toJson() => {'id': id, 'name': name, 'email': email};
}
