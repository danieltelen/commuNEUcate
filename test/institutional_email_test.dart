import 'package:communeucate/utils/institutional_email.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('isInstitutionalEmail', () {
    test('accepts the NEU domain case-insensitively with surrounding spaces', () {
      expect(isInstitutionalEmail('  Student@NEU.EDU.PH  '), isTrue);
    });

    test('rejects public and lookalike domains', () {
      expect(isInstitutionalEmail('student@gmail.com'), isFalse);
      expect(isInstitutionalEmail('student@neu.edu.ph.attacker.com'), isFalse);
      expect(isInstitutionalEmail('student@notneu.edu.ph'), isFalse);
    });

    test('rejects malformed addresses', () {
      expect(isInstitutionalEmail('neu.edu.ph'), isFalse);
      expect(isInstitutionalEmail('@neu.edu.ph'), isFalse);
      expect(isInstitutionalEmail('student@'), isFalse);
    });
  });
}
