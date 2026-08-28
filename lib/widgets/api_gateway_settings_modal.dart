import 'package:flutter/material.dart';
import '../config/api_config.dart';
import '../services/daraja_service.dart';
import '../services/telebirr_service.dart';
import '../theme/ethio_theme.dart';

class ApiGatewaySettingsModal extends StatefulWidget {
  final int initialTabIndex;

  const ApiGatewaySettingsModal({
    super.key,
    this.initialTabIndex = 0,
  });

  static Future<void> show(BuildContext context, {int initialTabIndex = 0}) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => ApiGatewaySettingsModal(initialTabIndex: initialTabIndex),
    );
  }

  @override
  State<ApiGatewaySettingsModal> createState() => _ApiGatewaySettingsModalState();
}

class _ApiGatewaySettingsModalState extends State<ApiGatewaySettingsModal>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // Gemini Controllers
  late TextEditingController _geminiKeyCtrl;

  // Daraja Controllers
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

  bool _testingConnection = false;
  String? _testStatusMessage;
  bool _testSuccess = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: 3,
      vsync: this,
      initialIndex: widget.initialTabIndex.clamp(0, 2),
    );

    // Init Gemini
    _geminiKeyCtrl = TextEditingController(text: ApiConfig.geminiApiKey);

    // Init Daraja
    _darajaConsumerKeyCtrl = TextEditingController(text: ApiConfig.darajaConsumerKey);
    _darajaConsumerSecretCtrl = TextEditingController(text: ApiConfig.darajaConsumerSecret);
    _darajaPasskeyCtrl = TextEditingController(text: ApiConfig.darajaPasskey);
    _darajaShortCodeCtrl = TextEditingController(text: ApiConfig.darajaShortCode);
    _darajaIsSandbox = ApiConfig.isDarajaSandbox;

    // Init Telebirr
    _telebirrAppIdCtrl = TextEditingController(text: ApiConfig.telebirrAppId);
    _telebirrAppKeyCtrl = TextEditingController(text: ApiConfig.telebirrAppKey);
    _telebirrPublicKeyCtrl = TextEditingController(text: ApiConfig.telebirrPublicKey);
    _telebirrShortCodeCtrl = TextEditingController(text: ApiConfig.telebirrShortCode);
    _telebirrIsSandbox = ApiConfig.isTelebirrSandbox;
  }

  // Daraja Test STK Controllers
  final TextEditingController _stkTestPhoneCtrl = TextEditingController(text: '0712345678');
  final TextEditingController _stkTestAmountCtrl = TextEditingController(text: '10');
  bool _testingStk = false;

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

    // 2. Daraja
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
        content: Text('✅ Gateway & API settings updated successfully!'),
        backgroundColor: EthioColors.forest,
        duration: Duration(seconds: 2),
      ),
    );

    Navigator.pop(context);
  }

  Future<void> _testDarajaConnection() async {
    setState(() {
      _testingConnection = true;
      _testStatusMessage = 'Testing Safaricom Daraja credentials...';
      _testSuccess = false;
    });

    // Temporarily apply current inputs
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

    setState(() {
      _testingStk = true;
      _testStatusMessage = 'Sending Safaricom Daraja STK Push to $phone ($amount ETB)...';
      _testSuccess = false;
    });

    // Apply configuration
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
      transactionDesc: 'Safaricom Debugger Test',
    );

    if (!mounted) return;

    setState(() {
      _testingStk = false;
      _testSuccess = res.success;
      _testStatusMessage = res.isSandboxSimulation
          ? '✅ [Sandbox Simulation] STK Push simulated successfully for $phone! Checkout ID: ${res.checkoutRequestId}'
          : '✅ Safaricom STK Push dispatched! Customer message: ${res.customerMessage}';
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
      _testStatusMessage = 'Loaded Daraja Developer Sandbox presets (ShortCode 174379).';
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
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.88,
      ),
      margin: EdgeInsets.only(bottom: bottomInset),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag Handle
          const SizedBox(height: 12),
          Container(
            width: 44,
            height: 4,
            decoration: BoxDecoration(
              color: EthioColors.divider,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 12),

          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: EthioColors.forest.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.security, color: EthioColors.forest, size: 22),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'API & Payment Gateways',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: EthioColors.charcoal),
                      ),
                      Text(
                        'Safaricom M-Pesa & Telebirr • Safe for GitHub commits',
                        style: TextStyle(fontSize: 12, color: EthioColors.muted),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: EthioColors.muted),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),

          const SizedBox(height: 12),

          // Tab Bar
          TabBar(
            controller: _tabController,
            indicatorColor: EthioColors.forest,
            indicatorWeight: 3,
            labelColor: EthioColors.forest,
            unselectedLabelColor: EthioColors.muted,
            labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
            tabs: const [
              Tab(
                icon: Icon(Icons.auto_awesome, size: 18),
                text: 'Gemini AI',
              ),
              Tab(
                icon: Icon(Icons.payments, size: 18),
                text: 'Daraja M-Pesa',
              ),
              Tab(
                icon: Icon(Icons.phone_android, size: 18),
                text: 'Telebirr Dev',
              ),
            ],
          ),
          const Divider(height: 1, color: EthioColors.divider),

          // Tab Content
          Flexible(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildGeminiTab(),
                _buildDarajaTab(),
                _buildTelebirrTab(),
              ],
            ),
          ),

          // Test Status Banner if present
          if (_testStatusMessage != null)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              color: _testSuccess ? Colors.green.shade50 : Colors.amber.shade50,
              child: Row(
                children: [
                  Icon(
                    _testSuccess ? Icons.check_circle : Icons.info_outline,
                    size: 16,
                    color: _testSuccess ? Colors.green.shade800 : Colors.amber.shade900,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _testStatusMessage!,
                      style: TextStyle(
                        fontSize: 12,
                        color: _testSuccess ? Colors.green.shade900 : Colors.amber.shade900,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),

          // Action Buttons Footer
          Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              border: Border(top: BorderSide(color: EthioColors.divider)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      side: const BorderSide(color: EthioColors.divider),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Cancel', style: TextStyle(color: EthioColors.charcoal)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: EthioColors.forest,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    onPressed: _saveAllSettings,
                    child: const Text('Save & Apply Settings', style: TextStyle(fontWeight: FontWeight.bold)),
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
  // 1. GEMINI AI TAB
  // ===========================================================================
  Widget _buildGeminiTab() {
    final hasKey = _geminiKeyCtrl.text.trim().isNotEmpty;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
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
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: EthioColors.sand.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.info_outline, size: 16, color: EthioColors.charcoal),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Your API key is kept locally in memory and never checked into GitHub. Obtain a free key from Google AI Studio (aistudio.google.com).',
                    style: TextStyle(fontSize: 12, color: EthioColors.charcoal),
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
  // 2. SAFARICOM DARAJA (M-PESA) TAB
  // ===========================================================================
  Widget _buildDarajaTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
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
          const SizedBox(height: 12),

          // Consumer Key
          const Text('Consumer Key', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
          const SizedBox(height: 4),
          TextField(
            controller: _darajaConsumerKeyCtrl,
            decoration: InputDecoration(
              hintText: 'Enter Daraja App Consumer Key',
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
              hintText: 'Enter Daraja App Consumer Secret',
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
              const SizedBox(width: 10),
              Expanded(
                flex: 2,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Passkey (Lipa Na M-Pesa)', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                    const SizedBox(height: 4),
                    TextField(
                      controller: _darajaPasskeyCtrl,
                      obscureText: true,
                      decoration: InputDecoration(
                        hintText: 'Online Passkey...',
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
          const SizedBox(height: 14),

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
                  label: const Text('Test OAuth Token Connection', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),

          const SizedBox(height: 18),

          // Live STK Push Test Box
          Container(
            padding: const EdgeInsets.all(14),
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
                      'Live STK Push Debug Tester',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.green.shade900),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  'Send an immediate test STK Push to verify Safaricom push delivery:',
                  style: TextStyle(fontSize: 11, color: Colors.grey.shade700),
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
                          labelText: 'Test Phone',
                          hintText: '0712345678',
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

          const SizedBox(height: 16),

          // Realtime Safaricom Debug Log Viewer
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Row(
                children: [
                  Icon(Icons.terminal_rounded, size: 16, color: EthioColors.charcoal),
                  SizedBox(width: 6),
                  Text('Safaricom Gateway Debug Log', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
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
                    final log = logs[logs.length - 1 - i]; // Newest first
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
      padding: const EdgeInsets.all(20),
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
          const SizedBox(height: 12),

          // App ID
          const Text('Telebirr App ID', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
          const SizedBox(height: 4),
          TextField(
            controller: _telebirrAppIdCtrl,
            decoration: InputDecoration(
              hintText: 'e.g. 20240101000000000',
              prefixIcon: const Icon(Icons.badge, size: 18),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              isDense: true,
            ),
          ),
          const SizedBox(height: 12),

          // App Key
          const Text('Telebirr App Key / Secret', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
          const SizedBox(height: 4),
          TextField(
            controller: _telebirrAppKeyCtrl,
            obscureText: true,
            decoration: InputDecoration(
              hintText: 'Enter Telebirr App Key',
              prefixIcon: const Icon(Icons.lock, size: 18),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              isDense: true,
            ),
          ),
          const SizedBox(height: 12),

          // ShortCode
          const Text('ShortCode / Merchant Code', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
          const SizedBox(height: 4),
          TextField(
            controller: _telebirrShortCodeCtrl,
            decoration: InputDecoration(
              hintText: '10011',
              prefixIcon: const Icon(Icons.numbers, size: 18),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              isDense: true,
            ),
          ),
          const SizedBox(height: 14),

          // Test Button
          OutlinedButton.icon(
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.blue.shade800,
              side: BorderSide(color: Colors.blue.shade400),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: _testingConnection ? null : _testTelebirrConnection,
            icon: _testingConnection
                ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2))
                : const Icon(Icons.network_check, size: 16),
            label: const Text('Test Telebirr Developer Connection'),
          ),
        ],
      ),
    );
  }
}
