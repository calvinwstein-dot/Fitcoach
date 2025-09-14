// lib/main.dart
import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';

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
  String _serverUrl = 'https://YOUR-REPLIT-SUBDOMAIN.replit.dev';

  final TextEditingController _serverCtrl = TextEditingController();
  final AudioPlayer _player = AudioPlayer();
  final Random _rng = Random();
  bool _audioUnlocked = false;

  int heartRate = 140;
  double distanceKm = 2.7;
  double paceMinPerKm = 4.9;
  late DateTime _start;
  Timer? _ticker;

  final double goalDistanceKm = 5.0;
  final int goalTimeSec = 25 * 60;

  // Tab controller
  late TabController _tabController;
  int _caloriesBurned = 0;

  // TTS controls (persisted)
  double _stability = 0.45;         // less robotic if 0.3–0.6
  double _similarity = 0.9;         // keep identity clear
  double _style = 0.7;              // more expressive (0–1)
  bool _speakerBoost = true;
  double _appVolume = 0.9;          // 0–1

  // Voice selection
  String _selectedVoice = "21m00Tcm4TlvDq8ikWAM";
  
  // 6 curated voices (3F/3M)
  final Map<String, String> _voices = const {
    "21m00Tcm4TlvDq8ikWAM": "Rachel (F)",
    "AZnzlk1XvdvUeBnXmlld": "Domi (F)",
    "EXAVITQu4vr4xnSDxMaL": "Bella (F)",
    "TxGEqnHWrfWFTfGW9XjX": "Josh (M)",
    "ErXwobaYiN019PkySvjV": "Antoni (M)",
    "pNInz6obpgDQGcFmaJgB": "Adam (M)",
  };

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 1, vsync: this);
    _serverCtrl.text = _serverUrl;
    _loadPreferences();
    _start = DateTime.now();
    _ticker = Timer.periodic(const Duration(seconds: 2), (_) => _simulateTick());
    
    // Initialize audio player for web
    if (kIsWeb) {
      _initializeWebAudio();
    }
  }
  
  void _initializeWebAudio() async {
    try {
      // Set audio context for web
      await _player.setPlayerMode(PlayerMode.lowLatency);
    } catch (e) {
      print('Web audio initialization failed: $e');
    }
  }

  @override
  void dispose() {
    _ticker?.cancel();
    _player.dispose();
    _serverCtrl.dispose();
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _savePreferences() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('server_url', _serverUrl);
    await prefs.setString('voice_id', _selectedVoice);
    await prefs.setDouble('tts_stability', _stability);
    await prefs.setDouble('tts_similarity', _similarity);
    await prefs.setDouble('tts_style', _style);
    await prefs.setBool('tts_speaker_boost', _speakerBoost);
    await prefs.setDouble('app_volume', _appVolume);
  }

  Future<void> _loadPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    final savedUrl = prefs.getString('server_url');
    if (savedUrl != null) {
      _serverUrl = savedUrl;
    }
    
    final v = prefs.getString('voice_id');
    if (v != null && _voices.containsKey(v)) _selectedVoice = v;
    _stability = prefs.getDouble('tts_stability') ?? _stability;
    _similarity = prefs.getDouble('tts_similarity') ?? _similarity;
    _style = prefs.getDouble('tts_style') ?? _style;
    _speakerBoost = prefs.getBool('tts_speaker_boost') ?? _speakerBoost;
    _appVolume = prefs.getDouble('app_volume') ?? _appVolume;
    await _player.setVolume(_appVolume.clamp(0.0, 1.0));
    setState(() {
      _serverCtrl.text = _serverUrl; // keep your existing server URL load
    });
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

  Future<void> _unlockAudio() async {
    if (_audioUnlocked) return;
    try {
      // tiny utterance to satisfy iOS user-gesture requirement
      final uri = Uri.parse('$_serverUrl/tts.mp3?text=%2E&voice=$_selectedVoice'); // "."
      await _player.stop();
      await _player.setReleaseMode(ReleaseMode.stop);
      await _player.play(UrlSource(uri.toString())); // call from a button tap
      _audioUnlocked = true;
    } catch (_) {
      // optional: show a hint
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('If audio doesn\'t start: tap Enable sound, or allow autoplay in Safari settings.')),
        );
      }
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
      line = "Back it off 5%. Drop the shoulders, soft hands, long exhale—control wins the race.";
    } else if (low && !onPace) {
      line = "You've got gears left. Quick feet, lift the chest—find that smooth, assertive rhythm.";
    } else {
      final remain = (goalDistanceKm - distanceKm).clamp(0.0, goalDistanceKm);
      if (remain <= 1.0) {
        line = "Last kilometer—this is yours. Tall posture, eyes up, breathe and **go**. Strong to the line!";
      } else if (onPace) {
        line = "Beautiful rhythm. You're right on plan—bank this feeling.";
      } else {
        line = "Good work. Settle, breathe, and lock into the best sustainable pace you own.";
      }
    }
    _speak(line);
  }

  void _simulateTick() {
    setState(() {
      heartRate = (heartRate + _rng.nextInt(5) - 2).clamp(110, 185);
      distanceKm += (paceMinPerKm <= 5.2 ? 0.02 : 0.015);
      paceMinPerKm = (paceMinPerKm + (_rng.nextDouble() - 0.5) * 0.06).clamp(4.2, 6.0);
      
      // Calculate calories burned
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
                Text(title, style: const TextStyle(fontSize: 13, color: Colors.white70)),
                const SizedBox(height: 4),
                Text(value, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _openSettings() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF121212),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.only(
            left: 16, right: 16,
            top: 16,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 16,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Text('Settings', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                    const Spacer(),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(ctx),
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                // Server URL
                const Text('TTS Server URL', style: TextStyle(fontWeight: FontWeight.w600)),
                const SizedBox(height: 6),
                TextField(
                  controller: _serverCtrl,
                  decoration: const InputDecoration(
                    hintText: 'https://your-tts.replit.dev',
                    border: OutlineInputBorder(),
                  ),
                  onSubmitted: (value) async {
                    _serverUrl = value.trim().replaceFirst(RegExp(r'/*$'), '');
                    _serverCtrl.text = _serverUrl;
                    await _savePreferences();
                  },
                ),

                const SizedBox(height: 16),

                // Voice
                const Text('Voice', style: TextStyle(fontWeight: FontWeight.w600)),
                const SizedBox(height: 6),
                DropdownButtonFormField<String>(
                  value: _selectedVoice,
                  isExpanded: true,
                  items: _voices.entries.map((e) =>
                    DropdownMenuItem(value: e.key, child: Text(e.value))).toList(),
                  onChanged: (v) async {
                    if (v == null) return;
                    setState(() => _selectedVoice = v);
                    await _savePreferences();
                  },
                  decoration: const InputDecoration(border: OutlineInputBorder()),
                ),

                const SizedBox(height: 16),

                // Emotion / naturalness
                const Text('Voice Naturalness', style: TextStyle(fontWeight: FontWeight.w600)),
                const SizedBox(height: 6),
                _sliderRow('Stability', _stability, (v) async { setState(() => _stability = v); await _savePreferences(); }),
                _sliderRow('Similarity', _similarity, (v) async { setState(() => _similarity = v); await _savePreferences(); }),
                _sliderRow('Style (expressive)', _style, (v) async { setState(() => _style = v); await _savePreferences(); }),

                const SizedBox(height: 10),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Speaker boost (richer presence)'),
                  value: _speakerBoost,
                  onChanged: (v) async { setState(() => _speakerBoost = v); await _savePreferences(); },
                ),

                const SizedBox(height: 10),
                _sliderRow('App volume', _appVolume, (v) async {
                  setState(() => _appVolume = v);
                  await _player.setVolume(v.clamp(0.0, 1.0));
                  await _savePreferences();
                }),

                const SizedBox(height: 16),
                Row(
                  children: [
                    ElevatedButton.icon(
                      onPressed: () => _speak("Hello! This is ${_voices[_selectedVoice]}. Let's run smart today."),
                      icon: const Icon(Icons.volume_up),
                      label: const Text('Test voice'),
                    ),
                    const SizedBox(width: 12),
                    OutlinedButton.icon(
                      onPressed: _unlockAudio,
                      icon: const Icon(Icons.lock_open),
                      label: const Text('Enable sound'),
                    ),
                  ],
                ),

                const SizedBox(height: 16),
                const Text('Coaching Test Prompts', style: TextStyle(fontWeight: FontWeight.w600)),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    ElevatedButton(
                      onPressed: () => _speak("Back it off 5%. Drop the shoulders, soft hands, long exhale—control wins the race."),
                      child: const Text('Heart Rate High'),
                    ),
                    ElevatedButton(
                      onPressed: () => _speak("You've got gears left. Quick feet, lift the chest—find that smooth, assertive rhythm."),
                      child: const Text('Heart Rate Low'),
                    ),
                    ElevatedButton(
                      onPressed: () => _speak("Last kilometer—this is yours. Tall posture, eyes up, breathe and go. Strong to the line!"),
                      child: const Text('Final Push'),
                    ),
                    ElevatedButton(
                      onPressed: () => _speak("Beautiful rhythm. You're right on plan—bank this feeling."),
                      child: const Text('On Pace'),
                    ),
                    ElevatedButton(
                      onPressed: () => _speak("Good work. Settle, breathe, and lock into the best sustainable pace you own."),
                      child: const Text('General Advice'),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
              ],
            ),
          ),
        );
      },
    );
  }

  // small helper widget for sliders
  Widget _sliderRow(String label, double value, ValueChanged<double> onChanged) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(label),
            const Spacer(),
            Text(value.toStringAsFixed(2), style: const TextStyle(color: Colors.white70)),
          ],
        ),
        Slider(value: value, onChanged: onChanged),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
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
            tooltip: 'Settings',
            icon: const Icon(Icons.settings),
            onPressed: _openSettings,
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.directions_run), text: 'Workout'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildWorkoutTab(),
        ],
      ),
    );
  }

  Widget _buildWorkoutTab() {
    final double distPct = (distanceKm / goalDistanceKm).clamp(0.0, 1.0);
    final double timePct = (DateTime.now().difference(_start).inSeconds / goalTimeSec).clamp(0.0, 1.0);

    return Padding(
      padding: const EdgeInsets.all(16),
      child: ListView(
        children: [
          const SizedBox(height: 6),
          const Center(
            child: Column(
              children: [
                Text('5K Morning Run', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700)),
                SizedBox(height: 6),
                Text('Central Park Loop • Goal: Sub 25:00', style: TextStyle(color: Colors.white70)),
              ],
            ),
          ),
          const SizedBox(height: 16),
          // Row 1: HR, Distance, Calories
          Row(
            children: [
              Expanded(child: _metricCard(icon: Icons.favorite, title: 'Heart Rate', value: '$heartRate BPM', color: Colors.redAccent)),
              const SizedBox(width: 12),
              Expanded(child: _metricCard(icon: Icons.social_distance, title: 'Distance', value: '${distanceKm.toStringAsFixed(1)} KM', color: Colors.lightBlueAccent)),
              const SizedBox(width: 12),
              Expanded(child: _metricCard(icon: Icons.local_fire_department, title: 'Calories', value: '$_caloriesBurned CAL', color: Colors.deepOrangeAccent)),
            ],
          ),
          const SizedBox(height: 12),

          // Row 2: Pace, Time
          Row(
            children: [
              Expanded(child: _metricCard(icon: Icons.speed, title: 'Pace', value: '${paceMinPerKm.toStringAsFixed(2)} MIN/KM', color: Colors.orangeAccent)),
              const SizedBox(width: 12),
              Expanded(child: _metricCard(icon: Icons.timer, title: 'Time', value: _elapsedString(), color: Colors.greenAccent)),
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
                const Text("Today's Goals", style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
                const SizedBox(height: 12),
                _goalBar('Distance Goal', '${(distPct * 100).toStringAsFixed(0)}% • ${distanceKm.toStringAsFixed(1)} of $goalDistanceKm km', distPct),
                const SizedBox(height: 10),
                _goalBar('Target Time', '${(timePct * 100).toStringAsFixed(0)}% • ${_elapsedString()} of 25:00', timePct),
              ],
            ),
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => _speak("Great pace! You're ahead of your target. Keep this rhythm for another kilometer, then we'll push."),
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
        ],
      ),
    );
  }



  Widget _goalBar(String title, String subtitle, double pct) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
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