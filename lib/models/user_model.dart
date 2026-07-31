class UserModel {
  final int id;
  final String fullName;
  final String role;
  final int? schoolId;
  final String? region;
  final String? division;
  final String? matNumber;
  final String token;

  const UserModel({
    required this.id,
    required this.fullName,
    required this.role,
    this.schoolId,
    this.region,
    this.division,
    this.matNumber,
    required this.token,
  });

  factory UserModel.fromJson(Map<String, dynamic> json, String token) {
    int parseId(dynamic val) {
      if (val is int) return val;
      if (val is String) return int.tryParse(val) ?? 0;
      return 0;
    }

    int? parseNullableId(dynamic val) {
      if (val == null) return null;
      if (val is int) return val;
      if (val is String) return int.tryParse(val);
      return null;
    }

    return UserModel(
      id:        parseId(json['user_id'] ?? json['id']),
      fullName:  (json['full_name'] ?? json['name'] ?? '').toString(),
      role:      (json['role'] ?? 'student').toString(),
      schoolId:  parseNullableId(json['school_id']),
      region:    json['region']?.toString(),
      division:  json['division']?.toString(),
      matNumber: json['mat_number']?.toString() ?? json['matricule']?.toString(),
      token:     token,
    );
  }

  Map<String, dynamic> toJson() => {
    'user_id':    id,
    'full_name':  fullName,
    'role':       role,
    'school_id':  schoolId,
    'region':     region,
    'division':   division,
    'mat_number': matNumber,
    'token':      token,
  };

  UserModel copyWith({
    int? id,
    String? fullName,
    String? role,
    int? schoolId,
    String? region,
    String? division,
    String? matNumber,
    String? token,
  }) {
    return UserModel(
      id: id ?? this.id,
      fullName: fullName ?? this.fullName,
      role: role ?? this.role,
      schoolId: schoolId ?? this.schoolId,
      region: region ?? this.region,
      division: division ?? this.division,
      matNumber: matNumber ?? this.matNumber,
      token: token ?? this.token,
    );
  }

  bool get isStudent            => role == 'student';
  bool get isTeacher            => role == 'teacher';
  bool get isPrincipal          => role == 'principal';
  bool get isDivisionalDelegate => role == 'divisional_delegate';
  bool get isRegionalDelegate   => role == 'regional_delegate';
  bool get isAdmin              => role == 'admin';
}
