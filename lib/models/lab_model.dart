class Lab {
  final int id;
  final String labId;
  final int userId;
  final String labName;
  final String labType;
  final String ownerName;
  final String labAddress;
  final String? city;
  final String? state;
  final String? pincode;
  final String licenseNumber;
  final String? registrationCertificatePath;
  final String? labImagePath;
  final bool pickupAvailable;
  final bool deliveryAvailable;
  final double deliveryCharges;
  final bool freeDelivery;
  final bool isActive;
  final DateTime? createdAt;

  Lab({
    required this.id,
    required this.labId,
    required this.userId,
    required this.labName,
    required this.labType,
    required this.ownerName,
    required this.labAddress,
    this.city,
    this.state,
    this.pincode,
    required this.licenseNumber,
    this.registrationCertificatePath,
    this.labImagePath,
    this.pickupAvailable = true,
    this.deliveryAvailable = true,
    this.deliveryCharges = 0.0,
    this.freeDelivery = false,
    this.isActive = true,
    this.createdAt,
  });

  factory Lab.fromJson(Map<String, dynamic> json) {
    return Lab(
      id: json['id'],
      labId: json['lab_id'],
      userId: json['user_id'],
      labName: json['lab_name'],
      labType: json['lab_type'],
      ownerName: json['owner_name'],
      labAddress: json['lab_address'],
      city: json['city'],
      state: json['state'],
      pincode: json['pincode'],
      licenseNumber: json['license_number'],
      registrationCertificatePath: json['registration_certificate_path'],
      labImagePath: json['lab_image_path'],
      pickupAvailable: json['pickup_available'] ?? true,
      deliveryAvailable: json['delivery_available'] ?? true,
      deliveryCharges: (json['delivery_charges'] ?? 0).toDouble(),
      freeDelivery: json['free_delivery'] ?? false,
      isActive: json['is_active'] ?? true,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'lab_id': labId,
      'user_id': userId,
      'lab_name': labName,
      'lab_type': labType,
      'owner_name': ownerName,
      'lab_address': labAddress,
      'city': city,
      'state': state,
      'pincode': pincode,
      'license_number': licenseNumber,
      'registration_certificate_path': registrationCertificatePath,
      'lab_image_path': labImagePath,
      'pickup_available': pickupAvailable,
      'delivery_available': deliveryAvailable,
      'delivery_charges': deliveryCharges,
      'free_delivery': freeDelivery,
      'is_active': isActive,
      'created_at': createdAt?.toIso8601String(),
    };
  }
}
