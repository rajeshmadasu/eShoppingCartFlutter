import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class Product with ChangeNotifier {
  final String id;
  final String title;
  final String description;
  final double price;
  final String imageUrl;

  bool isFavorite;

  Product(
      {required this.id,
      required this.title,
      required this.description,
      required this.price,
      required this.imageUrl,
      this.isFavorite = false});

  Future<void> toggleFavoritesStatus(String authToken, String userId) async {
    final oldStatus = isFavorite;
    isFavorite = !isFavorite;
    notifyListeners();

    final url =
        "https://utopian-button-116208.firebaseio.com/userfavorites/$userId/$id.json?auth=$authToken";

    try {
      http.put(Uri.parse(url),
          body: json.encode(
            isFavorite,
          ));
    } catch (error) {
      throw error;
    }
  }
}
