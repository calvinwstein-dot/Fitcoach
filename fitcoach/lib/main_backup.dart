// lib/main.dart
import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() => runApp(const FitCoachApp());

class FitCoachApp extends StatelessWidget {
  const FitCoachApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'FitCoach AI',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          brightness: Brightness.dark,
          seedColor: const Color(0xFF66C3FF),
        ),
        textTheme: GoogleFonts.interTextTheme(ThemeData.dark().textTheme),
        useMaterial3: true,
      ),
      home: const CoachScreen(),
    );
  }
}

class CoachScreen extends StatefulWidget {
  const CoachScreen({super.key});
  @override
  State<CoachScreen> createState() => _CoachScreenState();
}

class _CoachScreenState extends State<CoachScreen> with TickerProviderStateMixin {
  // TODO: replace with your real Replit URL (no trailing slash)
  String _serverUrl = 'https://63d0b674-9d16-478b-a272-e0513423bcfb-00-1pmi0mctu0qbh.janeway.replit.dev/';

  final TextEditingController _serverCtrl = TextEditingController();
  final AudioPlayer _player = AudioPlayer();
  final Random _rng = Random();

  int heartRate = 140;
  double distanceKm = 2.7;
  double paceMinPerKm = 4.9;
  late DateTime _start;
  Timer? _ticker;

  final double goalDistanceKm = 5.0;
  final int goalTimeSec = 25 * 60; // 25:00

  // Tab controller and calorie tracking
  late TabController _tabController;
  int _currentTabIndex = 0;
  int _caloriesBurned = 0;
  int _dailyCalorieGoal = 2500;
  int _caloriesConsumed = 1200;

  // Voice selection
  String _selectedVoice = "21m00Tcm4TlvDq8ikWAM"; // Default voice
  final Map<String, String> _voices = {
    "21m00Tcm4TlvDq8ikWAM": "Rachel (Default)",
    "AZnzlk1XvdvUeBnXmlld": "Domi",
    "EXAVITQu4vr4xnSDxMaL": "Bella",
    "ErXwobaYiN019PkySvjV": "Antoni",
    "MF3mGyEYCl7XYWbV9V6O": "Elli",
    "TxGEqnHWrfWFTfGW9XjX": "Josh",
    "VR6AewLTigWG4xSOukaG": "Arnold",
    "pNInz6obpgDQGcFmaJgB": "Adam",
    "yoZ06aMxZJJ28mfd3POQ": "Sam",
  };

