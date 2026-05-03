import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: 'https://rsytanuvcrvxnqqgcywm.supabase.co',
    anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InJzeXRhbnV2Y3J2eG5xcWdjeXdtIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzcyNTU2MDEsImV4cCI6MjA5MjgzMTYwMX0.2tWKZ6iTYsebHsnFFx0s-2m-fWmlVfqCcmVi8SiIO94',
  );

  runApp(const BioniqApp());
}

class BioniqApp extends StatelessWidget {
  const BioniqApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Bioniq',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF06101D),
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF2563EB),
          brightness: Brightness.dark,
        ),
      ),
      home: const LoginScreen(),
    );
  }
}

class AppColors {
  static const Color background = Color(0xFF06101D);
  static const Color card = Color(0xFF10233A);
  static const Color primary = Color(0xFF2563EB);
  static const Color green = Color(0xFF10B981);
  static const Color amber = Color(0xFFF59E0B);
  static const Color red = Color(0xFFEF4444);
  static const Color textMuted = Color(0xFF9DB0C4);
  static const Color border = Color(0xFF1C3652);
}

class ApiService {
  static const String baseUrl = 'http://10.151.90.13:5000';

  static Future<Map<String, dynamic>> login({
    required String uniqueId,
    required String password,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/api/auth/login'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'uniqueId': uniqueId,
        'password': password,
      }),
    );

    return jsonDecode(response.body) as Map<String, dynamic>;
  }

  static Future<Map<String, dynamic>> getDashboard(String customerId) async {
    final response = await http.get(
      Uri.parse('$baseUrl/api/dashboard/$customerId'),
    );

    return jsonDecode(response.body) as Map<String, dynamic>;
  }

  static Future<Map<String, dynamic>> markPaid(String customerId) async {
    final response = await http.post(
      Uri.parse('$baseUrl/api/billing/mark-paid'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'customerId': customerId,
      }),
    );

    return jsonDecode(response.body);
  }

  static Future<Map<String, dynamic>> markUnpaid({
    required String customerId,
    required num amount,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/api/billing/mark-unpaid'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'customerId': customerId,
        'amount': amount,
      }),
    );

    return jsonDecode(response.body) as Map<String, dynamic>;
  }

  static Future<Map<String, dynamic>> getDevices(String customerId) async {
    final response = await http.get(Uri.parse('$baseUrl/api/devices/$customerId'));
    return jsonDecode(response.body) as Map<String, dynamic>;
  }

  static Future<Map<String, dynamic>> disconnectDevice({
    required String customerId,
    required String deviceId,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/api/devices/disconnect'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'customerId': customerId, 'deviceId': deviceId}),
    );
    return jsonDecode(response.body) as Map<String, dynamic>;
  }

  static Future<Map<String, dynamic>> blockDevice({
    required String customerId,
    required String deviceId,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/api/devices/block'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'customerId': customerId, 'deviceId': deviceId}),
    );
    return jsonDecode(response.body) as Map<String, dynamic>;
  }

  static Future<Map<String, dynamic>> unblockDevice({
    required String customerId,
    required String deviceId,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/api/devices/unblock'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'customerId': customerId, 'deviceId': deviceId}),
    );
    return jsonDecode(response.body) as Map<String, dynamic>;
  }


  static Future<Map<String, dynamic>> blockService(String customerId) async {
    final response = await http.post(
      Uri.parse('$baseUrl/api/admin/block'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'customerId': customerId}),
    );

    return jsonDecode(response.body) as Map<String, dynamic>;
  }

  static Future<Map<String, dynamic>> unblockService(String customerId) async {
    final response = await http.post(
      Uri.parse('$baseUrl/api/admin/unblock'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'customerId': customerId}),
    );

    return jsonDecode(response.body) as Map<String, dynamic>;
  }

  static Future<Map<String, dynamic>> getAdminOverview() async {
    final response = await http.get(
      Uri.parse('$baseUrl/api/admin/overview'),
    );

    return jsonDecode(response.body) as Map<String, dynamic>;
  }

  static Future<Map<String, dynamic>> getAdminCustomers() async {
    final response = await http.get(
      Uri.parse('$baseUrl/api/admin/customers'),
    );

    return jsonDecode(response.body) as Map<String, dynamic>;
  }

}


class SupportService {
  static SupabaseClient get _client => Supabase.instance.client;

  static bool _isActiveStatus(String status) {
    return status == 'escalated' || status == 'human';
  }

  static Stream<List<Map<String, dynamic>>> supportChatsStream() {
    return _client
        .from('support_chats')
        .stream(primaryKey: ['id'])
        .order('updated_at')
        .map((rows) {
      final list = rows
          .where((row) => _isActiveStatus(row['status']?.toString() ?? ''))
          .map((row) => Map<String, dynamic>.from(row))
          .toList();

      list.sort((a, b) {
        final aTime = (a['updated_at'] ?? a['created_at'] ?? '').toString();
        final bTime = (b['updated_at'] ?? b['created_at'] ?? '').toString();
        return bTime.compareTo(aTime);
      });

      return list;
    });
  }

  static Stream<List<Map<String, dynamic>>> messagesStream(String chatId) {
    return _client
        .from('support_messages')
        .stream(primaryKey: ['id'])
        .eq('chat_id', chatId)
        .order('created_at', ascending: true)
        .map((rows) {
      final cleanRows = <Map<String, dynamic>>[];
      final seenIds = <String>{};

      for (final row in rows) {
        final item = Map<String, dynamic>.from(row);
        final id = item['id']?.toString() ?? '';
        final role = item['sender_role']?.toString() ?? '';
        final message = item['message']?.toString().trim() ?? '';
        final imageUrl = item['image_url']?.toString() ?? '';

        if (role == 'system') continue;
        if (message.isEmpty && imageUrl.isEmpty) continue;
        if (id.isNotEmpty && seenIds.contains(id)) continue;
        if (id.isNotEmpty) seenIds.add(id);
        cleanRows.add(item);
      }

      cleanRows.sort((a, b) {
        final aTime = a['created_at']?.toString() ?? '';
        final bTime = b['created_at']?.toString() ?? '';
        return aTime.compareTo(bTime);
      });

      return cleanRows;
    });
  }


  static List<Map<String, dynamic>> _cleanMessageRows(List<dynamic> rows) {
    final cleanRows = <Map<String, dynamic>>[];
    final seenIds = <String>{};

    for (final row in rows) {
      final item = Map<String, dynamic>.from(row as Map);
      final id = item['id']?.toString() ?? '';
      final role = item['sender_role']?.toString() ?? '';
      final message = item['message']?.toString().trim() ?? '';
      final imageUrl = item['image_url']?.toString() ?? '';

      if (role == 'system') continue;
      if (message.isEmpty && imageUrl.isEmpty) continue;
      if (id.isNotEmpty && seenIds.contains(id)) continue;
      if (id.isNotEmpty) seenIds.add(id);
      cleanRows.add(item);
    }

    cleanRows.sort((a, b) {
      final aTime = a['created_at']?.toString() ?? '';
      final bTime = b['created_at']?.toString() ?? '';
      return aTime.compareTo(bTime);
    });

    return cleanRows;
  }

  static Future<List<Map<String, dynamic>>> getMessages(String chatId) async {
    final rows = await _client
        .from('support_messages')
        .select()
        .eq('chat_id', chatId)
        .order('created_at', ascending: true);

    return _cleanMessageRows(rows as List<dynamic>);
  }

  static Future<List<Map<String, dynamic>>> _allChatsForCurrentCustomer() async {
    final combined = <Map<String, dynamic>>[];

    final byCustomerId = await _client
        .from('support_chats')
        .select()
        .eq('customer_id', DemoData.customerId)
        .order('updated_at', ascending: false);

    for (final row in byCustomerId) {
      combined.add(Map<String, dynamic>.from(row));
    }

    final byUniqueId = await _client
        .from('support_chats')
        .select()
        .eq('unique_id', DemoData.uniqueId)
        .order('updated_at', ascending: false);

    for (final row in byUniqueId) {
      final item = Map<String, dynamic>.from(row);
      final id = item['id']?.toString();
      if (id == null || combined.every((existing) => existing['id']?.toString() != id)) {
        combined.add(item);
      }
    }

    combined.sort((a, b) {
      final aTime = a['updated_at']?.toString() ?? a['created_at']?.toString() ?? '';
      final bTime = b['updated_at']?.toString() ?? b['created_at']?.toString() ?? '';
      return bTime.compareTo(aTime);
    });

    return combined;
  }

  static Future<void> _closeOtherActiveChats({required String keepChatId}) async {
    final chats = await _allChatsForCurrentCustomer();

    for (final chat in chats) {
      final id = chat['id']?.toString() ?? '';
      final status = chat['status']?.toString() ?? '';

      if (id.isEmpty || id == keepChatId) continue;
      if (!_isActiveStatus(status)) continue;

      await _client.from('support_chats').update({
        'updated_at': DateTime.now().toIso8601String(),
        'status': 'resolved',
      }).eq('id', id);
    }
  }

  static Future<Map<String, dynamic>?> getActiveChatForCurrentCustomer() async {
    final chats = await _allChatsForCurrentCustomer();

    final activeChats = chats.where((row) {
      final status = row['status']?.toString() ?? '';
      return _isActiveStatus(status);
    }).toList();

    if (activeChats.isEmpty) return null;

    final active = activeChats.first;
    final activeId = active['id']?.toString();

    if (activeId != null && activeId.isNotEmpty) {
      await _closeOtherActiveChats(keepChatId: activeId);
    }

    return active;
  }

  static Future<String?> uploadSupportImage(File imageFile) async {
    try {
      final bytes = await imageFile.readAsBytes();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final safeCustomerId = DemoData.customerId.replaceAll(RegExp(r'[^a-zA-Z0-9_-]'), '_');
      final filePath = '$safeCustomerId/router_$timestamp.jpg';

      await _client.storage.from('support-images').uploadBinary(
        filePath,
        bytes,
        fileOptions: const FileOptions(
          contentType: 'image/jpeg',
          upsert: true,
        ),
      );

      return _client.storage.from('support-images').getPublicUrl(filePath);
    } catch (e) {
      debugPrint('Support image upload error: $e');
      return null;
    }
  }

  static Future<String> createEscalatedChat({
    required String issueSummary,
    required String firstCustomerMessage,
    String? aiResponse,
    bool hasImage = false,
    File? imageFile,
  }) async {
    final uploadedImageUrl = imageFile != null ? await uploadSupportImage(imageFile) : null;

    final existingChat = await getActiveChatForCurrentCustomer();
    if (existingChat != null && existingChat['id'] != null) {
      final existingChatId = existingChat['id'].toString();

      await _client.from('support_chats').update({
        'updated_at': DateTime.now().toIso8601String(),
        'status': 'human',
        'priority': hasImage ? 'high' : (existingChat['priority'] ?? 'normal'),
        'issue_summary': issueSummary.isNotEmpty ? issueSummary : existingChat['issue_summary'],
      }).eq('id', existingChatId);

      await addMessage(
        chatId: existingChatId,
        senderRole: 'customer',
        senderName: DemoData.customerName,
        message: firstCustomerMessage.isEmpty
            ? 'Customer uploaded a router image for support review.'
            : firstCustomerMessage,
        imageUrl: uploadedImageUrl,
      );

      if (aiResponse != null && aiResponse.trim().isNotEmpty) {
        await addMessage(
          chatId: existingChatId,
          senderRole: 'assistant',
          senderName: 'Bioniq Assistant',
          message: aiResponse.trim(),
        );
      }

      return existingChatId;
    }

    final chat = await _client
        .from('support_chats')
        .insert({
      'customer_id': DemoData.customerId,
      'customer_name': DemoData.customerName,
      'unique_id': DemoData.uniqueId,
      'status': 'human',
      'priority': hasImage ? 'high' : 'normal',
      'issue_summary': issueSummary,
    })
        .select()
        .single();

    final chatId = chat['id'].toString();
    await _closeOtherActiveChats(keepChatId: chatId);

    await addMessage(
      chatId: chatId,
      senderRole: 'customer',
      senderName: DemoData.customerName,
      message: firstCustomerMessage.isEmpty
          ? 'Customer uploaded a router image for support review.'
          : firstCustomerMessage,
      imageUrl: uploadedImageUrl,
    );

    if (aiResponse != null && aiResponse.trim().isNotEmpty) {
      await addMessage(
        chatId: chatId,
        senderRole: 'assistant',
        senderName: 'Bioniq Assistant',
        message: aiResponse.trim(),
      );
    }

    return chatId;
  }

