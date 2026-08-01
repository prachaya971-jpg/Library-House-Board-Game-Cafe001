import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:fl_chart/fl_chart.dart';
import 'package:cafa_boardgame/utils/appapi.dart';

class RevenueBarChartCard extends StatefulWidget {
  const RevenueBarChartCard({super.key});

  @override
  State<RevenueBarChartCard> createState() => _RevenueBarChartCardState();
}

class _RevenueBarChartCardState extends State<RevenueBarChartCard> {
  String _selectedPeriod = 'daily'; // 'daily', 'monthly', 'yearly'
  String _selectedCategory = 'food'; // 'all', 'food', 'boardgame'

  List<dynamic> _chartData = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _fetchChartData();
  }

  Future<void> _fetchChartData() async {
  setState(() => _isLoading = true);

  try {
  
    final queryString = '/reports/revenue-chart?period=$_selectedPeriod&category=$_selectedCategory';

    
    final response = await AppAPI.get(queryString);

    if (response.statusCode == 200) {
      final json = jsonDecode(response.body);
      if (!json['isError']) {
        setState(() {
          _chartData = json['data'];
        });
      }
    } else {
      print("Server Error: ${response.statusCode} - ${response.body}");
    }
  } catch (e) {
    print("Error fetching chart data: $e");
  } finally {
    if (mounted) setState(() => _isLoading = false);
  }
}

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity, 
      height: 350,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Row บน: หัวข้อ + Dropdown ช่วงเวลา & หมวดหมู่
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                "สถิติรายได้",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1F2937),
                ),
              ),
              Row(
                children: [
                  _buildDropdown(
                    value: _selectedPeriod,
                    items: const [
                      DropdownMenuItem(value: 'daily', child: Text("วัน")),
                      DropdownMenuItem(value: 'monthly', child: Text("เดือน")),
                      DropdownMenuItem(value: 'yearly', child: Text("ปี")),
                    ],
                    onChanged: (val) {
                      if (val != null) {
                        setState(() => _selectedPeriod = val);
                        _fetchChartData();
                      }
                    },
                  ),
                  const SizedBox(width: 8),
                  _buildDropdown(
                    value: _selectedCategory,
                    items: const [
                      DropdownMenuItem(value: 'all', child: Text("ทั้งหมด")),
                      DropdownMenuItem(value: 'food', child: Text("อาหาร")),
                      DropdownMenuItem(value: 'boardgame', child: Text("เกม")),
                    ],
                    onChanged: (val) {
                      if (val != null) {
                        setState(() => _selectedCategory = val);
                        _fetchChartData();
                      }
                    },
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 24),

          // ส่วนแสดงผล กราฟแท่ง
          Expanded(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(color: Color(0xFF6E8B7E)),
                  )
                : _chartData.isEmpty
                    ? const Center(
                        child: Text(
                          "ไม่มีข้อมูลในช่วงเวลานี้",
                          style: TextStyle(color: Colors.grey),
                        ),
                      )
                    : BarChart(_buildBarChartData()),
          ),
        ],
      ),
    );
  }

  // สร้างอ็อบเจกต์ข้อมูลสำหรับวาดกราฟด้วย fl_chart
  BarChartData _buildBarChartData() {
    double maxTotal = 0;
    for (var item in _chartData) {
      double val = (item['total'] as num).toDouble();
      if (val > maxTotal) maxTotal = val;
    }

    return BarChartData(
      alignment: BarChartAlignment.spaceAround,
      // เผื่อระยะความสูงแกน Y ขึ้นไปอีก 25% เพื่อให้ข้อความยอดเงินด้านบนไม่ล้นขอบ
      maxY: maxTotal == 0 ? 100 : maxTotal * 1.25,
      
      // ตั้งค่า Tooltip และการแสดงตัวเลขยอดเงิน
      barTouchData: BarTouchData(
        enabled: true,
        touchTooltipData: BarTouchTooltipData(
          getTooltipColor: (group) => Colors.transparent, // ทำพื้นหลัง Tooltip ให้โปร่งใส
          tooltipMargin: 2,
          getTooltipItem: (group, groupIndex, rod, rodIndex) {
            return BarTooltipItem(
              rod.toY == 0 ? '' : '${rod.toY.toStringAsFixed(0)} ฿',
              const TextStyle(
                color: Color(0xFF4A6B5D),
                fontWeight: FontWeight.bold,
                fontSize: 11,
              ),
            );
          },
        ),
      ),

      titlesData: FlTitlesData(
        show: true,
        topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        bottomTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            getTitlesWidget: (double value, TitleMeta meta) {
              int index = value.toInt();
              if (index >= 0 && index < _chartData.length) {
                String label = _chartData[index]['label'].toString();

                // แปลงคำอธิบายแกน X ตาม Period
                if (_selectedPeriod == 'daily') {
                  label = "$label:00";
                } else if (_selectedPeriod == 'yearly') {
                  List<String> months = [
                    "ม.ค.", "ก.พ.", "มี.ค.", "เม.ย.", "พ.ค.", "มิ.ย.",
                    "ก.ค.", "ส.ค.", "ก.ย.", "ต.ค.", "พ.ย.", "ธ.ค."
                  ];
                  int mIdx = int.tryParse(label) ?? 1;
                  // คุม Index ไม่ให้ล้น 0-11 ป้องกัน RangeError
                  label = months[(mIdx - 1).clamp(0, 11)];
                }

                return Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    label,
                    style: const TextStyle(
                      fontSize: 11,
                      color: Color(0xFF6B7280),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                );
              }
              return const SizedBox.shrink();
            },
          ),
        ),
      ),
      borderData: FlBorderData(show: false),

      // สร้างกลุ่มแท่งกราฟ
      barGroups: _chartData.asMap().entries.map((entry) {
        int idx = entry.key;
        double val = (entry.value['total'] as num).toDouble();

        return BarChartGroupData(
          x: idx,
          showingTooltipIndicators: [0], 
          barRods: [
            BarChartRodData(
              toY: val,
              color: const Color(0xFF4A6B5D),
              width: _selectedPeriod == 'monthly' ? 8 : 16,
              borderRadius: BorderRadius.circular(6),
            ),
          ],
        );
      }).toList(),
    );
  }

  Widget _buildDropdown<T>({
    required T value,
    required List<DropdownMenuItem<T>> items,
    required ValueChanged<T?> onChanged,
  }) {
    return Container(
      height: 30,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFE2EBE6),
        borderRadius: BorderRadius.circular(8),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<T>(
          value: value,
          items: items,
          onChanged: onChanged,
          icon: const Icon(Icons.arrow_drop_down, color: Color(0xFF4A6B5D)),
          style: const TextStyle(
            color: Color(0xFF4A6B5D),
            fontSize: 12,
            fontWeight: FontWeight.bold,
          ),
          isDense: true,
        ),
      ),
    );
  }
}