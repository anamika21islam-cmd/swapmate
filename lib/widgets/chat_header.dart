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
    final localTime = time.toLocal();
    final difference = now.difference(localTime);

    if (difference.inSeconds < 60) {
      return 'Last seen just now';
    } else if (difference.inMinutes < 60) {
      final mins = difference.inMinutes;
      return 'Last seen $mins ${mins == 1 ? 'min' : 'mins'} ago';
    } else if (difference.inHours < 24 &&
        localTime.day == now.day) {
      // Same day — show time
      final hour = localTime.hour > 12
          ? localTime.hour - 12
          : (localTime.hour == 0 ? 12 : localTime.hour);
      final minute = localTime.minute.toString().padLeft(2, '0');
      final ampm = localTime.hour >= 12 ? 'PM' : 'AM';
      return 'Last seen today at $hour:$minute $ampm';
    } else if (difference.inDays == 1 ||
        (now.day - localTime.day == 1 &&
            now.month == localTime.month &&
            now.year == localTime.year)) {
      final hour = localTime.hour > 12
          ? localTime.hour - 12
          : (localTime.hour == 0 ? 12 : localTime.hour);
      final minute = localTime.minute.toString().padLeft(2, '0');
      final ampm = localTime.hour >= 12 ? 'PM' : 'AM';
      return 'Last seen yesterday at $hour:$minute $ampm';
    } else {
      const months = [
        '', 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
        'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
      ];
      final hour = localTime.hour > 12
          ? localTime.hour - 12
          : (localTime.hour == 0 ? 12 : localTime.hour);
      final minute = localTime.minute.toString().padLeft(2, '0');
      final ampm = localTime.hour >= 12 ? 'PM' : 'AM';
      return 'Last seen ${localTime.day} ${months[localTime.month]} at $hour:$minute $ampm';
    }
  }

  @override
  Widget build(BuildContext context) {
    String statusText;
    Color statusColor;

    if (isTyping) {
      statusText = 'Typing...';
      statusColor = Colors.greenAccent.shade100;
    } else if (isOnline) {
      statusText = 'Online';
      statusColor = Colors.greenAccent.shade100;
    } else {
      statusText = _formatLastSeen(lastSeen);
      statusColor = Colors.white60;
    }

    return AppBar(
      backgroundColor: Colors.teal.shade700,
      foregroundColor: Colors.white,
      elevation: 2,
      titleSpacing: 0,
      title: Row(
        children: [
          // Avatar with online indicator
          Stack(
            children: [
              CircleAvatar(
                radius: 21,
                backgroundColor: Colors.white24,
                backgroundImage: receiverImageUrl != null
                    ? NetworkImage(receiverImageUrl!)
                    : null,
                child: receiverImageUrl == null
                    ? Text(
                        receiverName.isNotEmpty
                            ? receiverName[0].toUpperCase()
                            : '?',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      )
                    : null,
              ),
              if (isOnline)
                Positioned(
                  bottom: 1,
                  right: 1,
                  child: Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: Colors.green.shade400,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Colors.teal.shade700,
                        width: 2,
                      ),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(width: 12),
          // Name + status
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  receiverName,
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.2,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  child: Text(
                    statusText,
                    key: ValueKey<String>(statusText),
                    style: TextStyle(
                      fontSize: 12.5,
                      color: statusColor,
                      fontWeight:
                          isTyping ? FontWeight.w600 : FontWeight.normal,
                      fontStyle:
                          isTyping ? FontStyle.italic : FontStyle.normal,
                    ),
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
