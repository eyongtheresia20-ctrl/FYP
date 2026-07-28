class UserModel {
  final int id;
  final String fullName;
  final String role;
  final int? schoolId;
  final String? region;
  final String? division;
  final String token;

  const UserModel({
    required this.id,
    required this.fullName,
    required this.role,
    this.schoolId,
    this.region,
    this.division,
    required this.token,
  });

  factory UserModel.fromJson(Map<String, dynamic> json, String token) {
    return UserModel(
      id:       json['user_id'] as int,
      fullName: json['full_name'] as String,
      role:     json['role'] as String,
      schoolId: json['school_id'] as int?,
      region:   json['region'] as String?,
      division: json['division'] as String?,
      token:    token,
    );
  }

  Map<String, dynamic> toJson() => {
    'user_id':   id,
    'full_name': fullName,
    'role':      role,
    'school_id': schoolId,
    'region':    region,
    'division':  division,
    'token':     token,
  };

  bool get isStudent            => role == 'student';
  bool get isTeacher            => role == 'teacher';
  bool get isPrincipal          => role == 'principal';
  bool get isDivisionalDelegate => role == 'divisional_delegate';
  bool get isRegionalDelegate   => role == 'regional_delegate';
  bool get isAdmin              => role == 'admin';
}
