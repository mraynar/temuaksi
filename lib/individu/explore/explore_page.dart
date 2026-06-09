import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../../viewmodels/explore_viewmodel.dart';
import '../../theme/app_colors.dart';
import 'detail_aksi_page.dart';

class ExplorePage extends StatefulWidget {
  final String? initialCategory;

  const ExplorePage({super.key, this.initialCategory});

  @override
  State<ExplorePage> createState() => _ExplorePageState();
}

class _ExplorePageState extends State<ExplorePage> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final vm = context.read<ExploreViewModel>();
      if (widget.initialCategory != null) {
        vm.filterByCategory(widget.initialCategory!);
      } else {
        vm.loadAksiList();
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<ExploreViewModel>();

    return Scaffold(
      backgroundColor: Colors.white,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          _buildAppBar(vm),
          SliverToBoxAdapter(child: _buildCategoryChips(vm)),
          _buildEventList(vm),
          const SliverToBoxAdapter(child: SizedBox(height: 100)),
        ],
      ),
    );
  }

  Widget _buildAppBar(ExploreViewModel vm) {
    return SliverAppBar(
      expandedHeight: 140,
      floating: false,
      pinned: true,
      elevation: 0,
      backgroundColor: Colors.white,
      flexibleSpace: FlexibleSpaceBar(
        centerTitle: false,
        titlePadding: const EdgeInsets.only(left: 20, bottom: 65),
        title: Text(
          "Jelajahi Aksi",
          style: GoogleFonts.plusJakartaSans(
            color: const Color(0xFF1D1D1F),
            fontWeight: FontWeight.w800,
            fontSize: 22,
            letterSpacing: -0.5,
          ),
        ),
        background: Container(color: Colors.white),
      ),
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(60),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
          child: _buildSearchBar(vm),
        ),
      ),
    );
  }

  Widget _buildSearchBar(ExploreViewModel vm) {
    return Container(
      height: 44,
      decoration: BoxDecoration(
        color: const Color(0xFFF2F2F7),
        borderRadius: BorderRadius.circular(12),
      ),
      child: TextField(
        controller: _searchController,
        onChanged: vm.searchAksi,
        decoration: InputDecoration(
          prefixIcon:
              const Icon(Icons.search_rounded, color: Color(0xFF8E8E93)),
          hintText: "Cari aksi kebaikan...",
          hintStyle: GoogleFonts.plusJakartaSans(
            color: const Color(0xFF8E8E93),
            fontSize: 15,
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 10),
        ),
      ),
    );
  }

  Widget _buildCategoryChips(ExploreViewModel vm) {
    return SizedBox(
      height: 60,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        itemCount: vm.categories.length,
        itemBuilder: (context, index) {
          final cat = vm.categories[index];
          final isSelected = vm.selectedCategory == cat;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: FilterChip(
              selected: isSelected,
              label: Text(cat),
              labelStyle: GoogleFonts.plusJakartaSans(
                fontSize: 13,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color: isSelected ? Colors.white : const Color(0xFF1D1D1F),
              ),
              backgroundColor: const Color(0xFFF2F2F7),
              selectedColor: AppColors.primary,
              onSelected: (_) => vm.filterByCategory(cat),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
                side: const BorderSide(color: Colors.transparent),
              ),
              showCheckmark: false,
            ),
          );
        },
      ),
    );
  }

  Widget _buildEventList(ExploreViewModel vm) {
    // Use live stream from ViewModel for real-time updates
    return StreamBuilder<QuerySnapshot>(
      stream: vm.streamAksiList(
        category: vm.selectedCategory == 'Semua' ? null : vm.selectedCategory,
      ),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SliverToBoxAdapter(
            child: Center(
              child: Padding(
                padding: EdgeInsets.all(40),
                child: CircularProgressIndicator(color: AppColors.primary),
              ),
            ),
          );
        }

        final docs = snapshot.data?.docs ?? [];
        final query = vm.searchQuery.toLowerCase();
        final filteredDocs = query.isEmpty
            ? docs
            : docs.where((doc) {
                final title = (doc['title'] ?? '').toString().toLowerCase();
                return title.contains(query);
              }).toList();

        if (filteredDocs.isEmpty) {
          return SliverFillRemaining(
            hasScrollBody: false,
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.search_off_rounded,
                      size: 64, color: Colors.grey[300]),
                  const SizedBox(height: 16),
                  Text(
                    "Aksi tidak ditemukan",
                    style: GoogleFonts.plusJakartaSans(
                        color: Colors.grey, fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ),
          );
        }

        return SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          sliver: SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) => _buildEventCard(filteredDocs[index]),
              childCount: filteredDocs.length,
            ),
          ),
        );
      },
    );
  }

  Widget _buildEventCard(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    final String title = data['title'] ?? 'Tanpa Judul';
    final String category = data['category'] ?? 'Lainnya';
    final int minFunding = data['min_funding'] ?? 0;
    final int maxFunding = data['max_funding'] ?? 0;
    final String scale = data['scale'] ?? 'Nasional';
    final String photoUrl = data['photo_url'] ?? '';

    final currencyFormat =
        NumberFormat.compactCurrency(locale: 'id_ID', symbol: 'Rp');

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => DetailAksiPage(actionDoc: doc),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                ClipRRect(
                  borderRadius:
                      const BorderRadius.vertical(top: Radius.circular(24)),
                  child: photoUrl.isNotEmpty
                      ? Image.network(
                          photoUrl,
                          height: 160,
                          width: double.infinity,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Container(
                            height: 160,
                            color: AppColors.primary.withValues(alpha: 0.1),
                            child: Center(
                              child: Icon(
                                _getCategoryIcon(category),
                                size: 50,
                                color: AppColors.primary.withValues(alpha: 0.3),
                              ),
                            ),
                          ),
                        )
                      : Container(
                          height: 160,
                          color: AppColors.primary.withValues(alpha: 0.1),
                          child: Center(
                            child: Icon(
                              _getCategoryIcon(category),
                              size: 50,
                              color: AppColors.primary.withValues(alpha: 0.3),
                            ),
                          ),
                        ),
                ),
                Positioned(
                  top: 15,
                  right: 15,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.9),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.public_rounded,
                            size: 14, color: AppColors.primary),
                        const SizedBox(width: 4),
                        Text(
                          scale,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: AppColors.primary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    category.toUpperCase(),
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      color: AppColors.primary,
                      letterSpacing: 1.0,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    title,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: const Color(0xFF1D1D1F),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Estimasi Pendanaan",
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 11,
                              color: const Color(0xFF8E8E93),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            "${currencyFormat.format(minFunding)} - ${currencyFormat.format(maxFunding)}",
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFF1D1D1F),
                            ),
                          ),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: const BoxDecoration(
                          color: AppColors.primary,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.arrow_forward_ios_rounded,
                          size: 14,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  IconData _getCategoryIcon(String category) {
    switch (category.toLowerCase()) {
      case 'teknologi':
        return Icons.memory_rounded;
      case 'lingkungan':
        return Icons.eco_rounded;
      case 'kesehatan':
        return Icons.health_and_safety_rounded;
      case 'olahraga':
        return Icons.fitness_center_rounded;
      case 'sosial & kemanusiaan':
        return Icons.volunteer_activism_rounded;
      default:
        return Icons.stars_rounded;
    }
  }
}
