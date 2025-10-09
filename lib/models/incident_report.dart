import 'package:cloud_firestore/cloud_firestore.dart';

class IncidentReport {
  final String id;
  final String assignedVehicleId;
  final String createdBy;
  final String createdById;
  final String description;
  final String location;
  final String persons;
  final DateTime timestamp;
  final String type;
  final String status; // You may want to add this field to Firestore

  IncidentReport({
    required this.id,
    required this.assignedVehicleId,
    required this.createdBy,
    required this.createdById,
    required this.description,
    required this.location,
    required this.persons,
    required this.timestamp,
    required this.type,
    this.status = 'In Progress',
  });

  // Create from Firestore document
  factory IncidentReport.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;

    return IncidentReport(
      id: doc.id,
      assignedVehicleId: data['assignedVehicleId'] ?? '',
      createdBy: data['createdBy'] ?? '',
      createdById: data['createdById'] ?? '',
      description: data['description'] ?? '',
      location: data['location'] ?? '',
      persons: data['persons'] ?? '',
      timestamp: (data['timestamp'] as Timestamp).toDate(),
      type: data['type'] ?? '',
      status: data['status'] ?? 'In Progress',
    );
  }

  // Convert to Firestore document
  Map<String, dynamic> toFirestore() {
    return {
      'assignedVehicleId': assignedVehicleId,
      'createdBy': createdBy,
      'createdById': createdById,
      'description': description,
      'location': location,
      'persons': persons,
      'timestamp': Timestamp.fromDate(timestamp),
      'type': type,
      'status': status,
    };
  }
}