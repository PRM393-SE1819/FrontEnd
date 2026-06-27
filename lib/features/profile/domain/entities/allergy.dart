class Allergy {
  final int allergyId;
  final String allergyName;
  final String? notes;

  const Allergy({
    required this.allergyId,
    required this.allergyName,
    this.notes,
  });
}
