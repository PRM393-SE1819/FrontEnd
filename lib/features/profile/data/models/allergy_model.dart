import '../../domain/entities/allergy.dart';

class AllergyModel extends Allergy {
  const AllergyModel({
    required super.allergyId,
    required super.allergyName,
    super.notes,
  });

  factory AllergyModel.fromJson(Map<String, dynamic> json) {
    return AllergyModel(
      allergyId: json['allergyId'] ?? json['id'] ?? 0,
      allergyName: json['allergyName'] ?? '',
      notes: json['notes'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'allergyId': allergyId,
      'allergyName': allergyName,
      'notes': notes,
    };
  }
}
