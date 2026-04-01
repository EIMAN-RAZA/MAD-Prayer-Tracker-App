import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

void main() {
  runApp(const SalahTrackerApp());
}

class SalahTrackerApp extends StatelessWidget {
  const SalahTrackerApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Salah Tracker',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.teal,
        scaffoldBackgroundColor: const Color(0xFFF0F4F8),
        appBarTheme: const AppBarTheme(
          elevation: 0,
          backgroundColor: Color(0xFF00796B),
        ),
      ),
      home: const SalahHome(),
    );
  }
}

class PrayerTime {
  final String name;
  final String arabicName;
  final String time;
  final IconData icon;

  PrayerTime({
    required this.name,
    required this.arabicName,
    required this.time,
    required this.icon,
  });
}

class SalahRecord {
  final DateTime date;
  final Map<String, bool> prayers; // prayer name -> completed status
  final Map<String, String> prayerType; // On Time, Qaza, Jamaat

  SalahRecord({
    required this.date,
    required this.prayers,
    required this.prayerType,
  });
}

class SalahHome extends StatefulWidget {
  const SalahHome({Key? key}) : super(key: key);

  @override
  State<SalahHome> createState() => _SalahHomeState();
}

class _SalahHomeState extends State<SalahHome> {
  final List<String> prayerNames = ['Fajr', 'Dhuhr', 'Asr', 'Maghrib', 'Isha'];

  final Map<String, String> arabicNames = {
    'Fajr': 'الفجر',
    'Dhuhr': 'الظهر',
    'Asr': 'العصر',
    'Maghrib': 'المغرب',
    'Isha': 'العشاء',
  };

  final Map<String, IconData> prayerIcons = {
    'Fajr': Icons.wb_twilight,
    'Dhuhr': Icons.wb_sunny,
    'Asr': Icons.wb_sunny_outlined,
    'Maghrib': Icons.wb_twilight,
    'Isha': Icons.nightlight_round,
  };

  // Sample prayer times (you can integrate API later)
  final Map<String, String> prayerTimes = {
    'Fajr': '5:30 AM',
    'Dhuhr': '12:15 PM',
    'Asr': '3:45 PM',
    'Maghrib': '5:50 PM',
    'Isha': '7:15 PM',
  };

  // Store prayer records (date -> prayer status)
  Map<String, SalahRecord> salahRecords = {};

  DateTime selectedDate = DateTime.now();
  int currentStreak = 0;
  int totalPrayers = 0;

  @override
  void initState() {
    super.initState();
    _initializeSampleData();
    _calculateStats();
  }

  void _initializeSampleData() {
    // Add sample data for last 7 days
    for (int i = 0; i < 7; i++) {
      final date = DateTime.now().subtract(Duration(days: i));
      final dateKey = DateFormat('yyyy-MM-dd').format(date);

      salahRecords[dateKey] = SalahRecord(
        date: date,
        prayers: {
          'Fajr': i < 5,
          'Dhuhr': true,
          'Asr': true,
          'Maghrib': i < 6,
          'Isha': true,
        },
        prayerType: {
          'Fajr': i < 5 ? 'On Time' : 'Missed',
          'Dhuhr': 'Jamaat',
          'Asr': 'On Time',
          'Maghrib': i < 6 ? 'On Time' : 'Missed',
          'Isha': 'On Time',
        },
      );
    }
  }

  void _calculateStats() {
    int streak = 0;
    int total = 0;

    for (var record in salahRecords.values) {
      bool allPrayed = record.prayers.values.every((prayed) => prayed);
      if (allPrayed) streak++;
      total += record.prayers.values.where((prayed) => prayed).length;
    }

    setState(() {
      currentStreak = streak;
      totalPrayers = total;
    });
  }

  String _getDateKey(DateTime date) {
    return DateFormat('yyyy-MM-dd').format(date);
  }

