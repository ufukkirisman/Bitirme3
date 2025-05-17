class Admin {
  final String id;
  final String email;
  final String name;
  final List<AdminPermission> permissions;
  final DateTime createdAt;
  final DateTime? lastLogin;

  Admin({
    required this.id,
    required this.email,
    required this.name,
    required this.permissions,
    required this.createdAt,
    this.lastLogin,
  });

  factory Admin.fromMap(Map<String, dynamic> map, String id) {
    try {
      print('Admin.fromMap çağrıldı, id: $id');
      print('Map verileri: $map');

      final permissionsValue = map['permissions'];
      print(
          'Permissions verisi: $permissionsValue (${permissionsValue.runtimeType})');

      List<AdminPermission> parsedPermissions = [];

      // Permissions değeri bir string ise
      if (permissionsValue is String) {
        try {
          // Tek bir string değeri AdminPermission'a çevir
          parsedPermissions = [_stringToPermission(permissionsValue)];
          print('İzin parse edildi (string): $parsedPermissions');
        } catch (permError) {
          print('İzin parse edilirken hata (string): $permError');
          parsedPermissions = [AdminPermission.viewUsers];
        }
      }
      // Permissions değeri bir liste ise (geriye dönük uyumluluk için)
      else if (permissionsValue is List) {
        try {
          parsedPermissions = permissionsValue
              .map((permission) => _stringToPermission(permission.toString()))
              .toList();
          print('İzinler parse edildi (liste): $parsedPermissions');
        } catch (permError) {
          print('İzinler parse edilirken hata (liste): $permError');
          parsedPermissions = [AdminPermission.viewUsers];
        }
      } else {
        print('İzin değeri beklenilen formatta değil, varsayılan kullanılıyor');
        parsedPermissions = [AdminPermission.viewUsers];
      }

      // SuperAdmin ise tüm yetkileri ver
      if (parsedPermissions.contains(AdminPermission.superAdmin)) {
        parsedPermissions = AdminPermission.values.toList();
        print(
            'SuperAdmin tespit edildi, tüm yetkiler eklendi: $parsedPermissions');
      }

      DateTime createdAtDateTime;
      try {
        createdAtDateTime = map['createdAt'] != null
            ? (map['createdAt'] as dynamic).toDate()
            : DateTime.now();
      } catch (dateError) {
        print('createdAt parse edilirken hata: $dateError');
        createdAtDateTime = DateTime.now();
      }

      DateTime? lastLoginDateTime;
      try {
        lastLoginDateTime = map['lastLogin'] != null
            ? (map['lastLogin'] as dynamic).toDate()
            : null;
      } catch (dateError) {
        print('lastLogin parse edilirken hata: $dateError');
        lastLoginDateTime = null;
      }

      return Admin(
        id: id,
        email: map['email'] ?? '',
        name: map['name'] ?? '',
        permissions: parsedPermissions,
        createdAt: createdAtDateTime,
        lastLogin: lastLoginDateTime,
      );
    } catch (e) {
      print('Admin.fromMap genel hatası: $e');
      // Varsayılan admin objesi dön
      return Admin(
        id: id,
        email: map['email'] ?? '',
        name: map['name'] ?? '',
        permissions: [AdminPermission.viewUsers],
        createdAt: DateTime.now(),
        lastLogin: null,
      );
    }
  }

  Map<String, dynamic> toMap() {
    return {
      'email': email,
      'name': name,
      'permissions': permissions.map((p) => _permissionToString(p)).toList(),
      'createdAt': createdAt,
      'lastLogin': lastLogin,
    };
  }

  static AdminPermission _stringToPermission(String permissionStr) {
    switch (permissionStr) {
      case 'manageUsers':
        return AdminPermission.manageUsers;
      case 'manageModules':
        return AdminPermission.manageModules;
      case 'manageQuizzes':
        return AdminPermission.manageQuizzes;
      case 'manageSimulations':
        return AdminPermission.manageSimulations;
      case 'manageTrainings':
        return AdminPermission.manageTrainings;
      case 'manageRoadmaps':
        return AdminPermission.manageRoadmaps;
      case 'superAdmin':
        return AdminPermission.superAdmin;
      case 'viewUsers':
      default:
        return AdminPermission.viewUsers;
    }
  }

  static String _permissionToString(AdminPermission permission) {
    switch (permission) {
      case AdminPermission.manageUsers:
        return 'manageUsers';
      case AdminPermission.manageModules:
        return 'manageModules';
      case AdminPermission.manageQuizzes:
        return 'manageQuizzes';
      case AdminPermission.manageSimulations:
        return 'manageSimulations';
      case AdminPermission.manageTrainings:
        return 'manageTrainings';
      case AdminPermission.manageRoadmaps:
        return 'manageRoadmaps';
      case AdminPermission.superAdmin:
        return 'superAdmin';
      case AdminPermission.viewUsers:
      default:
        return 'viewUsers';
    }
  }

  bool hasPermission(AdminPermission permission) {
    if (permissions.contains(AdminPermission.superAdmin)) {
      return true;
    }
    return permissions.contains(permission);
  }
}

enum AdminPermission {
  viewUsers,
  manageUsers,
  manageModules,
  manageQuizzes,
  manageSimulations,
  manageTrainings,
  manageRoadmaps,
  superAdmin,
}

class UserSummary {
  final String id;
  final String email;
  final String displayName;
  final DateTime? lastLogin;
  final bool isActive;
  final Map<String, dynamic>? progress;

  UserSummary({
    required this.id,
    required this.email,
    required this.displayName,
    this.lastLogin,
    this.isActive = true,
    this.progress,
  });

  factory UserSummary.fromMap(Map<String, dynamic> map, String id) {
    return UserSummary(
      id: id,
      email: map['email'] ?? '',
      displayName: map['displayName'] ?? '',
      lastLogin: map['lastLogin'] != null
          ? (map['lastLogin'] as dynamic).toDate()
          : null,
      isActive: map['isActive'] ?? true,
      progress: map['progress'],
    );
  }
}
