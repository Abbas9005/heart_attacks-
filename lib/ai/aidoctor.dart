import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
// import 'package:intl/intl.dart';
import 'dart:convert';
import 'package:flutter_localizations/flutter_localizations.dart';
// import 'package:shared_preferences/shared_preferences.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'AI Doctor Assistant',
      theme: ThemeData(
        primarySwatch: Colors.teal,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('en', 'US'),
        Locale('ur', 'PK'),
      ],
      home: const AiDoctorChatPage(),
    );
  }
}

class AiDoctorChatPage extends StatefulWidget {
  const AiDoctorChatPage({super.key});

  @override
  State<AiDoctorChatPage> createState() => _AiDoctorChatPageState();
}

class _AiDoctorChatPageState extends State<AiDoctorChatPage> {
  final TextEditingController _controller = TextEditingController();
  bool _isLoading = false;
  bool _isTyping = false;
  bool _isDarkMode = false;
  List<Map<String, String>> _messages = [];
  String _greeting = "";

  static const String apiKey = "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";
  static const String apiUrl = "https://openrouter.ai/api/v1/chat/completions";

  @override
  void initState() {
    super.initState();
    _messages = [
      {
        "role": "system",
        "content":
            "You are a professional, empathetic, and knowledgeable AI Medical Assistant named 'Dr. AI'. "
            "Ask clarifying questions about symptoms, duration, and severity. "
            "Always include a disclaimer that you are an AI and not a replacement for a human doctor. "
            "Respond in a friendly and reassuring tone. "
            "If the user is in Pakistan, provide localized advice for common health concerns like heatstroke, dengue, or malaria."
      },
      {
        "role": "assistant",
        "content":
            "Assalamualaikum, Abbas! I’m Dr. AI, your personal AI Doctor Assistant. "
            "How can I help you today? Please describe your symptoms or concerns.",
      }
    ];
    _greeting = _getGreeting();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _showDisclaimer();
    });
  }

  String _getGreeting() {
    final hour = DateTime.now().toUtc().add(const Duration(hours: 5)).hour;
    if (hour >= 6 && hour < 12) return "Good morning, Abbas!";
    if (hour >= 12 && hour < 17) return "Good afternoon, Abbas!";
    if (hour >= 17 && hour < 22) return "Good evening, Abbas!";
    return "Good night, Abbas!";
  }

  void _showDisclaimer() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Important Disclaimer"),
        content: const Text(
          "This AI is not a substitute for professional medical advice. "
          "Always consult a doctor for serious concerns. "
          "In case of emergency, call 1122 (Pakistan Emergency Helpline).",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("OK"),
          ),
        ],
      ),
    );
  }

  Future<void> sendMessage(String text) async {
    if (text.trim().isEmpty) return;

    setState(() {
      _messages.add({"role": "user", "content": text.trim()});
      _isLoading = true;
      _isTyping = true;
    });
    _controller.clear();

    try {
      if (apiKey.isEmpty) {
        _showError("API Key missing!");
        return;
      }

      const chosenModel = "openai/gpt-3.5-turbo";

      final response = await http.post(
        Uri.parse(apiUrl),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $apiKey",
          "HTTP-Referer": "https://your-app-name.com/",
          "X-Title": "Flutter AI Doc App"
        },
        body: json.encode({
          "model": chosenModel,
          "messages": _messages,
          "temperature": 0.7,
          "max_tokens": 512,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final reply = data['choices'][0]['message']['content'];

        setState(() {
          _messages.add({"role": "assistant", "content": reply});
          _isLoading = false;
          _isTyping = false;
        });
      } else {
        String errMessage = "Server Error: ${response.statusCode}";
        if (response.body.isNotEmpty) {
          try {
            final errJson = jsonDecode(response.body);
            if (errJson['error'] != null && errJson['error']['message'] != null) {
              errMessage += "\n${errJson['error']['message']}";
            }
          } catch (_) {}
        }
        _showError(errMessage);
      }
    } catch (e) {
      _showError("Connection failed. Check your internet. ${e.toString()}");
    }
  }

  void _showError(String error) {
    setState(() {
      _isLoading = false;
      _isTyping = false;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(error), backgroundColor: Colors.red[400]),
    );
  }

  void _showEmergencyContacts() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Emergency Contacts (Pakistan)"),
        content: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: Icon(Icons.local_hospital, color: Colors.red),
              title: Text("Ambulance"),
              subtitle: Text("1122"),
            ),
            ListTile(
              leading: Icon(Icons.volunteer_activism, color: Colors.green),
              title: Text("Edhi Foundation"),
              subtitle: Text("115"),
            ),
            ListTile(
              leading: Icon(Icons.local_police, color: Colors.blue),
              title: Text("Police"),
              subtitle: Text("15"),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Close"),
          ),
        ],
      ),
    );
  }


  void _showHealthTips() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Health Tips for Pakistan"),
        content: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: Icon(Icons.opacity, color: Colors.blue),
              title: Text("Stay hydrated in the heat!"),
            ),
            ListTile(
              leading: Icon(Icons.no_drinks, color: Colors.red),
              title: Text("Avoid sugary drinks."),
            ),
            ListTile(
              leading: Icon(Icons.mosque, color: Colors.green),
              title: Text("Use mosquito repellent to prevent dengue."),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Close"),
          ),
        ],
      ),
    );
  }

  void _clearChat() {
    setState(() {
      _messages.removeWhere((m) => m['role'] != 'system');
    });
  }

  void _toggleTheme() {
    setState(() {
      _isDarkMode = !_isDarkMode;
    });
  }

  @override
  Widget build(BuildContext context) {
    final displayMessages = _messages.where((m) => m['role'] != 'system').toList();

    return Scaffold(
      appBar: AppBar(
        title: Text(_greeting),
        backgroundColor: const Color(0xFF00838F),
        elevation: 4,
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(
              Theme.of(context).brightness == Brightness.dark
                  ? Icons.light_mode
                  : Icons.dark_mode,
              color: Colors.white,
            ),
            onPressed: (){_toggleTheme();
            
            }
          ),
          IconButton(
            icon: const Icon(Icons.delete, color: Colors.white),
            onPressed: _clearChat,
          ),
          IconButton(
            icon: const Icon(Icons.local_hospital, color: Colors.white),
            onPressed: _showEmergencyContacts,
          ),
        ],
      ),
    
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 15),
              itemCount: displayMessages.length,
              itemBuilder: (context, index) {
                final m = displayMessages[index];
                bool isUser = m['role'] == "user";
                return Align(
                  alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
                  child: Container(
                    margin: const EdgeInsets.symmetric(vertical: 5),
                    padding: const EdgeInsets.all(12),
                    constraints: BoxConstraints(
                      maxWidth: MediaQuery.of(context).size.width * 0.8,
                    ),
                    decoration: BoxDecoration(
                      color: isUser ? const Color(0xFF00838F) : Colors.white,
                      borderRadius: BorderRadius.only(
                        topLeft: const Radius.circular(15),
                        topRight: const Radius.circular(15),
                        bottomLeft: isUser ? const Radius.circular(15) : Radius.zero,
                        bottomRight: isUser ? Radius.zero : const Radius.circular(15),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.withOpacity(0.2),
                          spreadRadius: 1,
                          blurRadius: 3,
                          offset: const Offset(0, 1),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          isUser ? "You" : "Dr. AI",
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: isUser ? Colors.white : const Color(0xFF00838F),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          m['content'] ?? "",
                          style: TextStyle(
                            fontSize: 16,
                            color: isUser ? Colors.white : Colors.black87,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          if (_isTyping)
            const Padding(
              padding: EdgeInsets.all(8.0),
              child: Text("Dr. AI is typing...", style: TextStyle(color: Colors.grey)),
            ),
          if (_isLoading)
            const Padding(
              padding: EdgeInsets.all(12.0),
              child: CircularProgressIndicator(
                color: Color(0xFF00838F),
              ),
            ),
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.tips_and_updates, color: Color(0xFF00838F)),
                  onPressed: _showHealthTips,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: _controller,
                    decoration: InputDecoration(
                      hintText: "Describe your symptoms...",
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(25),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    ),
                    onSubmitted: (value) {
                      if (!_isLoading) sendMessage(value);
                    },
                    enabled: !_isLoading,
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: Color(0xFF00838F),
                  ),
                  child: IconButton(
                    icon: const Icon(Icons.send, color: Colors.white),
                    onPressed: _isLoading ? null : () => sendMessage(_controller.text),
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
