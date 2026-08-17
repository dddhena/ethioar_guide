import 'package:flutter/material.dart';
import '../../models/chat.dart';
import '../../services/auth_service.dart';
import '../../services/chat_service.dart';
import '../../widgets/app_scaffold.dart';
import 'chat_page.dart';

class ConversationsListPage extends StatefulWidget {
  const ConversationsListPage({super.key});

  @override
  State<ConversationsListPage> createState() => _ConversationsListPageState();
}

class _ConversationsListPageState extends State<ConversationsListPage> {
  final AuthService _auth = AuthService();
  final ChatService _chatService = ChatService();

  String _filterRole = 'all'; // 'all', 'provider', 'tour_guide', 'admin'
  String _searchQuery = '';

  Future<void> _startAdminSupportChat() async {
    final user = _auth.currentUser;
    if (user == null) return;

    final conv = await _chatService.getOrCreateConversation(
      currentUserId: user.uid,
      currentUserName: user.displayName ?? 'Tourist',
      currentUserRole: 'tourist',
      otherUserId: 'admin-support-desk',
      otherUserName: 'EthioAR Admin Support Desk',
      otherUserRole: 'admin',
      channelType: 'admin_support',
    );

    if (mounted) {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => ChatPage(
            chatId: conv.id,
            otherUserId: 'admin-support-desk',
            otherUserName: 'EthioAR Admin Support Desk',
            otherUserRole: 'admin',
            channelType: 'admin_support',
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = _auth.currentUser;

    if (user == null) {
      return AppScaffold(
        title: 'Messages & Support',
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.chat_outlined, size: 64, color: Colors.grey.shade400),
              const SizedBox(height: 16),
              const Text('Please sign in to view your conversations.', style: TextStyle(fontSize: 16)),
            ],
          ),
        ),
      );
    }

    return AppScaffold(
      title: 'Messages & Inquiries',
      actions: [
        IconButton(
          icon: const Icon(Icons.support_agent),
          tooltip: 'Contact Admin Support',
          onPressed: _startAdminSupportChat,
        ),
      ],
      body: Column(
        children: [
          // Filter chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
            child: Row(
              children: [
                _filterChip('all', 'All Messages'),
                _filterChip('provider', '🏢 Providers'),
                _filterChip('tour_guide', '🗺️ Tour Guides'),
                _filterChip('admin', '👑 Admin Support'),
              ],
            ),
          ),

          // Search bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Search by name or message...',
                prefixIcon: const Icon(Icons.search, size: 20),
                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              ),
              onChanged: (val) => setState(() => _searchQuery = val.trim().toLowerCase()),
            ),
          ),
          const SizedBox(height: 4),

          // Conversations List Stream
          Expanded(
            child: StreamBuilder<List<ChatConversation>>(
              stream: _chatService.getUserConversationsStream(user.uid),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting && !snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                final allList = snapshot.data ?? [];

                final filtered = allList.where((c) {
                  final otherRole = c.getOtherUserRole(user.uid);
                  final otherName = c.getOtherUserName(user.uid).toLowerCase();
                  final lastMsg = c.lastMessage.toLowerCase();

                  final matchesRole = _filterRole == 'all' || otherRole.toLowerCase() == _filterRole;
                  final matchesSearch = _searchQuery.isEmpty || otherName.contains(_searchQuery) || lastMsg.contains(_searchQuery);

                  return matchesRole && matchesSearch;
                }).toList();

                if (filtered.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: Colors.teal.shade50,
                              shape: BoxShape.circle,
                            ),
                            child: Icon(Icons.forum_outlined, size: 64, color: Colors.teal.shade700),
                          ),
                          const SizedBox(height: 18),
                          const Text('No Conversations Yet', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 8),
                          Text(
                            'Message service providers, connect with tour guides, or chat with Admin Support Desk.',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
                          ),
                          const SizedBox(height: 20),
                          ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.teal.shade700,
                              foregroundColor: Colors.white,
                            ),
                            icon: const Icon(Icons.support_agent),
                            label: const Text('Chat with Admin Support'),
                            onPressed: _startAdminSupportChat,
                          ),
                        ],
                      ),
                    ),
                  );
                }

                return ListView.separated(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  itemCount: filtered.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final c = filtered[index];
                    final otherId = c.getOtherUserId(user.uid);
                    final otherName = c.getOtherUserName(user.uid);
                    final otherRole = c.getOtherUserRole(user.uid);
                    final unread = c.getUnreadCount(user.uid);

                    Color roleColor;
                    String roleIcon;

                    switch (otherRole.toLowerCase()) {
                      case 'provider':
                        roleColor = Colors.blue.shade700;
                        roleIcon = '🏢';
                        break;
                      case 'tour_guide':
                        roleColor = Colors.green.shade700;
                        roleIcon = '🗺️';
                        break;
                      case 'admin':
                        roleColor = Colors.amber.shade800;
                        roleIcon = '👑';
                        break;
                      default:
                        roleColor = Colors.teal.shade700;
                        roleIcon = '🧭';
                    }

                    return ListTile(
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => ChatPage(
                              chatId: c.id,
                              otherUserId: otherId,
                              otherUserName: otherName,
                              otherUserRole: otherRole,
                              channelType: c.channelType,
                            ),
                          ),
                        );
                      },
                      leading: Stack(
                        children: [
                          CircleAvatar(
                            radius: 24,
                            backgroundColor: roleColor.withValues(alpha: 0.15),
                            child: Text(
                              roleIcon,
                              style: const TextStyle(fontSize: 20),
                            ),
                          ),
                          if (unread > 0)
                            Positioned(
                              top: 0,
                              right: 0,
                              child: Container(
                                padding: const EdgeInsets.all(4),
                                decoration: BoxDecoration(
                                  color: Colors.red.shade600,
                                  shape: BoxShape.circle,
                                ),
                                constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                                child: Text(
                                  unread > 9 ? '9+' : '$unread',
                                  style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            ),
                        ],
                      ),
                      title: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              otherName,
                              style: TextStyle(
                                fontWeight: unread > 0 ? FontWeight.bold : FontWeight.w600,
                                fontSize: 15,
                              ),
                            ),
                          ),
                          Text(
                            c.timeAgo,
                            style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
                          ),
                        ],
                      ),
                      subtitle: Text(
                        c.lastMessage,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: unread > 0 ? FontWeight.w600 : FontWeight.normal,
                          color: unread > 0 ? Colors.black87 : Colors.grey.shade600,
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _filterChip(String roleKey, String label) {
    final isSelected = _filterRole == roleKey;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: FilterChip(
        label: Text(label, style: TextStyle(fontSize: 12, fontWeight: isSelected ? FontWeight.bold : FontWeight.normal)),
        selected: isSelected,
        selectedColor: Colors.teal.shade100,
        checkmarkColor: Colors.teal.shade800,
        onSelected: (_) => setState(() => _filterRole = roleKey),
      ),
    );
  }
}
