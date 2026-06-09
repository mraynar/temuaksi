import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ExploreViewModel extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  List<QueryDocumentSnapshot> _aksiList = [];
  List<QueryDocumentSnapshot> _filteredList = [];
  bool _isLoading = false;
  String _searchQuery = '';
  String _selectedCategory = 'Semua';

  List<QueryDocumentSnapshot> get aksiList => _aksiList;
  List<QueryDocumentSnapshot> get filteredList => _filteredList;
  bool get isLoading => _isLoading;
  String get searchQuery => _searchQuery;
  String get selectedCategory => _selectedCategory;

  final List<String> categories = [
    'Semua',
    'Teknologi',
    'Lingkungan',
    'Sosial & Kemanusiaan',
    'Kesehatan',
    'Olahraga',
  ];

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  /// Load all aksi from Firestore
  Future<void> loadAksiList({String? category}) async {
    _setLoading(true);
    try {
      Query query = _firestore.collection('actions');
      if (category != null && category != 'Semua') {
        query = query.where('category', isEqualTo: category);
      }
      final snapshot = await query.get();
      _aksiList = snapshot.docs;
      _applyFilters();
    } catch (_) {
      _aksiList = [];
      _filteredList = [];
      notifyListeners();
    } finally {
      _setLoading(false);
    }
  }

  /// Real-time stream subscription to 'actions' collection
  Stream<QuerySnapshot> streamAksiList({String? category}) {
    Query query = _firestore.collection('actions');
    if (category != null && category != 'Semua') {
      query = query.where('category', isEqualTo: category);
    }
    return query.snapshots();
  }

  /// Update search query and re-filter
  void searchAksi(String query) {
    _searchQuery = query;
    _applyFilters();
  }

  /// Filter by category
  void filterByCategory(String category) {
    _selectedCategory = category;
    notifyListeners();
    loadAksiList(category: category == 'Semua' ? null : category);
  }

  void _applyFilters() {
    if (_searchQuery.isEmpty) {
      _filteredList = List.from(_aksiList);
    } else {
      _filteredList = _aksiList.where((doc) {
        final title = (doc['title'] ?? '').toString().toLowerCase();
        return title.contains(_searchQuery.toLowerCase());
      }).toList();
    }
    notifyListeners();
  }

  /// Reset state
  void reset() {
    _selectedCategory = 'Semua';
    _searchQuery = '';
    _aksiList = [];
    _filteredList = [];
    notifyListeners();
  }
}
