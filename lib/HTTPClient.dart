import 'dart:convert';

import 'package:tuple/tuple.dart';
import 'package:http/http.dart' as http;

const String SERVER_API_ADDRESS = "server.fastwash.kro.kr:8080";

Future<Tuple2<String, List<User>>> fetchData(int washerId) async {
    var response = await http.get(Uri.parse('http://${SERVER_API_ADDRESS}/washers/${washerId}'));
    if (response.statusCode == 200) {
      var jsonData = jsonDecode(utf8.decode(response.bodyBytes));
      List<User> fetchedUsers = [];
      for (var user in jsonData['users']) {
        fetchedUsers.add(User.fromJson(user));
      }

      return Tuple2(jsonData['time'], fetchedUsers);
    } else if(response.statusCode == 404) {
      throw Exception("일정을 찾을 수 없음");
    } else {
      throw Exception("알 수 없는 오류입니다");
    }
}

class User {
  final String? bluetoothDeviceName;
  final int id;
  final String name;
  final int webOtpSeed;

  User({
    this.bluetoothDeviceName,
    required this.id,
    required this.name,
    required this.webOtpSeed,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      bluetoothDeviceName: json['bluetoothDeviceName'],
      id: json['id'],
      name: json['name'],
      webOtpSeed: json['webOtpSeed'],
    );
  }
}