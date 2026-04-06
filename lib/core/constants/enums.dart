enum UserRole {
  student,
  warden;

  String get label {
    switch (this) {
      case UserRole.student:
        return 'Student';
      case UserRole.warden:
        return 'Warden';
    }
  }

  factory UserRole.fromString(String value) {
    return UserRole.values.firstWhere(
      (e) => e.name == value,
      orElse: () => throw ArgumentError('Invalid UserRole: $value'),
    );
  }
}

enum LeaveType {
  home,
  medical,
  personal,
  other;

  String get label {
    switch (this) {
      case LeaveType.home:
        return 'Home';
      case LeaveType.medical:
        return 'Medical';
      case LeaveType.personal:
        return 'Personal';
      case LeaveType.other:
        return 'Other';
    }
  }

  factory LeaveType.fromString(String value) {
    return LeaveType.values.firstWhere(
      (e) => e.name == value,
      orElse: () => throw ArgumentError('Invalid LeaveType: $value'),
    );
  }
}

enum LeaveStatus {
  pending,
  approved,
  rejected;

  String get label {
    switch (this) {
      case LeaveStatus.pending:
        return 'Pending';
      case LeaveStatus.approved:
        return 'Approved';
      case LeaveStatus.rejected:
        return 'Rejected';
    }
  }

  factory LeaveStatus.fromString(String value) {
    return LeaveStatus.values.firstWhere(
      (e) => e.name == value,
      orElse: () => throw ArgumentError('Invalid LeaveStatus: $value'),
    );
  }
}

enum GatePassStatus {
  pending,
  active,
  usedOut,
  usedIn,
  expired;

  String get label {
    switch (this) {
      case GatePassStatus.pending:
        return 'Pending';
      case GatePassStatus.active:
        return 'Active';
      case GatePassStatus.usedOut:
        return 'Used Out';
      case GatePassStatus.usedIn:
        return 'Used In';
      case GatePassStatus.expired:
        return 'Expired';
    }
  }

  factory GatePassStatus.fromString(String value) {
    return GatePassStatus.values.firstWhere(
      (e) => e.name == value,
      orElse: () => throw ArgumentError('Invalid GatePassStatus: $value'),
    );
  }
}
