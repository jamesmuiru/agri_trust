import 'package:cloud_firestore/cloud_firestore.dart';

enum UserRole { farmer, customer, delivery }
enum OrderStatus { pending, accepted, inTransit, delivered, cancelled }
enum MeasurementUnit { kg, piece, bunch, bag, litre, dozen }

class UserProfile {
  final String uid;
  final String email;
  final String name;
  final UserRole role;
  final String? phoneNumber;
  final Map<String, double>? location;

  UserProfile({
    required this.uid,
    required this.email,
    required this.name,
    required this.role,
    this.phoneNumber,
    this.location,
  });

  factory UserProfile.fromMap(Map<String, dynamic> map, String uid) {
    return UserProfile(
      uid: uid,
      email: map['email'] ?? '',
      name: map['name'] ?? '',
      role: UserRole.values.firstWhere(
        (e) => e.toString() == 'UserRole.${map['role']}',
        orElse: () => UserRole.customer,
      ),
      phoneNumber: map['phoneNumber'],
      location: map['location'] != null
          ? Map<String, double>.from(map['location'])
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'email': email,
      'name': name,
      'role': role.toString().split('.').last,
      'phoneNumber': phoneNumber,
      'location': location,
    };
  }
}

class Product {
  final String? id;
  final String farmerId;
  final String farmerName;
  final String name;
  final String description;
  final double pricePerUnit;
  final MeasurementUnit unit;
  final List<String> imageUrls;
  final DateTime? photoTakenDate;
  final double? quantity;
  final Map<String, double>? location;
  final DateTime createdAt;

  Product({
    this.id,
    required this.farmerId,
    required this.farmerName,
    required this.name,
    required this.description,
    required this.pricePerUnit,
    required this.unit,
    required this.imageUrls,
    this.photoTakenDate,
    this.quantity,
    this.location,
    required this.createdAt,
  });

  factory Product.fromMap(Map<String, dynamic> map, String id) {
    return Product(
      id: id,
      farmerId: map['farmerId'] ?? '',
      farmerName: map['farmerName'] ?? '',
      name: map['name'] ?? '',
      description: map['description'] ?? '',
      pricePerUnit: (map['pricePerUnit'] ?? 0).toDouble(),
      unit: MeasurementUnit.values.firstWhere(
        (e) => e.toString() == 'MeasurementUnit.${map['unit']}',
        orElse: () => MeasurementUnit.kg,
      ),
      imageUrls: List<String>.from(map['imageUrls'] ?? []),
      photoTakenDate: map['photoTakenDate'] != null
          ? (map['photoTakenDate'] as Timestamp).toDate()
          : null,
      quantity: map['quantity']?.toDouble(),
      location: map['location'] != null
          ? Map<String, double>.from(map['location'])
          : null,
      createdAt: (map['createdAt'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'farmerId': farmerId,
      'farmerName': farmerName,
      'name': name,
      'description': description,
      'pricePerUnit': pricePerUnit,
      'unit': unit.toString().split('.').last,
      'imageUrls': imageUrls,
      'photoTakenDate': photoTakenDate != null
          ? Timestamp.fromDate(photoTakenDate!)
          : null,
      'quantity': quantity,
      'location': location,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }
}

class Order {
  final String? id;
  final String customerId;
  final String customerName;
  final String customerPhone;
  final String farmerId;
  final String farmerName;
  final String productId;
  final String productName;
  final double quantity;
  final double totalPrice;
  final MeasurementUnit unit;
  final OrderStatus status;
  final String? deliveryPersonId;
  final String? deliveryPersonName;
  final Map<String, double> deliveryLocation;
  final DateTime createdAt;
  final DateTime? acceptedAt;
  final DateTime? deliveredAt;
  final String? paymentRef;

  Order({
    this.id,
    required this.customerId,
    required this.customerName,
    required this.customerPhone,
    required this.farmerId,
    required this.farmerName,
    required this.productId,
    required this.productName,
    required this.quantity,
    required this.totalPrice,
    required this.unit,
    required this.status,
    this.deliveryPersonId,
    this.deliveryPersonName,
    required this.deliveryLocation,
    required this.createdAt,
    this.acceptedAt,
    this.deliveredAt,
    this.paymentRef,
  });

  factory Order.fromMap(Map<String, dynamic> map, String id) {
    return Order(
      id: id,
      customerId: map['customerId'] ?? '',
      customerName: map['customerName'] ?? '',
      customerPhone: map['customerPhone'] ?? '',
      farmerId: map['farmerId'] ?? '',
      farmerName: map['farmerName'] ?? 'Farmer',
      productId: map['productId'] ?? '',
      productName: map['productName'] ?? '',
      quantity: (map['quantity'] ?? 0).toDouble(),
      totalPrice: (map['totalPrice'] ?? 0).toDouble(),
      unit: MeasurementUnit.values.firstWhere(
        (e) => e.toString() == 'MeasurementUnit.${map['unit']}',
        orElse: () => MeasurementUnit.kg,
      ),
      status: OrderStatus.values.firstWhere(
        (e) => e.toString() == 'OrderStatus.${map['status']}',
        orElse: () => OrderStatus.pending,
      ),
      deliveryPersonId: map['deliveryPersonId'],
      deliveryPersonName: map['deliveryPersonName'],
      deliveryLocation: Map<String, double>.from(map['deliveryLocation']),
      createdAt: (map['createdAt'] as Timestamp).toDate(),
      acceptedAt: map['acceptedAt'] != null
          ? (map['acceptedAt'] as Timestamp).toDate()
          : null,
      deliveredAt: map['deliveredAt'] != null
          ? (map['deliveredAt'] as Timestamp).toDate()
          : null,
      paymentRef: map['paymentRef'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'customerId': customerId,
      'customerName': customerName,
      'customerPhone': customerPhone,
      'farmerId': farmerId,
      'farmerName': farmerName,
      'productId': productId,
      'productName': productName,
      'quantity': quantity,
      'totalPrice': totalPrice,
      'unit': unit.toString().split('.').last,
      'status': status.toString().split('.').last,
      'deliveryPersonId': deliveryPersonId,
      'deliveryPersonName': deliveryPersonName,
      'deliveryLocation': deliveryLocation,
      'createdAt': Timestamp.fromDate(createdAt),
      'acceptedAt': acceptedAt != null ? Timestamp.fromDate(acceptedAt!) : null,
      'deliveredAt':
          deliveredAt != null ? Timestamp.fromDate(deliveredAt!) : null,
      'paymentRef': paymentRef,
    };
  }
}