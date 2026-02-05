class LocationService {
  LocationService._();
  static final LocationService instance = LocationService._();

  Future<String> currentAreaLabel() async {
    return 'Singapore';
  }
}
