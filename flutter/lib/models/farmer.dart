class Farmer {
  final String id;
  final String name;
  final String location;
  final String crops; // JSON string e.g. '["cotton","tomato"]'
  final double landAcres;
  final DateTime updatedAt;

  const Farmer({
    required this.id,
    required this.name,
    required this.location,
    required this.crops,
    required this.landAcres,
    required this.updatedAt,
  });
}
