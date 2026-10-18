import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../controllers/chat_controller.dart';
import '../../core/theme/app_colors.dart';
import '../../models/message_model.dart';

class ChatScreen extends StatefulWidget {
  final String chatId;
  final String title;
  final String? subtitle;
  final String? avatarUrl;

  const ChatScreen({
    super.key,
    required this.chatId,
    required this.title,
    this.subtitle,
    this.avatarUrl,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final ChatController _chatController = Get.find<ChatController>();
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _chatController.openChat(widget.chatId);
  }

  @override
  void dispose() {
    _textController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _handleSend() {
    final text = _textController.text.trim();
    if (text.isEmpty) return;
    _chatController.sendMessage(text);
    _textController.clear();

    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent + 80,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDarkTheme;

    return Scaffold(
      backgroundColor: context.scaffoldBg,
      appBar: AppBar(
        backgroundColor: context.surfaceBg,
        elevation: 1,
        shadowColor: context.borderColor,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, size: 18.w, color: context.textPrimaryColor),
          onPressed: () => Get.back(),
        ),
        title: Row(
          children: [
            CircleAvatar(
              radius: 18.r,
              backgroundColor: const Color(0xFF07274C).withValues(alpha: 0.15),
              backgroundImage: widget.avatarUrl != null && widget.avatarUrl!.isNotEmpty
                  ? NetworkImage(widget.avatarUrl!)
                  : null,
              child: widget.avatarUrl == null || widget.avatarUrl!.isEmpty
                  ? Icon(Icons.storefront_rounded, size: 18.w, color: context.primaryNav)
                  : null,
            ),
            SizedBox(width: 10.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 15.sp,
                      fontWeight: FontWeight.w700,
                      color: context.textPrimaryColor,
                    ),
                  ),
                  Obx(() {
                    if (_chatController.isOtherTyping.value) {
                      return Text(
                        "Typing...",
                        style: TextStyle(
                          fontSize: 11.sp,
                          color: const Color(0xFF10B981),
                          fontWeight: FontWeight.w600,
                        ),
                      );
                    }
                    return Text(
                      widget.subtitle ?? "Verified Dealer",
                      style: TextStyle(
                        fontSize: 11.sp,
                        color: context.textSecondaryColor,
                        fontWeight: FontWeight.w500,
                      ),
                    );
                  }),
                ],
              ),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          // Messages List
          Expanded(
            child: Obx(() {
              if (_chatController.isLoadingMessages.value && _chatController.messages.isEmpty) {
                return Center(
                  child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(context.primaryNav),
                  ),
                );
              }

              if (_chatController.messages.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.chat_bubble_outline_rounded, size: 48.w, color: context.textSecondaryColor),
                      SizedBox(height: 12.h),
                      Text(
                        "Start your conversation with ${widget.title}",
                        style: TextStyle(
                          fontSize: 13.sp,
                          color: context.textSecondaryColor,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                );
              }

              return ListView.builder(
                controller: _scrollController,
                padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
                itemCount: _chatController.messages.length,
                itemBuilder: (ctx, index) {
                  final msg = _chatController.messages[index];
                  return _buildMessageBubble(msg, isDark);
                },
              );
            }),
          ),

          // Message Input Field
          _buildInputBar(context),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(MessageModel msg, bool isDark) {
    final isMe = msg.isMine;

    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: EdgeInsets.only(
          bottom: 8.h,
          left: isMe ? 48.w : 0,
          right: isMe ? 0 : 48.w,
        ),
        padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 10.h),
        decoration: BoxDecoration(
          color: isMe
              ? context.primaryNav
              : (isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9)),
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(16.r),
            topRight: Radius.circular(16.r),
            bottomLeft: Radius.circular(isMe ? 16.r : 4.r),
            bottomRight: Radius.circular(isMe ? 4.r : 16.r),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            Text(
              msg.content,
              style: TextStyle(
                fontSize: 13.5.sp,
                height: 1.35,
                color: isMe
                    ? Colors.white
                    : (isDark ? Colors.white : const Color(0xFF0F172A)),
                fontWeight: FontWeight.w500,
              ),
            ),
            SizedBox(height: 4.h),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  _formatTime(msg.timestamp),
                  style: TextStyle(
                    fontSize: 9.5.sp,
                    color: isMe
                        ? Colors.white.withValues(alpha: 0.65)
                        : context.textSecondaryColor,
                  ),
                ),
                if (isMe) ...[
                  SizedBox(width: 4.w),
                  Icon(
                    msg.isSeen ? Icons.done_all_rounded : Icons.done_rounded,
                    size: 13.sp,
                    color: msg.isSeen ? const Color(0xFF38BDF8) : Colors.white.withValues(alpha: 0.65),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInputBar(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
      decoration: BoxDecoration(
        color: context.surfaceBg,
        border: Border(top: BorderSide(color: context.borderColor)),
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: context.cardBg,
                  borderRadius: BorderRadius.circular(24.r),
                  border: Border.all(color: context.borderColor),
                ),
                padding: EdgeInsets.symmetric(horizontal: 14.w),
                child: TextField(
                  controller: _textController,
                  onChanged: (val) {
                    if (val.trim().isNotEmpty) {
                      _chatController.sendTyping();
                    } else {
                      _chatController.sendStopTyping();
                    }
                  },
                  onSubmitted: (_) => _handleSend(),
                  style: TextStyle(fontSize: 14.sp, color: context.textPrimaryColor),
                  decoration: InputDecoration(
                    hintText: "Type a message...",
                    hintStyle: TextStyle(color: context.textSecondaryColor, fontSize: 13.sp),
                    border: InputBorder.none,
                    isDense: true,
                    contentPadding: EdgeInsets.symmetric(vertical: 10.h),
                  ),
                ),
              ),
            ),
            SizedBox(width: 8.w),
            GestureDetector(
              onTap: _handleSend,
              child: Container(
                width: 42.w,
                height: 42.h,
                decoration: BoxDecoration(
                  color: context.primaryNav,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.arrow_upward_rounded,
                  color: Colors.white,
                  size: 20,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatTime(String timestamp) {
    try {
      final dt = DateTime.parse(timestamp);
      final hour = dt.hour % 12 == 0 ? 12 : dt.hour % 12;
      final minute = dt.minute.toString().padLeft(2, '0');
      final period = dt.hour >= 12 ? 'PM' : 'AM';
      return "$hour:$minute $period";
    } catch (_) {
      return "Now";
    }
  }
}