  static Future<void> addMessage({
    required String chatId,
    required String senderRole,
    required String senderName,
    required String message,
    String? imageUrl,
  }) async {
    final cleanMessage = message.trim();
    if (cleanMessage.isEmpty && imageUrl == null) return;

    final recentRows = await _client
        .from('support_messages')
        .select('sender_role,message,image_url')
        .eq('chat_id', chatId)
        .order('created_at', ascending: false)
        .limit(8);

    if (recentRows is List && recentRows.isNotEmpty) {
      for (final raw in recentRows) {
        final last = raw as Map<String, dynamic>;
        final sameRole = last['sender_role']?.toString() == senderRole;
        final sameMessage = (last['message']?.toString().trim() ?? '') == cleanMessage;
        final sameImage = (last['image_url']?.toString() ?? '') == (imageUrl ?? '');
        if (sameRole && sameMessage && sameImage) return;
      }
    }

    await _client.from('support_messages').insert({
      'chat_id': chatId,
      'sender_role': senderRole,
      'sender_name': senderName,
      'message': cleanMessage,
      'image_url': imageUrl,
    });

    await _client.from('support_chats').update({
      'updated_at': DateTime.now().toIso8601String(),
      'status': 'human',
    }).eq('id', chatId);
  }

  static Future<void> closeChat(String chatId) async {
    await _client.from('support_chats').update({
      'updated_at': DateTime.now().toIso8601String(),
      'status': 'resolved',
    }).eq('id', chatId);
  }
}
class DemoData {
  static String customerName = 'Arthur';
  static String uniqueId = '20481';
  static String customerId = 'cust_001';
  static String accountNumber = 'BNQ-20481';
  static String email = 'arthur@bioniq.co.za';
  static String portalPassword = '12345';

  static String wifiName = 'Bioniq_HomeFiber';
  static String wifiPassword = 'Bioniq@2026';
  static String internetPackage = '50 Mbps Fiber';
  static String address = 'Middelburg, Mpumalanga';
  static String uptime = '12 days 4 hrs';
  static String publicIp = '102.67.18.24';
  static String wifiLastUpdated = 'Today';

  static DateTime dueDate = DateTime.now().add(const Duration(days: 3));
  static double monthlyAmount = 799.00;
  static double outstandingBalance = 799.00;

  static bool paymentUpToDate = false;
  static String technicalStatus = 'Online';

  static String paymentInstructions =
      'Pay via the Bioniq Portal using your Unique ID as payment reference.';
  static String paymentMethod = 'Bioniq Portal / EFT';
  static String bankName = 'Demo Bank';
  static String bankAccount = '0123456789';
  static String branchCode = '250655';
  static String paymentReference = '20481';
  static String servicePlan = 'Fiber Home 50 Mbps';

  static String get routerStatus {
    if (!paymentUpToDate) return 'Blocked';
    return technicalStatus;
  }

  static int get daysUntilDue => dueDate.difference(DateTime.now()).inDays;

  static String get paymentStatusText {
    if (!paymentUpToDate && outstandingBalance > 0) {
      return 'Payment outstanding';
    }
    return 'Paid up';
  }

  static int get activeConnectedDevicesCount =>
      devices.where((d) => d.connected && !d.blocked).length;

  static final List<DeviceInfo> devices = [
    DeviceInfo(
      id: 'dev_001',
      name: 'Arthur iPhone',
      type: 'Phone',
      ip: '192.168.0.2',
      mac: 'AA:BB:CC:11:22:33',
      connected: true,
      trusted: true,
      signalStrength: 'Excellent',
      usage: '2.4 GB today',
      blocked: false,
    ),
    DeviceInfo(
      id: 'dev_002',
      name: 'Samsung TV',
      type: 'TV',
      ip: '192.168.0.8',
      mac: 'DD:EE:FF:44:55:66',
      connected: true,
      trusted: true,
      signalStrength: 'Good',
      usage: '5.8 GB today',
      blocked: false,
    ),
    DeviceInfo(
      id: 'dev_003',
      name: 'Unknown Device',
      type: 'Unknown',
      ip: '192.168.0.15',
      mac: 'ZZ:YY:XX:88:77:66',
      connected: true,
      trusted: false,
      signalStrength: 'Fair',
      usage: '1.1 GB today',
      blocked: false,
    ),
  ];
}

class DeviceInfo {
  String id;
  String name;
  String type;
  String ip;
  String mac;
  bool connected;
  bool trusted;
  String signalStrength;
  String usage;
  bool blocked;

  DeviceInfo({
    required this.id,
    required this.name,
    required this.type,
    required this.ip,
    required this.mac,
    required this.connected,
    required this.trusted,
    required this.signalStrength,
    required this.usage,
    this.blocked = false,
  });
}

List<DeviceInfo> devicesFromBackend(List<dynamic> rawDevices) {
  return rawDevices.map((raw) {
    final item = raw as Map<String, dynamic>;

    return DeviceInfo(
      id: item['id'] ?? '',
      name: item['name'] ?? 'Unknown Device',
      type: item['type'] ?? 'Unknown',
      ip: item['ip'] ?? '',
      mac: item['mac'] ?? '',
      connected: item['connected'] ?? false,
      trusted: item['trusted'] ?? false,
      signalStrength: item['signalStrength'] ?? 'Unknown',
      usage: item['usage'] ?? '0 GB today',
      blocked: item['blocked'] ?? false,
    );
  }).toList();
}

class ChatMessage {
  final String text;
  final bool isUser;
  final File? image;
  final String? imageUrl;

  ChatMessage({
    required this.text,
    required this.isUser,
    this.image,
    this.imageUrl,
  });
}

class GeminiService {
  static const String apiKey = 'YOUR_API_KEY_HERE';

  static const List<String> _models = [
    'gemini-2.0-flash',
    'gemini-2.5-flash',
    'gemini-2.5-pro',
  ];

  static Future<String> sendMessage({
    required String userMessage,
    required List<ChatMessage> history,
  }) async {
    final directAnswer = _instantSystemAnswer(userMessage);
    if (directAnswer != null) {
      return directAnswer;
    }

    final conversationText = history
        .map((m) => '${m.isUser ? "Customer" : "Bioniq Assistant"}: ${m.text}')
        .join('\n');

    final systemContext = '''
You are Bioniq Assistant, a smart ISP customer support assistant inside the Bioniq mobile app.

Your job:
- Give direct, useful support answers based on the customer data below.
- Diagnose the likely cause first, then give 2 to 4 simple next steps.
- Sound like a real ISP support agent, not a generic chatbot.
- If the user asks why internet is offline, slow, blocked, disconnected, or not working, use router status and billing status immediately.
- If service is Blocked, clearly explain that payment restriction is the reason.
- If router status is Offline, explain it may be a technical/router/network issue and suggest checking power, WAN cable, router lights, and contacting support if it persists.
- If router status is Online but they complain, suggest checking connected devices, Wi-Fi signal, router restart, and speed test near router.
- If the user asks about connected devices, list the known devices and suggest blocking unknown devices.
- If the user asks about billing, mention the outstanding balance and payment reference.

Strict rules:
- Never mention AI, Gemini, API, model names, prompts, backend, or that this is simulated.
- Do not begin with generic phrases like "I can help with..." when the question is specific.
- Keep replies short, clear, and action-focused.
- Use the customer data. Do not invent account details.

Current customer data:
- Name: ${DemoData.customerName}
- Unique ID / payment reference: ${DemoData.uniqueId}
- Package: ${DemoData.internetPackage}
- Wi-Fi name: ${DemoData.wifiName}
- Router status: ${DemoData.routerStatus}
- Technical status: ${DemoData.technicalStatus}
- Payment up to date: ${DemoData.paymentUpToDate ? "Yes" : "No"}
- Outstanding balance: R${DemoData.outstandingBalance.toStringAsFixed(2)}
- Monthly amount: R${DemoData.monthlyAmount.toStringAsFixed(2)}
- Due in: ${DemoData.daysUntilDue} days
- Active connected devices: ${DemoData.activeConnectedDevicesCount}
- Devices: ${DemoData.devices.map((d) => '${d.name} (${d.blocked ? "Blocked" : d.connected ? "Connected" : "Disconnected"}, ${d.trusted ? "Trusted" : "Unknown"}, ${d.usage})').join(", ")}

Response style:
- Start with the answer.
- Then give next steps.
- End with one helpful instruction, such as opening Billing or Devices when relevant.
''';

    final body = {
      "contents": [
        {
          "parts": [
            {
              "text":
              "$systemContext\n\nConversation so far:\n$conversationText\n\nCustomer question: $userMessage"
            }
          ]
        }
      ],
      "generationConfig": {
        "temperature": 0.25,
        "topP": 0.85,
        "topK": 40,
        "maxOutputTokens": 220,
      }
    };

    for (final model in _models) {
      final result = await _callModel(model: model, body: body);
      if (result.isSuccess) {
        return _cleanAssistantReply(result.message);
      }
    }

    return _localFallback(userMessage);
  }

  static Future<String> sendImageMessage({
    required String userMessage,
    required File imageFile,
  }) async {
    final bytes = await imageFile.readAsBytes();
    final base64Image = base64Encode(bytes);

    final prompt = '''
You are Bioniq Assistant, a professional ISP support assistant.

A customer uploaded a router photo. Analyze the image carefully and explain what you can see.

Focus on:
- Power light
- Internet/WAN light
- Wi-Fi light
- LAN lights
- Red/LOS/warning lights
- Blinking or missing lights
- Cable connection clues if visible

Current customer data:
- Name: ${DemoData.customerName}
- Router status in system: ${DemoData.routerStatus}
- Technical status: ${DemoData.technicalStatus}
- Payment up to date: ${DemoData.paymentUpToDate ? "Yes" : "No"}
- Outstanding balance: R${DemoData.outstandingBalance.toStringAsFixed(2)}
- Wi-Fi name: ${DemoData.wifiName}
- Active connected devices: ${DemoData.activeConnectedDevicesCount}

Customer message: ${userMessage.isEmpty ? "Please analyze my router photo." : userMessage}

Answer format:
1. Start with what the router photo seems to show.
2. Give the most likely issue.
3. Give 2 to 4 practical steps.
4. If payment is not up to date, mention that even normal router lights may not restore access until payment is confirmed.

Rules:
- Do not mention AI, Gemini, API, model, or prompt.
- Do not claim certainty if the image is unclear. Say "from the photo, it looks like...".
- Keep the answer short and practical.
''';

    final body = {
      'contents': [
        {
          'parts': [
            {'text': prompt},
            {
              'inline_data': {
                'mime_type': 'image/jpeg',
                'data': base64Image,
              }
            }
          ]
        }
      ],
      'generationConfig': {
        'temperature': 0.2,
        'topP': 0.8,
        'topK': 32,
        'maxOutputTokens': 260,
      }
    };

    for (final model in _models) {
      final result = await _callModel(model: model, body: body);
      if (result.isSuccess) {
        return _cleanAssistantReply(result.message);
      }
    }

    return 'I could not analyze the router photo clearly. Please make sure the router lights are visible, then upload the image again. You can also tell me which lights are on, off, red, or blinking.';
  }

