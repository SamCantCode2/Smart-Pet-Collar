import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ThingSpeak Reader',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const ThingSpeakReader(),
    );
  }
}

class ThingSpeakReader extends StatefulWidget {
  const ThingSpeakReader({super.key});

  @override
  _ThingSpeakReaderState createState() => _ThingSpeakReaderState();
}

class _ThingSpeakReaderState extends State<ThingSpeakReader> {
  final String apiKey = "ESBOPL9TRLQ42A13";
  final String channelId = "2645017";
  final String baseUrl = "https://api.thingspeak.com/channels";
  Map<String, String> latestData = {
    "External Temperature": "-",
    "Humidity": "-",
    "Sunlight": "-",
    "Activity": "-",
    "Heart Rate": "-",
    "Body Temperature": "-",
    "SPO2": "-"
  };
  String warnings = "No warnings";

  Timer? timer;

  @override
  void initState() {
    super.initState();
    _fetchData(); // Initial data fetch
    timer = Timer.periodic(const Duration(seconds: 10), (Timer t) => _fetchData());
  }

  @override
  void dispose() {
    timer?.cancel();
    super.dispose();
  }

  Future<void> _fetchData() async {
    try {
      final response = await http.get(
        Uri.parse("$baseUrl/$channelId/feeds.json?api_key=$apiKey&results=1"),
      );
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final feeds = data['feeds'] as List<dynamic>;
        if (feeds.isNotEmpty) {
          final latestFeed = feeds.last;
          setState(() {
            latestData["External Temperature"] = latestFeed["field1"] ?? "-";
            latestData["Humidity"] = latestFeed["field2"] ?? "-";
            latestData["Sunlight"] = latestFeed["field3"] ?? "-";
            latestData["Activity"] = _determineActivity(latestFeed["field4"]);
            latestData["Heart Rate"] = latestFeed["field5"] ?? "-";
            latestData["Body Temperature"] = latestFeed["field6"] ?? "-";
            latestData["SPO2"] = latestFeed["field7"] ?? "-";

            // Update warnings based on conditions
            warnings = _generateWarnings(latestFeed);
          });
        }
      }
    } catch (e) {
      setState(() {
        warnings = "Error fetching data: ${e.toString()}";
      });
    }
  }

  String _determineActivity(String? accelerationStr) {
    if (accelerationStr == null || accelerationStr.isEmpty) return "Unknown";

    double? acceleration = double.tryParse(accelerationStr);
    if (acceleration == null) return "Invalid data";

    if (acceleration <= 3.5) {
      return "Walking";
    } else if (acceleration <= 6.5) {
      return "Jogging";
    } else {
      return "Running";
    }
  }

  String _generateWarnings(Map<String, dynamic> feed) {
    // Implement custom warning logic
    final double? bodyTemp = double.tryParse(feed["field6"] ?? "");
    final double? extTemp = double.tryParse(feed["field1"] ?? "");
    final double? hum = double.tryParse(feed["field2"] ?? "");
    final double? sun = double.tryParse(feed["field3"] ?? "");
    final double? heartrate = double.tryParse(feed["field5"] ?? "");
    final double? spo2 = double.tryParse(feed["field7"] ?? "");
    if((heartrate != null && heartrate > 140) && (spo2 != null && spo2 < 92)){
      return "HEART ATTACK IMMINENT OR OCCURRING. PLEASE TEND TO YOUR DOG";
    }
    if((heartrate != null && heartrate > 135) && (bodyTemp != null && bodyTemp > 40)){
      return "STROKE IMMINENT OR OCCURING. PLEASE TEND TO YOUR DOG";
    }
    if((sun != null && sun == 1.0) && (extTemp != null && extTemp > 25.0)){
      return "High temperatures in sunlight. Watch for heatstroke";
    }
    if(spo2 != null && spo2 < 92.0){
      return "Low blood oxygen detected. Possibly impaired lung function.";
    }
    if (bodyTemp != null && bodyTemp > 39.5) {
      return "High body temperature detected! Check for fever!";
    }
    if (bodyTemp != null && bodyTemp < 38.0){
      return "Low body temperature detected!";
    }
    if(extTemp != null && extTemp > 28.0){
      return "High external temperature. Please hydrate";
    }
    if(extTemp != null && extTemp < 15.0){
      return "Low external temperature. Please keep warm";
    }
    if(heartrate != null && heartrate < 80){
      return "Low heartrate. Possible infection or lung issue.";
    }
    return "No warnings";
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("ThingSpeak Reader"),
      ),
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: ListView.builder(
                itemCount: latestData.keys.length,
                itemBuilder: (context, index) {
                  final key = latestData.keys.elementAt(index);
                  return Card(
                    child: ListTile(
                      title: Text(key),
                      trailing: Text(latestData[key] ?? "-"),
                    ),
                  );
                },
              ),
            ),
            const Divider(),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text(
                "Warnings",
                style: Theme.of(context).textTheme.titleLarge,
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text(
                warnings,
                style: const TextStyle(color: Colors.red),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
