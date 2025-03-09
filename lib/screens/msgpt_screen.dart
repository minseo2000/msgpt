import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:markdown_widget/markdown_widget.dart';

class MsgptScreen extends StatefulWidget {
  const MsgptScreen({super.key});

  @override
  State<MsgptScreen> createState() => _MsgptScreenState();
}

class _MsgptScreenState extends State<MsgptScreen> {

  String serverIp = dotenv.get("SERVERIP");

  final TextEditingController _controller = TextEditingController();
  final List<Map<String, dynamic>> _messages = [];
  StreamSubscription<String>? _subscription;
  FocusNode _textFieldFocusNode = FocusNode();
  bool isGenerating = false;
  String currentResponse = "";
  final ScrollController _scrollController = ScrollController();

  void _startStreaming() {
    String inputText = _controller.text.trim();
    if (inputText.isEmpty) return;

    _subscription?.cancel();
    _messages.add({"role": "user", "content": inputText});
    currentResponse = "";
    setState(() {
      isGenerating = true;
    });

    String url = serverIp+"$inputText";

    _subscription = _connectToSSE(url).listen((event) {

      if (event.isNotEmpty) {
        setState(() {
          currentResponse += event;
        });
        _scrollToBottom();
      }
    }, onDone: () {
      setState(() {
        _messages.add({"role": "bot", "content": currentResponse.trim()});
        currentResponse = "";
        isGenerating = false;
      });
      _scrollToBottom();
    }, onError: (error) {
      setState(() {
        _messages.add({"role": "bot", "content": "오류 발생: $error"});
        currentResponse = "";
        isGenerating = false;
      });
    });

    _controller.clear();
    FocusScope.of(context).requestFocus(FocusNode());
  }

  void _scrollToBottom() {
    Future.delayed(Duration(milliseconds: 100), () {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    });
  }

  Stream<String> _connectToSSE(String url) async* {
    final request = http.Request("GET", Uri.parse(url))
      ..headers["Accept"] = "text/event-stream";

    final response = await http.Client().send(request);

    if (response.statusCode == 200) {
      final stream = response.stream.transform(utf8.decoder);
      await for (String line in stream) {

        yield line;
      }
    } else {
      throw Exception("Failed to connect: ${response.statusCode}");
    }
  }

  @override
  void dispose() {
    _subscription?.cancel();
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[200],
      appBar: AppBar(
        title: Text('MSGPT 😊'),
        centerTitle: true,
      ),
      body: Column(
        children: [
          Expanded(
            flex:7,
            child: ListView.builder(
              controller: _scrollController,
              padding: EdgeInsets.all(12),
              itemCount: _messages.length + (isGenerating ? 1 : 0),
              itemBuilder: (context, index) {
                if (index == _messages.length) {
                  return _chatBubble("bot", currentResponse);
                }
                return _chatBubble(
                    _messages[index]["role"]!, _messages[index]["content"]!);
              },
            ),
          ),
          _inputField(),

        ],
      ),
    );
  }

  Widget _chatBubble(String role, String content) {
    bool isUser = role == "user";

    // ✅ 마크다운 이미지 URL 감지
    final RegExp imageRegex = RegExp(r'!\[\]\((https?:\/\/.*\.(?:png|jpg|jpeg|gif|svg))\)');
    final Iterable<Match> matches = imageRegex.allMatches(content);

    // ✅ 감지된 이미지 URL 리스트 추출
    List<String> imageUrls = matches.map((match) => match.group(1)!).toList();
    String textWithoutImages = content.replaceAll(imageRegex, "").trim(); // ✅ 이미지 태그 제거 후 텍스트만 남김

    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: EdgeInsets.symmetric(vertical: 8, horizontal: 12),
        padding: EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isUser ? Colors.grey.shade300 : Colors.white,
          borderRadius: BorderRadius.circular(15),
          boxShadow: [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 4,
              spreadRadius: 1,
            ),
          ],
        ),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.75,
        ),
        child: Column(
          crossAxisAlignment: isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            MarkdownWidget(
              data: textWithoutImages, // ✅ 이미지 제외한 마크다운 텍스트 표시
              shrinkWrap: true,
            ),
            ...imageUrls.map((url) => Padding(
              padding: EdgeInsets.symmetric(vertical: 5),
              child: Image.network(
                url,
                fit: BoxFit.contain,
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return Center(child: CircularProgressIndicator());
                },
                errorBuilder: (context, error, stackTrace) {
                  return Center(child: Text("이미지를 불러올 수 없습니다."));
                },
              ),
            )),
          ],
        ),
      ),
    );
  }

  Widget _inputField() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 4,
            spreadRadius: 1,
          ),
        ],
      ),
      child: Container(
        padding: EdgeInsets.only(
            top: 5.0,
            left: 10.0,
            right: 10.0,
            bottom: 5.0
        ),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(
              color: Colors.grey.shade300
          ),
          borderRadius: BorderRadius.circular(10.0),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.5), // 그림자 색상과 투명도
              spreadRadius: 5, // 그림자 퍼짐 정도
              blurRadius: 10, // 그림자 흐림 정도
              offset: const Offset(3, 3), // 그림자 위치 (x, y)
            ),
          ],
        ),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: TextField(
                    maxLines: 10,
                    minLines: 1,
                    keyboardType: TextInputType.multiline,
                    expands: false,
                    controller: _controller,
                    focusNode: _textFieldFocusNode,
                    decoration: InputDecoration(
                      hintText: "무엇이든지 물어봐주세요 😊",
                      border: InputBorder.none,
                    ),
                    onSubmitted: (_) => _startStreaming(),
                  ),
                ),
              ],
            ),
            GestureDetector(
              onTap: _startStreaming,
              child: Container(
                child: Row(
                  children: [
                    Row(
                      children: [
                        Container(
                          child: IconButton(
                            onPressed: () {},
                            icon: Icon(Icons.add),
                          ),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.grey.shade300),
                          ),
                        ),
                        SizedBox(width: 5.0,),
                      ],
                    ),
                    Expanded(
                      child: Container(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            CircleAvatar(
                              backgroundColor: isGenerating ? Colors.red : Colors.black,
                              radius: 18,
                              child: Icon(isGenerating ? Icons.stop : Icons.arrow_upward_rounded, color: Colors.white, size: 14.0,),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            )
          ],
        ),
      ),
    );
  }
}