  static Future<_GeminiResult> _callModel({
    required String model,
    required Map<String, dynamic> body,
  }) async {
    final endpoint =
        'https://generativelanguage.googleapis.com/v1beta/models/$model:generateContent';

    try {
      var response = await http
          .post(
        Uri.parse(endpoint),
        headers: {
          'Content-Type': 'application/json',
          'x-goog-api-key': apiKey,
        },
        body: jsonEncode(body),
      )
          .timeout(const Duration(seconds: 20));

      if (response.statusCode == 503 || response.statusCode == 429) {
        await Future.delayed(const Duration(seconds: 2));
        response = await http
            .post(
          Uri.parse(endpoint),
          headers: {
            'Content-Type': 'application/json',
            'x-goog-api-key': apiKey,
          },
          body: jsonEncode(body),
        )
            .timeout(const Duration(seconds: 20));
      }

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final candidates = data['candidates'];

        if (candidates == null || candidates.isEmpty) {
          return _GeminiResult.failure();
        }

        final parts = candidates[0]['content']?['parts'] as List<dynamic>?;
        if (parts == null || parts.isEmpty) {
          return _GeminiResult.failure();
        }

        final text = parts
            .map((p) => p['text'])
            .whereType<String>()
            .join('\n')
            .trim();

        if (text.isEmpty) {
          return _GeminiResult.failure();
        }

        return _GeminiResult.success(text);
      }

      return _GeminiResult.failure();
    } on TimeoutException {
      return _GeminiResult.failure();
    } catch (_) {
      return _GeminiResult.failure();
    }
  }

  static String? _instantSystemAnswer(String input) {
    final text = input.toLowerCase();
    final status = DemoData.routerStatus.toLowerCase();
    final technicalStatus = DemoData.technicalStatus.toLowerCase();
    final hasBalance = DemoData.outstandingBalance > 0;
    final paymentBlocked = !DemoData.paymentUpToDate && hasBalance;

    final connectedDevices = DemoData.devices.where((d) => d.connected && !d.blocked).toList();
    final unknownDevices = DemoData.devices.where((d) => !d.trusted && !d.blocked).toList();
    final blockedDevices = DemoData.devices.where((d) => d.blocked).toList();
    final disconnectedDevices = DemoData.devices.where((d) => !d.connected && !d.blocked).toList();

    final asksOffline = text.contains('offline') ||
        text.contains('no internet') ||
        text.contains('not working') ||
        text.contains('not connecting') ||
        text.contains('no connection') ||
        text.contains('disconnected') ||
        text.contains('why is my internet') ||
        text.contains('router offline') ||
        text.contains('internet offline') ||
        text.contains('internet down') ||
        text.contains('wifi not working') ||
        text.contains('wi-fi not working');

    final asksSlow = text.contains('slow') ||
        text.contains('lag') ||
        text.contains('buffer') ||
        text.contains('speed') ||
        text.contains('latency') ||
        text.contains('ping');

    final asksDevices = (text.contains('who') && (text.contains('wifi') || text.contains('wi-fi'))) ||
        text.contains('connected devices') ||
        text.contains('devices connected') ||
        text.contains('unknown device') ||
        text.contains('unknown user') ||
        text.contains('who is connected') ||
        text.contains('using my wifi') ||
        text.contains('using my wi-fi') ||
        text.contains('kick') ||
        text.contains('block device') ||
        text.contains('remove device');

    final asksBilling = text.contains('billing') ||
        text.contains('payment') ||
        text.contains('balance') ||
        text.contains('due') ||
        text.contains('paid') ||
        text.contains('owe') ||
        text.contains('account');

    final asksPassword = text.contains('password') ||
        text.contains('wifi name') ||
        text.contains('wi-fi name') ||
        text.contains('change wifi') ||
        text.contains('change wi-fi') ||
        text.contains('ssid');

    final asksLights = text.contains('lights') ||
        text.contains('light') ||
        text.contains('wan') ||
        text.contains('los') ||
        text.contains('pon') ||
        text.contains('red light') ||
        text.contains('flickering') ||
        text.contains('blinking');

    final asksWhatCanSee = text.contains('what can you see') ||
        text.contains('account and connected') ||
        text.contains('my account') ||
        text.contains('account details') ||
        text.contains('summary');

    if (asksWhatCanSee) {
      final deviceSummary = DemoData.devices
          .map((d) => '${d.name} (${d.blocked ? "Blocked" : d.connected ? "Connected" : "Disconnected"})')
          .join(', ');
      return 'I can see that ${DemoData.customerName} is on the ${DemoData.internetPackage} package. Router status is ${DemoData.routerStatus}, Wi-Fi name is ${DemoData.wifiName}, outstanding balance is R${DemoData.outstandingBalance.toStringAsFixed(2)}, and there are ${DemoData.activeConnectedDevicesCount} active connected devices. Devices: $deviceSummary.';
    }

    if (asksOffline) {
      if (paymentBlocked) {
        return 'Your internet is offline because the service is blocked by billing. There is an outstanding balance of R${DemoData.outstandingBalance.toStringAsFixed(2)} on this account. Open Billing and use Unique ID ${DemoData.uniqueId} as the payment reference. Once payment is confirmed, access can be restored.';
      }

      if (status == 'blocked') {
        return 'Your service is restricted on the ISP side. Billing is not showing as the cause, so this may be an admin-side service control action. Please contact support to restore access.';
      }

      if (technicalStatus == 'offline' || status == 'offline') {
        return 'Your router is showing Offline, and billing is not the reason. This points to a technical connection issue. Please check router power, the WAN cable, and router lights, then restart the router. If it stays offline, support should check the line from the ISP side.';
      }

      if (status == 'online') {
        return 'Your service is showing Online, so the line looks active. If you still cannot browse, restart the router, test near the router, and check Devices for heavy users or unknown devices. There are currently ${DemoData.activeConnectedDevicesCount} active connected devices.';
      }
    }

    if (text.contains('blocked') || text.contains('restricted')) {
      if (paymentBlocked) {
        return 'Your service is restricted because there is an outstanding balance of R${DemoData.outstandingBalance.toStringAsFixed(2)}. Open Billing for payment instructions and use ${DemoData.uniqueId} as your payment reference.';
      }
      if (status == 'blocked') {
        return 'Your service is restricted on the ISP side, but billing is currently not showing as the cause. Please contact support or wait for the admin team to restore the service.';
      }
      return 'Your service is not showing as blocked right now. Current router status: ${DemoData.routerStatus}. If you cannot browse, restart the router and check Devices for heavy usage.';
    }

    if (asksSlow) {
      final unknownNote = unknownDevices.isNotEmpty
          ? ' I also see ${unknownDevices.length} unknown device(s), so review Devices and block anything you do not recognize.'
          : '';
      return 'Your package is ${DemoData.internetPackage}. If the connection feels slow, check Devices first: there are ${connectedDevices.length} active connected devices.$unknownNote Restart the router, test near the router, and disconnect or block heavy/unknown users before running another speed test.';
    }

    if (asksDevices) {
      final deviceSummary = DemoData.devices
          .map((d) => '${d.name} - ${d.blocked ? "Blocked" : d.connected ? "Connected" : "Disconnected"}${d.trusted ? "" : " (Unknown)"}, ${d.usage}')
          .join(', ');
      final actionAdvice = unknownDevices.isNotEmpty
          ? 'I recommend blocking unknown devices so they cannot reconnect.'
          : 'All visible devices are either trusted or already managed.';
      return 'There are ${connectedDevices.length} active connected devices. Devices on your network: $deviceSummary. $actionAdvice Open Devices to disconnect a device temporarily or block it permanently.';
    }

    if (asksBilling) {
      if (paymentBlocked) {
        return 'Your account has an outstanding balance of R${DemoData.outstandingBalance.toStringAsFixed(2)} and the service is restricted. Use Unique ID ${DemoData.uniqueId} as your payment reference in Billing. Once payment is confirmed, service can be restored.';
      }
      return 'Your payment is currently up to date. Monthly amount: R${DemoData.monthlyAmount.toStringAsFixed(2)}. Your payment reference is ${DemoData.uniqueId}. Current service status is ${DemoData.routerStatus}.';
    }

    if (asksPassword) {
      return 'Your current Wi-Fi name is ${DemoData.wifiName}. You can update the Wi-Fi name and password from the Wi-Fi Settings screen. After saving, reconnect your devices using the new password.';
    }

    if (asksLights) {
      if (paymentBlocked) {
        return 'Your account is currently billing-blocked, so even if router lights look normal, internet access can still be restricted. First complete payment using reference ${DemoData.uniqueId}, then restart the router after confirmation.';
      }
      return 'For router lights: Power should be on, WAN/Internet should show a link, and warning lights such as LOS/red light usually mean line or signal trouble. Check that the WAN cable is firmly connected, restart the router, and contact support if the red/LOS light stays on.';
    }

    if (text.contains('restart') || text.contains('reboot')) {
      return 'To restart safely: switch the router off for 10 seconds, switch it back on, then wait 2 to 3 minutes for it to reconnect. If the status remains ${DemoData.routerStatus}, open the app again or contact support.';
    }

    if (text.contains('thank')) {
      return 'You are welcome. I am here if you need help with your connection, billing, Wi-Fi settings, or connected devices.';
    }

    return null;
  }

  static String _localFallback(String input) {
    final direct = _instantSystemAnswer(input);
    if (direct != null) return direct;

    return 'I can help with your internet connection, router lights, Wi-Fi settings, connected devices, and billing. Tell me what you are experiencing, for example “my internet is offline”, “my speed is slow”, or “who is connected to my Wi-Fi”.';
  }

  static String _cleanAssistantReply(String reply) {
    return reply
        .replaceAll('AI', 'assistant')
        .replaceAll('Gemini', 'Bioniq Assistant')
        .trim();
  }
}

class _GeminiResult {
  final bool isSuccess;
  final String message;

  const _GeminiResult._({
    required this.isSuccess,
    required this.message,
  });

  factory _GeminiResult.success(String message) {
    return _GeminiResult._(
      isSuccess: true,
      message: message,
    );
  }

  factory _GeminiResult.failure() {
    return const _GeminiResult._(
      isSuccess: false,
      message: '',
    );
  }
}

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _uniqueIdController =
  TextEditingController(text: DemoData.uniqueId);
  final TextEditingController _passwordController =
  TextEditingController(text: DemoData.portalPassword);

  bool _isLoggingIn = false;

  @override
  void dispose() {
    _uniqueIdController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    final uniqueId = _uniqueIdController.text.trim();
    final password = _passwordController.text.trim();

    if (uniqueId.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter Unique ID and password.')),
      );
      return;
    }

    setState(() => _isLoggingIn = true);

    try {
      final result = await ApiService.login(
        uniqueId: uniqueId,
        password: password,
      );

      if (result['success'] == true) {
        final user = result['user'];
        final role = result['role'];

        if (!mounted) return;

        if (role == 'admin') {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const AdminOverviewScreen()),
          );
          return;
        }

        DemoData.customerId = user['id'] ?? DemoData.customerId;
        DemoData.customerName = user['name'] ?? DemoData.customerName;
        DemoData.uniqueId = user['uniqueId'] ?? DemoData.uniqueId;
        DemoData.email = user['email'] ?? DemoData.email;

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const MainShell()),
        );
      } else {
        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(result['message'] ?? 'Login failed')),
        );
      }
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Connection error. Make sure backend is running.'),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoggingIn = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(22),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Spacer(),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.18),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Icon(
                  Icons.wifi_tethering_rounded,
                  size: 40,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'Welcome to Bioniq',
                style: TextStyle(fontSize: 30, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              const Text(
                'Login with your portal Unique ID and password.',
                style: TextStyle(
                  fontSize: 15,
                  color: AppColors.textMuted,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 28),
              _AppTextField(
                controller: _uniqueIdController,
                hint: 'Unique ID',
                icon: Icons.badge_outlined,
              ),
              const SizedBox(height: 14),
              _AppTextField(
                controller: _passwordController,
                hint: 'Password',
                icon: Icons.lock_outline,
                obscureText: true,
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _isLoggingIn ? null : _login,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: Text(
                    _isLoggingIn ? 'Logging in...' : 'Login',
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              Center(
                child: Text(
                  'Demo login: ${DemoData.uniqueId} / ${DemoData.portalPassword}',
                  style: const TextStyle(color: AppColors.textMuted),
                ),
              ),
              const Spacer(),
            ],
          ),
        ),
      ),
    );
  }
}

class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _currentIndex = 0;

  late final List<Widget> _screens = [
    const HomeTab(),
    const AssistantTab(),
    const DevicesTab(),
    const BillingTab(),
    const ProfileTab(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_currentIndex],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        backgroundColor: const Color(0xFF0B1727),
        indicatorColor: AppColors.primary.withOpacity(0.22),
        onDestinationSelected: (index) {
          setState(() => _currentIndex = index);
        },
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home_outlined), label: 'Home'),
          NavigationDestination(
            icon: Icon(Icons.support_agent_outlined),
            label: 'Assistant',
          ),
          NavigationDestination(
            icon: Icon(Icons.devices_outlined),
            label: 'Devices',
          ),
          NavigationDestination(
            icon: Icon(Icons.receipt_long_outlined),
            label: 'Billing',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}

class HomeTab extends StatefulWidget {
  const HomeTab({super.key});

  @override
  State<HomeTab> createState() => _HomeTabState();
}