  SalahRecord _getTodayRecord() {
    final dateKey = _getDateKey(selectedDate);
    return salahRecords[dateKey] ?? SalahRecord(
      date: selectedDate,
      prayers: {for (var name in prayerNames) name: false},
      prayerType: {for (var name in prayerNames) name: 'Missed'},
    );
  }

  void _togglePrayer(String prayerName, bool completed) {
    final dateKey = _getDateKey(selectedDate);

    setState(() {
      if (!salahRecords.containsKey(dateKey)) {
        salahRecords[dateKey] = SalahRecord(
          date: selectedDate,
          prayers: {for (var name in prayerNames) name: false},
          prayerType: {for (var name in prayerNames) name: 'Missed'},
        );
      }

      salahRecords[dateKey]!.prayers[prayerName] = completed;
      if (!completed) {
        salahRecords[dateKey]!.prayerType[prayerName] = 'Missed';
      }
      _calculateStats();
    });
  }

  void _showPrayerOptions(String prayerName) {
    final record = _getTodayRecord();
    final currentType = record.prayerType[prayerName] ?? 'Missed';

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Mark $prayerName Prayer',
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 24),
            _buildOptionTile('On Time', Icons.check_circle, Colors.green, currentType, prayerName),
            _buildOptionTile('Qaza (Late)', Icons.access_time, Colors.orange, currentType, prayerName),
            _buildOptionTile('Jamaat (Congregation)', Icons.groups, Colors.blue, currentType, prayerName),
            _buildOptionTile('Missed', Icons.cancel, Colors.red, currentType, prayerName),
          ],
        ),
      ),
    );
  }

  Widget _buildOptionTile(String type, IconData icon, Color color, String currentType, String prayerName) {
    final isSelected = currentType == type;
    return ListTile(
      leading: Icon(icon, color: color),
      title: Text(type, style: TextStyle(fontWeight: isSelected ? FontWeight.bold : FontWeight.normal)),
      trailing: isSelected ? const Icon(Icons.check, color: Colors.green) : null,
      tileColor: isSelected ? color.withOpacity(0.1) : null,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      onTap: () {
        final dateKey = _getDateKey(selectedDate);
        setState(() {
          if (!salahRecords.containsKey(dateKey)) {
            salahRecords[dateKey] = SalahRecord(
              date: selectedDate,
              prayers: {for (var name in prayerNames) name: false},
              prayerType: {for (var name in prayerNames) name: 'Missed'},
            );
          }
          salahRecords[dateKey]!.prayerType[prayerName] = type;
          salahRecords[dateKey]!.prayers[prayerName] = type != 'Missed';
          _calculateStats();
        });
        Navigator.pop(context);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final record = _getTodayRecord();
    final completedToday = record.prayers.values.where((v) => v).length;
    final percentage = (completedToday / 5 * 100).toInt();

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 200,
            floating: false,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFF00796B), Color(0xFF004D40)],
                  ),
                ),
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        const Text(
                          'Salah Tracker',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          DateFormat('EEEE, MMMM d, yyyy').format(selectedDate),
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  // Stats Cards
                  Row(
                    children: [
                      Expanded(
                        child: _buildStatCard(
                          'Today',
                          '$completedToday/5',
                          '$percentage%',
                          Icons.today,
                          Colors.teal,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildStatCard(
                          'Streak',
                          '$currentStreak Days',
                          '🔥',
                          Icons.local_fire_department,
                          Colors.orange,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _buildStatCard(
                          'Total Prayers',
                          '$totalPrayers',
                          'Completed',
                          Icons.check_circle,
                          Colors.green,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildStatCard(
                          'This Week',
                          '${_getWeeklyPercentage()}%',
                          'Success',
                          Icons.trending_up,
                          Colors.blue,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // Date Selector
                  _buildDateSelector(),

                  const SizedBox(height: 24),

                  // Prayer List
                  ...prayerNames.map((name) => _buildPrayerCard(name, record)),

                  const SizedBox(height: 80),
                ],
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showStatistics(),
        icon: const Icon(Icons.bar_chart),
        label: const Text('Statistics'),
        backgroundColor: const Color(0xFF00796B),
      ),
    );
  }

  Widget _buildStatCard(String title, String value, String subtitle, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              const Spacer(),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDateSelector() {
    return Container(
      height: 80,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: 14,
        itemBuilder: (context, index) {
          final date = DateTime.now().subtract(Duration(days: 13 - index));
          final isSelected = DateFormat('yyyy-MM-dd').format(date) ==
              DateFormat('yyyy-MM-dd').format(selectedDate);
          final dateKey = _getDateKey(date);
          final record = salahRecords[dateKey];
          final completedCount = record?.prayers.values.where((v) => v).length ?? 0;

          return GestureDetector(
            onTap: () {
              setState(() {
                selectedDate = date;
              });
            },
            child: Container(
              width: 60,
              margin: const EdgeInsets.only(right: 8),
              decoration: BoxDecoration(
                color: isSelected ? const Color(0xFF00796B) : Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isSelected ? const Color(0xFF00796B) : Colors.grey.shade300,
                  width: 2,
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    DateFormat('E').format(date),
                    style: TextStyle(
                      fontSize: 12,
                      color: isSelected ? Colors.white : Colors.grey.shade600,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    DateFormat('d').format(date),
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: isSelected ? Colors.white : Colors.black,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(
                      5,
                          (i) => Container(
                        width: 4,
                        height: 4,
                        margin: const EdgeInsets.symmetric(horizontal: 1),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: i < completedCount
                              ? (isSelected ? Colors.white : Colors.green)
                              : Colors.grey.shade300,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildPrayerCard(String name, SalahRecord record) {
    final isCompleted = record.prayers[name] ?? false;
    final prayerType = record.prayerType[name] ?? 'Missed';
    final color = _getPrayerTypeColor(prayerType);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _showPrayerOptions(name),
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(prayerIcons[name], color: color, size: 28),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            name,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            arabicNames[name]!,
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.grey.shade600,
                              fontFamily: 'Arial',
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(Icons.access_time, size: 14, color: Colors.grey.shade500),
                          const SizedBox(width: 4),
                          Text(
                            prayerTimes[name]!,
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey.shade600,
                            ),
                          ),
                          if (isCompleted) ...[
                            const SizedBox(width: 12),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: color.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                prayerType,
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: color,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
                Checkbox(
                  value: isCompleted,
                  onChanged: (value) => _togglePrayer(name, value ?? false),
                  activeColor: color,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Color _getPrayerTypeColor(String type) {
    switch (type) {
      case 'On Time':
        return Colors.green;
      case 'Qaza (Late)':
        return Colors.orange;
      case 'Jamaat (Congregation)':
        return Colors.blue;
      case 'Missed':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  int _getWeeklyPercentage() {
    final now = DateTime.now();
    int completed = 0;
    int total = 0;

    for (int i = 0; i < 7; i++) {
      final date = now.subtract(Duration(days: i));
      final dateKey = _getDateKey(date);
      final record = salahRecords[dateKey];
      if (record != null) {
        completed += record.prayers.values.where((v) => v).length;
        total += 5;
      }
    }

    return total > 0 ? (completed / total * 100).round() : 0;
  }

  void _showStatistics() {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Prayer Statistics',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 24),
              _buildStatRow('Total Prayers Offered', totalPrayers.toString()),
              _buildStatRow('Current Streak', '$currentStreak days'),
              _buildStatRow('Weekly Success', '${_getWeeklyPercentage()}%'),
              _buildStatRow('Today\'s Progress', '${_getTodayRecord().prayers.values.where((v) => v).length}/5'),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF00796B),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text('Close', style: TextStyle(fontSize: 16)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 16)),
          Text(
            value,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Color(0xFF00796B),
            ),
          ),
        ],
      ),
    );
  }
}