import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'dart:html' as html;
import '../../models/chat.dart';
import '../../services/auth_service.dart';
import '../../services/chat_service.dart';
import '../../services/location_service.dart';
import '../../widgets/app_scaffold.dart';
import '../../widgets/snackbar_helper.dart';

class ChatPage extends StatefulWidget {
  final String chatId;
  final String otherUserId;
  final String otherUserName;
  final String otherUserRole; // 'provider', 'tour_guide', 'admin', 'tourist'
  final String channelType;

  const ChatPage({
    super.key,
    required this.chatId,
    required this.otherUserId,
    required this.otherUserName,
    required this.otherUserRole,
    this.channelType = 'provider_tourist',
  });

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final ChatService _chatService = ChatService();
  final AuthService _auth = AuthService();
  final TextEditingController _textCtrl = TextEditingController();
  final ScrollController _scrollCtrl = ScrollController();

  bool _sending = false;

  @override
  void initState() {
    super.initState();
    _markRead();
  }

  @override
  void dispose() {
    _textCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  void _markRead() {
    final user = _auth.currentUser;
    if (user != null) {
      _chatService.markChatAsRead(widget.chatId, user.uid);
    }
  }

  Future<void> _sendMessage({String? textOverride, double? lat, double? lng, bool isEmergency = false}) async {
    final user = _auth.currentUser;
    if (user == null) return;

    final content = textOverride ?? _textCtrl.text.trim();
    if (content.isEmpty && lat == null) return;

    if (textOverride == null) _textCtrl.clear();
    setState(() => _sending = true);

    try {
      final myRole = widget.channelType == 'guide_tourist'
          ? (widget.otherUserRole == 'tour_guide' ? 'tourist' : 'tour_guide')
          : widget.channelType == 'admin_support'
              ? (widget.otherUserRole == 'admin' ? 'tourist' : 'admin')
              : (widget.otherUserRole == 'provider' ? 'tourist' : 'provider');
      await _chatService.sendMessage(
        chatId: widget.chatId,
        senderId: user.uid,
        senderName: user.displayName ?? 'User',
        senderRole: myRole,
        recipientId: widget.otherUserId,
        text: content,
        latitude: lat,
        longitude: lng,
        isEmergency: isEmergency,
      );
      _scrollToBottom();
    } catch (e) {
      if (mounted) SnackbarHelper.show(context, 'Failed to send: $e');
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  Future<void> _shareLocation() async {
    try {
      final loc = await LocationService.getCurrentPositionWeb();
      if (loc != null) {
        final lat = loc['latitude']!;
        final lng = loc['longitude']!;
        await _sendMessage(
          textOverride: '📍 Shared Location (${lat.toStringAsFixed(4)}, ${lng.toStringAsFixed(4)})',
          lat: lat,
          lng: lng,
        );
      } else {
        if (mounted) SnackbarHelper.show(context, 'Could not determine GPS location.');
      }
    } catch (e) {
      if (mounted) SnackbarHelper.show(context, 'Location error: $e');
    }
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollCtrl.hasClients) {
        _scrollCtrl.animateTo(
          _scrollCtrl.position.maxScrollExtent,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
      }
    });
  }

  String get _roleBadge {
    switch (widget.otherUserRole.toLowerCase()) {
      case 'provider':
        return '🏢 Service Provider';
      case 'tour_guide':
        return '🗺️ Tour Guide';
      case 'admin':
        return '👑 Admin Support';
      default:
        return '🧭 Tourist';
    }
  }

  Color get _roleColor {
    switch (widget.otherUserRole.toLowerCase()) {
      case 'provider':
        return Colors.blue.shade700;
      case 'tour_guide':
        return Colors.green.shade700;
      case 'admin':
        return Colors.amber.shade800;
      default:
        return Colors.teal.shade700;
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentUserId = _auth.currentUser?.uid ?? '';

    return AppScaffold(
      title: widget.otherUserName,
      actions: [
        Center(
          child: Container(
            margin: const EdgeInsets.only(right: 12),
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: _roleColor.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: _roleColor.withValues(alpha: 0.5)),
            ),
            child: Text(
              _roleBadge,
              style: TextStyle(color: _roleColor, fontWeight: FontWeight.bold, fontSize: 11),
            ),
          ),
        ),
      ],
      body: Column(
        children: [
          // Messages list
          Expanded(
            child: StreamBuilder<List<ChatMessage>>(
              stream: _chatService.getChatMessagesStream(widget.chatId),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting && !snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                final messages = snapshot.data ?? [];

                if (messages.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.chat_bubble_outline, size: 54, color: Colors.grey.shade400),
                          const SizedBox(height: 12),
                          Text(
                            'Start a conversation with ${widget.otherUserName}',
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Send a greeting or ask questions about bookings and guidance.',
                            style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  );
                }

                return ListView.builder(
                  controller: _scrollCtrl,
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final m = messages[index];
                    final isMe = m.senderId == currentUserId;

                    return Align(
                      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                      child: Container(
                        margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
                        decoration: BoxDecoration(
                          color: m.isEmergency
                              ? Colors.red.shade50
                              : isMe
                                  ? Colors.teal.shade700
                                  : Colors.grey.shade200,
                          borderRadius: BorderRadius.only(
                            topLeft: const Radius.circular(14),
                            topRight: const Radius.circular(14),
                            bottomLeft: isMe ? const Radius.circular(14) : Radius.zero,
                            bottomRight: isMe ? Radius.zero : const Radius.circular(14),
                          ),
                          border: m.isEmergency ? Border.all(color: Colors.red.shade400) : null,
                        ),
                        child: Column(
                          crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                          children: [
                            if (!isMe) ...[
                              Text(
                                m.senderName,
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 11,
                                  color: m.isEmergency ? Colors.red.shade900 : Colors.teal.shade900,
                                ),
                              ),
                              const SizedBox(height: 2),
                            ],
                            Text(
                              m.text,
                              style: TextStyle(
                                color: m.isEmergency
                                    ? Colors.red.shade900
                                    : isMe
                                        ? Colors.white
                                        : Colors.black87,
                                fontSize: 14,
                              ),
                            ),
                            if (m.hasLocation) ...[
                              const SizedBox(height: 6),
                              ElevatedButton.icon(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: isMe ? Colors.white : Colors.teal.shade700,
                                  foregroundColor: isMe ? Colors.teal.shade900 : Colors.white,
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                  minimumSize: Size.zero,
                                ),
                                icon: const Icon(Icons.map, size: 14),
                                label: const Text('Open in Maps', style: TextStyle(fontSize: 11)),
                                onPressed: () {
                                  final url = 'https://www.google.com/maps/search/?api=1&query=${m.latitude},${m.longitude}';
                                  if (kIsWeb) {
                                    html.window.open(url, '_blank');
                                  }
                                },
                              ),
                            ],
                            const SizedBox(height: 2),
                            Text(
                              m.formattedTime,
                              style: TextStyle(
                                fontSize: 10,
                                color: isMe ? Colors.white70 : Colors.grey.shade600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),

          // Preset Quick Responses
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            child: Row(
              children: [
                _quickReplyChip('Hello! 👋'),
                _quickReplyChip('When is check-in? 🏨'),
                _quickReplyChip('I have arrived 📍'),
                _quickReplyChip('Please confirm details ✅'),
              ],
            ),
          ),

          // Text Input Bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 4, offset: const Offset(0, -2)),
              ],
            ),
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.my_location, color: Colors.teal),
                  tooltip: 'Share GPS Location',
                  onPressed: _shareLocation,
                ),
                Expanded(
                  child: TextField(
                    controller: _textCtrl,
                    decoration: const InputDecoration(
                      hintText: 'Type a message...',
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(horizontal: 12),
                    ),
                    onSubmitted: (_) => _sendMessage(),
                  ),
                ),
                IconButton(
                  icon: _sending
                      ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                      : const Icon(Icons.send, color: Colors.teal),
                  onPressed: _sending ? null : () => _sendMessage(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _quickReplyChip(String text) {
    return Padding(
      padding: const EdgeInsets.only(right: 6),
      child: ActionChip(
        label: Text(text, style: const TextStyle(fontSize: 11)),
        onPressed: () => _sendMessage(textOverride: text),
        backgroundColor: Colors.teal.shade50,
      ),
    );
  }
}