  // Settings panel
  bool _showSettings = false;
  late AnimationController _settingsController;
  late Animation<double> _settingsAnimation;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      setState(() {
        _currentTabIndex = _tabController.index;
      });
    });
    _settingsController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _settingsAnimation = CurvedAnimation(
      parent: _settingsController,
      curve: Curves.easeInOut,
    );
    _serverCtrl.text = _serverUrl;
    _loadPreferences();
    _start = DateTime.now();
    _ticker = Timer.periodic(const Duration(seconds: 2), (_) => _simulateTick());
  }

  @override
  void dispose() {
    _ticker?.cancel();
    _player.dispose();
    _serverCtrl.dispose();
    _tabController.dispose();
    _settingsController.dispose();
    super.dispose();
  }

  Future<void> _savePreferences() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('server_url', _serverUrl);
  }

  Future<void> _loadPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    final savedUrl = prefs.getString('server_url');
    final savedVoice = prefs.getString('selected_voice');
    if (savedUrl != null) {
      setState(() {
        _serverUrl = savedUrl;
        _serverCtrl.text = savedUrl;
      });
    }
    if (savedVoice != null) {
      setState(() {
        _selectedVoice = savedVoice;
      });
    }
  }

  Future<void> _saveVoicePreference() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('selected_voice', _selectedVoice);
  }

  void _toggleSettings() {
    setState(() {
      _showSettings = !_showSettings;
    });
    if (_showSettings) {
      _settingsController.forward();
    } else {
      _settingsController.reverse();
    }
  }

  Future<void> _speak(String text) async {
    final uri = Uri.parse('$_serverUrl/tts?text=${Uri.encodeComponent(text)}&voice=$_selectedVoice');
    try {
      await _player.stop();
      await _player.play(UrlSource(uri.toString()));
    } catch (_) {
      // ignore playback errors in demo
    }
  }

  void _autoCue() {
    const int maxHr = 190;
    final bool high = heartRate > (0.90 * maxHr);
    final bool low = heartRate < (0.72 * maxHr);
    final int elapsedSec = DateTime.now().difference(_start).inSeconds;
    final bool onPace =
        (elapsedSec / goalTimeSec) <= (distanceKm / goalDistanceKm) + 0.03;

    String line;
    if (high) {
      line =
          "Ease it back a touch. Breathe, relax your shoulders—let’s keep it controlled.";
    } else if (low && !onPace) {
      line =
          "You’ve got more in you. Lift the knees, quicken the turnover—let’s nudge the pace.";
    } else {
      final double remain =
          (goalDistanceKm - distanceKm).clamp(0.0, goalDistanceKm);
      if (remain <= 1.0) {
        line =
            "Final push! Less than a kilometer to go. Tall posture, strong finish—go!";
      } else if (onPace) {
        line = "Perfect rhythm. You’re right on target—keep this smooth cadence.";
      } else {
        line =
            "Good work—lock into your breathing and settle into your best sustainable pace.";
      }
    }
    _speak(line);
  }

  void _simulateTick() {
    setState(() {
      heartRate = (heartRate + _rng.nextInt(5) - 2).clamp(110, 185);
      distanceKm += (paceMinPerKm <= 5.2 ? 0.02 : 0.015);
      paceMinPerKm =
          (paceMinPerKm + (_rng.nextDouble() - 0.5) * 0.06).clamp(4.2, 6.0);
      
      // Update calories burned based on heart rate and time
      final int elapsedMinutes = DateTime.now().difference(_start).inMinutes;
      _caloriesBurned = (elapsedMinutes * (heartRate / 150) * 8).round();
      
      if (_rng.nextDouble() < 0.35) _autoCue();
    });
  }

  String _elapsedString() {
    final int sec = DateTime.now().difference(_start).inSeconds;
    final String m = (sec ~/ 60).toString().padLeft(2, '0');
    final String s = (sec % 60).toString().padLeft(2, '0');
    return "$m:$s";
  }

  Widget _metricCard({
    required IconData icon,
    required String title,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.06),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white24),
      ),
      child: Row(
        children: [
          Icon(icon, size: 28, color: color),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: const TextStyle(fontSize: 13, color: Colors.white70)),
                const SizedBox(height: 4),
                Text(value,
                    style:
                        const TextStyle(fontSize: 22, fontWeight: FontWeight.w700)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final double distPct = (distanceKm / goalDistanceKm).clamp(0.0, 1.0);
    final double timePct =
        (DateTime.now().difference(_start).inSeconds / goalTimeSec)
            .clamp(0.0, 1.0);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.black.withOpacity(0.2),
        titleSpacing: 12,
        title: Row(
          children: [
            const CircleAvatar(
              radius: 14,
              backgroundColor: Color(0xFF141922),
              child: Icon(Icons.fitness_center, size: 16),
            ),
            const SizedBox(width: 10),
            const Text('FitCoach AI'),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.15),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.greenAccent.withOpacity(0.4)),
              ),
              child: const Row(children: [
                Icon(Icons.circle, size: 8, color: Colors.greenAccent),
                SizedBox(width: 6),
                Text('Running Session Active', style: TextStyle(fontSize: 12)),
              ]),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: RotationTransition(
              turns: Tween(begin: 0.0, end: 0.5).animate(_settingsAnimation),
              child: const Icon(Icons.settings),
            ),
            onPressed: _toggleSettings,
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.directions_run), text: 'Workout'),
            Tab(icon: Icon(Icons.local_fire_department), text: 'Calories'),
          ],
        ),
      ),
      body: Stack(
        children: [
          TabBarView(
            controller: _tabController,
            children: [
              _buildWorkoutTab(),
              _buildCalorieTab(),
            ],
          ),
          if (_showSettings) _buildSettingsPanel(),
        ],
      ),
    );
  }

  Widget _buildWorkoutTab() {
    final double distPct = (distanceKm / goalDistanceKm).clamp(0.0, 1.0);
    final double timePct =
        (DateTime.now().difference(_start).inSeconds / goalTimeSec)
            .clamp(0.0, 1.0);

    return Padding(
      padding: const EdgeInsets.all(16),
      child: ListView(
        children: [
            const SizedBox(height: 6),
            const Center(
              child: Column(
                children: [
                  Text('5K Morning Run',
                      style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700)),
                  SizedBox(height: 6),
                  Text('Central Park Loop • Goal: Sub 25:00',
                      style: TextStyle(color: Colors.white70)),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _metricCard(
                    icon: Icons.favorite,
                    title: 'Heart Rate',
                    value: '$heartRate BPM',
                    color: Colors.redAccent,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _metricCard(
                    icon: Icons.social_distance,
                    title: 'Distance',
                    value: '${distanceKm.toStringAsFixed(1)} KM',
                    color: Colors.lightBlueAccent,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _metricCard(
                    icon: Icons.speed,
                    title: 'Pace',
                    value: '${paceMinPerKm.toStringAsFixed(2)} MIN/KM',
                    color: Colors.orangeAccent,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _metricCard(
                    icon: Icons.timer,
                    title: 'Time',
                    value: _elapsedString(),
                    color: Colors.greenAccent,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.06),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.white24),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("Today's Goals",
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 12),
                  _goalBar(
                    'Distance Goal',
                    '${(distPct * 100).toStringAsFixed(0)}% • ${distanceKm.toStringAsFixed(1)} of $goalDistanceKm km',
                    distPct,
                  ),
                  const SizedBox(height: 10),
                  _goalBar(
                    'Target Time',
                    '${(timePct * 100).toStringAsFixed(0)}% • ${_elapsedString()} of 25:00',
                    timePct,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _speak(
                        "Great pace! You're ahead of your target. Keep this rhythm for another kilometer, then we’ll push."),
                    icon: const Icon(Icons.campaign),
                    label: const Padding(
                      padding: EdgeInsets.symmetric(vertical: 12),
                      child: Text('Motivate Me!'),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _autoCue,
                    icon: const Icon(Icons.psychology),
                    label: const Padding(
                      padding: EdgeInsets.symmetric(vertical: 12),
                      child: Text('Get Advice'),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.06),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.white24),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("Server Configuration",
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _serverCtrl,
                    decoration: const InputDecoration(
                      labelText: 'TTS Server URL',
                      hintText: 'Enter your server URL',
                      border: OutlineInputBorder(),
                    ),
                    onSubmitted: (value) async {
                      _serverUrl = value.trim();
                      await _savePreferences();
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCalorieTab() {
    final double calorieProgress = (_caloriesConsumed / _dailyCalorieGoal).clamp(0.0, 1.0);
    final int remainingCalories = (_dailyCalorieGoal - _caloriesConsumed + _caloriesBurned).clamp(0, _dailyCalorieGoal);

    return Padding(
      padding: const EdgeInsets.all(16),
      child: ListView(
        children: [
          const SizedBox(height: 6),
          const Center(
            child: Column(
              children: [
                Text('Daily Calorie Tracking',
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700)),
                SizedBox(height: 6),
                Text('Monitor your daily calorie balance',
                    style: TextStyle(color: Colors.white70)),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _metricCard(
                  icon: Icons.local_fire_department,
                  title: 'Burned',
                  value: '$_caloriesBurned CAL',
                  color: Colors.orangeAccent,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _metricCard(
                  icon: Icons.restaurant,
                  title: 'Consumed',
                  value: '$_caloriesConsumed CAL',
                  color: Colors.blueAccent,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _metricCard(
                  icon: Icons.track_changes,
                  title: 'Remaining',
                  value: '$remainingCalories CAL',
                  color: Colors.greenAccent,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _metricCard(
                  icon: Icons.flag,
                  title: 'Daily Goal',
                  value: '$_dailyCalorieGoal CAL',
                  color: Colors.purpleAccent,
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.06),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.white24),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text("Daily Progress",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
                const SizedBox(height: 12),
                _goalBar(
                  'Calorie Goal',
                  '${(calorieProgress * 100).toStringAsFixed(0)}% • $_caloriesConsumed of $_dailyCalorieGoal cal',
                  calorieProgress,
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.06),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.white24),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text("Voice Selection",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: _selectedVoice,
                  decoration: const InputDecoration(
                    labelText: 'Coach Voice',
                    border: OutlineInputBorder(),
                  ),
                  items: _voices.entries.map((entry) {
                    return DropdownMenuItem<String>(
                      value: entry.key,
                      child: Text(entry.value),
                    );
                  }).toList(),
                  onChanged: (String? newValue) {
                    if (newValue != null) {
                      setState(() {
                        _selectedVoice = newValue;
                      });
                      _saveVoicePreference();
                    }
                  },
                ),
                const SizedBox(height: 16),
                const Text("Test Voice Prompts",
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    ElevatedButton(
                      onPressed: () => _speak("Welcome to FitCoach! Let's get started with your workout."),
                      child: const Text('Welcome'),
                    ),
                    ElevatedButton(
                      onPressed: () => _speak("Great pace! You're ahead of your target. Keep this rhythm."),
                      child: const Text('Motivation'),
                    ),
                    ElevatedButton(
                      onPressed: () => _speak("Ease it back a touch. Breathe, relax your shoulders."),
                      child: const Text('Slow Down'),
                    ),
                    ElevatedButton(
                      onPressed: () => _speak("You've got more in you. Lift the knees, quicken the turnover."),
                      child: const Text('Speed Up'),
                    ),
                    ElevatedButton(
                      onPressed: () => _speak("Final push! Less than a kilometer to go. Strong finish!"),
                      child: const Text('Final Push'),
                    ),
                    ElevatedButton(
                      onPressed: () => _speak("Perfect rhythm. You're right on target—keep this smooth cadence."),
                      child: const Text('On Target'),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.06),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.white24),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text("Server Configuration",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
                const SizedBox(height: 12),
                TextField(
                  controller: _serverCtrl,
                  decoration: const InputDecoration(
                    labelText: 'TTS Server URL',
                    hintText: 'Enter your server URL',
                    border: OutlineInputBorder(),
                  ),
                  onSubmitted: (value) async {
                    _serverUrl = value.trim();
                    await _savePreferences();
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsPanel() {
    return AnimatedBuilder(
      animation: _settingsAnimation,
      builder: (context, child) {
        return Positioned(
          top: 0,
          right: -300 + (300 * _settingsAnimation.value),
          child: Container(
            width: 300,
            height: MediaQuery.of(context).size.height,
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.95),
              border: Border(
                left: BorderSide(color: Colors.white.withOpacity(0.2)),
              ),
            ),
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Settings',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: _toggleSettings,
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    const Text(
                      'Voice Selection',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.white.withOpacity(0.3)),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: _selectedVoice,
                          isExpanded: true,
                          dropdownColor: Colors.grey[900],
                          items: _voices.entries.map((entry) {
                            return DropdownMenuItem<String>(
                              value: entry.key,
                              child: Text(entry.value),
                            );
                          }).toList(),
                          onChanged: (String? newValue) {
                            if (newValue != null) {
                              setState(() {
                                _selectedVoice = newValue;
                              });
                              _saveVoicePreference();
                            }
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    const Text(
                      'Test Voice',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _settingsButton('Welcome', () => _speak("Welcome to FitCoach! Let's get started.")),
                        _settingsButton('Motivation', () => _speak("Great pace! Keep this rhythm.")),
                        _settingsButton('Slow Down', () => _speak("Ease it back a touch. Breathe, relax.")),
                        _settingsButton('Speed Up', () => _speak("You've got more in you. Quicken the pace.")),
                        _settingsButton('Final Push', () => _speak("Final push! Strong finish!")),
                      ],
                    ),
                    const SizedBox(height: 24),
                    const Text(
                      'Server Configuration',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _serverCtrl,
                      decoration: InputDecoration(
                        labelText: 'TTS Server URL',
                        hintText: 'Enter your server URL',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        filled: true,
                        fillColor: Colors.white.withOpacity(0.1),
                      ),
                      style: const TextStyle(fontSize: 14),
                      onSubmitted: (value) async {
                        _serverUrl = value.trim();
                        await _savePreferences();
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _settingsButton(String label, VoidCallback onPressed) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.white.withOpacity(0.1),
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 8),
        ),
        child: Text(label, style: const TextStyle(fontSize: 12)),
      ),
    );
  }

  Widget _goalBar(String title, String subtitle, double pct) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
        const SizedBox(height: 6),
        Stack(
          children: [
            Container(
              height: 10,
              decoration: BoxDecoration(
                color: Colors.white12,
                borderRadius: BorderRadius.circular(6),
              ),
            ),
            FractionallySizedBox(
              widthFactor: pct.clamp(0.0, 1.0),
              child: Container(
                height: 10,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(6),
                  gradient: const LinearGradient(
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                    colors: [Color(0xFF1FB7FF), Color(0xFFFFC061)],
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(subtitle, style: const TextStyle(color: Colors.white70)),
      ],
    );
  }
}