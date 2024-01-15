import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';

Clients clientsFromJson(String str) => Clients.fromJson(json.decode(str));

String clientsToJson(Clients data) => json.encode(data.toJson());

class Clients {
  String id;
  String name;
  String gender;
  Timestamp dob;
  int age;
  String image;
  int contact;

  Clients({
    required this.id,
    required this.name,
    required this.gender,
    required this.dob,
    required this.age,
    required this.image,
    required this.contact,
  });

  factory Clients.fromJson(Map<String, dynamic> json) => Clients(
        id: json['id'],
        name: json["name"],
        gender: json["gender"],
        dob: json["dob"],
        age: json["age"],
        image: json["image"],
        contact: json["contact"],
      );

  Map<String, dynamic> toJson() => {
        "id": id,
        "name": name,
        "gender": gender,
        "dob": dob,
        "age": age,
        "image": image,
        "contact": contact,
      };
}
