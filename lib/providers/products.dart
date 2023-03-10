import 'dart:convert';
import 'package:eshopingcart/models/http_exception.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import './product.dart';

class Products with ChangeNotifier {
  List<Product> _items = [
    // Product(
    //   id: 'p1',
    //   title: 'Red Shirt',
    //   description: 'A red shirt - it is pretty red!',
    //   price: 29.99,
    //   imageUrl:
    //       'https://cdn.pixabay.com/photo/2016/10/02/22/17/red-t-shirt-1710578_1280.jpg',
    // ),
    // Product(
    //   id: 'p2',
    //   title: 'Trousers',
    //   description: 'A nice pair of trousers.',
    //   price: 59.99,
    //   imageUrl:
    //       'https://upload.wikimedia.org/wikipedia/commons/thumb/e/e8/Trousers%2C_dress_%28AM_1960.022-8%29.jpg/512px-Trousers%2C_dress_%28AM_1960.022-8%29.jpg',
    // ),
    // Product(
    //   id: 'p3',
    //   title: 'Yellow Scarf',
    //   description: 'Warm and cozy - exactly what you need for the winter.',
    //   price: 19.99,
    //   imageUrl:
    //       'https://live.staticflickr.com/4043/4438260868_cc79b3369d_z.jpg',
    // ),
    // Product(
    //   id: 'p4',
    //   title: 'A Pan',
    //   description: 'Prepare any meal you want.',
    //   price: 49.99,
    //   imageUrl:
    //       'https://upload.wikimedia.org/wikipedia/commons/thumb/1/14/Cast-Iron-Pan.jpg/1024px-Cast-Iron-Pan.jpg',
    // ),
  ];
  // var _showFavoritesOnly = false;

  final String authToken;
  final String userId;
  Products(this.authToken, this._items, this.userId);

  List<Product> get items {
    // if (_showFavoritesOnly) {
    //   return _items.where((prodItem) => prodItem.isFavorite).toList();
    // }
    return [..._items];
  }

  List<Product> get favoriteItems {
    return _items.where((prodItem) => prodItem.isFavorite).toList();
  }

  Product findById(String id) {
    return _items.firstWhere((prod) => prod.id == id);
  }

  Future<void> fetchAndSetProducts([bool filterByUser = false]) async {
    final String filterString =
        filterByUser ? "orderBy=\"creatorId\"&equalTo=\"$userId\"" : '';
    var url =
        "https://utopian-button-116208.firebaseio.com/products.json?auth=$authToken&$filterString";

    try {
      final response = await http.get(Uri.parse(url));
      final extractedData = json.decode(response.body) as Map<String, dynamic>;
      if (extractedData == null) {
        return;
      }

      url =
          "https://utopian-button-116208.firebaseio.com/userfavorites/$userId.json?auth=$authToken";

      final favoriteResponse = await http.get(Uri.parse(url));

      final favoriteData =
          json.decode(favoriteResponse.body) as Map<String, dynamic>;

      final List<Product> loadedProds = [];
      extractedData.forEach((prodId, prodData) {
        loadedProds.add(Product(
          id: prodId,
          title: prodData['title'],
          description: prodData['description'],
          price: prodData['price'],
          imageUrl: prodData['imageUrl'],
          isFavorite:
              favoriteData == null ? false : favoriteData[prodId] ?? false,
        ));
      });
      _items = loadedProds;
      notifyListeners();
    } catch (error) {
      throw error;
    }
  }

  Future<void> addProduct(Product product) async {
    final url =
        "https://utopian-button-116208.firebaseio.com/products.json?auth=$authToken";

    final response = await http.post(Uri.parse(url),
        body: json.encode({
          'creatorId': userId,
          'title': product.title,
          'description': product.description,
          'price': product.price,
          'imageUrl': product.imageUrl
        }));

    final newProduct = Product(
        id: json.decode(response.body)['name'],
        title: product.title,
        description: product.description,
        price: product.price,
        imageUrl: product.imageUrl);

    _items.add(newProduct);

    notifyListeners();
  }

  Future<void> updateProduct(String id, Product newProduct) async {
    final prodIndex = _items.indexWhere((prod) => prod.id == id);

    if (prodIndex >= 0) {
      final url =
          "https://utopian-button-116208.firebaseio.com/products/$id.json?auth=$authToken";

      await http.patch(Uri.parse(url),
          body: json.encode({
            'title': newProduct.title,
            'description': newProduct.description,
            'price': newProduct.price,
            'imageUrl': newProduct.imageUrl
          }));
      _items[prodIndex] = newProduct;

      notifyListeners();
    }
  }

  Future<void> deleteProduct(String id) async {
    final url =
        "https://utopian-button-116208.firebaseio.com/products/$id.json?auth=$authToken";

    final existingProdIndex = _items.indexWhere((prod) => prod.id == id);
    Product? existingProduct = _items[existingProdIndex];
    _items.removeAt(existingProdIndex);
    notifyListeners();
    final response = await http.delete(Uri.parse(url));
    if (response.statusCode >= 400) {
      _items.insert(existingProdIndex, existingProduct);
      notifyListeners();
      throw HttpException("Could not delete the product");
    }
    existingProduct = null;
  }
}
