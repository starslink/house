class Property {
  final String id;
  final String address;
  final double waterRate;
  final double electricityRate;
  final double managementFee;
  final List<Unit> units;

  Property({
    required this.id,
    required this.address,
    required this.waterRate,
    required this.electricityRate,
    required this.managementFee,
    required this.units,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'address': address,
      'waterRate': waterRate,
      'electricityRate': electricityRate,
      'managementFee': managementFee,
      'units': units.map((unit) => unit.toMap()).toList(),
    };
  }

  factory Property.fromMap(Map<String, dynamic> map) {
    return Property(
      id: map['id'],
      address: map['address'],
      waterRate: map['waterRate'],
      electricityRate: map['electricityRate'],
      managementFee: map['managementFee'],
      units: List<Unit>.from(map['units']?.map((x) => Unit.fromMap(x))),
    );
  }
}

class Unit {
  final String id;
  final String unitNumber;
  final double baseRent;
  String? currentTenantId;

  Unit({
    required this.id,
    required this.unitNumber,
    required this.baseRent,
    this.currentTenantId,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'unitNumber': unitNumber,
      'baseRent': baseRent,
      'currentTenantId': currentTenantId,
    };
  }

  factory Unit.fromMap(Map<String, dynamic> map) {
    return Unit(
      id: map['id'],
      unitNumber: map['unitNumber'],
      baseRent: map['baseRent'],
      currentTenantId: map['currentTenantId'],
    );
  }
}
