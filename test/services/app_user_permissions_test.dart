import 'package:flutter_test/flutter_test.dart';
import 'package:hero_coffee_finance/models/app_user.dart';

void main() {
  test('owner has full critical permissions', () {
    const user = AppUser(
      username: 'owner',
      displayName: 'Owner',
      role: 'Owner',
    );

    expect(user.canCreateTransaction, isTrue);
    expect(user.canEditTransaction, isTrue);
    expect(user.canDeleteTransaction, isTrue);
    expect(user.canEditBudget, isTrue);
    expect(user.canExportReport, isTrue);
    expect(user.canSyncBackup, isTrue);
    expect(user.canManageCategories, isTrue);
    expect(user.canManageOutlets, isTrue);
    expect(user.canViewAuditLog, isTrue);
    expect(user.canViewFullPrediction, isTrue);
    expect(user.canLockPeriods, isTrue);
    expect(user.canAccessOutlet('any-outlet'), isTrue);
  });

  test('admin has limited permissions', () {
    const user = AppUser(
      username: 'admin',
      displayName: 'Admin',
      role: 'Admin',
    );

    expect(user.canCreateTransaction, isTrue);
    expect(user.canEditTransaction, isTrue);
    expect(user.canDeleteTransaction, isFalse);
    expect(user.canEditBudget, isFalse);
    expect(user.canExportReport, isFalse);
    expect(user.canSyncBackup, isFalse);
    expect(user.canManageCategories, isFalse);
    expect(user.canManageOutlets, isFalse);
    expect(user.canViewAuditLog, isFalse);
    expect(user.canViewFullPrediction, isFalse);
    expect(user.canLockPeriods, isFalse);
    expect(user.canAccessOutlet('main'), isTrue);
    expect(user.canAccessOutlet('other-outlet'), isFalse);
  });
}
