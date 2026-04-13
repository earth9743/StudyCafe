import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

enum AuthProvider { email, google, kakao }

class UserModel extends Equatable {
  final String uid;
  final String email;
  final String displayName;
  final String? nickname;
  final String? photoUrl;
  final AuthProvider provider;
  final DateTime createdAt;
  final DateTime updatedAt;
  final List<String> bookmarkedCafeIds;
  final bool agreedToTerms;
  final bool agreedToPrivacy;
  final bool agreedToLocation;
  final bool agreedToMarketing;

  const UserModel({
    required this.uid,
    required this.email,
    required this.displayName,
    this.nickname,
    this.photoUrl,
    required this.provider,
    required this.createdAt,
    required this.updatedAt,
    this.bookmarkedCafeIds = const [],
    this.agreedToTerms = false,
    this.agreedToPrivacy = false,
    this.agreedToLocation = false,
    this.agreedToMarketing = false,
  });

  factory UserModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return UserModel(
      uid: data['uid'] ?? doc.id,
      email: data['email'] ?? '',
      displayName: data['displayName'] ?? '',
      nickname: data['nickname'],
      photoUrl: data['photoUrl'],
      provider: AuthProvider.values.firstWhere(
        (e) => e.name == data['provider'],
        orElse: () => AuthProvider.email,
      ),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      bookmarkedCafeIds: List<String>.from(data['bookmarkedCafeIds'] ?? []),
      agreedToTerms: data['agreedToTerms'] ?? false,
      agreedToPrivacy: data['agreedToPrivacy'] ?? false,
      agreedToLocation: data['agreedToLocation'] ?? false,
      agreedToMarketing: data['agreedToMarketing'] ?? false,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'uid': uid,
      'email': email,
      'displayName': displayName,
      'nickname': nickname,
      'photoUrl': photoUrl,
      'provider': provider.name,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'bookmarkedCafeIds': bookmarkedCafeIds,
      'agreedToTerms': agreedToTerms,
      'agreedToPrivacy': agreedToPrivacy,
      'agreedToLocation': agreedToLocation,
      'agreedToMarketing': agreedToMarketing,
    };
  }

  UserModel copyWith({
    String? uid,
    String? email,
    String? displayName,
    String? nickname,
    String? photoUrl,
    AuthProvider? provider,
    DateTime? createdAt,
    DateTime? updatedAt,
    List<String>? bookmarkedCafeIds,
    bool? agreedToTerms,
    bool? agreedToPrivacy,
    bool? agreedToLocation,
    bool? agreedToMarketing,
  }) {
    return UserModel(
      uid: uid ?? this.uid,
      email: email ?? this.email,
      displayName: displayName ?? this.displayName,
      nickname: nickname ?? this.nickname,
      photoUrl: photoUrl ?? this.photoUrl,
      provider: provider ?? this.provider,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      bookmarkedCafeIds: bookmarkedCafeIds ?? this.bookmarkedCafeIds,
      agreedToTerms: agreedToTerms ?? this.agreedToTerms,
      agreedToPrivacy: agreedToPrivacy ?? this.agreedToPrivacy,
      agreedToLocation: agreedToLocation ?? this.agreedToLocation,
      agreedToMarketing: agreedToMarketing ?? this.agreedToMarketing,
    );
  }

  @override
  List<Object?> get props => [uid, email, displayName, nickname, photoUrl, provider];
}
