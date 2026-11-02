import 'package:flutter_test/flutter_test.dart';
import 'package:vowora/models/birthday/birthday_payment_model.dart';

void main() {
  group('BirthdayPaymentPlan', () {
    test('calculates a 30 percent deposit and balance from total', () {
      final plan = BirthdayPaymentPlan.calculate(
        totalAmount: 20000,
        depositPercentage: 30,
        eventDate: DateTime(2026, 12, 20),
        today: DateTime(2026, 11, 1),
      );

      expect(plan.depositAmount, 6000);
      expect(plan.remainingBalance, 14000);
      expect(plan.balanceDueAt, DateTime(2026, 12, 13));
    });

    test('uses the event date when the normal balance deadline has passed', () {
      final plan = BirthdayPaymentPlan.calculate(
        totalAmount: 1250,
        depositPercentage: 100,
        eventDate: DateTime(2026, 11, 5),
        today: DateTime(2026, 11, 2),
      );

      expect(plan.depositAmount, 1250);
      expect(plan.remainingBalance, 0);
      expect(plan.balanceDueAt, DateTime(2026, 11, 5));
    });

    test('rejects deposit percentages outside zero to one hundred', () {
      expect(
        () => BirthdayPaymentPlan.calculate(
          totalAmount: 1000,
          depositPercentage: 101,
          eventDate: DateTime(2026, 12, 20),
          today: DateTime(2026, 11, 1),
        ),
        throwsArgumentError,
      );
    });
  });

  test('persists each requested payment method distinctly', () {
    expect(BirthdayPaymentMethod.bkash.dbValue, 'bkash');
    expect(BirthdayPaymentMethod.nagad.dbValue, 'nagad');
    expect(BirthdayPaymentMethod.visa.dbValue, 'visa');
    expect(BirthdayPaymentMethod.mastercard.dbValue, 'mastercard');
    expect(BirthdayPaymentMethod.bankTransfer.dbValue, 'bank_transfer');
    expect(BirthdayPaymentMethod.fromString('card'), BirthdayPaymentMethod.visa);
  });
}