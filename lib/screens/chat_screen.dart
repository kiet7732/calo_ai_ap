import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter/scheduler.dart';
import '../providers/today_stats_provider.dart';
import '../providers/chat_provider.dart'; 

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  static const Color primaryColor = Color(0xFFA8D15D);

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    print(" [ChatScreen] build() called"); // LOG UI

    return ChangeNotifierProvider(
      create: (context) {
        print(" [ChatScreen] Tạo ChatProvider mới"); // LOG
        return ChatProvider();
      },
      child: Consumer<ChatProvider>(
        builder: (context, chatProvider, child) {
          
          // INIT AN TOÀN
          if (chatProvider.messages.isEmpty && chatProvider.isLoadingProfile) {
             print(" [ChatScreen] Phát hiện chưa init, đăng ký callback..."); // LOG
             SchedulerBinding.instance.addPostFrameCallback((_) {
                print(" [ChatScreen] Thực thi initializeChat sau khi build xong"); // LOG
                final stats = Provider.of<TodayStatsProvider>(context, listen: false);
                chatProvider.initializeChat(stats);
             });
          }

          return Scaffold(
            backgroundColor: const Color(0xFFF5F7FA), // Nền xám rất nhạt hiện đại
            appBar: AppBar(
              title: const Text("Trợ lý Dinh dưỡng", style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold)),
              backgroundColor: Colors.white,
              elevation: 0.5,
              centerTitle: true,
              automaticallyImplyLeading: false,
            ),
            body: Column(
              children: [
                if (chatProvider.isLoadingProfile)
                  const LinearProgressIndicator(minHeight: 2, color: primaryColor, backgroundColor: Colors.white),
                Expanded(
                  child: ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
                    itemCount: chatProvider.messages.length + (chatProvider.isSending ? 1 : 0),
                    itemBuilder: (context, index) {
                      // Hiển thị indicator đang nhập (loading)
                      if (index == chatProvider.messages.length) {
                        return Padding(
                          padding: const EdgeInsets.only(left: 0, bottom: 12),
                          child: Row(
                            children: [
                              _buildAvatar(isUser: false),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(18),
                                  boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 5, offset: const Offset(0, 2))],
                                ),
                                child: SizedBox(
                                  width: 40,
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                    children: List.generate(3, (i) => Container(
                                      width: 6, height: 6,
                                      decoration: BoxDecoration(color: Colors.grey.shade400, shape: BoxShape.circle),
                                    )),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      }

                      final msg = chatProvider.messages[index];
                      final isUser = msg.isUser;

                      return Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: Row(
                          mainAxisAlignment: isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (!isUser) ...[
                              _buildAvatar(isUser: false),
                              const SizedBox(width: 8),
                            ],
                            Flexible(
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                decoration: BoxDecoration(
                                  color: isUser ? primaryColor : Colors.white,
                                  borderRadius: BorderRadius.only(
                                    topLeft: const Radius.circular(18),
                                    topRight: const Radius.circular(18),
                                    bottomLeft: isUser ? const Radius.circular(18) : const Radius.circular(4),
                                    bottomRight: isUser ? const Radius.circular(4) : const Radius.circular(18),
                                  ),
                                  boxShadow: isUser ? [] : [
                                    BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 5, offset: const Offset(0, 2))
                                  ],
                                ),
                                child: Text(
                                  msg.text,
                                  style: TextStyle(
                                    color: isUser ? Colors.white : Colors.black87,
                                    fontSize: 15,
                                    height: 1.4,
                                  ),
                                ),
                              ),
                            ),
                           // if (isUser) const SizedBox(width: 40),
                          ],
                        ),
                      );
                    },
                  ),
                ),
                
                // Input Area
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    boxShadow: [
                      BoxShadow(color: Colors.black.withOpacity(0.05), offset: const Offset(0, -2), blurRadius: 10),
                    ],
                  ),
                  child: SafeArea(
                    child: Row(
                      children: [
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF0F2F5),
                              borderRadius: BorderRadius.circular(24),
                            ),
                            child: TextField(
                              controller: _controller,
                              textInputAction: TextInputAction.send,
                              onSubmitted: (text) {
                                print("👆 [UI] User submitted: $text");
                                chatProvider.sendMessage(text);
                                _controller.clear();
                                _scrollToBottom();
                              },
                              decoration: const InputDecoration(
                                hintText: "Hỏi về thực đơn, calo...",
                                border: InputBorder.none,
                                hintStyle: TextStyle(color: Colors.grey, fontSize: 14),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        GestureDetector(
                          onTap: () {
                            print("👆 [UI] User pressed send");
                            chatProvider.sendMessage(_controller.text);
                            _controller.clear();
                            _scrollToBottom();
                          },
                          child: Container(
                            padding: const EdgeInsets.all(10),
                            decoration: const BoxDecoration(
                              color: primaryColor,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.send_rounded, color: Colors.white, size: 20),
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildAvatar({required bool isUser}) {
    return Container(
      width: 32, height: 32,
      decoration: BoxDecoration(
        color: isUser ? Colors.blue[100] : Colors.white,
        shape: BoxShape.circle,
        border: isUser ? null : Border.all(color: Colors.grey.shade200),
      ),
      child: Icon(
        isUser ? Icons.person : Icons.smart_toy_outlined,
        size: 18,
        color: isUser ? Colors.blue : primaryColor,
      ),
    );
  }
}