import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';

class MpesaService {
  // ⭐️ YOUR NEW AGRIPAY SANDBOX CREDENTIALS
  final String _consumerKey = 'VLFAACHKbT3qna4kFEj9il2IsAz89uXOvJPf8Rqfp2hAN5xG'.trim();
  final String _consumerSecret = 'NlCwNFAfcejf0Eyc8X5VJjVr7gt5jSG5NQoiN1i7HBHgGs3tm0WyiR10ovrwGd5n'.trim();

  // ⚙️ STANDARD SAFARICOM SANDBOX CONFIGURATION (Fixed for all test apps)
  final String _baseUrl = 'https://sandbox.safaricom.co.ke';
  final String _shortCode = '174379'; // Default Test Paybill
  final String _passKey = 'bfb279f9aa9bdbcf158e97dd71a467cd2e0c893059b10f78e6b72ada1ed2c919'; 

  /// 1. Authenticate and get the Access Token
  Future<String?> getAccessToken() async {
    String cleanCreds = '$_consumerKey:$_consumerSecret';
    String encoded = base64Encode(utf8.encode(cleanCreds));
    
    try {
      print("Attempting M-Pesa Auth...");
      
      final response = await http.get(
        Uri.parse('$_baseUrl/oauth/v1/generate?grant_type=client_credentials'),
        headers: {
          'Authorization': 'Basic $encoded',
        },
      );

      print('M-Pesa Auth Status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        // print("Token received: ${data['access_token']}"); // Uncomment for debugging
        return data['access_token'];
      } else {
        print('Auth Failed: ${response.body}');
        return null;
      }
    } catch (e) {
      print("Error getting token: $e");
      return null;
    }
  }

  /// 2. Trigger STK Push (The popup on the phone)
  Future<bool> startSTKPush(String phoneNumber, double amount) async {
    String? token = await getAccessToken();
    
    if (token == null) {
      print("Cannot start STK Push: Token is null");
      return false;
    }

    // Generate Timestamp and Password required by Daraja API
    String timestamp = DateFormat('yyyyMMddHHmmss').format(DateTime.now());
    String password = base64Encode(utf8.encode('$_shortCode$_passKey$timestamp'));
    
    // Format phone number to start with 254 (Safaricom requirement)
    String formattedPhone = phoneNumber.trim();
    if (formattedPhone.startsWith('0')) {
      formattedPhone = '254${formattedPhone.substring(1)}';
    } else if (formattedPhone.startsWith('+254')) {
      formattedPhone = formattedPhone.substring(1);
    }

    // Round amount to nearest whole number (Sandbox often rejects decimals)
    int payAmount = amount.ceil(); 

    final headers = {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };

    final body = {
      "BusinessShortCode": _shortCode,
      "Password": password,
      "Timestamp": timestamp,
      "TransactionType": "CustomerPayBillOnline",
      "Amount": payAmount,
      "PartyA": formattedPhone,
      "PartyB": _shortCode,
      "PhoneNumber": formattedPhone,
      "CallBackURL": "https://mydomain.com/path", // Sandbox just needs a valid URL format
      "AccountReference": "AgriConnect",
      "TransactionDesc": "Farm Produce Payment"
    };

    try {
      print("Sending STK Push to $formattedPhone for KES $payAmount...");
      
      final response = await http.post(
        Uri.parse('$_baseUrl/mpesa/stkpush/v1/processrequest'),
        headers: headers,
        body: jsonEncode(body),
      );
      
      final responseData = jsonDecode(response.body);
      print("M-Pesa Response: $responseData");

      // 'ResponseCode' 0 means Safaricom accepted the request
      return responseData['ResponseCode'] == '0';
    } catch (e) {
      print("Error STK Push: $e");
      return false;
    }
  }
}