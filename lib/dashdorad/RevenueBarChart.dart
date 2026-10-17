import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:fl_chart/fl_chart.dart';
import 'package:cafa_boardgame/utils/appapi.dart';
import 'package:intl/intl.dart';

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
      final queryString =
          '/reports/revenue-chart?period=$_selectedPeriod&category=$_selectedCategory';

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
  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFF1F5F9)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F172A).withOpacity(0.04),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0D9488).withOpacity(0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.bar_chart_rounded,
                      color: Color(0xFF0D9488),
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 10),
                  const Text(
                    "สถิติรายได้",
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF1E293B),
                    ),
                  ),
                ],
              ),
              Row(
                children: [
                  _buildFilterDropdown(
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
                  _buildFilterDropdown(
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
          SizedBox(
            height: 260,
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(
                      color: Color(0xFF0D9488),
                      strokeWidth: 2.5,
                    ),
                  )
                : _chartData.isEmpty
                ? const Center(
                    child: Text(
                      "ไม่มีข้อมูลในช่วงเวลานี้",
                      style: TextStyle(color: Color(0xFF94A3B8)),
                    ),
                  )
                : BarChart(_buildBarChartData()),
          ),
        ],
      ),
    );
  }

  BarChartData _buildBarChartData() {
  double maxTotal = 0;
  for (var item in _chartData) {
    double val = (item['total'] as num).toDouble();
    if (val > maxTotal) maxTotal = val;
  }

  // 1. ตรวจสอบว่าช่วงนี้มียอดสูงสุดเท่าไหร่ เพื่อทำสเกลของแกน Y
  double ceilingY = maxTotal == 0 ? 500 : (maxTotal * 1.2); // เผื่อระยะด้านบนไว้ 20% เพื่อไม่ให้ตัวเลขราคาชนขอบบน

  return BarChartData(
    alignment: BarChartAlignment.spaceAround,
    maxY: ceilingY,
    
    // แสดงเส้นกริดแนวนอนแบบบางๆ
    gridData: FlGridData(
      show: true,
      drawVerticalLine: false,
      horizontalInterval: ceilingY / 5 > 0 ? ceilingY / 5 : 100, // แบ่งเป็น 5 ช่องตามสเกล
      getDrawingHorizontalLine: (value) => FlLine(
        color: const Color(0xFFE2E8F0),
        strokeWidth: 1,
      ),
    ),

    // กำหนด Tooltip / ป้ายราคาบนหัวแท่งให้โชว์ตลอดเวลา
    barTouchData: BarTouchData(
      enabled: false, // ปิดการตอบสนองตอนกด (เพื่อให้แสดงแบบ static ตลอดเวลา)
      touchTooltipData: BarTouchTooltipData(
        getTooltipColor: (group) => Colors.transparent, // ทำให้พื้นหลังโปร่งใสเพื่อเน้นตัวเลข
        tooltipPadding: EdgeInsets.zero,
        tooltipMargin: 6, // ระยะห่างจากหัวแท่ง
        getTooltipItem: (group, groupIndex, rod, rodIndex) {
          return BarTooltipItem(
            NumberFormat('#,##0').format(rod.toY),
            const TextStyle(
              color: Color(0xFF1E293B), // สีตัวเลขเข้มเห็นชัด
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          );
        },
      ),
    ),

    // ตั้งค่าแกน และชื่อ (แกน Y ด้านซ้าย และ แกน X ด้านล่าง)
    titlesData: FlTitlesData(
      show: true,
      topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
      rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
      
      // แสดงตัวเลขราคาแกน Y ฝั่งซ้าย
      leftTitles: AxisTitles(
        sideTitles: SideTitles(
          showTitles: true,
          reservedSize: 40,
          interval: ceilingY / 5 > 0 ? ceilingY / 5 : 100,
          getTitlesWidget: (value, meta) {
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: Text(
                NumberFormat('#,##0').format(value),
                textAlign: TextAlign.right,
                style: const TextStyle(
                  color: Color(0xFF94A3B8),
                  fontSize: 10,
                  fontWeight: FontWeight.w500,
                ),
              ),
            );
          },
        ),
      ),

      // แสดงป้ายกำกับแกน X ด้านล่าง
      bottomTitles: AxisTitles(
        sideTitles: SideTitles(
          showTitles: true,
          reservedSize: 28,
          getTitlesWidget: (double value, TitleMeta meta) {
            int index = value.toInt();
            if (index >= 0 && index < _chartData.length) {
              String label = _chartData[index]['label'].toString();
              if (_selectedPeriod == 'daily') {
                label = "$label:00";
              } else if (_selectedPeriod == 'yearly') {
                const months = ["ม.ค.", "ก.พ.", "มี.ค.", "เม.ย.", "พ.ค.", "มิ.ย.", "ก.ค.", "ส.ค.", "ก.ย.", "ต.ค.", "พ.ย.", "ธ.ค."];
                int mIdx = int.tryParse(label) ?? 1;
                label = months[(mIdx - 1).clamp(0, 11)];
              }
              return Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  label,
                  style: const TextStyle(
                    fontSize: 11, 
                    color: Color(0xFF64748B), 
                    fontWeight: FontWeight.w600
                  ),
                ),
              );
            }
            return const SizedBox.shrink();
          },
        ),
      ),
    ),
    borderData: FlBorderData(
      show: true,
      border: const Border(
        bottom: BorderSide(color: Color(0xFFCBD5E1), width: 1), // เส้นขอบล่าง
      ),
    ),

    // วาดกลุ่มแท่งกราฟ
    barGroups: _chartData.asMap().entries.map((entry) {
      int idx = entry.key;
      double val = (entry.value['total'] as num).toDouble();

      // สลับสีแต่ละแท่งเพื่อความสวยงามและแยกประเภทง่าย (น้ำเงิน, แดง, ฟ้า, เขียว ตามรูปตัวอย่าง)
      List<Color> barColors;
      if (idx % 4 == 0) {
        barColors = [const Color(0xFF2563EB), const Color(0xFF3B82F6)]; // น้ำเงิน
      } else if (idx % 4 == 1) {
        barColors = [const Color(0xFFEF4444), const Color(0xFFF87171)]; // แดง
      } else if (idx % 4 == 2) {
        barColors = [const Color(0xFF0EA5E9), const Color(0xFF38BDF8)]; // ฟ้า
      } else {
        barColors = [const Color(0xFF84CC16), const Color(0xFFA3E635)]; // เขียว
      }

      return BarChartGroupData(
        x: idx,
        showingTooltipIndicators: [0], // <--- สำคัญมาก: เพื่อบังคับให้แสดงตัวเลขราคาบนหัวแท่งตลอดเวลา
        barRods: [
          BarChartRodData(
            toY: val,
            gradient: LinearGradient(
              colors: barColors,
              begin: Alignment.bottomCenter,
              end: Alignment.topCenter,
            ),
            width: _selectedPeriod == 'monthly' ? 8 : 16, // ปรับความหนาของแท่ง
            borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
          ),
        ],
      );
    }).toList(),
  );
}

  Widget _buildFilterDropdown<T>({
    required T value,
    required List<DropdownMenuItem<T>> items,
    required ValueChanged<T?> onChanged,
  }) {
    return Container(
      height: 30,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<T>(
          value: value,
          items: items,
          onChanged: onChanged,
          icon: const Icon(
            Icons.arrow_drop_down,
            color: Color(0xFF64748B),
            size: 18,
          ),
          style: const TextStyle(
            color: Color(0xFF334155),
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
          isDense: true,
        ),
      ),
    );
  }
}