class _HomeTabState extends State<HomeTab> {
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchDashboard();
  }

  Future<void> fetchDashboard() async {
    try {
      final result = await ApiService.getDashboard(DemoData.customerId);

      if (result['success'] == true) {
        final data = result['data'];
        final customer = data['customer'];
        final router = data['router'];
        final billing = data['billing'];

        final devicesResult = await ApiService.getDevices(DemoData.customerId);
        final backendDevices = devicesResult['success'] == true
            ? devicesFromBackend(devicesResult['data']['devices'] ?? [])
            : DemoData.devices;

        setState(() {
          DemoData.devices
            ..clear()
            ..addAll(backendDevices);

          DemoData.customerName = customer['name'] ?? DemoData.customerName;
          DemoData.uniqueId = customer['uniqueId'] ?? DemoData.uniqueId;
          DemoData.email = customer['email'] ?? DemoData.email;
          DemoData.accountNumber = customer['accountNumber'] ?? DemoData.accountNumber;
          DemoData.internetPackage = customer['package'] ?? DemoData.internetPackage;
          DemoData.address = customer['address'] ?? DemoData.address;

          DemoData.technicalStatus = router['status'] ?? DemoData.technicalStatus;
          DemoData.wifiName = router['wifiName'] ?? DemoData.wifiName;
          DemoData.publicIp = router['publicIp'] ?? DemoData.publicIp;
          DemoData.uptime = router['uptime'] ?? DemoData.uptime;

          DemoData.monthlyAmount =
              (billing['monthlyAmount'] as num?)?.toDouble() ?? DemoData.monthlyAmount;
          DemoData.outstandingBalance =
              (billing['outstandingBalance'] as num?)?.toDouble() ?? DemoData.outstandingBalance;
          DemoData.paymentUpToDate =
              billing['paymentUpToDate'] ?? DemoData.paymentUpToDate;

          isLoading = false;
        });
      } else {
        setState(() => isLoading = false);
      }
    } catch (e) {
      debugPrint('Dashboard error: $e');
      if (mounted) {
        setState(() => isLoading = false);
      }
    }
  }

  String getDueText() {
    final difference = DemoData.daysUntilDue;
    if (difference <= 0) return 'Due today';
    if (difference == 1) return 'Due in 1 day';
    return 'Due in $difference days';
  }

  Color _statusColor() {
    switch (DemoData.routerStatus.toLowerCase()) {
      case 'online':
        return AppColors.green;
      case 'offline':
        return AppColors.amber;
      case 'blocked':
        return AppColors.red;
      default:
        return AppColors.red;
    }
  }

  String getStatusText() {
    switch (DemoData.routerStatus.toLowerCase()) {
      case 'online':
        return 'Your service is online and running normally.';
      case 'offline':
        return 'Your service is currently offline. There may be a connection issue.';
      case 'blocked':
        return 'Your service is currently restricted due to an outstanding payment.';
      default:
        return 'Service status unavailable.';
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final paymentAccent =
    DemoData.paymentUpToDate ? AppColors.green : AppColors.amber;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Bioniq'),
        backgroundColor: Colors.transparent,
      ),
      body: ListView(
        padding: const EdgeInsets.all(18),
        children: [
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF2563EB), Color(0xFF0F8B8D)],
              ),
              borderRadius: BorderRadius.circular(22),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        'Hello, ${DemoData.customerName}',
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.14),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Text(
                        DemoData.uniqueId,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  getStatusText(),
                  style: const TextStyle(fontSize: 15, height: 1.5),
                ),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    _MiniStatChip(
                      icon: Icons.router_outlined,
                      text: DemoData.routerStatus,
                    ),
                    _MiniStatChip(
                      icon: Icons.wifi,
                      text: DemoData.wifiName,
                    ),
                    _MiniStatChip(
                      icon: Icons.devices_outlined,
                      text: '${DemoData.activeConnectedDevicesCount} Devices',
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.card,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Router Health',
                  style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        color: _statusColor(),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      DemoData.routerStatus,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                _BillingRow(label: 'Public IP', value: DemoData.publicIp),
                _BillingRow(label: 'Uptime', value: DemoData.uptime),
                _BillingRow(
                  label: 'Connected Devices',
                  value: '${DemoData.activeConnectedDevicesCount}',
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          _InfoCard(
            title: 'Upcoming Payment',
            subtitle:
            'R${DemoData.outstandingBalance.toStringAsFixed(2)} • ${getDueText()}\n'
                '${DemoData.routerStatus == 'Blocked' ? 'Service restricted until payment is received' : 'Tap to view billing details'}',
            icon: Icons.notifications_active_outlined,
            accent: paymentAccent,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const BillingDetailsScreen(),
                ),
              );
            },
          ),
          const SizedBox(height: 18),
          _InfoCard(
            title: 'Wi-Fi Settings',
            subtitle:
            'Network: ${DemoData.wifiName}\nTap to update Wi-Fi name and password',
            icon: Icons.wifi_password_outlined,
            accent: AppColors.primary,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const WifiSettingsScreen(),
                ),
              );
            },
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(
                child: _ShortcutCard(
                  title: 'View Devices',
                  icon: Icons.devices_outlined,
                  onTap: () {
                    final shellState =
                    context.findAncestorStateOfType<_MainShellState>();
                    shellState?.setState(() {
                      shellState._currentIndex = 2;
                    });
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _ShortcutCard(
                  title: 'Open Billing',
                  icon: Icons.receipt_long_outlined,
                  onTap: () {
                    final shellState =
                    context.findAncestorStateOfType<_MainShellState>();
                    shellState?.setState(() {
                      shellState._currentIndex = 3;
                    });
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class BillingDetailsScreen extends StatelessWidget {
  const BillingDetailsScreen({super.key});

  String getDueText() {
    final difference = DemoData.daysUntilDue;
    if (difference <= 0) return 'Due today';
    if (difference == 1) return 'Due in 1 day';
    return 'Due in $difference days';
  }

  @override
  Widget build(BuildContext context) {
    final isBlocked = DemoData.routerStatus.toLowerCase() == 'blocked';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Upcoming Payment'),
        backgroundColor: Colors.transparent,
      ),
      body: ListView(
        padding: const EdgeInsets.all(18),
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.card,
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Payment Alert',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 21),
                ),
                const SizedBox(height: 18),
                _BillingRow(
                  label: 'Outstanding balance',
                  value: 'R${DemoData.outstandingBalance.toStringAsFixed(2)}',
                ),
                _BillingRow(label: 'Due date', value: getDueText()),
                _BillingRow(
                  label: 'Service status',
                  value: DemoData.routerStatus.toUpperCase(),
                ),
                _BillingRow(
                  label: 'Reference',
                  value: DemoData.paymentReference,
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.card,
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'How to Complete Payment',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 19),
                ),
                const SizedBox(height: 16),
                Text(
                  'Use your Unique ID ${DemoData.uniqueId} as your payment reference when paying through the Bioniq Portal or EFT.',
                  style: const TextStyle(
                    color: AppColors.textMuted,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
          if (isBlocked) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: AppColors.red.withOpacity(0.14),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.red.withOpacity(0.35)),
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Service Restricted',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Payment is overdue and service has been restricted. Please make payment to restore access.',
                    style: TextStyle(height: 1.5),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class WifiSettingsScreen extends StatefulWidget {
  const WifiSettingsScreen({super.key});

  @override
  State<WifiSettingsScreen> createState() => _WifiSettingsScreenState();
}

class _WifiSettingsScreenState extends State<WifiSettingsScreen> {
  late final TextEditingController _wifiNameController;
  late final TextEditingController _wifiPasswordController;

  @override
  void initState() {
    super.initState();
    _wifiNameController = TextEditingController(text: DemoData.wifiName);
    _wifiPasswordController =
        TextEditingController(text: DemoData.wifiPassword);
  }

  @override
  void dispose() {
    _wifiNameController.dispose();
    _wifiPasswordController.dispose();
    super.dispose();
  }

  void _saveWifi() {
    setState(() {
      DemoData.wifiName = _wifiNameController.text.trim();
      DemoData.wifiPassword = _wifiPasswordController.text.trim();
      DemoData.wifiLastUpdated = 'Just now';
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Wi-Fi settings updated successfully.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Wi-Fi Settings'),
        backgroundColor: Colors.transparent,
      ),
      body: ListView(
        padding: const EdgeInsets.all(18),
        children: [
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: AppColors.card,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Manage Wi-Fi Settings',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 6),
                Text(
                  'Last updated: ${DemoData.wifiLastUpdated}',
                  style: const TextStyle(color: AppColors.textMuted),
                ),
                const SizedBox(height: 14),
                _AppTextField(
                  controller: _wifiNameController,
                  hint: 'Wi-Fi name',
                  icon: Icons.wifi,
                ),
                const SizedBox(height: 12),
                _AppTextField(
                  controller: _wifiPasswordController,
                  hint: 'Wi-Fi password',
                  icon: Icons.lock_outline,
                ),
                const SizedBox(height: 14),
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: _saveWifi,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                    ),
                    child: const Text('Save Changes'),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: AppColors.card,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Current Network Details',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                _BillingRow(label: 'Wi-Fi Name', value: DemoData.wifiName),
                _BillingRow(label: 'Security', value: 'WPA2/WPA3 Personal'),
                _BillingRow(
                  label: 'Connected Devices',
                  value: '${DemoData.activeConnectedDevicesCount}',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class AssistantTab extends StatefulWidget {
  const AssistantTab({super.key});

  @override
  State<AssistantTab> createState() => _AssistantTabState();
}

class _AssistantTabState extends State<AssistantTab> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final ImagePicker _picker = ImagePicker();
  File? _selectedImage;
  bool _isLoading = false;
  bool _isEscalatedToTechnician = false;
  String? _activeSupportChatId;
  StreamSubscription<List<Map<String, dynamic>>>? _supportMessageSubscription;
  Timer? _supportRefreshTimer;
  final Set<String> _seenSupportMessageIds = {};

  @override
  void initState() {
    super.initState();
    _restoreActiveSupportChat();
  }

  Future<void> _restoreActiveSupportChat() async {
    try {
      final chat = await SupportService.getActiveChatForCurrentCustomer();
      if (!mounted || chat == null) return;

      final chatId = chat['id']?.toString();
      if (chatId == null || chatId.isEmpty) return;

      setState(() {
        _activeSupportChatId = chatId;
        _isEscalatedToTechnician = true;
        _messages
          ..clear()
          ..add(ChatMessage(
            text: 'Technician handoff created. Office support can now continue from here.',
            isUser: false,
          ));
        _seenSupportMessageIds.clear();
      });

      _listenForSupportMessages(chatId);
    } catch (e) {
      debugPrint('Restore support chat error: $e');
    }
  }

  final List<ChatMessage> _messages = [
    ChatMessage(
      text:
      'Hello, how can I help you today? I can assist with internet issues, router lights, password changes, connected devices, and billing.',
      isUser: false,
    ),
  ];

  final List<String> quickIssues = [
    'Slow internet',
    'No connection',
    'Router blocked',
    'Change Wi-Fi password',
  ];

  Future<void> _pickImage() async {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      backgroundColor: AppColors.card,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  leading: const Icon(Icons.photo_camera_outlined),
                  title: const Text('Take router photo'),
                  onTap: () => Navigator.pop(context, ImageSource.camera),
                ),
                ListTile(
                  leading: const Icon(Icons.photo_library_outlined),
                  title: const Text('Choose from gallery'),
                  onTap: () => Navigator.pop(context, ImageSource.gallery),
                ),
              ],
            ),
          ),
        );
      },
    );

    if (source == null) return;

    final picked = await _picker.pickImage(
      source: source,
      imageQuality: 75,
      maxWidth: 1200,
    );

    if (picked != null && mounted) {
      setState(() {
        _selectedImage = File(picked.path);
      });
    }
  }


  bool _needsTechnician(String customerText, String assistantReply, bool hasImage) {
    final combined = '$customerText $assistantReply'.toLowerCase();

    return hasImage ||
        combined.contains('los') ||
        combined.contains('red light') ||
        combined.contains('no power') ||
        combined.contains('damaged cable') ||
        combined.contains('line fault') ||
        combined.contains('technician') ||
        combined.contains('installation') ||
        combined.contains('support should check') ||
        combined.contains('contact support') ||
        combined.contains('isp side');
  }

  String _issueSummary(String customerText, String assistantReply, bool hasImage) {
    if (hasImage) return 'Router image uploaded for light/status analysis';
    final text = customerText.trim().isEmpty ? assistantReply.trim() : customerText.trim();
    if (text.length <= 90) return text;
    return '${text.substring(0, 90)}...';
  }

  Future<void> _startTechnicianHandoff({
    required String customerText,
    required String assistantReply,
    required bool hasImage,
    File? imageFile,
  }) async {
    if (_activeSupportChatId != null) return;

    try {
      final chatId = await SupportService.createEscalatedChat(
        issueSummary: _issueSummary(customerText, assistantReply, hasImage),
        firstCustomerMessage: customerText,
        aiResponse: assistantReply,
        hasImage: hasImage,
        imageFile: imageFile,
      );

      if (!mounted) return;

      setState(() {
        _activeSupportChatId = chatId;
        _isEscalatedToTechnician = true;
        _messages.clear();
        _seenSupportMessageIds.clear();
      });

      _listenForSupportMessages(chatId);
    } catch (e) {
      debugPrint('Support escalation error: $e');
    }
  }

  List<ChatMessage> _supportRowsToChatMessages(List<Map<String, dynamic>> rows) {
    return rows.map((row) {
      final role = row['sender_role']?.toString() ?? '';
      final sender = row['sender_name']?.toString() ?? '';
      final message = row['message']?.toString() ?? '';
      final imageUrl = row['image_url']?.toString();
      final isCustomer = role == 'customer';
      final label = role == 'system' ? '' : (sender.isNotEmpty ? '$sender\n' : '');
      final text = imageUrl != null && imageUrl.isNotEmpty
          ? '${label}${message.isEmpty ? "Router image attached." : message}'
          : '$label$message';

      return ChatMessage(
        text: text.trim(),
        isUser: isCustomer,
        imageUrl: imageUrl != null && imageUrl.isNotEmpty ? imageUrl : null,
      );
    }).toList();
  }

  Future<void> _refreshSupportMessages(String chatId) async {
    try {
      final rows = await SupportService.getMessages(chatId);
      if (!mounted || _activeSupportChatId != chatId) return;

      setState(() {
        _messages
          ..clear()
          ..addAll(_supportRowsToChatMessages(rows));
      });
      _scrollToBottom();
    } catch (e) {
      debugPrint('Support message refresh error: $e');
    }
  }

  void _listenForSupportMessages(String chatId) {
    _supportMessageSubscription?.cancel();
    _supportRefreshTimer?.cancel();

    _refreshSupportMessages(chatId);

    _supportMessageSubscription = SupportService.messagesStream(chatId).listen((rows) {
      if (!mounted || _activeSupportChatId != chatId) return;

      setState(() {
        _messages
          ..clear()
          ..addAll(_supportRowsToChatMessages(rows));
      });
      _scrollToBottom();
    });

    // Backup refresh. This keeps the chat live even if Supabase Realtime is slow
    // or disabled for the table.
    _supportRefreshTimer = Timer.periodic(const Duration(seconds: 2), (_) {
      if (!mounted || _activeSupportChatId != chatId) return;
      _refreshSupportMessages(chatId);
    });
  }

  Future<void> _saveCustomerMessageToSupport(String text, File? imageFile) async {
    final chatId = _activeSupportChatId;
    if (chatId == null) return;

    final uploadedImageUrl = imageFile != null ? await SupportService.uploadSupportImage(imageFile) : null;

    await SupportService.addMessage(
      chatId: chatId,
      senderRole: 'customer',
      senderName: DemoData.customerName,
      message: text.trim().isEmpty ? 'Customer uploaded a router image.' : text.trim(),
      imageUrl: uploadedImageUrl,
    );

    await _refreshSupportMessages(chatId);
  }

  Future<void> _endTechnicianHandoff() async {
    final chatId = _activeSupportChatId;
    if (chatId == null || _isLoading) return;

    setState(() => _isLoading = true);
    try {
      await SupportService.closeChat(chatId);
      await _supportMessageSubscription?.cancel();
      _supportRefreshTimer?.cancel();
      if (!mounted) return;
      setState(() {
        _activeSupportChatId = null;
        _isEscalatedToTechnician = false;
        _seenSupportMessageIds.clear();
        _messages
          ..clear()
          ..add(ChatMessage(
            text: 'Technician handoff ended. I can assist you again with internet issues, router lights, billing, and connected devices.',
            isUser: false,
          ));
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not end support chat. Check connection.')),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _send(String text) async {
    final trimmed = text.trim();
    if ((trimmed.isEmpty && _selectedImage == null) || _isLoading) return;

    final imageToSend = _selectedImage;

    if (_isEscalatedToTechnician && _activeSupportChatId == null) {
      await _restoreActiveSupportChat();
    }

    if (_isEscalatedToTechnician && _activeSupportChatId != null) {
      setState(() {
        _controller.clear();
        _selectedImage = null;
        _isLoading = true;
      });

      try {
        await _saveCustomerMessageToSupport(trimmed, imageToSend);
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not send to technician. Check connection.')),
        );
      } finally {
        if (mounted) setState(() => _isLoading = false);
      }
      return;
    }

    setState(() {
      _messages.add(ChatMessage(
        text: trimmed,
        isUser: true,
        image: imageToSend,
      ));
      _controller.clear();
      _selectedImage = null;
      _isLoading = true;
    });

    _scrollToBottom();

    final reply = imageToSend != null
        ? await GeminiService.sendImageMessage(
      userMessage: trimmed,
      imageFile: imageToSend,
    )
        : await GeminiService.sendMessage(
      userMessage: trimmed,
      history: List<ChatMessage>.from(_messages),
    );

    if (!mounted) return;

    final shouldEscalate = _needsTechnician(trimmed, reply, imageToSend != null);

    setState(() {
      _messages.add(ChatMessage(text: reply, isUser: false));
      _isLoading = false;
    });

    if (shouldEscalate) {
      await _startTechnicianHandoff(
        customerText: trimmed,
        assistantReply: reply,
        hasImage: imageToSend != null,
        imageFile: imageToSend,
      );
    }

    _scrollToBottom();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) return;
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent + 120,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
      );
    });
  }

  @override
  void dispose() {
    _supportMessageSubscription?.cancel();
    _supportRefreshTimer?.cancel();
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEscalatedToTechnician ? 'Office Support' : 'Bioniq Assistant'),
        backgroundColor: Colors.transparent,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: Center(
              child: _SupportModeBadge(
                label: _isEscalatedToTechnician ? 'TECH LIVE' : 'AI ONLINE',
                color: _isEscalatedToTechnician ? AppColors.amber : AppColors.green,
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          if (_isEscalatedToTechnician)
            Container(
              width: double.infinity,
              margin: const EdgeInsets.fromLTRB(16, 10, 16, 0),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.amber.withOpacity(0.14),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: AppColors.amber.withOpacity(0.38)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(9),
                    decoration: BoxDecoration(
                      color: AppColors.amber.withOpacity(0.20),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(Icons.support_agent, color: AppColors.amber),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Technician handoff active',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Messages now go to office support. End the handoff when the issue is resolved.',
                          style: TextStyle(color: AppColors.textMuted, height: 1.35),
                        ),
                      ],
                    ),
                  ),
                  TextButton(
                    onPressed: _isLoading ? null : _endTechnicianHandoff,
                    child: const Text('End'),
                  ),
                ],
              ),
            ),
          if (!_isEscalatedToTechnician)
            Container(
              width: double.infinity,
              margin: const EdgeInsets.fromLTRB(16, 10, 16, 0),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.12),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: AppColors.primary.withOpacity(0.28)),
              ),
              child: const Row(
                children: [
                  Icon(Icons.auto_awesome, color: AppColors.primary),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'AI support is active. Upload a router photo or describe the issue. Serious faults can be escalated to a technician.',
                      style: TextStyle(color: AppColors.textMuted, height: 1.35),
                    ),
                  ),
                ],
              ),
            ),
          if (!_isEscalatedToTechnician)
            SizedBox(
              height: 52,
              child: ListView.separated(
                padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
                scrollDirection: Axis.horizontal,
                itemBuilder: (context, index) {
                  final issue = quickIssues[index];
                  return ActionChip(
                    label: Text(issue),
                    onPressed: () => _send(issue),
                    backgroundColor: AppColors.card,
                    side: const BorderSide(color: AppColors.border),
                  );
                },
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemCount: quickIssues.length,
              ),
            ),
          const SizedBox(height: 8),
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(16),
              itemCount: _messages.length + (_isLoading ? 1 : 0),
              itemBuilder: (context, index) {
                if (_isLoading && index == _messages.length) {
                  return Align(
                    alignment: Alignment.centerLeft,
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: AppColors.card,
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Text(_isEscalatedToTechnician ? 'Sending to technician...' : 'Bioniq Assistant is thinking...'),
                    ),
                  );
                }

                final message = _messages[index];
                return Align(
                  alignment: message.isUser
                      ? Alignment.centerRight
                      : Alignment.centerLeft,
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(14),
                    constraints: BoxConstraints(
                      maxWidth: MediaQuery.of(context).size.width * 0.78,
                    ),
                    decoration: BoxDecoration(
                      color: message.isUser
                          ? AppColors.primary
                          : AppColors.card,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(
                        color: message.isUser
                            ? AppColors.primary
                            : AppColors.border,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (message.image != null)
                          Padding(
                            padding: EdgeInsets.only(
                              bottom: message.text.isNotEmpty ? 8 : 0,
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: Image.file(
                                message.image!,
                                height: 150,
                                width: double.infinity,
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),
                        if (message.imageUrl != null)
                          Padding(
                            padding: EdgeInsets.only(
                              bottom: message.text.isNotEmpty ? 8 : 0,
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: Image.network(
                                message.imageUrl!,
                                height: 150,
                                width: double.infinity,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => const Text('Router image could not load.'),
                              ),
                            ),
                          ),
                        if (message.text.isNotEmpty)
                          Text(
                            message.text,
                            style: const TextStyle(height: 1.45),
                          ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          if (_selectedImage != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.card,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.border),
                ),
                child: Row(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: Image.file(
                        _selectedImage!,
                        height: 54,
                        width: 54,
                        fit: BoxFit.cover,
                      ),
                    ),
                    const SizedBox(width: 10),
                    const Expanded(
                      child: Text(
                        'Router photo attached. Add a short note or tap send for analysis.',
                        style: TextStyle(color: AppColors.textMuted),
                      ),
                    ),
                    IconButton(
                      onPressed: () => setState(() => _selectedImage = null),
                      icon: const Icon(Icons.close),
                    ),
                  ],
                ),
              ),
            ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            child: Row(
              children: [
                IconButton(
                  onPressed: _isLoading ? null : _pickImage,
                  icon: const Icon(Icons.image_outlined),
                  tooltip: 'Upload router photo',
                ),
                Expanded(
                  child: TextField(
                    controller: _controller,
                    minLines: 1,
                    maxLines: 4,
                    decoration: InputDecoration(
                      hintText: _isEscalatedToTechnician ? 'Message office support...' : 'Ask about internet, billing, devices...',
                      hintStyle: const TextStyle(color: AppColors.textMuted),
                      filled: true,
                      fillColor: AppColors.card,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: const BorderSide(color: AppColors.border),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: const BorderSide(color: AppColors.border),
                      ),
                    ),
                    onSubmitted: (_) => _send(_controller.text),
                  ),
                ),
                const SizedBox(width: 10),
                FloatingActionButton(
                  onPressed: _isLoading ? null : () => _send(_controller.text),
                  backgroundColor: AppColors.primary,
                  child: const Icon(Icons.send),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class DevicesTab extends StatefulWidget {
  const DevicesTab({super.key});

  @override
  State<DevicesTab> createState() => _DevicesTabState();
}

class _DevicesTabState extends State<DevicesTab> {
  bool isLoading = true;
  bool isActionLoading = false;

  @override
  void initState() {
    super.initState();
    fetchDevices();
  }

  Future<void> fetchDevices() async {
    try {
      final result = await ApiService.getDevices(DemoData.customerId);

      if (result['success'] == true) {
        final rawDevices = result['data']['devices'] ?? [];

        setState(() {
          DemoData.devices
            ..clear()
            ..addAll(devicesFromBackend(rawDevices));
          isLoading = false;
        });
      } else {
        setState(() => isLoading = false);
      }
    } catch (e) {
      debugPrint('Devices error: $e');
      if (mounted) {
        setState(() => isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not load devices. Check backend.')),
        );
      }
    }
  }

  Future<void> _runDeviceAction({
    required DeviceInfo device,
    required Future<Map<String, dynamic>> Function() action,
  }) async {
    if (isActionLoading) return;

    setState(() => isActionLoading = true);

    try {
      final result = await action();

      if (result['success'] == true) {
        await fetchDevices();

        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(result['message'] ?? '${device.name} updated.')),
        );
      } else {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(result['message'] ?? 'Action failed.')),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Connection error. Check backend.')),
      );
    } finally {
      if (mounted) {
        setState(() => isActionLoading = false);
      }
    }
  }

  void _disconnectDevice(DeviceInfo device) {
    _runDeviceAction(
      device: device,
      action: () => ApiService.disconnectDevice(
        customerId: DemoData.customerId,
        deviceId: device.id,
      ),
    );
  }

  void _blockDevice(DeviceInfo device) {
    _runDeviceAction(
      device: device,
      action: () => ApiService.blockDevice(
        customerId: DemoData.customerId,
        deviceId: device.id,
      ),
    );
  }

  void _unblockDevice(DeviceInfo device) {
    _runDeviceAction(
      device: device,
      action: () => ApiService.unblockDevice(
        customerId: DemoData.customerId,
        deviceId: device.id,
      ),
    );
  }

  IconData _deviceIcon(String type) {
    switch (type.toLowerCase()) {
      case 'phone':
        return Icons.smartphone;
      case 'tv':
        return Icons.tv;
      case 'laptop':
        return Icons.laptop_mac;
      default:
        return Icons.device_unknown;
    }
  }

  Color _signalColor(String signal) {
    switch (signal.toLowerCase()) {
      case 'excellent':
        return AppColors.green;
      case 'good':
        return AppColors.primary;
      case 'fair':
        return AppColors.amber;
      default:
        return AppColors.red;
    }
  }

  String _connectionStatus(DeviceInfo device) {
    if (device.blocked) return 'Blocked';
    if (device.connected) return 'Connected';
    return 'Disconnected';
  }

  Color _connectionStatusColor(DeviceInfo device) {
    if (device.blocked) return AppColors.red;
    if (device.connected) return AppColors.green;
    return AppColors.amber;
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Connected Devices'),
        backgroundColor: Colors.transparent,
        actions: [
          IconButton(
            onPressed: isActionLoading ? null : fetchDevices,
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh devices',
          ),
        ],
      ),
      body: DemoData.devices.isEmpty
          ? const Center(
        child: Text(
          'No devices found for this account.',
          style: TextStyle(color: AppColors.textMuted),
        ),
      )
          : ListView.builder(
        padding: const EdgeInsets.all(18),
        itemCount: DemoData.devices.length,
        itemBuilder: (context, index) {
          final device = DemoData.devices[index];

          return Container(
            margin: const EdgeInsets.only(bottom: 14),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.card,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: device.trusted
                            ? AppColors.primary.withOpacity(0.18)
                            : Colors.red.withOpacity(0.16),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Icon(_deviceIcon(device.type)),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            device.name,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${device.type} • ${device.ip}',
                            style: const TextStyle(color: AppColors.textMuted),
                          ),
                          Text(
                            device.mac,
                            style: const TextStyle(color: AppColors.textMuted),
                          ),
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              _DetailPill(
                                label: device.trusted ? 'Trusted' : 'Unknown',
                                color: device.trusted
                                    ? AppColors.green
                                    : AppColors.red,
                              ),
                              _DetailPill(
                                label: _connectionStatus(device),
                                color: _connectionStatusColor(device),
                              ),
                              _DetailPill(
                                label: device.signalStrength,
                                color: _signalColor(device.signalStrength),
                              ),
                              _DetailPill(
                                label: device.usage,
                                color: AppColors.primary,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                if (!device.blocked)
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: isActionLoading
                              ? null
                              : () => _disconnectDevice(device),
                          child: const Text('Disconnect'),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: OutlinedButton(
                          onPressed: isActionLoading
                              ? null
                              : () => _blockDevice(device),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.red,
                          ),
                          child: const Text('Block'),
                        ),
                      ),
                    ],
                  ),
                if (device.blocked)
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: isActionLoading
                          ? null
                          : () => _unblockDevice(device),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.green,
                      ),
                      child: const Text('Unblock'),
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class BillingTab extends StatefulWidget {
  const BillingTab({super.key});

  @override
  State<BillingTab> createState() => _BillingTabState();
}

