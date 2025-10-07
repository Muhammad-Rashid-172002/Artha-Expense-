import 'package:cloud_firestore/cloud_firestore.dart';

class TransactionModel {
  String? id; // Firebase document ID
  final String type; // "Income" or "Expense"
  final double amount;
  final String categoryOrSource;
  final String description;
  final DateTime date;
  final String? location;
  final String? receiptPath;
  final String? paymentMethod;

  TransactionModel({
    this.id,
    required this.type,
    required this.amount,
    required this.categoryOrSource,
    required this.description,
    required this.date,
    this.location,
    this.receiptPath,
    this.paymentMethod,
  });

  // Convert to Map for Firebase
  Map<String, dynamic> toMap() {
    return {
      'type': type,
      'amount': amount,
      'categoryOrSource': categoryOrSource,
      'description': description,
      'date': date,
      'location': location,
      'receiptPath': receiptPath,
      'paymentMethod': paymentMethod,
    };
  }

  // Convert from Firebase document
  factory TransactionModel.fromDoc(DocumentSnapshot doc) {
    return TransactionModel(
      id: doc.id,
      type: doc['type'],
      amount: doc['amount'],
      categoryOrSource: doc['categoryOrSource'],
      description: doc['description'],
      date: (doc['date'] as Timestamp).toDate(),
      location: doc['location'],
      receiptPath: doc['receiptPath'],
      paymentMethod: doc['paymentMethod'],
    );
  }
}
