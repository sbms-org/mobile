import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pm/core/enums/user_role.dart';
import 'package:pm/features/servicebook/domain/models/servicebook_models.dart';
import 'package:pm/features/auth/presentation/pages/role_selection_page.dart';

void main() {
  group('UserRole.fromApiValue', () {
    test('recognizes all supported SBMS roles and common API aliases', () {
      expect(UserRole.fromApiValue('client'), UserRole.client);
      expect(
        UserRole.fromApiValue('individual_provider'),
        UserRole.individualProvider,
      );
      expect(UserRole.fromApiValue('company_staff'), UserRole.companyStaff);
      expect(UserRole.fromApiValue('broker'), UserRole.broker);
      expect(UserRole.fromApiValue('support_agent'), UserRole.supportAgent);
      expect(UserRole.fromApiValue('admin'), UserRole.administrator);
      expect(UserRole.fromApiValue('tenant'), isNull);
    });
  });

  test('provider model reads service and availability details', () {
    final provider = ServiceProvider.fromJson({
      'id': 42,
      'full_name': 'Aster',
      'services': [
        {'id': 'svc-1', 'name': 'Electrical repair'},
      ],
      'availability': {
        'days': ['Monday'],
      },
    });

    expect(provider.id, '42');
    expect(provider.name, 'Aster');
    expect(provider.services.single['name'], 'Electrical repair');
    expect(provider.availability, isA<Map>());
  });

  test('booking model preserves meeting mode and status', () {
    final booking = ServiceBooking.fromJson({
      'id': 'booking-1',
      'status': 'pending',
      'meeting_mode': 'remote',
      'scheduled_at': '2026-11-26T10:00:00Z',
      'service': {'name': 'Translation'},
    });

    expect(booking.id, 'booking-1');
    expect(booking.status, 'pending');
    expect(booking.meetingMode, 'remote');
    expect(booking.serviceName, 'Translation');
    expect(booking.scheduledAt, DateTime.utc(2026, 11, 26, 10));
  });

  testWidgets('role selection exposes only supported ServiceBook roles', (
    tester,
  ) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(home: RoleSelectionPage()),
      ),
    );

    expect(find.text('Client'), findsOneWidget);
    expect(find.text('Individual provider'), findsOneWidget);
    expect(find.text('Company staff'), findsOneWidget);
    expect(find.text('Broker'), findsOneWidget);
    expect(find.text('Support agent'), findsOneWidget);
    expect(find.text('Administrator'), findsOneWidget);
    expect(find.text('Property Owner'), findsNothing);
    expect(find.text('Tenant'), findsNothing);
  });
}
