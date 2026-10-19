import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import '../../controllers/chat_controller.dart';
import '../../core/theme/app_colors.dart';
import '../../models/message_model.dart';
import 'chat_screen.dart';

class ConversationsScreen extends StatefulWidget {
  const ConversationsScreen({super.key});

  @override
  State<ConversationsScreen> createState() => _ConversationsScreenState();
}

class _ConversationsScreenState extends State<ConversationsScreen> {
  final ChatController _chatController = Get.find<ChatController>();
  final TextEditingController _searchController = TextEditingController();
  String _filterQuery = '';
  int _selectedFilterIndex = 0; // 0: All, 1: Dealers, 2: Support

  @override
  void initState() {
    super.initState();
    _chatController.loadChats();
    _searchController.addListener(() {
      setState(() {
        _filterQuery = _searchController.text.trim().toLowerCase();
      });
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  String _formatTime(String rawTime) {
    if (rawTime.isEmpty) return '';
    final dt = DateTime.tryParse(rawTime);
    if (dt == null) return '';
    final now = DateTime.now();
    final diff = now.difference(dt);

    if (diff.inSeconds < 60) {
      return "Just now";
    } else if (diff.inMinutes < 60) {
      return "${diff.inMinutes}m ago";
    } else if (diff.inHours < 24) {
      return "${diff.inHours}h ago";
    } else if (diff.inDays == 1) {
      return "Yesterday";
    } else if (diff.inDays < 7) {
      return "${diff.inDays}d ago";
    } else {
      return "${dt.month}/${dt.day}/${dt.year.toString().substring(2)}";
    }
  }

  void _showNewInquirySheet() {
    final subjectCtrl = TextEditingController();
    final messageCtrl = TextEditingController();

    Get.bottomSheet(
      Container(
        padding: EdgeInsets.all(20.w),
        decoration: BoxDecoration(
          color: context.surfaceBg,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
          border: Border.all(color: context.borderColor),
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40.w,
                  height: 4.h,
                  decoration: BoxDecoration(
                    color: context.borderColor,
                    borderRadius: BorderRadius.circular(2.r),
                  ),
                ),
              ),
              SizedBox(height: 16.h),
              Text(
                "Start New Conversation",
                style: TextStyle(
                  fontSize: 18.sp,
                  fontWeight: FontWeight.bold,
                  color: context.textPrimaryColor,
                ),
              ),
              SizedBox(height: 6.h),
              Text(
                "Send an inquiry to our verified dealer network or concierge support.",
                style: TextStyle(
                  fontSize: 13.sp,
                  color: context.textSecondaryColor,
                ),
              ),
              SizedBox(height: 18.h),
              Text(
                "Subject / Watch Reference",
                style: TextStyle(
                  fontSize: 13.sp,
                  fontWeight: FontWeight.w600,
                  color: context.textPrimaryColor,
                ),
              ),
              SizedBox(height: 6.h),
              TextField(
                controller: subjectCtrl,
                style: TextStyle(color: context.textPrimaryColor, fontSize: 14.sp),
                decoration: InputDecoration(
                  hintText: "e.g. Rolex Submariner inquiry or Order assistance",
                  filled: true,
                  fillColor: context.cardBg,
                  contentPadding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 12.h),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12.r),
                    borderSide: BorderSide(color: context.borderColor),
                  ),
                ),
              ),
              SizedBox(height: 14.h),
              Text(
                "Initial Message",
                style: TextStyle(
                  fontSize: 13.sp,
                  fontWeight: FontWeight.w600,
                  color: context.textPrimaryColor,
                ),
              ),
              SizedBox(height: 6.h),
              TextField(
                controller: messageCtrl,
                maxLines: 3,
                style: TextStyle(color: context.textPrimaryColor, fontSize: 14.sp),
                decoration: InputDecoration(
                  hintText: "Type your questions or details here...",
                  filled: true,
                  fillColor: context.cardBg,
                  contentPadding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 12.h),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12.r),
                    borderSide: BorderSide(color: context.borderColor),
                  ),
                ),
              ),
              SizedBox(height: 20.h),
              SizedBox(
                width: double.infinity,
                height: 48.h,
                child: ElevatedButton(
                  onPressed: () async {
                    final sub = subjectCtrl.text.trim();
                    final msg = messageCtrl.text.trim();
                    if (sub.isEmpty && msg.isEmpty) {
                      Get.snackbar("Required", "Please provide a subject or message.");
                      return;
                    }
                    Get.back();
                    final chat = await _chatController.createOrGetChat(
                      initialMessage: msg.isNotEmpty ? msg : sub,
                    );
                    if (chat != null) {
                      Get.to(() => ChatScreen(
                        chatId: chat.id,
                        title: chat.name.isNotEmpty ? chat.name : (sub.isNotEmpty ? sub : "Concierge Inquiry"),
                        subtitle: chat.watchTitle ?? "Live Conversation",
                      ));
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: context.primaryNav,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
                  ),
                  child: Text(
                    "Start Conversation",
                    style: TextStyle(fontSize: 15.sp, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
              SizedBox(height: 12.h),
            ],
          ),
        ),
      ),
      isScrollControlled: true,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.scaffoldBg,
      appBar: AppBar(
        title: Text(
          "Conversations",
          style: TextStyle(
            fontSize: 18.sp,
            fontWeight: FontWeight.bold,
            color: context.textPrimaryColor,
          ),
        ),
        centerTitle: true,
        backgroundColor: context.surfaceBg,
        elevation: 0.5,
        shadowColor: context.borderColor,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, size: 18.w, color: context.textPrimaryColor),
          onPressed: () => Get.back(),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.add_comment_outlined, color: context.primaryNav, size: 22.w),
            tooltip: "New Conversation",
            onPressed: _showNewInquirySheet,
          ),
        ],
      ),
      body: Column(
        children: [
          // 1. Search Bar
          Container(
            padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 10.h),
            color: context.surfaceBg,
            child: TextField(
              controller: _searchController,
              style: TextStyle(color: context.textPrimaryColor, fontSize: 14.sp),
              decoration: InputDecoration(
                hintText: "Search dealers, watches, or messages...",
                hintStyle: TextStyle(color: context.textSecondaryColor, fontSize: 13.5.sp),
                prefixIcon: Icon(Icons.search_rounded, color: context.textSecondaryColor, size: 20.w),
                suffixIcon: _filterQuery.isNotEmpty
                    ? IconButton(
                        icon: Icon(Icons.clear_rounded, size: 18.w, color: context.textSecondaryColor),
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _filterQuery = '');
                        },
                      )
                    : null,
                filled: true,
                fillColor: context.cardBg,
                contentPadding: EdgeInsets.symmetric(vertical: 10.h),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12.r),
                  borderSide: BorderSide(color: context.borderColor),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12.r),
                  borderSide: BorderSide(color: context.borderColor),
                ),
              ),
            ),
          ),

          // 2. Filter Filter Chips
          Container(
            height: 44.h,
            color: context.surfaceBg,
            padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 4.h),
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                _buildFilterChip(0, "All Conversations"),
                SizedBox(width: 8.w),
                _buildFilterChip(1, "Dealer Inquiries"),
                SizedBox(width: 8.w),
                _buildFilterChip(2, "Support Concierge"),
              ],
            ),
          ),
          Divider(height: 1, color: context.borderColor),

          // 3. Conversation List / Empty State
          Expanded(
            child: Obx(() {
              if (_chatController.isLoadingChats.value && _chatController.chatRooms.isEmpty) {
                return Center(
                  child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(context.primaryNav),
                  ),
                );
              }

              // Filter rooms based on search query and category tab
              final allRooms = _chatController.chatRooms;
              final filteredRooms = allRooms.where((room) {
                if (_selectedFilterIndex == 1) {
                  // Dealer inquiries
                  if (room.name.toLowerCase().contains('support') || room.id == 'concierge') return false;
                } else if (_selectedFilterIndex == 2) {
                  // Support
                  if (!room.name.toLowerCase().contains('support') && room.id != 'concierge') return false;
                }

                if (_filterQuery.isEmpty) return true;
                final matchName = room.name.toLowerCase().contains(_filterQuery);
                final matchMsg = room.lastMessage.toLowerCase().contains(_filterQuery);
                final matchWatch = room.watchTitle?.toLowerCase().contains(_filterQuery) ?? false;
                return matchName || matchMsg || matchWatch;
              }).toList();

              if (filteredRooms.isEmpty) {
                return RefreshIndicator(
                  onRefresh: () async => _chatController.loadChats(),
                  child: ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    children: [
                      SizedBox(height: 80.h),
                      Center(
                        child: Container(
                          width: 80.w,
                          height: 80.w,
                          decoration: BoxDecoration(
                            color: context.primaryNav.withOpacity(0.08),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.forum_outlined,
                            size: 40.w,
                            color: context.primaryNav,
                          ),
                        ),
                      ),
                      SizedBox(height: 20.h),
                      Center(
                        child: Text(
                          _filterQuery.isNotEmpty ? "No matching conversations" : "No Conversations Yet",
                          style: TextStyle(
                            fontSize: 17.sp,
                            fontWeight: FontWeight.bold,
                            color: context.textPrimaryColor,
                          ),
                        ),
                      ),
                      SizedBox(height: 8.h),
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 40.w),
                        child: Text(
                          _filterQuery.isNotEmpty
                              ? "Try searching with different keywords."
                              : "Connect directly with verified dealers about available watches, or chat with our 24/7 Concierge.",
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 13.5.sp,
                            color: context.textSecondaryColor,
                            height: 1.4,
                          ),
                        ),
                      ),
                      SizedBox(height: 24.h),
                      Center(
                        child: ElevatedButton.icon(
                          onPressed: () {
                            Get.to(() => const ChatScreen(
                              chatId: "concierge",
                              title: "Support Concierge",
                              subtitle: "Live Dealer & App Support",
                            ));
                          },
                          icon: const Icon(Icons.support_agent_rounded, size: 18),
                          label: const Text("Chat with Concierge"),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: context.primaryNav,
                            foregroundColor: Colors.white,
                            padding: EdgeInsets.symmetric(horizontal: 22.w, vertical: 12.h),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }

              return RefreshIndicator(
                onRefresh: () async => _chatController.loadChats(),
                child: ListView.separated(
                  physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
                  itemCount: filteredRooms.length,
                  separatorBuilder: (ctx, i) => Divider(height: 1, indent: 76.w, color: context.borderColor),
                  itemBuilder: (ctx, i) {
                    final chat = filteredRooms[i];
                    return _buildConversationTile(chat);
                  },
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(int index, String label) {
    final isSelected = _selectedFilterIndex == index;
    return GestureDetector(
      onTap: () {
        setState(() => _selectedFilterIndex = index);
      },
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 6.h),
        decoration: BoxDecoration(
          color: isSelected ? context.primaryNav : context.cardBg,
          borderRadius: BorderRadius.circular(20.r),
          border: Border.all(
            color: isSelected ? context.primaryNav : context.borderColor,
          ),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12.5.sp,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
            color: isSelected ? Colors.white : context.textSecondaryColor,
          ),
        ),
      ),
    );
  }

  Widget _buildConversationTile(ChatModel chat) {
    final isDark = context.isDarkTheme;
    final timeStr = _formatTime(chat.lastMessageTime);
    final hasUnread = chat.unreadCount > 0;

    return InkWell(
      onTap: () {
        Get.to(() => ChatScreen(
          chatId: chat.id,
          title: chat.name,
          subtitle: chat.watchTitle ?? (chat.id == 'concierge' ? 'Concierge Live Chat' : 'Direct Conversation'),
          avatarUrl: chat.avatarUrl,
        ));
      },
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
        color: hasUnread
            ? (isDark ? const Color(0xFF1E293B).withOpacity(0.5) : const Color(0xFFF0F7FF))
            : Colors.transparent,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Avatar
            Stack(
              clipBehavior: Clip.none,
              children: [
                CircleAvatar(
                  radius: 24.r,
                  backgroundColor: context.primaryNav.withOpacity(0.12),
                  backgroundImage: chat.avatarUrl != null && chat.avatarUrl!.isNotEmpty
                      ? NetworkImage(chat.avatarUrl!)
                      : null,
                  child: chat.avatarUrl == null || chat.avatarUrl!.isEmpty
                      ? Text(
                          chat.name.isNotEmpty ? chat.name[0].toUpperCase() : "D",
                          style: TextStyle(
                            fontSize: 18.sp,
                            fontWeight: FontWeight.bold,
                            color: context.primaryNav,
                          ),
                        )
                      : null,
                ),
                // Indicator for concierge
                if (chat.id == 'concierge' || chat.name.toLowerCase().contains('concierge'))
                  Positioned(
                    right: -2,
                    bottom: -2,
                    child: Container(
                      padding: const EdgeInsets.all(2),
                      decoration: BoxDecoration(
                        color: context.surfaceBg,
                        shape: BoxShape.circle,
                      ),
                      child: Container(
                        width: 10.w,
                        height: 10.w,
                        decoration: const BoxDecoration(
                          color: Color(0xFF10B981),
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            SizedBox(width: 12.w),

            // Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          chat.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 15.sp,
                            fontWeight: hasUnread ? FontWeight.w800 : FontWeight.w600,
                            color: context.textPrimaryColor,
                          ),
                        ),
                      ),
                      SizedBox(width: 8.w),
                      Text(
                        timeStr,
                        style: TextStyle(
                          fontSize: 11.5.sp,
                          color: hasUnread ? context.primaryNav : context.textSecondaryColor,
                          fontWeight: hasUnread ? FontWeight.bold : FontWeight.normal,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 3.h),

                  // Watch Reference Tag if present
                  if (chat.watchTitle != null && chat.watchTitle!.isNotEmpty)
                    Padding(
                      padding: EdgeInsets.only(bottom: 3.h),
                      child: Row(
                        children: [
                          Icon(Icons.watch_outlined, size: 12.w, color: const Color(0xFF0064D2)),
                          SizedBox(width: 3.w),
                          Expanded(
                            child: Text(
                              chat.watchTitle!,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 11.5.sp,
                                fontWeight: FontWeight.w600,
                                color: const Color(0xFF0064D2),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          chat.lastMessage.isNotEmpty ? chat.lastMessage : "Tap to open conversation",
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 13.sp,
                            color: hasUnread ? context.textPrimaryColor : context.textSecondaryColor,
                            fontWeight: hasUnread ? FontWeight.w600 : FontWeight.normal,
                          ),
                        ),
                      ),
                      if (hasUnread) ...[
                        SizedBox(width: 6.w),
                        Container(
                          padding: EdgeInsets.symmetric(horizontal: 7.w, vertical: 2.h),
                          decoration: BoxDecoration(
                            color: context.primaryNav,
                            borderRadius: BorderRadius.circular(10.r),
                          ),
                          child: Text(
                            chat.unreadCount > 99 ? '99+' : chat.unreadCount.toString(),
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 10.5.sp,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
