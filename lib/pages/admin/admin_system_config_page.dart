import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../config/api_config.dart';
import '../../services/daraja_service.dart';
import '../../services/gemini_service.dart';
import '../../services/telebirr_service.dart';
import '../../theme/ethio_theme.dart';
import '../../services/theme_service.dart';

class AdminSystemConfigPage extends StatefulWidget {
  final bool isEmbedded;
  final int initialTabIndex;

  const AdminSystemConfigPage({
    super.key,
    this.isEmbedded = false,
    this.initialTabIndex = 0,
  });

  static Future<void> open(BuildContext context, {int initialTabIndex = 0}) {
    return Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => AdminSystemConfigPage(
          isEmbedded: false,
          initialTabIndex: initialTabIndex,
        ),
      ),
    );
  }

  @override
  State<AdminSystemConfigPage> createState() => _AdminSystemConfigPageState();
}

class _AdminSystemConfigPageState extends State<AdminSystemConfigPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // Gemini State
  late TextEditingController _geminiKeyCtrl;
  String _selectedGeminiModel = ApiConfig.selectedGeminiModel;
  List<String> _availableGeminiModels = [];

  // Safaricom Ethiopia Controllers
  late TextEditingController _darajaConsumerKeyCtrl;
  late TextEditingController _darajaConsumerSecretCtrl;
  late TextEditingController _darajaPasskeyCtrl;
  late TextEditingController _darajaShortCodeCtrl;
  late bool _darajaIsSandbox;

  // Telebirr Controllers
  late TextEditingController _telebirrAppIdCtrl;
  late TextEditingController _telebirrAppKeyCtrl;
  late TextEditingController _telebirrPublicKeyCtrl;
  late TextEditingController _telebirrShortCodeCtrl;
  late bool _telebirrIsSandbox;

  // Testing states
  bool _testingConnection = false;
  String? _testStatusMessage;
  bool _testSuccess = false;

  // Safaricom Test STK Controllers
  final TextEditingController _stkTestPhoneCtrl = TextEditingController(text: '0770000000');
  final TextEditingController _stkTestAmountCtrl = TextEditingController(text: '10');
  bool _testingStk = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: 3,
      vsync: this,
      initialIndex: widget.initialTabIndex.clamp(0, 2),
    );

    _geminiKeyCtrl = TextEditingController(text: ApiConfig.geminiApiKey);
    _selectedGeminiModel = ApiConfig.selectedGeminiModel;

    GeminiService.listAvailableModels().then((models) {
      if (mounted && models.isNotEmpty) {
        setState(() => _availableGeminiModels = models);
      }
    });

    _darajaConsumerKeyCtrl = TextEditingController(text: ApiConfig.darajaConsumerKey);
    _darajaConsumerSecretCtrl = TextEditingController(text: ApiConfig.darajaConsumerSecret);
    _darajaPasskeyCtrl = TextEditingController(text: ApiConfig.darajaPasskey);
    _darajaShortCodeCtrl = TextEditingController(text: ApiConfig.darajaShortCode);
    _darajaIsSandbox = ApiConfig.isDarajaSandbox;

    _telebirrAppIdCtrl = TextEditingController(text: ApiConfig.telebirrAppId);
    _telebirrAppKeyCtrl = TextEditingController(text: ApiConfig.telebirrAppKey);
    _telebirrPublicKeyCtrl = TextEditingController(text: ApiConfig.telebirrPublicKey);
    _telebirrShortCodeCtrl = TextEditingController(text: ApiConfig.telebirrShortCode);
    _telebirrIsSandbox = ApiConfig.isTelebirrSandbox;
  }

  @override
  void dispose() {
    _tabController.dispose();
    _geminiKeyCtrl.dispose();
    _darajaConsumerKeyCtrl.dispose();
    _darajaConsumerSecretCtrl.dispose();
    _darajaPasskeyCtrl.dispose();
    _darajaShortCodeCtrl.dispose();
    _telebirrAppIdCtrl.dispose();
    _telebirrAppKeyCtrl.dispose();
    _telebirrPublicKeyCtrl.dispose();
    _telebirrShortCodeCtrl.dispose();
    _stkTestPhoneCtrl.dispose();
    _stkTestAmountCtrl.dispose();
    super.dispose();
  }

  void _saveAllSettings() {
    // 1. Gemini
    ApiConfig.customApiKey = _geminiKeyCtrl.text.trim();
    ApiConfig.selectedGeminiModel = _selectedGeminiModel;

    // 2. Safaricom Ethiopia
    ApiConfig.setDarajaConfig(
      consumerKey: _darajaConsumerKeyCtrl.text.trim(),
      consumerSecret: _darajaConsumerSecretCtrl.text.trim(),
      passkey: _darajaPasskeyCtrl.text.trim(),
      shortCode: _darajaShortCodeCtrl.text.trim(),
      isSandbox: _darajaIsSandbox,
    );

    // 3. Telebirr
    ApiConfig.setTelebirrConfig(
      appId: _telebirrAppIdCtrl.text.trim(),
      appKey: _telebirrAppKeyCtrl.text.trim(),
      publicKey: _telebirrPublicKeyCtrl.text.trim(),
      shortCode: _telebirrShortCodeCtrl.text.trim(),
      isSandbox: _telebirrIsSandbox,
    );

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('✅ System configuration saved & applied successfully!'),
        backgroundColor: Colors.green,
        duration: Duration(seconds: 3),
      ),
    );

    if (!widget.isEmbedded) {
      Navigator.pop(context);
    }
  }

  Future<void> _testGeminiConnection() async {
    final key = _geminiKeyCtrl.text.trim();
    if (key.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a Gemini API key to test.')),
      );
      return;
    }

    setState(() {
      _testingConnection = true;
      _testStatusMessage = 'Querying Google Generative AI API and discovering models...';
      _testSuccess = false;
    });

    ApiConfig.customApiKey = key;
    ApiConfig.selectedGeminiModel = _selectedGeminiModel;

    final res = await GeminiService().testConnection(apiKey: key);
    if (!mounted) return;

    final models = (res['availableModels'] as List?)?.cast<String>() ?? [];

    setState(() {
      _testingConnection = false;
      _testSuccess = res['success'] as bool? ?? false;
      _testStatusMessage = _testSuccess
          ? '${res['message']} (Response: "${res['reply']}")'
          : '${res['message']}';
      if (models.isNotEmpty) {
        _availableGeminiModels = models;
        if (res['model'] != null) {
          _selectedGeminiModel = res['model'] as String;
        }
      }
    });
  }

  Future<void> _testDarajaConnection() async {
    setState(() {
      _testingConnection = true;
      _testStatusMessage = 'Testing Safaricom Ethiopia M-Pesa credentials...';
      _testSuccess = false;
    });

    ApiConfig.setDarajaConfig(
      consumerKey: _darajaConsumerKeyCtrl.text.trim(),
      consumerSecret: _darajaConsumerSecretCtrl.text.trim(),
      passkey: _darajaPasskeyCtrl.text.trim(),
      shortCode: _darajaShortCodeCtrl.text.trim(),
      isSandbox: _darajaIsSandbox,
    );

    final res = await DarajaService().testConnection();
    if (!mounted) return;

    setState(() {
      _testingConnection = false;
      _testStatusMessage = res['message'] as String;
      _testSuccess = res['success'] as bool;
    });
  }

  Future<void> _triggerTestStkPush() async {
    final phone = _stkTestPhoneCtrl.text.trim();
    final amount = double.tryParse(_stkTestAmountCtrl.text.trim()) ?? 10.0;

    if (phone.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter an Ethiopian phone number (e.g. 07XXXXXXXX or +251 7...)')),
      );
      return;
    }

    if (!DarajaService.isValidEthiopianPhone(phone)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Note: Safaricom Ethiopia numbers start with 07 (or +251 7). Formatting to Ethiopian format.'),
          backgroundColor: Colors.teal,
          duration: Duration(seconds: 2),
        ),
      );
    }

    setState(() {
      _testingStk = true;
      _testStatusMessage = 'Sending Safaricom Ethiopia STK Push to $phone ($amount ETB)...';
      _testSuccess = false;
    });

    ApiConfig.setDarajaConfig(
      consumerKey: _darajaConsumerKeyCtrl.text.trim(),
      consumerSecret: _darajaConsumerSecretCtrl.text.trim(),
      passkey: _darajaPasskeyCtrl.text.trim(),
      shortCode: _darajaShortCodeCtrl.text.trim(),
      isSandbox: _darajaIsSandbox,
    );

    final res = await DarajaService().initiateStkPush(
      phone: phone,
      amount: amount,
      accountReference: 'TEST-DEBUG',
      transactionDesc: 'Safaricom Ethiopia Debug Test',
    );

    if (!mounted) return;

    setState(() {
      _testingStk = false;
      _testSuccess = res.success;
      _testStatusMessage = res.isSandboxSimulation
          ? '✅ [Ethiopia Sandbox Simulation] STK Push sent successfully for $phone! Checkout ID: ${res.checkoutRequestId}'
          : '✅ Safaricom Ethiopia STK Push dispatched! Customer message: ${res.customerMessage}';
    });
  }

  Future<void> _testTelebirrConnection() async {
    setState(() {
      _testingConnection = true;
      _testStatusMessage = 'Testing Telebirr Developer credentials...';
      _testSuccess = false;
    });

    ApiConfig.setTelebirrConfig(
      appId: _telebirrAppIdCtrl.text.trim(),
      appKey: _telebirrAppKeyCtrl.text.trim(),
      publicKey: _telebirrPublicKeyCtrl.text.trim(),
      shortCode: _telebirrShortCodeCtrl.text.trim(),
      isSandbox: _telebirrIsSandbox,
    );

    final res = await TelebirrService().testConnection();
    if (!mounted) return;

    setState(() {
      _testingConnection = false;
      _testStatusMessage = res['message'] as String;
      _testSuccess = res['success'] as bool;
    });
  }

  void _loadDarajaSandboxPresets() {
    setState(() {
      _darajaIsSandbox = true;
      _darajaShortCodeCtrl.text = '174379';
      _darajaPasskeyCtrl.text = 'bfb279f9aa9bdbcf158e97dd71a467cd2e0c893059b10f78e6b72ada1ed2c919';
      _testStatusMessage = 'Loaded Safaricom Ethiopia Developer Sandbox presets (ShortCode 174379).';
      _testSuccess = true;
    });
  }

  void _loadTelebirrSandboxPresets() {
    setState(() {
      _telebirrIsSandbox = true;
      _telebirrShortCodeCtrl.text = '10011';
      _testStatusMessage = 'Loaded Telebirr Developer Sandbox presets (ShortCode 10011).';
      _testSuccess = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: ThemeService(),
      builder: (context, _) {
        final isDark = ThemeService().isDarkMode;
        final content = Column(
          children: [
            // Header Section
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: EthioColors.forest.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.settings_suggest, color: EthioColors.forest, size: 24),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'System & Gateway Configuration',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: isDark ? Colors.white : EthioColors.charcoal,
                          ),
                        ),
                        Text(
                          'Admin Restricted • Configure Gemini AI & Payment Gateways (Safaricom M-Pesa & Telebirr)',
                          style: TextStyle(
                            fontSize: 12,
                            color: isDark ? Colors.white60 : EthioColors.muted,
                          ),
                        ),
                      ],
                    ),
                  ),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: EthioColors.forest,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    icon: const Icon(Icons.check, size: 18),
                    label: const Text('Save Configuration', style: TextStyle(fontWeight: FontWeight.bold)),
                    onPressed: _saveAllSettings,
                  ),
                ],
              ),
            ),

            // Tab Bar
            Container(
              color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
              child: TabBar(
                controller: _tabController,
                indicatorColor: EthioColors.forest,
                indicatorWeight: 3,
                labelColor: EthioColors.forest,
                unselectedLabelColor: isDark ? Colors.white54 : EthioColors.muted,
                labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                tabs: const [
                  Tab(
                    icon: Icon(Icons.auto_awesome, size: 18),
                    text: 'Gemini AI',
                  ),
                  Tab(
                    icon: Icon(Icons.payments, size: 18),
                    text: 'Safaricom M-Pesa (ET) 🇪🇹',
                  ),
                  Tab(
                    icon: Icon(Icons.phone_android, size: 18),
                    text: 'Telebirr Dev 📱',
                  ),
                ],
              ),
            ),
            Divider(height: 1, color: isDark ? Colors.white12 : EthioColors.divider),

            // Test Status Banner if present
            if (_testStatusMessage != null)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                color: _testSuccess ? Colors.green.shade50 : Colors.amber.shade50,
                child: Row(
                  children: [
                    Icon(
                      _testSuccess ? Icons.check_circle : Icons.info_outline,
                      size: 18,
                      color: _testSuccess ? Colors.green.shade800 : Colors.amber.shade900,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _testStatusMessage!,
                        style: TextStyle(
                          fontSize: 12,
                          color: _testSuccess ? Colors.green.shade900 : Colors.amber.shade900,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

            // Tab Views
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildGeminiTab(),
                  _buildDarajaTab(),
                  _buildTelebirrTab(),
                ],
              ),
            ),
          ],
        );

        if (widget.isEmbedded) {
          return content;
        }

        return Scaffold(
          backgroundColor: isDark ? const Color(0xFF121212) : Colors.grey.shade50,
          appBar: AppBar(
            title: const Text('System Configuration', style: TextStyle(fontWeight: FontWeight.bold)),
            backgroundColor: const Color(0xFF1B4D3E),
            foregroundColor: Colors.white,
            elevation: 0,
          ),
          body: content,
        );
      },
    );
  }

  // ===========================================================================
  // 1. GEMINI AI TAB
  // ===========================================================================
  Widget _buildGeminiTab() {
    final hasKey = _geminiKeyCtrl.text.trim().isNotEmpty;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: hasKey ? Colors.green.shade50 : Colors.amber.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: hasKey ? Colors.green.shade300 : Colors.amber.shade300,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      hasKey ? Icons.bolt : Icons.vpn_key_outlined,
                      size: 14,
                      color: hasKey ? Colors.green.shade800 : Colors.amber.shade800,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      hasKey ? 'Live AI Key Active' : 'Offline Travel Knowledge Mode',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: hasKey ? Colors.green.shade900 : Colors.amber.shade900,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          const Text(
            'Google Gemini API Key',
            style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
          ),
          const SizedBox(height: 6),
          TextField(
            controller: _geminiKeyCtrl,
            decoration: InputDecoration(
              hintText: 'AIzaSy...',
              prefixIcon: const Icon(Icons.key, color: EthioColors.forest),
              suffixIcon: _geminiKeyCtrl.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear, size: 18),
                      onPressed: () {
                        setState(() => _geminiKeyCtrl.clear());
                      },
                    )
                  : null,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 16),

          // Active Gemini Model Selector
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Active Gemini Model',
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
              ),
              if (_availableGeminiModels.isNotEmpty)
                Text(
                  '${_availableGeminiModels.length} models discovered',
                  style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                ),
            ],
          ),
          const SizedBox(height: 6),
          DropdownButtonFormField<String>(
            initialValue: (_availableGeminiModels.contains(_selectedGeminiModel))
                ? _selectedGeminiModel
                : (_availableGeminiModels.isNotEmpty ? _availableGeminiModels.first : 'gemini-3.6-flash'),
            decoration: InputDecoration(
              prefixIcon: const Icon(Icons.smart_toy_outlined, color: EthioColors.forest),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              isDense: true,
            ),
            items: (_availableGeminiModels.isNotEmpty
                    ? _availableGeminiModels
                    : ['gemini-3.6-flash', 'gemini-3.7-flash', 'gemini-3.8-flash', 'gemini-2.5-flash'])
                .map((m) => DropdownMenuItem(
                      value: m,
                      child: Text(
                        '$m ${m.contains('3.6') ? '⭐ (Recommended)' : ''}',
                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
                      ),
                    ))
                .toList(),
            onChanged: (val) {
              if (val != null) {
                setState(() => _selectedGeminiModel = val);
              }
            },
          ),
          const SizedBox(height: 14),

          // Test Gemini Connection Button
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                foregroundColor: EthioColors.forest,
                side: const BorderSide(color: EthioColors.forest),
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              onPressed: _testingConnection ? null : _testGeminiConnection,
              icon: _testingConnection
                  ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Icon(Icons.network_check, size: 16),
              label: const Text(
                'Test Gemini API & Fetch Live Models',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
              ),
            ),
          ),
          const SizedBox(height: 14),

          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: EthioColors.sand.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: EthioColors.sand),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.auto_awesome, size: 18, color: EthioColors.terracotta),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Future-Proof Dynamic Model Discovery',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: EthioColors.charcoal),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'The system dynamically queries Google Generative AI for supported models. Any new models (such as Gemini 3.6, 3.7, 3.8, etc.) or future Gemini updates released by Google are automatically discovered, tested, and prioritized without requiring code changes.',
                        style: TextStyle(fontSize: 11, color: Colors.grey.shade700, height: 1.4),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // 2. SAFARICOM ETHIOPIA (M-PESA) TAB
  // ===========================================================================
  Widget _buildDarajaTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Developer Portal Official Callout for Ethiopia
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.green.shade50,
                  Colors.teal.shade50.withValues(alpha: 0.6),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.green.shade300),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: Colors.green.shade700,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Text(
                        'ETHIOPIA 🇪🇹',
                        style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                      ),
                    ),
                    const SizedBox(width: 10),
                    const Expanded(
                      child: Text(
                        'Safaricom Ethiopia Developer Portal',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF1B5E20)),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                const Text(
                  'Ethiopian developers register apps on the official Safaricom Ethiopia developer portal to obtain credentials for Safaricom Ethiopia M-PESA:',
                  style: TextStyle(fontSize: 12, color: Colors.black87),
                ),
                const SizedBox(height: 10),
                InkWell(
                  onTap: () {
                    Clipboard.setData(const ClipboardData(text: 'https://developer.safaricom.et/apps'));
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Copied https://developer.safaricom.et/apps to clipboard! 📋'),
                        duration: Duration(seconds: 3),
                      ),
                    );
                  },
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.green.shade200),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.link_rounded, size: 18, color: EthioColors.forest),
                        const SizedBox(width: 8),
                        const Expanded(
                          child: Text(
                            'https://developer.safaricom.et/apps',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: EthioColors.forest,
                              decoration: TextDecoration.underline,
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            color: Colors.green.shade100,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.copy, size: 13, color: EthioColors.forest),
                              SizedBox(width: 4),
                              Text('Copy Link', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: EthioColors.forest)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Text(
                      'Endpoints: ',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey.shade700),
                    ),
                    Text(
                      _darajaIsSandbox ? 'apisandbox.safaricom.et (Sandbox)' : 'api.safaricom.et (Live)',
                      style: TextStyle(
                        fontSize: 12,
                        fontFamily: 'monospace',
                        color: _darajaIsSandbox ? Colors.orange.shade800 : Colors.green.shade800,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),

          // Sandbox Mode Switch & Preset Button
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Text('Mode:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                  const SizedBox(width: 8),
                  ChoiceChip(
                    label: const Text('Sandbox (Free)'),
                    selected: _darajaIsSandbox,
                    selectedColor: Colors.green.shade100,
                    onSelected: (val) => setState(() => _darajaIsSandbox = true),
                  ),
                  const SizedBox(width: 6),
                  ChoiceChip(
                    label: const Text('Live / Prod'),
                    selected: !_darajaIsSandbox,
                    selectedColor: Colors.teal.shade100,
                    onSelected: (val) => setState(() => _darajaIsSandbox = false),
                  ),
                ],
              ),
              TextButton.icon(
                onPressed: _loadDarajaSandboxPresets,
                icon: const Icon(Icons.bolt, size: 16, color: EthioColors.forest),
                label: const Text('Use Sandbox Presets', style: TextStyle(fontSize: 12, color: EthioColors.forest)),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Consumer Key
          const Text('Consumer Key', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
          const SizedBox(height: 4),
          TextField(
            controller: _darajaConsumerKeyCtrl,
            decoration: InputDecoration(
              hintText: 'Enter Safaricom Ethiopia App Consumer Key',
              prefixIcon: const Icon(Icons.key, size: 18),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              isDense: true,
            ),
          ),
          const SizedBox(height: 12),

          // Consumer Secret
          const Text('Consumer Secret', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
          const SizedBox(height: 4),
          TextField(
            controller: _darajaConsumerSecretCtrl,
            obscureText: true,
            decoration: InputDecoration(
              hintText: 'Enter Safaricom Ethiopia App Consumer Secret',
              prefixIcon: const Icon(Icons.lock, size: 18),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              isDense: true,
            ),
          ),
          const SizedBox(height: 12),

          // Passkey & ShortCode
          Row(
            children: [
              Expanded(
                flex: 1,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('ShortCode', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                    const SizedBox(height: 4),
                    TextField(
                      controller: _darajaShortCodeCtrl,
                      decoration: InputDecoration(
                        hintText: '174379',
                        prefixIcon: const Icon(Icons.tag, size: 18),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                        isDense: true,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Passkey (M-Pesa Express)', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                    const SizedBox(height: 4),
                    TextField(
                      controller: _darajaPasskeyCtrl,
                      obscureText: true,
                      decoration: InputDecoration(
                        hintText: 'Safaricom Online Passkey...',
                        prefixIcon: const Icon(Icons.password, size: 18),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                        isDense: true,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Test Connection Button
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.green.shade800,
                    side: BorderSide(color: Colors.green.shade400),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  onPressed: _testingConnection ? null : _testDarajaConnection,
                  icon: _testingConnection
                      ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2))
                      : const Icon(Icons.network_check, size: 16),
                  label: const Text('Test Safaricom Ethiopia OAuth Token', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          // Live STK Push Test Box
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.green.shade50.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.green.shade200),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.flash_on_rounded, size: 18, color: Colors.green.shade800),
                    const SizedBox(width: 6),
                    Text(
                      'Ethiopian M-Pesa STK Push Tester',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.green.shade900),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  'Send an immediate test STK Push to verify Safaricom Ethiopia push delivery (07XXXXXXXX or +251 7...):',
                  style: TextStyle(fontSize: 11, color: Colors.grey.shade700),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 6,
                  children: [
                    ActionChip(
                      label: const Text('0770000000', style: TextStyle(fontSize: 10)),
                      backgroundColor: Colors.white,
                      onPressed: () => setState(() => _stkTestPhoneCtrl.text = '0770000000'),
                    ),
                    ActionChip(
                      label: const Text('251700000000', style: TextStyle(fontSize: 10)),
                      backgroundColor: Colors.white,
                      onPressed: () => setState(() => _stkTestPhoneCtrl.text = '251700000000'),
                    ),
                    ActionChip(
                      label: const Text('0712345678', style: TextStyle(fontSize: 10)),
                      backgroundColor: Colors.white,
                      onPressed: () => setState(() => _stkTestPhoneCtrl.text = '0712345678'),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: TextField(
                        controller: _stkTestPhoneCtrl,
                        keyboardType: TextInputType.phone,
                        decoration: InputDecoration(
                          labelText: 'Ethiopian Phone',
                          hintText: '07XXXXXXXX or +251 7...',
                          prefixIcon: const Icon(Icons.phone_android, size: 16),
                          isDense: true,
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      flex: 1,
                      child: TextField(
                        controller: _stkTestAmountCtrl,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          labelText: 'ETB',
                          hintText: '10',
                          isDense: true,
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green.shade700,
                    foregroundColor: Colors.white,
                    minimumSize: const Size(double.infinity, 38),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  onPressed: _testingStk ? null : _triggerTestStkPush,
                  icon: _testingStk
                      ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : const Icon(Icons.send_rounded, size: 16),
                  label: const Text('Send Test STK Push Prompt', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                ),
              ],
            ),
          ),

          const SizedBox(height: 18),

          // Realtime Safaricom Debug Log Viewer
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Row(
                children: [
                  Icon(Icons.terminal_rounded, size: 16, color: EthioColors.charcoal),
                  SizedBox(width: 6),
                  Text('Safaricom Ethiopia Gateway Debug Log', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                ],
              ),
              TextButton(
                onPressed: () {
                  DarajaService.clearLogs();
                  setState(() {});
                },
                child: const Text('Clear', style: TextStyle(fontSize: 11)),
              ),
            ],
          ),
          const SizedBox(height: 4),
          StreamBuilder<List<DarajaDebugLog>>(
            stream: DarajaService.logStream,
            initialData: DarajaService.debugLogs,
            builder: (context, snapshot) {
              final logs = snapshot.data ?? [];
              if (logs.isEmpty) {
                return Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E1E1E),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text(
                    'No gateway events logged yet. Trigger a test STK push or connection test above.',
                    style: TextStyle(color: Colors.white54, fontSize: 11, fontFamily: 'monospace'),
                  ),
                );
              }

              return Container(
                width: double.infinity,
                constraints: const BoxConstraints(maxHeight: 180),
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFF181818),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey.shade800),
                ),
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: logs.length,
                  itemBuilder: (ctx, i) {
                    final log = logs[logs.length - 1 - i];
                    Color levelColor = Colors.greenAccent;
                    if (log.level == 'ERROR') levelColor = Colors.redAccent;
                    if (log.level == 'REQUEST') levelColor = Colors.lightBlueAccent;
                    if (log.level == 'RESPONSE') levelColor = Colors.amberAccent;
                    if (log.level == 'SIMULATION') levelColor = Colors.purpleAccent;

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                '[${log.formattedTime}] ',
                                style: const TextStyle(color: Colors.white38, fontSize: 10, fontFamily: 'monospace'),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                                decoration: BoxDecoration(
                                  color: levelColor.withValues(alpha: 0.2),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  log.level,
                                  style: TextStyle(color: levelColor, fontSize: 9, fontWeight: FontWeight.bold, fontFamily: 'monospace'),
                                ),
                              ),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  log.title,
                                  style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600, fontFamily: 'monospace'),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 2),
                          Text(
                            log.details,
                            style: const TextStyle(color: Colors.white70, fontSize: 10, fontFamily: 'monospace'),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // 3. TELEBIRR DEVELOPER GATEWAY TAB
  // ===========================================================================
  Widget _buildTelebirrTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Text('Mode:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                  const SizedBox(width: 8),
                  ChoiceChip(
                    label: const Text('Sandbox (Free)'),
                    selected: _telebirrIsSandbox,
                    selectedColor: Colors.blue.shade100,
                    onSelected: (val) => setState(() => _telebirrIsSandbox = true),
                  ),
                  const SizedBox(width: 6),
                  ChoiceChip(
                    label: const Text('Live / Prod'),
                    selected: !_telebirrIsSandbox,
                    selectedColor: Colors.teal.shade100,
                    onSelected: (val) => setState(() => _telebirrIsSandbox = false),
                  ),
                ],
              ),
              TextButton.icon(
                onPressed: _loadTelebirrSandboxPresets,
                icon: const Icon(Icons.bolt, size: 16, color: Colors.blue),
                label: const Text('Use Sandbox Presets', style: TextStyle(fontSize: 12, color: Colors.blue)),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // App ID
          const Text('Telebirr App ID', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
          const SizedBox(height: 4),
          TextField(
            controller: _telebirrAppIdCtrl,
            decoration: InputDecoration(
              hintText: 'Enter Telebirr Developer App ID',
              prefixIcon: const Icon(Icons.apps, size: 18),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              isDense: true,
            ),
          ),
          const SizedBox(height: 12),

          // App Key
          const Text('Telebirr App Key', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
          const SizedBox(height: 4),
          TextField(
            controller: _telebirrAppKeyCtrl,
            obscureText: true,
            decoration: InputDecoration(
              hintText: 'Enter Telebirr Developer App Key',
              prefixIcon: const Icon(Icons.key, size: 18),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              isDense: true,
            ),
          ),
          const SizedBox(height: 12),

          // ShortCode
          const Text('ShortCode', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
          const SizedBox(height: 4),
          TextField(
            controller: _telebirrShortCodeCtrl,
            decoration: InputDecoration(
              hintText: '10011',
              prefixIcon: const Icon(Icons.tag, size: 18),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              isDense: true,
            ),
          ),
          const SizedBox(height: 12),

          // Public Key
          const Text('Telebirr Public Key', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
          const SizedBox(height: 4),
          TextField(
            controller: _telebirrPublicKeyCtrl,
            maxLines: 2,
            decoration: InputDecoration(
              hintText: 'MIIBIjANBgkqhkiG9w0BAQEFAAOCAQ8AMIIBCg...',
              prefixIcon: const Icon(Icons.vpn_key, size: 18),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              isDense: true,
            ),
          ),
          const SizedBox(height: 16),

          // Test Connection Button
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.blue.shade800,
                    side: BorderSide(color: Colors.blue.shade400),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  onPressed: _testingConnection ? null : _testTelebirrConnection,
                  icon: _testingConnection
                      ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2))
                      : const Icon(Icons.network_check, size: 16),
                  label: const Text('Test Telebirr Gateway Connection', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
