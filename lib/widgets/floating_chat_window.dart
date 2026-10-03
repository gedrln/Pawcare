import 'package:flutter/material.dart';

import '../core/constants/app_constants.dart';
import '../models/pet.dart';
import '../services/pawcare_ai_service.dart';

class FloatingChatWindow extends StatefulWidget {
  final Pet pet;
  final VoidCallback onClose;

  const FloatingChatWindow({
    super.key,
    required this.pet,
    required this.onClose,
  });

  @override
  State<FloatingChatWindow> createState() => _FloatingChatWindowState();
}

class _FloatingChatWindowState extends State<FloatingChatWindow> {
  final TextEditingController _controller = TextEditingController();

  final ScrollController _scrollController = ScrollController();

  final PawcareAiService _aiService = PawcareAiService();

  final List<_Message> _messages = [];

  bool _sending = false;

  @override
  void initState() {
    super.initState();

    _messages.add(
      _Message(
        text:
            'Hi! I’m Pawcare AI. I can help with general pet-care questions about ${widget.pet.name}.',
        fromUser: false,
      ),
    );
  }

  Future<void> _send() async {
    final text = _controller.text.trim();

    if (text.isEmpty || _sending) {
      return;
    }

    _controller.clear();

    final previousMessages = List<_Message>.from(
      _messages,
    );

    setState(() {
      _messages.add(
        _Message(
          text: text,
          fromUser: true,
        ),
      );

      _sending = true;
    });

    _scrollToBottom();

    try {
      final history = previousMessages
          .where(
            (message) => message.text.trim().isNotEmpty,
          )
          .map(
            (message) => {
              'role': message.fromUser ? 'user' : 'assistant',
              'content': message.text,
            },
          )
          .toList();

      final reply = await _aiService.ask(
        message: text,
        pet: widget.pet,
        conversation: history,
      );

      if (!mounted) return;

      setState(() {
        _messages.add(
          _Message(
            text: reply,
            fromUser: false,
          ),
        );

        _sending = false;
      });
    } catch (error) {
      if (!mounted) return;

      setState(() {
        _messages.add(
          const _Message(
            text:
                'I could not connect to Pawcare AI right now. Please make sure the Supabase Edge Function is deployed and your OpenAI API key is configured.',
            fromUser: false,
          ),
        );

        _sending = false;
      });
    }

    _scrollToBottom();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback(
      (_) {
        if (!_scrollController.hasClients) {
          return;
        }

        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
      },
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.sizeOf(context).width;

    final screenHeight = MediaQuery.sizeOf(context).height;

    final windowWidth = screenWidth > 420 ? 370.0 : screenWidth - 32;

    final windowHeight = screenHeight > 760 ? 480.0 : screenHeight * 0.58;

    return Material(
      elevation: 14,
      borderRadius: BorderRadius.circular(24),
      color: Colors.white,
      child: SizedBox(
        width: windowWidth,
        height: windowHeight,
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.fromLTRB(
                16,
                12,
                8,
                12,
              ),
              decoration: const BoxDecoration(
                color: AppConstants.primaryColor,
                borderRadius: BorderRadius.vertical(
                  top: Radius.circular(24),
                ),
              ),
              child: Row(
                children: [
                  const CircleAvatar(
                    radius: 19,
                    backgroundColor: Colors.white24,
                    child: Icon(
                      Icons.pets_rounded,
                      color: Colors.white,
                      size: 21,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Pawcare AI',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                            fontSize: 16,
                          ),
                        ),
                        Text(
                          'About ${widget.pet.name}',
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: widget.onClose,
                    icon: const Icon(
                      Icons.close_rounded,
                    ),
                    color: Colors.white,
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView.builder(
                controller: _scrollController,
                padding: const EdgeInsets.fromLTRB(
                  12,
                  14,
                  12,
                  8,
                ),
                itemCount: _messages.length + (_sending ? 1 : 0),
                itemBuilder: (context, index) {
                  if (_sending && index == _messages.length) {
                    return const _TypingBubble();
                  }

                  return _ChatBubble(
                    message: _messages[index],
                  );
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(
                10,
                6,
                10,
                10,
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      minLines: 1,
                      maxLines: 3,
                      textInputAction: TextInputAction.send,
                      onSubmitted: (_) => _send(),
                      decoration: InputDecoration(
                        hintText: 'Ask about ${widget.pet.name}...',
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 11,
                        ),
                        suffixIcon: IconButton(
                          onPressed: _sending ? null : _send,
                          icon: const Icon(
                            Icons.send_rounded,
                          ),
                          color: AppConstants.primaryColor,
                        ),
                      ),
                    ),
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

class _Message {
  final String text;
  final bool fromUser;

  const _Message({
    required this.text,
    required this.fromUser,
  });
}

class _ChatBubble extends StatelessWidget {
  final _Message message;

  const _ChatBubble({
    required this.message,
  });

  @override
  Widget build(BuildContext context) {
    final isUser = message.fromUser;

    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.sizeOf(context).width * .70,
        ),
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 9,
        ),
        decoration: BoxDecoration(
          color: isUser ? AppConstants.primaryColor : AppConstants.lightPrimary,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: Radius.circular(
              isUser ? 16 : 4,
            ),
            bottomRight: Radius.circular(
              isUser ? 4 : 16,
            ),
          ),
        ),
        child: Text(
          message.text,
          style: TextStyle(
            color: isUser ? Colors.white : AppConstants.darkText,
            fontSize: 12.5,
            height: 1.35,
          ),
        ),
      ),
    );
  }
}

class _TypingBubble extends StatelessWidget {
  const _TypingBubble();

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(
          horizontal: 13,
          vertical: 10,
        ),
        decoration: BoxDecoration(
          color: AppConstants.lightPrimary,
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Text(
          '•••',
          style: TextStyle(
            color: AppConstants.darkText,
            fontWeight: FontWeight.w900,
            letterSpacing: 2,
          ),
        ),
      ),
    );
  }
}
