class AppUser {
  const AppUser({
    required this.username,
    required this.displayName,
    required this.role,
    this.assignedOutletIds = const ['main'],
  });

  final String username;
  final String displayName;
  final String role;
  final List<String> assignedOutletIds;

  bool get isOwner => role.toLowerCase() == 'owner';
  bool get isAdmin => role.toLowerCase() == 'admin';

  bool get canCreateTransaction => isOwner || isAdmin;
  bool get canEditTransaction => isOwner || isAdmin;
  bool get canDeleteTransaction => isOwner;
  bool get canEditBudget => isOwner;
  bool get canExportReport => isOwner;
  bool get canSyncBackup => isOwner;
  bool get canManageCategories => isOwner;
  bool get canManageOutlets => isOwner;
  bool get canViewAuditLog => isOwner;
  bool get canViewFullPrediction => isOwner;
  bool get canLockPeriods => isOwner;
  bool get canViewAllOutlets => isOwner;

  bool canAccessOutlet(String outletId) {
    return canViewAllOutlets || assignedOutletIds.contains(outletId);
  }
}
