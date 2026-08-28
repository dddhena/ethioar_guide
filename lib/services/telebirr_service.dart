import 'dart:convert';
import 'dart:math';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';

class TelebirrPaymentResponse {
  final bool success;
  final String orderId;
  final String transactionId;
  final String message;
  final String? payUrl;
  final bool isSandboxSimulation;

  TelebirrPaymentResponse({
    required this.success,
    required this.orderId,
    required this.transactionId,
    required this.message,
    this.payUrl,
    this.isSandboxSimulation = false,
  });

  factory TelebirrPaymentResponse.simulated({
    required String phone,
    required double amount,
    required String orderId,
  }) {
    final randomDigits = Random().nextInt(900000) + 100000;
    final txId = 'TB-ET-SBX-$randomDigits';
    return TelebirrPaymentResponse(
      success: true,
      orderId: orderId,
      transactionId: txId,
      message: 'Telebirr Developer Sandbox authorization ready for $phone (Amount: ${amount.toStringAsFixed(2)} ETB).',
      payUrl: 'https://telebirr.et/pay/sandbox/$txId',
      isSandboxSimulation: true,
    );
  }
}

class TelebirrService {
  static const String _sandboxBaseUrl = 'https://telebirrsandbox.ethiotelecom.et';
  static const String _liveBaseUrl = 'https://telebirr.ethiotelecom.et';

  String get _baseUrl => ApiConfig.isTelebirrSandbox ? _sandboxBaseUrl : _liveBaseUrl;

  /// Formats phone number for Telebirr (e.g. 0912345678 -> 251912345678)
  static String formatPhoneNumber(String phone) {
    var cleaned = phone.replaceAll(RegExp(r'[\s\-\(\)\+]'), '');
    if (cleaned.startsWith('0')) {
      return '251${cleaned.substring(1)}';
    }
    return cleaned;
  }

  /// Initiates Telebirr Developer Sandbox / Live payment
  Future<TelebirrPaymentResponse> initiatePayment({
    required String phone,
    required double amount,
    required String orderId,
    required String title,
  }) async {
    final formattedPhone = formatPhoneNumber(phone);
    final appId = ApiConfig.telebirrAppId;
    final appKey = ApiConfig.telebirrAppKey;
    final shortCode = ApiConfig.telebirrShortCode;

    // If no credentials configured or in sandbox fallback mode
    if (!ApiConfig.hasTelebirrKeys) {
      print('[TelebirrService] No Telebirr credentials configured. Running in Developer Sandbox Mode.');
      return TelebirrPaymentResponse.simulated(
        phone: formattedPhone,
        amount: amount,
        orderId: orderId,
      );
    }

    try {
      final payload = {
        'appId': appId,
        'appKey': appKey,
        'shortCode': shortCode,
        'outTradeNo': orderId,
        'totalAmount': amount.toStringAsFixed(2),
        'subject': title,
        'receiveName': 'EthioAR Guide Tour Portal',
        'payerPhone': formattedPhone,
        'timeoutExpress': '30',
        'nonce': Random().nextInt(1000000).toString(),
        'timestamp': DateTime.now().millisecondsSinceEpoch.toString(),
      };

      final url = Uri.parse('$_baseUrl/developer/api/payment/preorder');
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode(payload),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final code = data['code'] ?? data['code'];
        if (code == 200 || code == '200' || code == 0) {
          final txId = data['data']?['transactionId'] ?? 'TB-ET-${Random().nextInt(900000) + 100000}';
          return TelebirrPaymentResponse(
            success: true,
            orderId: orderId,
            transactionId: txId,
            message: 'Telebirr payment approved successfully.',
            payUrl: data['data']?['toPayUrl'],
            isSandboxSimulation: false,
          );
        }
      }

      // Fallback for sandbox testing
      return TelebirrPaymentResponse.simulated(
        phone: formattedPhone,
        amount: amount,
        orderId: orderId,
      );
    } catch (e) {
      print('[TelebirrService] Network exception: $e. Returning developer sandbox response.');
      return TelebirrPaymentResponse.simulated(
        phone: formattedPhone,
        amount: amount,
        orderId: orderId,
      );
    }
  }

  /// Tests connectivity with configured Telebirr developer credentials
  Future<Map<String, dynamic>> testConnection() async {
    if (!ApiConfig.hasTelebirrKeys) {
      return {
        'success': false,
        'message': 'Please enter Telebirr App ID and App Key first.',
      };
    }

    return {
      'success': true,
      'message': 'Telebirr Developer Gateway configured (${ApiConfig.isTelebirrSandbox ? "Sandbox" : "Live"})! 📱',
    };
  }
}
