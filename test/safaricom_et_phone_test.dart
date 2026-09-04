import 'package:flutter_test/flutter_test.dart';
import 'package:ethioar_guide/services/daraja_service.dart';
import 'package:ethioar_guide/config/api_config.dart';

void main() {
  group('Safaricom Ethiopia Phone Normalization & Validation Tests', () {
    test('Formats local Safaricom Ethiopia 07XXXXXXXX to 2517XXXXXXXX', () {
      expect(DarajaService.formatPhoneNumber('0712345678'), equals('251712345678'));
      expect(DarajaService.formatPhoneNumber('0770000000'), equals('251770000000'));
    });

    test('Formats local Ethio Telecom 09XXXXXXXX to 2519XXXXXXXX', () {
      expect(DarajaService.formatPhoneNumber('0912345678'), equals('251912345678'));
    });

    test('Preserves already formatted +251 and 251 numbers', () {
      expect(DarajaService.formatPhoneNumber('+251712345678'), equals('251712345678'));
      expect(DarajaService.formatPhoneNumber('251712345678'), equals('251712345678'));
      expect(DarajaService.formatPhoneNumber('00251712345678'), equals('251712345678'));
    });

    test('Formats 9-digit numbers without leading zero', () {
      expect(DarajaService.formatPhoneNumber('712345678'), equals('251712345678'));
      expect(DarajaService.formatPhoneNumber('912345678'), equals('251912345678'));
    });

    test('Validates Ethiopian mobile numbers correctly', () {
      expect(DarajaService.isValidEthiopianPhone('0712345678'), isTrue);
      expect(DarajaService.isValidEthiopianPhone('+251712345678'), isTrue);
      expect(DarajaService.isValidEthiopianPhone('0912345678'), isTrue);
      expect(DarajaService.isValidEthiopianPhone('254708374149'), isFalse); // Kenya number rejected
      expect(DarajaService.isValidEthiopianPhone('12345'), isFalse);
    });

    test('Validates Safaricom Ethiopia specific numbers correctly', () {
      expect(DarajaService.isSafaricomEthiopiaPhone('0712345678'), isTrue);
      expect(DarajaService.isSafaricomEthiopiaPhone('0912345678'), isFalse); // Ethio telecom, not Safaricom
    });
  });

  group('Safaricom Ethiopia Config & Endpoints Tests', () {
    test('Portal URL points to developer.safaricom.et/apps', () {
      expect(ApiConfig.safaricomPortalUrl, equals('https://developer.safaricom.et/apps'));
      expect(DarajaService.developerPortalUrl, equals('https://developer.safaricom.et/apps'));
    });

    test('Sandbox URL points to apisandbox.safaricom.et', () {
      ApiConfig.setDarajaConfig(isSandbox: true);
      expect(ApiConfig.safaricomBaseUrl, equals('https://apisandbox.safaricom.et'));
    });

    test('Live URL points to api.safaricom.et', () {
      ApiConfig.setDarajaConfig(isSandbox: false);
      expect(ApiConfig.safaricomBaseUrl, equals('https://api.safaricom.et'));
    });
  });
}
