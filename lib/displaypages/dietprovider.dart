import 'package:chat_gpt_sdk/chat_gpt_sdk.dart';
import 'package:dash_chat_2/dash_chat_2.dart';
import 'package:flutter/material.dart';
import 'package:kr_fitness/utils/consts.dart';

class DietProvider extends StatefulWidget {
  const DietProvider({super.key});

  @override
  State<DietProvider> createState() => _DietProviderState();
}

class _DietProviderState extends State<DietProvider> {
  final _openAI = OpenAI.instance.build(
      token: OPENAI_API_KEY,
      baseOption: HttpSetup(receiveTimeout: const Duration(seconds: 5)),
      enableLog: true);
  final ChatUser _currentUser =
      ChatUser(id: '1', firstName: 'sai', lastName: 'prasad');
  final ChatUser _gptChatUser =
      ChatUser(id: '2', firstName: 'chat', lastName: 'GPT');

  List<ChatMessage> _messages = <ChatMessage>[];
  List<ChatUser> _typingUsers = <ChatUser>[];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: Colors.white,
        title: Text(
          'Diet Provider',
          style: TextStyle(
              fontSize: 23, color: Colors.black, fontWeight: FontWeight.w500),
        ),
        centerTitle: true,
      ),
      body: DashChat(
        typingUsers: _typingUsers,
        messageOptions: const MessageOptions(
            currentUserContainerColor: Colors.black,
            containerColor: Colors.blue,
            textColor: Colors.white),
        currentUser: _currentUser,
        onSend: (ChatMessage m) {
          getChatResponse(m);
        },
        messages: _messages,
      ),
    );
  }

  Future<void> getChatResponse(ChatMessage m) async {
    setState(() {
      _messages.insert(0, m);
      _typingUsers.add(_gptChatUser);
    });
    List<Messages> _messageHistory = _messages.reversed.map((m) {
      if (m.user == _currentUser) {
        return Messages(role: Role.user, content: m.text);
      } else {
        return Messages(role: Role.assistant, content: m.text);
      }
    }).toList();

    final request = ChatCompleteText(
        model: GptTurbo0631Model(), messages: _messageHistory, maxToken: 200);
    final response = await _openAI.onChatCompletion(request: request);
    for (var element in response!.choices) {
      if (element.message != null) {
        setState(() {
          _messages.insert(
            0,
            ChatMessage(
                user: _gptChatUser,
                createdAt: DateTime.now(),
                text: element.message!.content),
          );
        });
      }
    }
    setState(() {
      _typingUsers.remove(_gptChatUser);
    });
  }
}