class _BillingTabState extends State<BillingTab> {

  String getDueText() {
    final dueIn = DemoData.daysUntilDue;
    if (dueIn <= 0) return 'Due today';
    if (dueIn == 1) return 'Due in 1 day';
    return 'Due in $dueIn days';
  }

  @override
  Widget build(BuildContext context) {
    final isBlocked = DemoData.routerStatus.toLowerCase() == 'blocked';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Billing'),
        backgroundColor: Colors.transparent,
      ),
      body: ListView(
        padding: const EdgeInsets.all(18),
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.card,
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Account Billing Summary',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 21),
                ),
                const SizedBox(height: 18),
                _BillingRow(label: 'Unique ID', value: DemoData.uniqueId),
                _BillingRow(label: 'Package', value: DemoData.servicePlan),
                _BillingRow(
                  label: 'Monthly amount',
                  value: 'R${DemoData.monthlyAmount.toStringAsFixed(2)}',
                ),
                _BillingRow(
                  label: 'Outstanding balance',
                  value: 'R${DemoData.outstandingBalance.toStringAsFixed(2)}',
                ),
                _BillingRow(label: 'Due date', value: getDueText()),
                _BillingRow(
                  label: 'Payment status',
                  value: DemoData.paymentStatusText,
                ),
                _BillingRow(
                  label: 'Service status',
                  value: DemoData.routerStatus.toUpperCase(),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.card,
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Payment Instructions',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 19),
                ),
                const SizedBox(height: 16),
                _BillingRow(
                  label: 'Payment method',
                  value: DemoData.paymentMethod,
                ),
                _BillingRow(label: 'Bank', value: DemoData.bankName),
                _BillingRow(
                  label: 'Account number',
                  value: DemoData.bankAccount,
                ),
                _BillingRow(label: 'Branch code', value: DemoData.branchCode),
                _BillingRow(
                  label: 'Reference',
                  value: DemoData.paymentReference,
                ),
                const SizedBox(height: 8),
                Text(
                  DemoData.paymentInstructions,
                  style: const TextStyle(
                    color: AppColors.textMuted,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.card,
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: AppColors.border),
            ),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Payment History',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 19),
                ),
                SizedBox(height: 12),
                Text(
                  'No recent payments available in this demo yet.',
                  style: TextStyle(
                    color: AppColors.textMuted,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),

          if (isBlocked) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: AppColors.red.withOpacity(0.14),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.red.withOpacity(0.35)),
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Service Restricted',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Your service is currently blocked because payment is outstanding. Once payment is confirmed, access can be restored.',
                    style: TextStyle(height: 1.5),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class ProfileTab extends StatefulWidget {
  const ProfileTab({super.key});

  @override
  State<ProfileTab> createState() => _ProfileTabState();
}

