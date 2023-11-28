import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../widgets/admin_bottom_navigation_bar.dart';
import 'admin_add_announcement_screan.dart';

class AdminMainScreen extends StatefulWidget {
  AdminMainScreen({super.key});

  @override
  State<AdminMainScreen> createState() => _BarChartSample7State();
}

// 바 차트 상태
class _BarChartSample7State extends State<AdminMainScreen> {
  List<Map<String, dynamic>> dataList = [];
  List<Map<String, dynamic>> posts = [];
  int maxY = 0;
  int touchedGroupIndex = -1;
  bool isLoading = true; // 데이터 로딩 상태 추적을 위한 변수

  @override
  void initState() {
    super.initState();
    loadData();
  }

  Future<Map<String, int>> getDocumentCounts(String collection) async {
    var now = DateTime.now();
    var todayStart = DateTime(now.year, now.month, now.day);
    var yesterdayStart = todayStart.subtract(const Duration(days: 1));

    var todayTimestamp = Timestamp.fromDate(todayStart);
    var yesterdayTimestamp = Timestamp.fromDate(yesterdayStart);

    var todayQuery = FirebaseFirestore.instance
        .collection(collection)
        .where('createdTime', isGreaterThanOrEqualTo: todayTimestamp);
    var yesterdayQuery = FirebaseFirestore.instance
        .collection(collection)
        .where('createdTime', isGreaterThanOrEqualTo: yesterdayTimestamp)
        .where('createdTime', isLessThan: todayTimestamp);

    var todayQuerySnapshot = await todayQuery.get();
    var yesterdayQuerySnapshot = await yesterdayQuery.get();

    return {
      "today": todayQuerySnapshot.docs.length,
      "yesterday": yesterdayQuerySnapshot.docs.length
    };
  }

  Future<Map<String, Map<String, int>>> getReportCounts() async {
    var now = DateTime.now();
    var todayStart = DateTime(now.year, now.month, now.day);
    var yesterdayStart = todayStart.subtract(const Duration(days: 1));

    var yesterdayTimestamp = Timestamp.fromDate(yesterdayStart);

    var reportsSnapshot = await FirebaseFirestore.instance
        .collection('reports')
        .where('createdTime', isGreaterThanOrEqualTo: yesterdayTimestamp)
        .get();

    Map<String, int> todayCounts = {'post': 0, 'comment': 0, 'user': 0};
    Map<String, int> yesterdayCounts = {'post': 0, 'comment': 0, 'user': 0};

    for (var report in reportsSnapshot.docs) {
      DateTime reportTime =
      (report.data() as Map<String, dynamic>)['createdTime'].toDate();
      String entityType = report['entityType'];
      if (reportTime.isAfter(todayStart)) {
        todayCounts[entityType] = (todayCounts[entityType] ?? 0) + 1;
      } else if (reportTime.isAfter(yesterdayStart)) {
        yesterdayCounts[entityType] = (yesterdayCounts[entityType] ?? 0) + 1;
      }
    }

    return {"today": todayCounts, "yesterday": yesterdayCounts};
  }

