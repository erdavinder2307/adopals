// Which part of a pet's address a person may see: the pet giver (and admins) see the address as stored,
// everyone else sees the city only. Same rule as the website.

// Indian states and union territories as Google Places writes them (lower case). When one sits just before the
// country, the city is the part before it. Delhi and Chandigarh are left out: there the state name is the city.
const Set<String> _states = {
  'andhra pradesh', 'arunachal pradesh', 'assam', 'bihar', 'chhattisgarh', 'goa', 'gujarat', 'haryana',
  'himachal pradesh', 'jharkhand', 'karnataka', 'kerala', 'madhya pradesh', 'maharashtra', 'manipur',
  'meghalaya', 'mizoram', 'nagaland', 'odisha', 'punjab', 'rajasthan', 'sikkim', 'tamil nadu', 'telangana',
  'tripura', 'uttar pradesh', 'uttarakhand', 'west bengal', 'andaman and nicobar islands',
  'dadra and nagar haveli and daman and diu', 'jammu and kashmir', 'ladakh', 'lakshadweep', 'puducherry',
};

// Last parts treated as a country (lower case). Without one, a typed address may end
// "<street or society>, <city>", so only the last part is kept.
const Set<String> _countries = {
  'india', 'nepal', 'bangladesh', 'sri lanka', 'bhutan', 'uae', 'united arab emirates', 'singapore',
  'uk', 'united kingdom', 'usa', 'united states', 'canada', 'australia', 'new zealand',
};

final RegExp _hasDigit = RegExp(r'\p{Nd}', unicode: true);

/// "<city>, <country>" from a Google Places address; never the street, society or locality. Parts with a digit
/// (house numbers, sectors, postcodes) are dropped, then the country (last part) and the city before it are kept,
/// skipping a state: "Sector 70, Mohali, Punjab, India" gives "Mohali, India" and "Green Avenue, Mohali" gives
/// "Mohali". Returns an empty string when no city is left (for example "221B").
String publicPetLocation(Object? address) {
  if (address is! String) return '';
  final parts = address.split(',').map((p) => p.trim()).where((p) => p.isNotEmpty && !_hasDigit.hasMatch(p)).toList();
  final country = <String>[];
  if (parts.isNotEmpty && _countries.contains(parts.last.toLowerCase())) {
    country.add(parts.removeLast());
  }
  if (parts.length >= 2 && _states.contains(parts.last.toLowerCase())) {
    parts.removeLast();
  }
  return [if (parts.isNotEmpty) parts.last, ...country].join(', ');
}

/// The location as [viewerId] may see it: as stored for the pet giver ([createdBy]) and for admins, the city only
/// for everyone else, including signed-out visitors (no [viewerId]). A missing location, or one without a city,
/// gives an empty string and never falls back to the street.
String petLocationFor(Object? location, {String? createdBy, String? viewerId, bool isAdmin = false}) {
  if (location is! String) return '';
  final value = location.trim();
  if (value.isEmpty) return '';
  final isGiver = viewerId != null && viewerId.isNotEmpty && createdBy != null && viewerId == createdBy;
  return isGiver || isAdmin ? value : publicPetLocation(value);
}