class _ProfileTabState extends State<ProfileTab> {
  Future<void> _confirmLogout() async {
    final shouldLogout = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Log out'),
          content: const Text('Are you sure you want to log out?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Log out'),
            ),
          ],
        );
      },
    );

    if (shouldLogout == true && mounted) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const LoginScreen()),
            (route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        backgroundColor: Colors.transparent,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _confirmLogout,
            tooltip: 'Log out',
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(18),
        children: [
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: AppColors.card,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              children: [
                CircleAvatar(
                  radius: 32,
                  backgroundColor: AppColors.primary.withOpacity(0.2),
                  child: const Icon(Icons.person, size: 34),
                ),
                const SizedBox(height: 12),
                Text(
                  DemoData.customerName,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  DemoData.email,
                  style: const TextStyle(color: AppColors.textMuted),
                ),
                const SizedBox(height: 4),
                Text(
                  'Unique ID: ${DemoData.uniqueId}',
                  style: const TextStyle(color: AppColors.textMuted),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: AppColors.card,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Service Details',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                _BillingRow(label: 'Address', value: DemoData.address),
                _BillingRow(label: 'Package', value: DemoData.internetPackage),
                _BillingRow(
                  label: 'Router Status',
                  value: DemoData.routerStatus,
                ),
                _BillingRow(label: 'Wi-Fi Name', value: DemoData.wifiName),
              ],
            ),
          ),
        ],
      ),
    );
  }
}


class AdminOverviewScreen extends StatefulWidget {
  const AdminOverviewScreen({super.key});

  @override
  State<AdminOverviewScreen> createState() => _AdminOverviewScreenState();
}

class _AdminOverviewScreenState extends State<AdminOverviewScreen> {
  bool isLoading = true;
  Map<String, dynamic> data = {};

  @override
  void initState() {
    super.initState();
    fetchOverview();
  }

  Future<void> fetchOverview() async {
    try {
      final result = await ApiService.getAdminOverview();

      if (result['success'] == true) {
        setState(() {
          data = result['data'] ?? {};
          isLoading = false;
        });
      } else {
        setState(() => isLoading = false);
      }
    } catch (e) {
      debugPrint('Admin overview error: $e');
      if (mounted) {
        setState(() => isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not load admin overview. Check backend.')),
        );
      }
    }
  }

  int statValue(String key) {
    final value = data[key];
    if (value is int) return value;
    if (value is num) return value.toInt();
    return 0;
  }

  Widget statCard({
    required String title,
    required int value,
    required IconData icon,
    required Color color,
    required String filter,
  }) {
    return Expanded(
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => AdminCustomersScreen(
                filter: filter,
                title: title,
              ),
            ),
          );
        },
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.card,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.16),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, color: color),
              ),
              const SizedBox(height: 14),
              Text(
                '$value',
                style: const TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                title,
                style: const TextStyle(color: AppColors.textMuted),
              ),
              const SizedBox(height: 8),
              Row(
                children: const [
                  Text(
                    'Tap to view',
                    style: TextStyle(
                      color: AppColors.textMuted,
                      fontSize: 12,
                    ),
                  ),
                  SizedBox(width: 4),
                  Icon(
                    Icons.arrow_forward_ios,
                    size: 10,
                    color: AppColors.textMuted,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Overview'),
        backgroundColor: Colors.transparent,
        actions: [
          IconButton(
            icon: const Icon(Icons.support_agent_outlined),
            tooltip: 'Support inbox',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const AdminSupportInboxScreen(),
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.people_outline),
            tooltip: 'View customers',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const AdminCustomersScreen(),
                ),
              );
            },
          ),
          IconButton(
            onPressed: fetchOverview,
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh overview',
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Log out',
            onPressed: () {
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (_) => const LoginScreen()),
                    (route) => false,
              );
            },
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(18),
        children: [
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF2563EB), Color(0xFF0F8B8D)],
              ),
              borderRadius: BorderRadius.circular(22),
            ),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Bioniq Admin Panel',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  'Operational overview for customers, services, billing, and connected devices.',
                  style: TextStyle(height: 1.5),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              statCard(
                title: 'Customers',
                value: statValue('totalCustomers'),
                icon: Icons.people_outline,
                color: Colors.white,
                filter: 'all',
              ),
              const SizedBox(width: 12),
              statCard(
                title: 'Online',
                value: statValue('onlineServices'),
                icon: Icons.check_circle_outline,
                color: AppColors.green,
                filter: 'online',
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              statCard(
                title: 'Offline',
                value: statValue('offlineServices'),
                icon: Icons.wifi_off_outlined,
                color: AppColors.amber,
                filter: 'offline',
              ),
              const SizedBox(width: 12),
              statCard(
                title: 'Blocked',
                value: statValue('blockedServices'),
                icon: Icons.block_outlined,
                color: AppColors.red,
                filter: 'blocked',
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              statCard(
                title: 'Overdue',
                value: statValue('overdueAccounts'),
                icon: Icons.warning_amber_outlined,
                color: AppColors.red,
                filter: 'overdue',
              ),
              const SizedBox(width: 12),
              statCard(
                title: 'Devices',
                value: statValue('totalConnectedDevices'),
                icon: Icons.devices_outlined,
                color: AppColors.primary,
                filter: 'devices',
              ),
            ],
          ),
        ],
      ),
    );
  }
}


class AdminCustomersScreen extends StatefulWidget {
  final String filter;
  final String title;

  const AdminCustomersScreen({
    super.key,
    this.filter = 'all',
    this.title = 'Customers',
  });

  @override
  State<AdminCustomersScreen> createState() => _AdminCustomersScreenState();
}

class _AdminCustomersScreenState extends State<AdminCustomersScreen> {
  bool isLoading = true;
  List<dynamic> customers = [];

  @override
  void initState() {
    super.initState();
    fetchCustomers();
  }

  Future<void> fetchCustomers() async {
    try {
      final result = await ApiService.getAdminCustomers();

      if (result['success'] == true) {
        setState(() {
          customers = result['data'] ?? [];
          isLoading = false;
        });
      } else {
        setState(() => isLoading = false);
      }
    } catch (e) {
      debugPrint('Admin customers error: $e');
      if (mounted) {
        setState(() => isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not load customers. Check backend.')),
        );
      }
    }
  }