  Future<void> loadData() async {
    setState(() {
      isLoading = true; // 데이터 로딩 시작
    });
    var expressBusPosts = await getDocumentCounts('express_bus_posts');
    var schoolPosts = await getDocumentCounts('school_posts');
    var trainPosts = await getDocumentCounts('train_posts');
    var comments = await getDocumentCounts('bus_chat');
    var users = await getDocumentCounts('users');
    var reports = await getReportCounts();

    setState(() {
      dataList = [
        {
          "color": Colors.blue,
          "today": expressBusPosts['today']! +
              schoolPosts['today']! +
              trainPosts['today']!,
          "yesterday": expressBusPosts['yesterday']! +
              schoolPosts['yesterday']! +
              trainPosts['yesterday']!,
          "label": "게시글 수",
          "icon": Icons.local_taxi
        },
        {
          "color": Colors.blue,
          "today": comments['today']!,
          "yesterday": comments['yesterday']!,
          "label": "댓글 수",
          "icon": Icons.directions_bus
        },
        {
          "color": Colors.blue,
          "today": users['today']!,
          "yesterday": users['yesterday']!,
          "label": "사용자 수",
          "icon": Icons.sentiment_very_satisfied
        },
        {
          "color": Colors.red,
          "today": reports['today']!['post']!,
          "yesterday": reports['yesterday']!['post']!,
          "label": "게시글 신고 수",
          "icon": Icons.taxi_alert
        },
        {
          "color": Colors.red,
          "today": reports['today']!['comment']!,
          "yesterday": reports['yesterday']!['comment']!,
          "label": "댓글 신고 수",
          "icon": Icons.bus_alert
        },
        {
          "color": Colors.red,
          "today": reports['today']!['user']!,
          "yesterday": reports['yesterday']!['user']!,
          "label": "사용자 신고 수",
          "icon": Icons.sentiment_very_dissatisfied
        },
      ];
      // 데이터 로딩 후 최대값 계산
      int calculatedMaxY = dataList.fold(0, (previousValue, element) {
        int todayMax = element['today'] ?? 0; // null 체크
        int yesterdayMax = element['yesterday'] ?? 0; // null 체크
        return max(previousValue, max(todayMax, yesterdayMax));
      });

      // 최대값이 0보다 크면 업데이트, 그렇지 않으면 기본값 유지
      if (calculatedMaxY > 0) {
        maxY = calculatedMaxY + 1; // 여유 공간을 위해 1 추가
      }
      isLoading = false; // 데이터 로딩 완료
    });
  }

