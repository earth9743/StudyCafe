import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

enum CrowdLevel { low, moderate, high, unknown }
enum OutletStatus { available, limited, unavailable, unknown }
enum NoiseLevel { quiet, moderate, loud, unknown }

class CafeModel extends Equatable {
  final String cafeId;
  final String name;
  final String address;
  final String? phone;
  final double lat;
  final double lng;
  final Map<String, String> businessHours;
  final List<String> photoUrls;
  final CrowdLevel currentCrowdLevel;
  final OutletStatus currentOutletStatus;
  final NoiseLevel currentNoiseLevel;
  final double averageRating;
  final int reviewCount;
  final bool isVerified;
  final DateTime createdAt;
  final DateTime updatedAt;

  const CafeModel({
    required this.cafeId,
    required this.name,
    required this.address,
    this.phone,
    required this.lat,
    required this.lng,
    this.businessHours = const {},
    this.photoUrls = const [],
    this.currentCrowdLevel = CrowdLevel.unknown,
    this.currentOutletStatus = OutletStatus.unknown,
    this.currentNoiseLevel = NoiseLevel.unknown,
    this.averageRating = 0.0,
    this.reviewCount = 0,
    this.isVerified = false,
    required this.createdAt,
    required this.updatedAt,
  });

  factory CafeModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return CafeModel(
      cafeId: data['cafeId'] ?? doc.id,
      name: data['name'] ?? '',
      address: data['address'] ?? '',
      phone: data['phone'],
      lat: (data['lat'] ?? 0.0).toDouble(),
      lng: (data['lng'] ?? 0.0).toDouble(),
      businessHours: Map<String, String>.from(data['businessHours'] ?? {}),
      photoUrls: List<String>.from(data['photoUrls'] ?? []),
      currentCrowdLevel: CrowdLevel.values.firstWhere(
        (e) => e.name == data['currentCrowdLevel'],
        orElse: () => CrowdLevel.unknown,
      ),
      currentOutletStatus: OutletStatus.values.firstWhere(
        (e) => e.name == data['currentOutletStatus'],
        orElse: () => OutletStatus.unknown,
      ),
      currentNoiseLevel: NoiseLevel.values.firstWhere(
        (e) => e.name == data['currentNoiseLevel'],
        orElse: () => NoiseLevel.unknown,
      ),
      averageRating: (data['averageRating'] ?? 0.0).toDouble(),
      reviewCount: data['reviewCount'] ?? 0,
      isVerified: data['isVerified'] ?? false,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'cafeId': cafeId,
      'name': name,
      'address': address,
      'phone': phone,
      'lat': lat,
      'lng': lng,
      'businessHours': businessHours,
      'photoUrls': photoUrls,
      'currentCrowdLevel': currentCrowdLevel.name,
      'currentOutletStatus': currentOutletStatus.name,
      'currentNoiseLevel': currentNoiseLevel.name,
      'averageRating': averageRating,
      'reviewCount': reviewCount,
      'isVerified': isVerified,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  @override
  List<Object?> get props => [cafeId, name, address, lat, lng];
}
