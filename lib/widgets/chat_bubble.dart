import 'package:flutter/material.dart';

class ChatBubble extends StatelessWidget {
  final Map<String, dynamic> message;
  final bool isMe;

  const ChatBubble({
    super.key,
    required this.message,
    required this.isMe,
  });

  String _formatTime(String? timestamp) {
    if (timestamp == null) return '';
    final time = DateTime.tryParse(timestamp);
    if (time == null) return '';
    final local = time.toLocal();
    final hour = local.hour > 12
        ? local.hour - 12
        : (local.hour == 0 ? 12 : local.hour);
    final minute = local.minute.toString().padLeft(2, '0');
    final ampm = local.hour >= 12 ? 'PM' : 'AM';
    return '$hour:$minute $ampm';
  }

  /// WhatsApp-style message status indicator.
  /// Only shown for messages sent by the current user (isMe == true).
  Widget _buildStatusIcon(String status) {
    if (!isMe) return const SizedBox.shrink();

    switch (status) {
      case 'sending':
        // Clock icon — message is being uploaded
        return const SizedBox(
          width: 14,
          height: 14,
          child: CircularProgressIndicator(
            strokeWidth: 1.5,
            valueColor: AlwaysStoppedAnimation<Color>(Colors.white60),
          ),
        );

      case 'sent':
        // Single grey tick
        return const Icon(
          Icons.check,
          size: 16,
          color: Colors.white70,
        );

      case 'delivered':
        // Double grey tick (uses a custom stack of two tick icons)
        return _doubleCheck(Colors.white70);

      case 'read':
        // Double blue tick
        return _doubleCheck(Colors.lightBlueAccent);

      case 'failed':
        return const Icon(
          Icons.error_outline,
          size: 14,
          color: Colors.redAccent,
        );

      default:
        return const SizedBox.shrink();
    }
  }

  /// Renders two overlapping check marks (WhatsApp-style double tick).
  Widget _doubleCheck(Color color) {
    return SizedBox(
      width: 20,
      height: 14,
      child: Stack(
        children: [
          Positioned(
            left: 0,
            child: Icon(Icons.check, size: 14, color: color),
          ),
          Positioned(
            left: 6,
            child: Icon(Icons.check, size: 14, color: color),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final status = message['status'] as String? ?? 'sent';
    final isFailed = status == 'failed';
    final isSending = status == 'sending';

    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Opacity(
        opacity: isSending ? 0.75 : 1.0,
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: 3, horizontal: 12),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
          constraints: BoxConstraints(
            maxWidth: MediaQuery.of(context).size.width * 0.75,
          ),
          decoration: BoxDecoration(
            color: isFailed
                ? Colors.red.shade100
                : isMe
                    ? Colors.teal.shade600
                    : Colors.white,
            borderRadius: BorderRadius.only(
              topLeft: const Radius.circular(18),
              topRight: const Radius.circular(18),
              bottomLeft: Radius.circular(isMe ? 18 : 4),
              bottomRight: Radius.circular(isMe ? 4 : 18),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.07),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Message text
              Text(
                message['message'] ?? '',
                style: TextStyle(
                  color: isFailed
                      ? Colors.red.shade900
                      : isMe
                          ? Colors.white
                          : Colors.black87,
                  fontSize: 15.5,
                  height: 1.3,
                ),
              ),
              const SizedBox(height: 3),
              // Time + status row
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    _formatTime(message['created_at']),
                    style: TextStyle(
                      color: isFailed
                          ? Colors.red.shade700
                          : isMe
                              ? Colors.teal.shade100
                              : Colors.grey.shade500,
                      fontSize: 10.5,
                    ),
                  ),
                  if (isMe) ...[
                    const SizedBox(width: 5),
                    _buildStatusIcon(status),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