  BarChartGroupData generateBarGroup(
      int x, Color color, int value, int shadowValue) {
    return BarChartGroupData(
      x: x,
      barRods: [
        BarChartRodData(
          toY: value.toDouble(),
          color: color,
          width: 6,
        ),
        BarChartRodData(
          toY: 0,
          color: Colors.grey,
          width: 1,
        ),
        BarChartRodData(
          toY: shadowValue.toDouble(),
          color: Colors.grey,
          width: 6,
        ),
      ],
      showingTooltipIndicators: touchedGroupIndex == x ? [0, 2] : [],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('금오로드 관리', style: TextStyle(color: Colors.black)),
        centerTitle: false,
        backgroundColor: Colors.white,
        elevation: 1,
        automaticallyImplyLeading: false,
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                Image.asset('assets/images/app_logo.png', width: 24, height: 24),
                const SizedBox(width: 8),
                const Text(
                  '금오로드 앱 하루 동향',
                  style: TextStyle(fontSize: 15),
                ),
              ],
            ),
          ),
          buildBarChart(dataList),
          buildChartLegend(),
          const Padding(
            padding: EdgeInsets.all(16.0),
            child: Row(
              children: [
                Icon(Icons.announcement, size: 24),
                SizedBox(width: 8),
                Text(
                  '공지사항',
                  style: TextStyle(fontSize: 15),
                ),
              ],
            ),
          ),
          buildAnnouncements()
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.of(context).push(
            MaterialPageRoute(builder: (context) => AddAnnouncementScreen()),
          );
        }, // Adjust icon size as needed
        mini: true,
        child: const Icon(Icons.add, size: 20), // Set to true to reduce the size of the FAB
      ),
      bottomNavigationBar:
      const AdminCustomBottomNavigationBar(selectedIndex: 0), // 예시 인덱스
    );
  }

  Widget buildBarChart(List<Map<String, dynamic>> dataList) {
    if (isLoading) {
      return const Expanded(
        child: Center(
          child: SizedBox(
            child: Center(child: CircularProgressIndicator()),
          ),
        ),
      );
    }
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24.0),
        child: BarChart(
          BarChartData(
            alignment: BarChartAlignment.spaceBetween,
            borderData: FlBorderData(
              show: true,
              border: Border.symmetric(
                horizontal: BorderSide(
                  color: Colors.white54.withOpacity(0.2),
                ),
              ),
            ),
            titlesData: FlTitlesData(
              show: true,
              leftTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 30,
                  getTitlesWidget: (value, meta) {
                    return Padding(
                      padding:
                      const EdgeInsets.only(right: 4.0), // 오른쪽 패딩 추가
                      child: Text(
                        value.toInt().toString(),
                        style: const TextStyle(fontSize: 10), // 글씨 크기 조정
                      ),
                    );
                  },
                ),
              ),
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 36,
                  getTitlesWidget: (value, meta) {
                    final index = value.toInt();
                    final icon = dataList[index]['icon'] as IconData;
                    final isSelected = index == touchedGroupIndex;
                    bool isReportIcon = [
                      Icons.taxi_alert,
                      Icons.bus_alert,
                      Icons.sentiment_very_dissatisfied
                    ].contains(icon);

                    return GestureDetector(
                      onTap: () {
                        setState(() {
                          touchedGroupIndex = index;
                        });
                      },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        padding:
                        const EdgeInsets.symmetric(vertical: 4.0),
                        child: Icon(
                          icon,
                          color: isSelected && isReportIcon
                              ? Colors.red
                              : (isSelected ? Colors.blue : Colors.grey),
                          size: isSelected ? 30 : 24,
                        ),
                      ),
                    );
                  },
                ),
              ),
              rightTitles: const AxisTitles(),
              topTitles: const AxisTitles(),
            ),
            gridData: FlGridData(
              show: true,
              drawVerticalLine: false,
              getDrawingHorizontalLine: (value) => const FlLine(
                color: Color(0x11FFFFFF),
                strokeWidth: 1,
              ),
            ),
            barGroups: dataList.asMap().entries.map((e) {
              final index = e.key;
              final data = e.value;
              return generateBarGroup(
                index,
                data['color'],
                data['today'],
                data['yesterday'],
              );
            }).toList(),
            maxY: maxY.toDouble(), // 계산된 maxY 값 사용
            barTouchData: BarTouchData(
              enabled: true, // 터치 활성화
              handleBuiltInTouches: true, // 기본 터치 처리 활성화
              touchTooltipData: BarTouchTooltipData(
                tooltipBgColor: Colors.transparent,
                tooltipMargin: 0,
                getTooltipItem: (
                    BarChartGroupData group,
                    int groupIndex,
                    BarChartRodData rod,
                    int rodIndex,
                    ) {
                  return BarTooltipItem(
                    '${rod.toY.toInt()}',
                    TextStyle(
                      fontWeight: FontWeight.bold,
                      color: rod.color,
                      fontSize: 18,
                      shadows: const [
                        Shadow(
                          color: Colors.black26,
                          blurRadius: 12,
                        ),
                      ],
                    ),
                  );
                },
              ),
              touchCallback: (event, response) {
                if (event.isInterestedForInteractions &&
                    response != null &&
                    response.spot != null) {
                  setState(() {
                    touchedGroupIndex =
                        response.spot!.touchedBarGroupIndex;
                  });
                } else {
                  setState(() {
                    touchedGroupIndex = -1;
                  });
                }
              },
            ),
          ),
        ),
      ),
    );
  }
  Widget buildChartLegend() {
    return const Padding(
      padding: EdgeInsets.all(16.0),
      child: Row(
        children: [
          Icon(Icons.square, color: Colors.blue),
          SizedBox(width: 4),
          Text("오늘"),
          SizedBox(width: 16),
          Icon(Icons.square, color: Colors.red),
          SizedBox(width: 4),
          Text("오늘 - 신고"),
          SizedBox(width: 16),
          Icon(Icons.square, color: Colors.grey),
          SizedBox(width: 4),
          Text("어제"),
        ],
      ),
    );
  }

  Widget buildAnnouncements() {
    return Expanded(
      child: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('announcements').orderBy('date', descending: true).snapshots(),
        builder: (BuildContext context, AsyncSnapshot<QuerySnapshot> snapshot) {
          if (snapshot.hasError) {
            return const Text('오류');
          }
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final data = snapshot.requireData;
          return ListView.builder(
            itemCount: data.size,
            itemBuilder: (context, index) {
              var announcement = data.docs[index];
              return Card(
                elevation: 4,
                margin: const EdgeInsets.all(3),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15), // 더 동그란 모서리
                ),
                child: ListTile(
                  leading: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      color: Colors.grey[400],
                    ),
                    child: Text(
                      announcement['type'],
                      style: const TextStyle(color: Colors.white),
                    ),
                  ),
                  title: Text(announcement['title']),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
