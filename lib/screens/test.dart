import 'dart:convert';
import 'dart:async';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';


class ChatScreen extends StatefulWidget {
  final String userId;
  ChatScreen({required this.userId});

  @override
  _ChatScreenState createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final String serverUrl = "http://127.0.0.1:5000";
  List<String> messages = [];
  StreamSubscription? _subscription;

  @override
  void initState() {
    super.initState();
    subscribeToEvents(widget.userId);
  }

  void sendMessage(String content) async {
    var response = await http.post(
      Uri.parse("$serverUrl/send_message"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        "user_id": widget.userId,
        "message_id": "msg_123",
        "content": content
      }),
    );

    if (response.statusCode == 200) {
      print("Message sent!");
    } else {
      print("Error sending message: ${response.body}");
    }
  }

  void finishMessage() async {
    var response = await http.post(
      Uri.parse("$serverUrl/finish_message"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        "user_id": widget.userId,
        "message_id": "msg_123"
      }),
    );

    if (response.statusCode == 200) {
      print("Message finished!");
    } else {
      print("Error finishing message: ${response.body}");
    }
  }

  void subscribeToEvents(String userId) async {
    var request = http.Request("GET", Uri.parse("$serverUrl/events/$userId"));
    var response = await request.send();

    _subscription = response.stream
        .transform(utf8.decoder)
        .transform(LineSplitter())
        .listen((data) {
      if (data.startsWith("data: ")) {
        String jsonStr = data.substring(6);
        Map<String, dynamic> event = jsonDecode(jsonStr);

        if (event.containsKey("v")) {
          setState(() {
            messages.add(event["v"]);
          });
        }
      }
    });
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("SSE Chat (${widget.userId})")),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              itemCount: messages.length,
              itemBuilder: (context, index) {
                return ListTile(
                  title: Text(messages[index]),
                );
              },
            ),
          ),
          TextField(
            onSubmitted: (text) {
              print(text);
              sendMessage(text);
            },
            decoration: InputDecoration(labelText: "Send a message"),
          ),
          ElevatedButton(
            onPressed: finishMessage,
            child: Text("Finish Message"),
          )
        ],
      ),
    );
  }
}
