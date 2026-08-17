import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../services/chat_service.dart';
import '../pages/chat/conversations_list_page.dart';

class ChatIconButton extends StatelessWidget {
  final Color? color;

  const ChatIconButton({super.key, this.color});

  @override
  Widget build(BuildContext context) {
    final user = AuthService().currentUser;
    if (user == null) {
      return IconButton(
        icon: Icon(Icons.chat_bubble_outline, color: color),
        tooltip: 'Messages & Support',
        onPressed: () => Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const ConversationsListPage()),
        ),
      );
    }

    return StreamBuilder<int>(
      stream: ChatService().getTotalUnreadMessagesCountStream(user.uid),
      builder: (context, snapshot) {
        final count = snapshot.data ?? 0;

        return Stack(
          alignment: Alignment.center,
          children: [
            IconButton(
              icon: Icon(
                count > 0 ? Icons.chat_bubble : Icons.chat_bubble_outline,
                color: count > 0 ? Colors.teal.shade700 : color,
              ),
              tooltip: 'Messages ($count unread)',
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const ConversationsListPage()),
              ),
            ),
            if (count > 0)
              Positioned(
                top: 6,
                right: 6,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.teal.shade700,
                    shape: BoxShape.circle,
                  ),
                  constraints: const BoxConstraints(
                    minWidth: 16,
                    minHeight: 16,
                  ),
                  child: Center(
                    child: Text(
                      count > 99 ? '99+' : count.toString(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}
