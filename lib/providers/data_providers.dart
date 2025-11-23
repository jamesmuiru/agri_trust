import 'dart:io';
import 'package:flutter/foundation.dart'; 
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart' hide Order; 
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart'; 
import '../models/models.dart';

class ProductProvider extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  List<Product> _products = [];
  List<Product> get products => _products;

  Future<void> loadProducts() async {
    try {
      final snapshot = await _firestore
          .collection('products')
          .orderBy('createdAt', descending: true)
          .get();

      _products = snapshot.docs
          .map((doc) => Product.fromMap(doc.data(), doc.id))
          .toList();
      notifyListeners();
    } catch (e) {
      print("Error loading products: $e");
    }
  }

  Future<void> loadFarmerProducts(String farmerId) async {
    try {
      final snapshot = await _firestore
          .collection('products')
          .where('farmerId', isEqualTo: farmerId)
          .orderBy('createdAt', descending: true)
          .get();

      _products = snapshot.docs
          .map((doc) => Product.fromMap(doc.data(), doc.id))
          .toList();
      notifyListeners();
    } catch (e) {
      print("Error loading farmer products: $e");
    }
  }

  Future<String?> addProduct(Product product, List<XFile> imageFiles) async {
    try {
      // ⚠️ Images Skipped for Free Tier stability
      List<String> imageUrls = [];

      final updatedProduct = Product(
        farmerId: product.farmerId,
        farmerName: product.farmerName,
        name: product.name,
        description: product.description,
        pricePerUnit: product.pricePerUnit,
        unit: product.unit,
        imageUrls: imageUrls,
        photoTakenDate: DateTime.now(),
        quantity: product.quantity,
        location: product.location,
        createdAt: DateTime.now(),
      );

      await _firestore.collection('products').add(updatedProduct.toMap());
      await loadProducts();
      return null;
    } catch (e) {
      print('Error adding product: $e');
      return e.toString();
    }
  }

  Future<String?> updateProductStock(String productId, double newQuantity) async {
    try {
      await _firestore.collection('products').doc(productId).update({
        'quantity': newQuantity,
      });
      await loadProducts(); 
      return null;
    } catch (e) {
      return e.toString();
    }
  }
}

class OrderProvider extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  List<Order> _orders = [];
  List<Order> get orders => _orders;

  Future<void> loadCustomerOrders(String customerId) async {
    try {
      final snapshot = await _firestore
          .collection('orders')
          .where('customerId', isEqualTo: customerId)
          .orderBy('createdAt', descending: true)
          .get();
      
      _orders = snapshot.docs.map((doc) => Order.fromMap(doc.data(), doc.id)).toList();
      notifyListeners();
    } catch (e) { print("Error loading customer orders: $e"); }
  }

  Future<void> loadFarmerOrders(String farmerId) async {
    try {
      final snapshot = await _firestore
          .collection('orders')
          .where('farmerId', isEqualTo: farmerId)
          .orderBy('createdAt', descending: true)
          .get();
      
      _orders = snapshot.docs.map((doc) => Order.fromMap(doc.data(), doc.id)).toList();
      notifyListeners();
    } catch (e) { print("Error loading farmer orders: $e"); }
  }

  Future<void> loadAvailableDeliveries() async {
    try {
      final snapshot = await _firestore
          .collection('orders')
          .where('status', isEqualTo: 'accepted')
          .where('deliveryPersonId', isNull: true)
          .orderBy('createdAt', descending: true)
          .get();
      
      _orders = snapshot.docs.map((doc) => Order.fromMap(doc.data(), doc.id)).toList();
      notifyListeners();
    } catch (e) { print("Error loading available deliveries: $e"); }
  }

  Future<void> loadDeliveryPersonOrders(String deliveryPersonId) async {
    try {
      // Simplified query to avoid index issues, sort locally
      final snapshot = await _firestore
          .collection('orders')
          .where('deliveryPersonId', isEqualTo: deliveryPersonId)
          .get();
      
      _orders = snapshot.docs.map((doc) => Order.fromMap(doc.data(), doc.id)).toList();
      _orders.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      notifyListeners();
    } catch (e) { print("Error loading driver orders: $e"); }
  }

  // ⭐️ TRANSACTIONAL ORDER PLACEMENT
  Future<String?> placeOrder(Order order) async {
    try {
      await _firestore.runTransaction((transaction) async {
        DocumentReference productRef = _firestore.collection('products').doc(order.productId);
        DocumentSnapshot productSnapshot = await transaction.get(productRef);

        if (!productSnapshot.exists) {
          throw Exception("Product does not exist!");
        }

        double currentStock = (productSnapshot.get('quantity') ?? 0).toDouble();
        if (currentStock < order.quantity) {
          throw Exception("Not enough stock! Only ${currentStock} left.");
        }

        double newStock = currentStock - order.quantity;
        transaction.update(productRef, {'quantity': newStock});

        DocumentReference orderRef = _firestore.collection('orders').doc();
        transaction.set(orderRef, order.toMap());
      });

      await loadCustomerOrders(order.customerId);
      return null;
    } catch (e) {
      return e.toString().replaceAll("Exception:", "");
    }
  }

  Future<String?> updateOrderStatus(String orderId, OrderStatus status, {String? deliveryPersonId, String? deliveryPersonName}) async {
    try {
      Map<String, dynamic> updateData = {'status': status.toString().split('.').last};
      if (status == OrderStatus.accepted) updateData['acceptedAt'] = Timestamp.now();
      else if (status == OrderStatus.delivered) updateData['deliveredAt'] = Timestamp.now();

      if (deliveryPersonId != null) {
        updateData['deliveryPersonId'] = deliveryPersonId;
        updateData['deliveryPersonName'] = deliveryPersonName;
      }

      await _firestore.collection('orders').doc(orderId).update(updateData);
      return null;
    } catch (e) {
      return e.toString();
    }
  }
}