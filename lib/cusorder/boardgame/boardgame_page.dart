import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:cafa_boardgame/utils/appapicus.dart';
import 'package:cafa_boardgame/config/app_config.dart';

enum GameMode { sale, play }

class BoardGamePage extends StatefulWidget {
  const BoardGamePage({super.key});

  @override
  State<BoardGamePage> createState() => _BoardGamePageState();
}

class _BoardGamePageState extends State<BoardGamePage> {
  bool _isLoading = false;
  GameMode _currentMode = GameMode.sale;

  List<dynamic> _gamesList = [];
  List<dynamic> _filteredGamesList = [];

  // คงไว้เฉพาะ Mock หมวดหมู่สำหรับแสดงผล UI Bar
  final List<String> _categoriesList = [
    'ทั้งหมด',
    'Strategy',
    'Family',
    'Party',
    'Card Game',
    'Thematic',
    'Abstract',
  ];

  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fetchGames();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _fetchGames() async {
    setState(() => _isLoading = true);
    final endpoint = _currentMode == GameMode.sale
        ? '/boardgame/sale'
        : '/boardgame/play';

    try {
      final response = await AppAPICUS.get(endpoint);
      if (response.statusCode == 200) {
        final jsonResult = jsonDecode(response.body);
        if (jsonResult != null && jsonResult['isError'] == false) {
          final List rawData =
              (jsonResult['data'] is List) ? jsonResult['data'] : [];

          if (mounted) {
            setState(() {
              _gamesList = rawData;
              _applyFilter();
            });
          }
        }
      }
    } catch (e) {
      debugPrint("Error fetching board games: $e");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // กรองเฉพาะคำค้นหาชื่อเกมอย่างเดียว
  void _applyFilter() {
    final query = _searchController.text.trim().toLowerCase();

    setState(() {
      _filteredGamesList = _gamesList.where((item) {
        final isSale = _currentMode == GameMode.sale;
        final name = (item[isSale ? 'bg_name' : 'bgp_name'] ?? '')
            .toString()
            .toLowerCase();

        return query.isEmpty || name.contains(query);
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: Column(
                children: [
                  _buildModeSelector(),
                  const SizedBox(height: 12),
                  _buildSearchField(),
                  const SizedBox(height: 12),
                  _buildCategoryBar(),
                ],
              ),
            ),
            Expanded(
              child: _isLoading
                  ? const Center(
                      child: CircularProgressIndicator(
                        color: Color(0xFFE5A93C),
                      ),
                    )
                  : _filteredGamesList.isEmpty
                      ? const Center(
                          child: Text(
                            'ไม่พบบอร์ดเกมที่ค้นหา',
                            style: TextStyle(color: Colors.grey, fontSize: 14),
                          ),
                        )
                      : GridView.builder(
                          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                          itemCount: _filteredGamesList.length,
                          gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            crossAxisSpacing: 12,
                            mainAxisSpacing: 12,
                            childAspectRatio: 0.74,
                          ),
                          itemBuilder: (context, index) {
                            return _buildGameCard(_filteredGamesList[index]);
                          },
                        ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildModeSelector() {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Expanded(
            child: _buildModeButton(
              title: 'สำหรับซื้อ (Sale)',
              mode: GameMode.sale,
            ),
          ),
          Expanded(
            child: _buildModeButton(
              title: 'สำหรับเล่น (Play)',
              mode: GameMode.play,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModeButton({required String title, required GameMode mode}) {
    final isSelected = _currentMode == mode;
    return GestureDetector(
      onTap: () {
        if (_currentMode != mode) {
          setState(() {
            _currentMode = mode;
          });
          _fetchGames();
        }
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFE5A93C) : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Center(
          child: Text(
            title,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: isSelected ? Colors.white : Colors.black54,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSearchField() {
    return SizedBox(
      height: 44,
      child: TextField(
        controller: _searchController,
        style: const TextStyle(fontSize: 14),
        decoration: InputDecoration(
          hintText: 'ค้นหาชื่อบอร์ดเกม...',
          hintStyle: TextStyle(color: Colors.grey.shade500, fontSize: 14),
          prefixIcon: const Icon(Icons.search, color: Colors.grey, size: 20),
          suffixIcon: _searchController.text.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear, size: 18, color: Colors.grey),
                  onPressed: () {
                    _searchController.clear();
                    _applyFilter();
                  },
                )
              : null,
          filled: true,
          fillColor: Colors.grey.shade100,
          contentPadding: const EdgeInsets.symmetric(horizontal: 14),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
        ),
        onChanged: (_) => _applyFilter(),
      ),
    );
  }

  Widget _buildCategoryBar() {
    return SizedBox(
      height: 38,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: _categoriesList.length,
        itemBuilder: (context, index) {
          final catName = _categoriesList[index];
          final isFirst = index == 0;

          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            margin: const EdgeInsets.only(right: 8),
            decoration: BoxDecoration(
              color: isFirst ? const Color(0xFFE5A93C) : Colors.grey.shade100,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Center(
              child: Text(
                catName,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: isFirst ? FontWeight.bold : FontWeight.normal,
                  color: isFirst ? Colors.white : Colors.black87,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildGameCard(dynamic item) {
    final isSale = _currentMode == GameMode.sale;
    final String name =
        (item[isSale ? 'bg_name' : 'bgp_name'] ?? '').toString();
    final String? imgName =
        (item[isSale ? 'img_game_sale' : 'img_game_play'])?.toString();
    final String price = (item['price'] ?? '').toString();
    final String categories = (item['catagory_bg_name'] ?? '').toString();

    final imageFolder = isSale ? 'boardgame' : 'borrow';

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      elevation: 1,
      shadowColor: Colors.black.withOpacity(0.05),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () {
          final id = isSale ? item['bg_id'] : item['bgp_id'];
          debugPrint("Tapped game ID: $id, Mode: $_currentMode");
        },
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    color: Colors.grey.shade50,
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: (imgName != null && imgName.isNotEmpty)
                        ? Image.network(
                            '${AppConfig.apiBaseUri.replaceAll('/api', '')}/img/$imageFolder/$imgName',
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) =>
                                _buildDefaultImage(),
                          )
                        : _buildDefaultImage(),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                name.trim(),
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              if (categories.isNotEmpty) ...[
                const SizedBox(height: 2),
                Text(
                  categories,
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey.shade600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
              const SizedBox(height: 4),
              if (isSale)
                Text(
                  '$price บาท',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFFE5A93C),
                  ),
                )
              else
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.green.shade50,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    'พร้อมให้เล่นที่ร้าน',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: Colors.green.shade700,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDefaultImage() {
    return Container(
      color: Colors.grey[200],
      child: const Center(
        child: Icon(Icons.casino_outlined, color: Colors.grey, size: 36),
      ),
    );
  }
}