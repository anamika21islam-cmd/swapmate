import 'package:flutter/material.dart';

class ChatHeader extends StatelessWidget implements PreferredSizeWidget {
  final String receiverName;
  final String? receiverImageUrl;
  final bool isOnline;
  final String? lastSeen;
  final bool isTyping;

  const ChatHeader({
    super.key,
    required this.receiverName,
    this.receiverImageUrl,
    required this.isOnline,
    this.lastSeen,
    required this.isTyping,
  });

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  String _formatLastSeen(String? timestamp) {
    if (timestamp == null) return 'Offline';
    final time = DateTime.tryParse(timestamp);
    if (time == null) return 'Offline';
    
    final now = DateTime.now();
    final difference = now.difference(time);
    
    if (difference.inMinutes < 1) {
      return 'Last seen just now';
    } else if (difference.inMinutes < 60) {
      return 'Last seen ${difference.inMinutes} minutes ago';
    } else if (difference.inHours < 24) {
      return 'Last seen ${difference.inHours} hours ago';
    } else {
      final local = time.toLocal();
      return 'Last seen ${local.day}/${local.month} at ${local.hour}:${local.minute.toString().padLeft(2, '0')}';
    }
  }

  @override
  Widget build(BuildContext context) {
    final statusText = isTyping 
        ? 'Typing...' 
        : isOnline 
            ? 'Online' 
            : _formatLastSeen(lastSeen);

    return AppBar(
      backgroundColor: Colors.teal.shade700,
      foregroundColor: Colors.white,
      elevation: 2,
      titleSpacing: 0,
      title: Row(
        children: [
          CircleAvatar(
            radius: 20,
            backgroundColor: Colors.white24,
            backgroundImage: receiverImageUrl != null ? NetworkImage(receiverImageUrl!) : null,
            child: receiverImageUrl == null
                ? Text(
                    receiverName.isNotEmpty ? receiverName[0].toUpperCase() : '?',
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                  )
                : null,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  receiverName,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  statusText,
                  style: TextStyle(
                    fontSize: 13,
                    color: isOnline || isTyping ? Colors.greenAccent.shade100 : Colors.white70,
                    fontWeight: isTyping ? FontWeight.bold : FontWeight.normal,
                    fontStyle: isTyping ? FontStyle.italic : FontStyle.normal,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
