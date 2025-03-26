class ThingSpeakData {
  final String field1; // External Temperature
  final String field2; // Humidity
  final String field3; // Sunlight
  final String field4; // Action
  final String field5; // Heart Rate
  final String field6; // Body Temperature
  final String field7; // Blood Oxygen

  ThingSpeakData({
    required this.field1,
    required this.field2,
    required this.field3,
    required this.field4,
    required this.field5,
    required this.field6,
    required this.field7,
  });

  factory ThingSpeakData.fromJson(Map<String, dynamic> json) {
    return ThingSpeakData(
      field1: json['field1'] ?? '',
      field2: json['field2'] ?? '',
      field3: json['field3'] ?? '',
      field4: json['field4'] ?? '',
      field5: json['field5'] ?? '',
      field6: json['field6'] ?? '',
      field7: json['field7'] ?? '',
    );
  }
}