  Color getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'online':
        return AppColors.green;
      case 'blocked':
        return AppColors.red;
      case 'offline':
        return AppColors.amber;
      default:
        return AppColors.textMuted;
    }
  }

  String money(dynamic value) {
    if (value is num) return 'R${value.toStringAsFixed(2)}';
    return 'R0.00';
  }

  List<dynamic> filteredCustomers() {
    switch (widget.filter) {
      case 'online':
        return customers
            .where((c) => (c['routerStatus']?.toString().toLowerCase() ?? '') == 'online')
            .toList();
      case 'offline':
        return customers
            .where((c) => (c['routerStatus']?.toString().toLowerCase() ?? '') == 'offline')
            .toList();
      case 'blocked':
        return customers
            .where((c) => (c['routerStatus']?.toString().toLowerCase() ?? '') == 'blocked')
            .toList();
      case 'overdue':
        return customers
            .where((c) => c['paymentUpToDate'] != true && (c['outstandingBalance'] ?? 0) > 0)
            .toList();
      case 'devices':
        final list = List<dynamic>.from(customers);
        list.sort((a, b) => ((b['connectedDevices'] ?? 0) as num)
            .compareTo((a['connectedDevices'] ?? 0) as num));
        return list;
      case 'all':
      default:
        return customers;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final visibleCustomers = filteredCustomers();

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        backgroundColor: Colors.transparent,
        actions: [
          IconButton(
            onPressed: fetchCustomers,
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh customers',
          ),
        ],
      ),
      body: visibleCustomers.isEmpty
          ? const Center(
        child: Text(
          'No customers found for this view.',
          style: TextStyle(color: AppColors.textMuted),
        ),
      )
          : ListView.builder(
        padding: const EdgeInsets.all(18),
        itemCount: visibleCustomers.length,
        itemBuilder: (context, index) {
          final customer = visibleCustomers[index] as Map<String, dynamic>;
          final status = customer['routerStatus']?.toString() ?? 'Unknown';
          final statusColor = getStatusColor(status);

          return InkWell(
            borderRadius: BorderRadius.circular(18),
            onTap: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => AdminCustomerControlScreen(
                    customerId: customer['id']?.toString() ?? '',
                  ),
                ),
              );
              fetchCustomers();
            },
            child: Container(
              margin: const EdgeInsets.only(bottom: 14),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.card,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: statusColor.withOpacity(0.16),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Icon(Icons.person_outline, color: statusColor),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              customer['name']?.toString() ?? 'Unknown customer',
                              style: const TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Unique ID: ${customer['uniqueId'] ?? '-'}',
                              style: const TextStyle(color: AppColors.textMuted),
                            ),
                            Text(
                              customer['email']?.toString() ?? '',
                              style: const TextStyle(color: AppColors.textMuted),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                        decoration: BoxDecoration(
                          color: statusColor.withOpacity(0.14),
                          borderRadius: BorderRadius.circular(30),
                          border: Border.all(color: statusColor.withOpacity(0.35)),
                        ),
                        child: Text(
                          status,
                          style: TextStyle(
                            color: statusColor,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  _BillingRow(label: 'Package', value: customer['package']?.toString() ?? '-'),
                  _BillingRow(label: 'Balance', value: money(customer['outstandingBalance'])),
                  _BillingRow(label: 'Payment', value: customer['paymentUpToDate'] == true ? 'Paid' : 'Outstanding'),
                  _BillingRow(label: 'Devices', value: '${customer['connectedDevices'] ?? 0}'),
                  const SizedBox(height: 8),
                  const Text(
                    'Tap to manage customer',
                    style: TextStyle(color: AppColors.textMuted, fontSize: 12),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}


class AdminCustomerControlScreen extends StatefulWidget {
  final String customerId;

  const AdminCustomerControlScreen({
    super.key,
    required this.customerId,
  });

  @override
  State<AdminCustomerControlScreen> createState() => _AdminCustomerControlScreenState();
}

class _AdminCustomerControlScreenState extends State<AdminCustomerControlScreen> {
  bool isLoading = true;
  bool isActionLoading = false;
  String? activeAction;
  Map<String, dynamic>? customer;

  @override
  void initState() {
    super.initState();
    fetchCustomer();
  }

  Future<void> fetchCustomer() async {
    try {
      final result = await ApiService.getAdminCustomers();

      if (result['success'] == true) {
        final list = result['data'] as List<dynamic>;
        final found = list.cast<Map<String, dynamic>>().firstWhere(
              (item) => item['id'] == widget.customerId,
          orElse: () => {},
        );

        setState(() {
          customer = found.isEmpty ? null : found;
          isLoading = false;
        });
      } else {
        setState(() => isLoading = false);
      }
    } catch (e) {
      debugPrint('Customer control error: $e');
      if (mounted) {
        setState(() => isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not load customer. Check backend.')),
        );
      }
    }
  }

  Color statusColor(String status) {
    switch (status.toLowerCase()) {
      case 'online':
        return AppColors.green;
      case 'blocked':
        return AppColors.red;
      case 'offline':
        return AppColors.amber;
      default:
        return AppColors.textMuted;
    }
  }

  String money(dynamic value) {
    if (value is num) return 'R${value.toStringAsFixed(2)}';
    return 'R0.00';
  }

  Future<void> runAdminAction({
    required String actionName,
    required Future<Map<String, dynamic>> Function() action,
    required String successMessage,
  }) async {
    if (isActionLoading) return;

    setState(() {
      isActionLoading = true;
      activeAction = actionName;
    });

    try {
      final result = await action();

      if (result['success'] == true) {
        await fetchCustomer();

        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(result['message'] ?? successMessage)),
        );
      } else {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(result['message'] ?? 'Action failed')),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Action failed. Check backend.')),
      );
    } finally {
      if (mounted) {
        setState(() {
          isActionLoading = false;
          activeAction = null;
        });
      }
    }
  }

  Future<void> markPaid() async {
    await runAdminAction(
      actionName: 'paid',
      action: () => ApiService.markPaid(widget.customerId),
      successMessage: 'Customer marked as paid',
    );
  }

  Future<void> markUnpaid() async {
    final amount = (customer?['monthlyAmount'] as num?) ?? 799;

    await runAdminAction(
      actionName: 'unpaid',
      action: () => ApiService.markUnpaid(
        customerId: widget.customerId,
        amount: amount,
      ),
      successMessage: 'Customer marked as unpaid',
    );
  }

  Future<void> blockService() async {
    await runAdminAction(
      actionName: 'block',
      action: () => ApiService.blockService(widget.customerId),
      successMessage: 'Service blocked successfully',
    );
  }

  Future<void> unblockService() async {
    await runAdminAction(
      actionName: 'restore',
      action: () => ApiService.unblockService(widget.customerId),
      successMessage: 'Service restored successfully',
    );
  }

  Widget _statusBadge(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: color.withOpacity(0.14),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: color.withOpacity(0.35)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.bold,
          fontSize: 12,
        ),
      ),
    );
  }

  Widget _adminActionButton({
    required String actionName,
    required String label,
    required IconData icon,
    required Color color,
    required VoidCallback onPressed,
  }) {
    final isThisActionLoading = isActionLoading && activeAction == actionName;

    return SizedBox(
      width: double.infinity,
      height: 54,
      child: ElevatedButton.icon(
        onPressed: isActionLoading ? null : onPressed,
        icon: isThisActionLoading
            ? const SizedBox(
          width: 18,
          height: 18,
          child: CircularProgressIndicator(strokeWidth: 2),
        )
            : Icon(icon),
        label: Text(
          isThisActionLoading ? 'Processing...' : label,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
    );
  }

  Widget _sectionCard({
    required String title,
    required List<Widget> children,
  }) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 14),
          ...children,
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (customer == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Customer Control'),
          backgroundColor: Colors.transparent,
        ),
        body: const Center(
          child: Text('Customer not found.'),
        ),
      );
    }

    final status = customer!['routerStatus']?.toString() ?? 'Unknown';
    final color = statusColor(status);
    final isPaid = customer!['paymentUpToDate'] == true;
    final paymentColor = isPaid ? AppColors.green : AppColors.red;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Customer Control'),
        backgroundColor: Colors.transparent,
        actions: [
          IconButton(
            onPressed: isActionLoading ? null : fetchCustomer,
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh customer',
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(18),
        children: [
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF2563EB), Color(0xFF0F8B8D)],
              ),
              borderRadius: BorderRadius.circular(22),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  customer!['name']?.toString() ?? 'Unknown customer',
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text('Unique ID: ${customer!['uniqueId'] ?? '-'}'),
                Text(customer!['email']?.toString() ?? ''),
                const SizedBox(height: 14),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _statusBadge(status, color),
                    _statusBadge(isPaid ? 'Paid' : 'Outstanding', paymentColor),
                    _statusBadge('${customer!['connectedDevices'] ?? 0} devices', AppColors.primary),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            height: 54,
            child: ElevatedButton.icon(
              onPressed: isActionLoading
                  ? null
                  : () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => AdminCustomerPreviewScreen(
                      customerId: widget.customerId,
                      customerName: customer!["name"]?.toString() ?? 'Customer',
                    ),
                  ),
                );
              },
              icon: const Icon(Icons.visibility_outlined),
              label: const Text(
                'View as Customer',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          _sectionCard(
            title: 'Customer Details',
            children: [
              _BillingRow(label: 'Package', value: customer!['package']?.toString() ?? '-'),
              _BillingRow(label: 'Address', value: customer!['address']?.toString() ?? '-'),
              _BillingRow(label: 'Account number', value: customer!['accountNumber']?.toString() ?? '-'),
              _BillingRow(label: 'Due date', value: customer!['dueDate']?.toString() ?? '-'),
            ],
          ),
          const SizedBox(height: 16),
          _sectionCard(
            title: 'Service & Billing',
            children: [
              _BillingRow(label: 'Monthly amount', value: money(customer!['monthlyAmount'])),
              _BillingRow(label: 'Outstanding balance', value: money(customer!['outstandingBalance'])),
              _BillingRow(label: 'Payment status', value: isPaid ? 'Paid' : 'Outstanding'),
              _BillingRow(label: 'Router status', value: status),
              _BillingRow(label: 'Technical status', value: customer!['technicalStatus']?.toString() ?? '-'),
            ],
          ),
          const SizedBox(height: 16),
          _sectionCard(
            title: 'Billing Control',
            children: [
              if (!isPaid)
                _adminActionButton(
                  actionName: 'paid',
                  label: 'Mark as Paid',
                  icon: Icons.check_circle_outline,
                  color: AppColors.green,
                  onPressed: markPaid,
                ),
              if (isPaid)
                _adminActionButton(
                  actionName: 'unpaid',
                  label: 'Mark as Unpaid',
                  icon: Icons.warning_amber_outlined,
                  color: AppColors.amber,
                  onPressed: markUnpaid,
                ),
              const SizedBox(height: 10),
              const Text(
                'Use this when payment is confirmed or when simulating an overdue account.',
                style: TextStyle(color: AppColors.textMuted, height: 1.4),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _sectionCard(
            title: 'Service Control',
            children: [
              Row(
                children: [
                  Expanded(
                    child: _adminActionButton(
                      actionName: 'block',
                      label: 'Block',
                      icon: Icons.block_outlined,
                      color: AppColors.red,
                      onPressed: blockService,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _adminActionButton(
                      actionName: 'restore',
                      label: 'Restore',
                      icon: Icons.power_settings_new,
                      color: AppColors.green,
                      onPressed: unblockService,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              const Text(
                'Block simulates a manual restriction or technical suspension. Restore sets the router back online when allowed.',
                style: TextStyle(color: AppColors.textMuted, height: 1.4),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class AdminCustomerPreviewScreen extends StatefulWidget {
  final String customerId;
  final String customerName;

  const AdminCustomerPreviewScreen({super.key, required this.customerId, required this.customerName});

  @override
  State<AdminCustomerPreviewScreen> createState() => _AdminCustomerPreviewScreenState();
}

class _AdminCustomerPreviewScreenState extends State<AdminCustomerPreviewScreen> {
  bool isLoading = true;
  Map<String, dynamic>? dashboard;
  List<DeviceInfo> devices = [];

  @override
  void initState() {
    super.initState();
    fetchCustomerView();
  }

  Future<void> fetchCustomerView() async {
    setState(() => isLoading = true);
    try {
      final dashboardResult = await ApiService.getDashboard(widget.customerId);
      final devicesResult = await ApiService.getDevices(widget.customerId);
      if (dashboardResult['success'] == true) {
        setState(() {
          dashboard = dashboardResult['data'];
          devices = devicesResult['success'] == true
              ? devicesFromBackend(devicesResult['data']['devices'] ?? [])
              : <DeviceInfo>[];
          isLoading = false;
        });
      } else {
        setState(() => isLoading = false);
      }
    } catch (e) {
      debugPrint('Preview error: $e');
      if (mounted) {
        setState(() => isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not load customer preview. Check backend.')),
        );
      }
    }
  }

  Color statusColor(String status) {
    switch (status.toLowerCase()) {
      case 'online':
        return AppColors.green;
      case 'blocked':
        return AppColors.red;
      case 'offline':
        return AppColors.amber;
      default:
        return AppColors.textMuted;
    }
  }

  String money(dynamic value) {
    if (value is num) return 'R${value.toStringAsFixed(2)}';
    return 'R0.00';
  }

  Widget statusBadge(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: color.withOpacity(0.14),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: color.withOpacity(0.35)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.bold,
          fontSize: 12,
        ),
      ),
    );
  }

  Widget sectionCard({required String title, required List<Widget> children}) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 14),
          ...children,
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (dashboard == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Customer Preview'),
          backgroundColor: Colors.transparent,
        ),
        body: const Center(child: Text('Customer preview not available.')),
      );
    }

    final customer = dashboard!['customer'] ?? {};
    final router = dashboard!['router'] ?? {};
    final billing = dashboard!['billing'] ?? {};
    final status = router['status']?.toString() ?? 'Unknown';
    final color = statusColor(status);
    final isPaid = billing['paymentUpToDate'] == true;
    final activeDevices = devices.where((d) => d.connected && !d.blocked).length;

    return Scaffold(
      appBar: AppBar(
        title: const Text('View as Customer'),
        backgroundColor: Colors.transparent,
        actions: [
          IconButton(
            onPressed: fetchCustomerView,
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh preview',
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(18),
        children: [
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF2563EB), Color(0xFF0F8B8D)],
              ),
              borderRadius: BorderRadius.circular(22),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        'Hello, ${customer['name'] ?? widget.customerName}',
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.14),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Text(
                        customer['uniqueId']?.toString() ?? '-',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  status.toLowerCase() == 'online'
                      ? 'Your service is online and running normally.'
                      : status.toLowerCase() == 'offline'
                      ? 'Your service is currently offline. There may be a connection issue.'
                      : 'Your service is currently restricted due to an outstanding payment or admin restriction.',
                  style: const TextStyle(fontSize: 15, height: 1.5),
                ),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    statusBadge(status, color),
                    statusBadge(isPaid ? 'Paid' : 'Outstanding', isPaid ? AppColors.green : AppColors.red),
                    statusBadge('$activeDevices active devices', AppColors.primary),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          sectionCard(
            title: 'Router Health',
            children: [
              _BillingRow(label: 'Status', value: status),
              _BillingRow(label: 'Wi-Fi name', value: router['wifiName']?.toString() ?? '-'),
              _BillingRow(label: 'Public IP', value: router['publicIp']?.toString() ?? '-'),
              _BillingRow(label: 'Uptime', value: router['uptime']?.toString() ?? '-'),
              _BillingRow(label: 'Connected devices', value: '$activeDevices'),
            ],
          ),
          const SizedBox(height: 16),
          sectionCard(
            title: 'Billing Preview',
            children: [
              _BillingRow(label: 'Monthly amount', value: money(billing['monthlyAmount'])),
              _BillingRow(label: 'Outstanding balance', value: money(billing['outstandingBalance'])),
              _BillingRow(label: 'Payment status', value: isPaid ? 'Paid up' : 'Payment outstanding'),
              _BillingRow(label: 'Due date', value: billing['dueDate']?.toString() ?? '-'),
            ],
          ),
          const SizedBox(height: 16),
          sectionCard(
            title: 'Customer Devices',
            children: devices.isEmpty
                ? [
              const Text(
                'No devices found for this customer.',
                style: TextStyle(color: AppColors.textMuted),
              ),
            ]
                : devices.map((device) {
              final deviceStatus = device.blocked
                  ? 'Blocked'
                  : device.connected
                  ? 'Connected'
                  : 'Disconnected';
              final deviceColor = device.blocked
                  ? AppColors.red
                  : device.connected
                  ? AppColors.green
                  : AppColors.amber;

              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.background.withOpacity(0.45),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.border),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            device.name,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                        statusBadge(deviceStatus, deviceColor),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '${device.type} • ${device.ip}',
                      style: const TextStyle(color: AppColors.textMuted),
                    ),
                    Text(
                      device.usage,
                      style: const TextStyle(color: AppColors.textMuted),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}


class AdminSupportInboxScreen extends StatelessWidget {
  const AdminSupportInboxScreen({super.key});

  Color _priorityColor(String priority) {
    switch (priority.toLowerCase()) {
      case 'high':
        return AppColors.red;
      default:
        return AppColors.amber;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Support Inbox'),
        backgroundColor: Colors.transparent,
      ),
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: SupportService.supportChatsStream(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final chats = snapshot.data ?? [];

          if (chats.isEmpty) {
            return const Center(
              child: Text(
                'No escalated support chats yet.',
                style: TextStyle(color: AppColors.textMuted),
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(18),
            itemCount: chats.length,
            itemBuilder: (context, index) {
              final chat = chats[index];
              final priority = chat['priority']?.toString() ?? 'normal';
              final color = _priorityColor(priority);

              return InkWell(
                borderRadius: BorderRadius.circular(18),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => AdminSupportChatScreen(chat: chat),
                    ),
                  );
                },
                child: Container(
                  margin: const EdgeInsets.only(bottom: 14),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.card,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: color.withOpacity(0.16),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: Icon(Icons.support_agent_outlined, color: color),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  chat['customer_name']?.toString() ?? 'Customer',
                                  style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
                                ),
                                Text(
                                  'Unique ID: ${chat['unique_id'] ?? '-'}',
                                  style: const TextStyle(color: AppColors.textMuted),
                                ),
                              ],
                            ),
                          ),
                          _DetailPill(label: priority.toUpperCase(), color: color),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        chat['issue_summary']?.toString() ?? 'Escalated support chat',
                        style: const TextStyle(height: 1.4),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Tap to join chat',
                        style: TextStyle(color: AppColors.textMuted, fontSize: 12),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class AdminSupportChatScreen extends StatefulWidget {
  final Map<String, dynamic> chat;

  const AdminSupportChatScreen({
    super.key,
    required this.chat,
  });

  @override
  State<AdminSupportChatScreen> createState() => _AdminSupportChatScreenState();
}

class _AdminSupportChatScreenState extends State<AdminSupportChatScreen> {
  final TextEditingController _replyController = TextEditingController();
  final ScrollController _adminChatScrollController = ScrollController();
  StreamSubscription<List<Map<String, dynamic>>>? _adminMessageSubscription;
  Timer? _adminRefreshTimer;
  bool isSending = false;
  bool isLoadingMessages = true;
  List<Map<String, dynamic>> _adminMessages = [];

  String get chatId => widget.chat['id'].toString();

  @override
  void initState() {
    super.initState();
    _listenForAdminMessages();
  }

  Future<void> _refreshAdminMessages() async {
    try {
      final rows = await SupportService.getMessages(chatId);
      if (!mounted) return;
      setState(() {
        _adminMessages = rows;
        isLoadingMessages = false;
      });
      _scrollAdminToBottom();
    } catch (e) {
      debugPrint('Admin message refresh error: $e');
      if (mounted) setState(() => isLoadingMessages = false);
    }
  }

  void _listenForAdminMessages() {
    _adminMessageSubscription?.cancel();
    _adminRefreshTimer?.cancel();

    _refreshAdminMessages();

    _adminMessageSubscription = SupportService.messagesStream(chatId).listen((rows) {
      if (!mounted) return;
      setState(() {
        _adminMessages = rows;
        isLoadingMessages = false;
      });
      _scrollAdminToBottom();
    });

    _adminRefreshTimer = Timer.periodic(const Duration(seconds: 2), (_) {
      if (!mounted) return;
      _refreshAdminMessages();
    });
  }

  void _scrollAdminToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_adminChatScrollController.hasClients) return;
      _adminChatScrollController.animateTo(
        _adminChatScrollController.position.maxScrollExtent + 120,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
      );
    });
  }

  Future<void> _sendTechnicianReply() async {
    final text = _replyController.text.trim();
    if (text.isEmpty || isSending) return;

    setState(() => isSending = true);

    try {
      await SupportService.addMessage(
        chatId: chatId,
        senderRole: 'technician',
        senderName: 'Office Technician',
        message: text,
      );
      _replyController.clear();
      await _refreshAdminMessages();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not send reply. Check Supabase connection.')),
      );
    } finally {
      if (mounted) setState(() => isSending = false);
    }
  }

  @override
  void dispose() {
    _adminMessageSubscription?.cancel();
    _adminRefreshTimer?.cancel();
    _adminChatScrollController.dispose();
    _replyController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.chat['customer_name']?.toString() ?? 'Support Chat'),
        backgroundColor: Colors.transparent,
        actions: [
          TextButton(
            onPressed: () async {
              await SupportService.closeChat(chatId);
              if (context.mounted) Navigator.pop(context);
            },
            child: const Text('Close'),
          ),
        ],
      ),
      body: Column(
        children: [
          Container(
            width: double.infinity,
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.14),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: AppColors.primary.withOpacity(0.35)),
            ),
            child: Text(
              'Issue: ${widget.chat['issue_summary'] ?? 'Escalated support chat'}',
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
          Expanded(
            child: isLoadingMessages
                ? const Center(child: CircularProgressIndicator())
                : ListView.builder(
              controller: _adminChatScrollController,
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              itemCount: _adminMessages.length,
              itemBuilder: (context, index) {
                final msg = _adminMessages[index];
                final role = msg['sender_role']?.toString() ?? '';
                final isTech = role == 'technician';
                final sender = msg['sender_name']?.toString() ?? role;
                final text = msg['message']?.toString() ?? '';
                final hasImage = msg['image_url'] != null;

                return Align(
                  alignment: isTech ? Alignment.centerRight : Alignment.centerLeft,
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.all(13),
                    constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.78),
                    decoration: BoxDecoration(
                      color: isTech ? AppColors.primary : AppColors.card,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: isTech ? AppColors.primary : AppColors.border),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(sender, style: const TextStyle(fontSize: 11, color: AppColors.textMuted)),
                        if (hasImage) ...[
                          const SizedBox(height: 6),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Image.network(
                              msg['image_url'].toString(),
                              height: 160,
                              width: double.infinity,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => const Text('Router image could not load.'),
                            ),
                          ),
                        ],
                        if (text.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Text(text, style: const TextStyle(height: 1.4)),
                        ],
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _replyController,
                    minLines: 1,
                    maxLines: 3,
                    decoration: InputDecoration(
                      hintText: 'Reply as technician...',
                      hintStyle: const TextStyle(color: AppColors.textMuted),
                      filled: true,
                      fillColor: AppColors.card,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: const BorderSide(color: AppColors.border),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                FloatingActionButton(
                  onPressed: isSending ? null : _sendTechnicianReply,
                  backgroundColor: AppColors.primary,
                  child: isSending
                      ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                      : const Icon(Icons.send),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}


class _SupportModeBadge extends StatelessWidget {
  final String label;
  final Color color;

  const _SupportModeBadge({
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.16),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: color.withOpacity(0.35)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 7,
            height: 7,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 11,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color accent;
  final VoidCallback? onTap;

  const _InfoCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.accent,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final child = Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: accent.withOpacity(0.18),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: const TextStyle(
                    color: AppColors.textMuted,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
          if (onTap != null) const Icon(Icons.chevron_right),
        ],
      ),
    );

    if (onTap == null) return child;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: child,
    );
  }
}

class _ShortcutCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final VoidCallback onTap;

  const _ShortcutCard({
    required this.title,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Ink(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: AppColors.primary),
            const SizedBox(height: 12),
            Text(
              title,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }
}

class _DetailPill extends StatelessWidget {
  final String label;
  final Color color;

  const _DetailPill({
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: color.withOpacity(0.14),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: color.withOpacity(0.35)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color == AppColors.amber ? Colors.white : null,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _BillingRow extends StatelessWidget {
  final String label;
  final String value;

  const _BillingRow({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: const TextStyle(color: AppColors.textMuted),
            ),
          ),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}

class _MiniStatChip extends StatelessWidget {
  final IconData icon;
  final String text;

  const _MiniStatChip({
    required this.icon,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.14),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16),
          const SizedBox(width: 8),
          Text(text),
        ],
      ),
    );
  }
}

class _AppTextField extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final IconData icon;
  final bool obscureText;

  const _AppTextField({
    required this.controller,
    required this.hint,
    required this.icon,
    this.obscureText = false,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      obscureText: obscureText,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: AppColors.textMuted),
        prefixIcon: Icon(icon),
        filled: true,
        fillColor: AppColors.card,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppColors.primary),
        ),
      ),
    );
  }
}