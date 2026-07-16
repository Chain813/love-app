import 'package:flutter/material.dart';
import '../services/leancloud_service.dart';

class UserProvider extends ChangeNotifier {
  Map<String, dynamic>? _currentUser;
  Map<String, dynamic>? _relation;
  bool _isLoading = true;

  Map<String, dynamic>? get currentUser => _currentUser;
  Map<String, dynamic>? get relation => _relation;
  bool get isLoading => _isLoading;

  Future<void> loadUser() async {
    _isLoading = true;
    notifyListeners();

    try {
      _currentUser = await LeanCloudService.getCurrentUser();
      if (_currentUser != null) {
        _relation = await LeanCloudService.getLocalRelation() ?? await LeanCloudService.checkPairStatus();
      }
    } catch (e) {
      print('UserProvider loadUser error: ');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> refreshUser() async {
    await loadUser();
  }
}
