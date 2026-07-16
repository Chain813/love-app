import 'package:flutter/material.dart';
import '../features/diary/models/diary.dart';
import '../services/leancloud_service.dart';

class DiaryProvider extends ChangeNotifier {
  List<Diary> _diaries = [];
  bool _isLoading = false;
  bool _hasMore = true;
  int _offset = 0;
  final int _limit = 20;

  List<Diary> get diaries => _diaries;
  bool get isLoading => _isLoading;
  bool get hasMore => _hasMore;

  Future<void> fetchInitial() async {
    _isLoading = true;
    _offset = 0;
    _hasMore = true;
    notifyListeners();

    try {
      final results = await LeanCloudService.fetchDiaries(limit: _limit, offset: _offset);
      _diaries = results;
      if (results.length < _limit) {
        _hasMore = false;
      } else {
        _offset += _limit;
      }
    } catch (e) {
      print('DiaryProvider fetchInitial error: ');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> fetchMore() async {
    if (_isLoading || !_hasMore) return;

    _isLoading = true;
    notifyListeners();

    try {
      final results = await LeanCloudService.fetchDiaries(limit: _limit, offset: _offset);
      if (results.isEmpty) {
        _hasMore = false;
      } else {
        _diaries.addAll(results);
        _offset += _limit;
        if (results.length < _limit) {
          _hasMore = false;
        }
      }
    } catch (e) {
      print('DiaryProvider fetchMore error: ');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void refresh() {
    fetchInitial();
  }
}
