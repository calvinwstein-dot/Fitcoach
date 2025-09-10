// lib/main.dart
import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:html' as html;

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
  final int goalTimeSec = 25 * 60;

  // Tab controller
  late TabController _tabController;
  int _caloriesBurned = 0;
  final int _dailyCalorieGoal = 2500;
  final int _caloriesConsumed = 1200;

  // Voice selection
  String _selectedVoice = "21m00Tcm4TlvDq8ikWAM";
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

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
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
    super.dispose();
  }

  Future<void> _savePreferences() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('server_url', _serverUrl);
    await prefs.setString('selected_voice', _selectedVoice);
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
    
    if (savedVoice != null && _voices.containsKey(savedVoice)) {
      setState(() {
        _selectedVoice = savedVoice;
      });
    }
  }

  Future<void> _speak(String text) async {
    try {
      // Try ElevenLabs TTS server first
      if (_serverUrl.isNotEmpty) {
        final uri = Uri.parse('$_serverUrl/tts?text=${Uri.encodeComponent(text)}&voice=$_selectedVoice');
        
        print('🔊 Attempting ElevenLabs TTS: $uri');
        
        // Stop any current playback
        await _player.stop();
        
        // Set player mode for web streaming
        await _player.setReleaseMode(ReleaseMode.stop);
        await _player.setPlayerMode(PlayerMode.mediaPlayer);
        
        // Try HTML5 audio first for better web compatibility
        try {
          final audioElement = html.AudioElement(uri.toString());
          audioElement.crossOrigin = 'anonymous';
          audioElement.preload = 'auto';
          
          // Wait for audio to load
          await audioElement.onCanPlay.first.timeout(const Duration(seconds: 5));
          
          // Play the audio
          await audioElement.play();
          
          print('✅ HTML5 audio playing successfully');
        } catch (htmlError) {
          print('⚠️ HTML5 audio failed: $htmlError, trying AudioPlayer...');
          
          // Fallback to AudioPlayer
          await _player.play(UrlSource(uri.toString()));
          print('🎵 AudioPlayer fallback used');
        }
        
        // Show success feedback
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('🔊 ElevenLabs ${_voices[_selectedVoice]}: "${text.length > 30 ? text.substring(0, 30) + '...' : text}"'),
              backgroundColor: Colors.green.withOpacity(0.8),
              duration: const Duration(seconds: 2),
            ),
          );
        }
        return;
      }
    } catch (e) {
      print('❌ ElevenLabs TTS failed: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('⚠️ ElevenLabs failed: $e. Using browser TTS...'),
            backgroundColor: Colors.orange.withOpacity(0.8),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    }
    
    // Fallback to browser's built-in speech synthesis
    try {
      print('🔄 Falling back to browser TTS');
      await _speakWithBrowserTTS(text);
    } catch (e) {
      print('❌ Browser TTS failed: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ All audio failed: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    }
  }

  Future<void> _testAudio() async {
    try {
      // First test ElevenLabs server connection
      if (_serverUrl.isNotEmpty) {
        final testUri = Uri.parse('$_serverUrl/tts?text=${Uri.encodeComponent("Testing ElevenLabs connection with ${_voices[_selectedVoice]} voice")}&voice=$_selectedVoice');
        
        print('Testing ElevenLabs with: $testUri');
        
        // Test with HTML5 audio for better web compatibility
        try {
          final audioElement = html.AudioElement(testUri.toString());
          audioElement.crossOrigin = 'anonymous';
          audioElement.preload = 'auto';
          
          await audioElement.onCanPlay.first.timeout(const Duration(seconds: 5));
          await audioElement.play();
          
          print('✅ ElevenLabs test successful with HTML5 audio');
        } catch (htmlError) {
          print('⚠️ HTML5 test failed: $htmlError, trying AudioPlayer...');
          await _player.stop();
          await _player.play(UrlSource(testUri.toString()));
        }
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('✅ ElevenLabs ${_voices[_selectedVoice]} voice test successful!'),
              backgroundColor: Colors.green,
              duration: const Duration(seconds: 3),
            ),
          );
        }
        return;
      }
    } catch (e) {
      print('ElevenLabs test failed: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('⚠️ ElevenLabs server unavailable. Testing browser TTS...'),
            backgroundColor: Colors.orange,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    }
    
    // Fallback to browser TTS test
    try {
      if (html.window.speechSynthesis != null) {
        final voices = html.window.speechSynthesis!.getVoices();
        final englishVoices = voices.where((v) => v.lang?.startsWith('en') == true).length;
        
        await _speakWithBrowserTTS("Browser TTS test successful! Found $englishVoices English voices available.");
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('✅ Browser TTS working! Found $englishVoices English voices.'),
              backgroundColor: Colors.blue,
              duration: const Duration(seconds: 3),
            ),
          );
        }
      } else {
        throw Exception('Speech synthesis not available');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Audio test failed: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    }
  }

  Future<void> _speakWithBrowserTTS(String text) async {
    // Use browser's built-in speech synthesis
    if (html.window.navigator.userAgent.contains('Chrome') || 
        html.window.navigator.userAgent.contains('Firefox') ||
        html.window.navigator.userAgent.contains('Safari')) {
      
      // Cancel any ongoing speech
      html.window.speechSynthesis?.cancel();
      
      // Create speech utterance
      final utterance = html.SpeechSynthesisUtterance(text);
      utterance.rate = 0.9;
      utterance.pitch = 1.0;
      utterance.volume = 0.8;
      
      // Get available voices
      final voices = html.window.speechSynthesis?.getVoices() ?? [];
      
      // Try to find a good English voice
      html.SpeechSynthesisVoice? selectedVoice;
      for (final voice in voices) {
        if (voice.lang?.startsWith('en') == true) {
          if (voice.name?.contains('Google') == true || 
              voice.name?.contains('Microsoft') == true || 
              voice.name?.contains('Alex') == true ||
              voice.name?.contains('Samantha') == true) {
            selectedVoice = voice;
            break;
          }
          selectedVoice ??= voice; // Fallback to first English voice
        }
      }
      
      if (selectedVoice != null) {
        utterance.voice = selectedVoice;
      }
      
      // Speak the text
      html.window.speechSynthesis?.speak(utterance);
      
      // Show feedback to user
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('🔊 Speaking: "${text.length > 30 ? text.substring(0, 30) + '...' : text}"'),
            backgroundColor: Colors.green.withOpacity(0.8),
            duration: const Duration(seconds: 1),
          ),
        );
      }
    } else {
      throw Exception('Speech synthesis not supported in this browser');
    }
  }

  void _autoCue() {
    const int maxHr = 190;
    final bool high = heartRate > (0.90 * maxHr);
    final bool low = heartRate < (0.72 * maxHr);
    final int elapsedSec = DateTime.now().difference(_start).inSeconds;
    final bool onPace =
        (elapsedSec / goalTimeSec) <= (distanceKm / goalDistanceKm) + 0.03;

    final List<String> highHrPrompts = [
      "Breathe deep, warrior! Control that fire inside you. Channel that power into smooth, controlled strides.",
      "Easy now, champion! Your heart is roaring with strength. Let's harness that energy and flow like water.",
      "Slow it down, beast! You're burning too hot. Cool that engine and let your body find its perfect rhythm.",
      "Relax those shoulders, fighter! Your heart is screaming with power. Let's use that strength wisely.",
      "Breathe through it, gladiator! That heart rate shows your incredible strength. Now let's control it like a master.",
      "Gentle now, powerful soul. Your heart is singing with energy. Let's channel that into graceful, flowing movement.",
      "Ease back, magnificent runner. Your cardiovascular system is working beautifully. Let's find that sweet sustainable zone.",
      "Breathe into calmness, strong one. Your heart is pumping with incredible efficiency. Trust your body's wisdom.",
      "Soften that intensity, champion. Your engine is running hot with power. Let's cool it to perfection.",
      "Flow with your breath, warrior. Your heart rate shows your incredible fitness. Now let's use it intelligently.",
      "Relax into your strength, athlete. Your cardiovascular system is firing on all cylinders. Let's moderate that power.",
      "Breathe deeply, runner. Your heart is demonstrating its incredible capacity. Let's harness that energy wisely.",
      "Ease into your rhythm, champion. Your body is showing its amazing power. Let's channel that into endurance.",
      "Calm that storm, warrior. Your heart rate reveals your incredible strength. Now let's control that beast.",
      "Breathe through the intensity, fighter. Your cardiovascular system is roaring. Let's tame that power.",
      "Gentle control, powerful runner. Your heart is beating with the rhythm of strength. Let's moderate that fire.",
      "Soften your effort, champion. Your body is demonstrating incredible power. Let's use that energy efficiently.",
      "Flow into calmness, athlete. Your heart rate shows your amazing fitness. Trust your body to find balance.",
      "Breathe into serenity, warrior. Your cardiovascular system is working magnificently. Let's optimize that power.",
      "Ease that intensity, strong soul. Your heart is pumping with incredible force. Let's channel that into grace."
    ];

    final List<String> lowHrSlowPrompts = [
      "WAKE UP THAT FIRE! You've got volcanic power inside you! Unleash it NOW! Drive those knees up!",
      "TIME TO EXPLODE! Your body is capable of so much more! DIG DEEPER! Find that beast within!",
      "IGNITE THAT ENGINE! You're holding back greatness! PUSH HARDER! Show me what you're made of!",
      "UNLEASH THE FURY! Your potential is limitless! FASTER! STRONGER! This is your moment to shine!",
      "BREAK THOSE CHAINS! You're stronger than you know! ACCELERATE! Let that inner warrior roar!",
      "DEMOLISH YOUR LIMITS! You're built for speed! CRUSH this pace! Your body craves more intensity!",
      "SHATTER THAT COMFORT ZONE! You're a speed demon! ACCELERATE! Show the world your true power!",
      "OBLITERATE THAT HESITATION! Your legs are rockets! LAUNCH! This is where legends are born!",
      "ANNIHILATE THAT DOUBT! You're pure lightning! STRIKE! Your potential is absolutely limitless!",
      "DESTROY THAT FEAR! You're a running machine! DOMINATE! Every step should thunder with power!",
      "PULVERIZE THAT RESISTANCE! Your body is screaming for speed! UNLEASH! You're unstoppable force!",
      "VAPORIZE THAT HOLDING BACK! You're built for velocity! EXPLODE! This is your moment of truth!",
      "INCINERATE THAT CAUTION! Your spirit demands more! SURGE! You're capable of incredible things!",
      "EVISCERATE THAT COMFORT! You're a speed warrior! CHARGE! Your body is begging for intensity!",
      "OBLITERATE THAT RESTRAINT! You're pure kinetic energy! DETONATE! Show me that inner fire!",
      "ANNIHILATE THAT TIMIDITY! Your legs are pistons of power! FIRE! This is where you transcend!",
      "DEMOLISH THAT RESERVATION! You're a velocity machine! IGNITE! Your potential knows no bounds!",
      "SHATTER THAT HESITATION! Your body is craving speed! EXPLODE! You're built for greatness!",
      "CRUSH THAT DOUBT! You're lightning in human form! STRIKE! This is your defining moment!",
      "DESTROY THAT LIMITATION! Your spirit is pure acceleration! LAUNCH! You're absolutely magnificent!"
    ];

    final List<String> finalPushPrompts = [
      "THIS IS IT! FINAL KILOMETER! You're a MACHINE! DESTROY this finish line! NOTHING can stop you!",
      "VICTORY IS YOURS! Less than 1K left! You're UNSTOPPABLE! CRUSH this final stretch like the champion you are!",
      "FINISH STRONG, WARRIOR! Your body is pure power! DOMINATE these final meters! GLORY awaits!",
      "FINAL PUSH, LEGEND! You've got LIGHTNING in your legs! EXPLODE to that finish! You're INVINCIBLE!",
      "LAST KILOMETER, CHAMPION! Your heart beats with the rhythm of victory! CONQUER this moment!",
      "ANNIHILATE THIS DISTANCE! You're a TERMINATOR! OBLITERATE every meter! Victory is inevitable!",
      "DEMOLISH THIS FINAL STRETCH! You're PURE DYNAMITE! DETONATE your way to glory! You're UNSTOPPABLE!",
      "VAPORIZE THIS LAST KILOMETER! You're a ROCKET! LAUNCH into legendary status! NOTHING can contain you!",
      "INCINERATE THIS FINISH! You're MOLTEN STEEL! FORGE your way to triumph! You're ABSOLUTELY INVINCIBLE!",
      "PULVERIZE THIS DISTANCE! You're a HURRICANE! DEVASTATE this final push! GREATNESS is your destiny!",
      "EVISCERATE THESE METERS! You're PURE LIGHTNING! ELECTRIFY this finish! You're BEYOND LIMITS!",
      "OBLITERATE THIS CHALLENGE! You're a JUGGERNAUT! STEAMROLL to victory! NOTHING can stop your power!",
      "SHATTER THIS FINAL BARRIER! You're EXPLOSIVE FORCE! DETONATE across that line! You're MAGNIFICENT!",
      "CRUSH THIS LAST PUSH! You're a BATTERING RAM! SMASH through to glory! Victory BELONGS to you!",
      "DESTROY THIS FINAL TEST! You're PURE ENERGY! SURGE to triumph! You're ABSOLUTELY PHENOMENAL!",
      "ANNIHILATE THIS DISTANCE! You're a FORCE OF NATURE! UNLEASH your final fury! LEGENDARY awaits!",
      "DEMOLISH THIS STRETCH! You're CONCENTRATED POWER! EXPLODE into victory! You're TRULY INVINCIBLE!",
      "VAPORIZE THIS CHALLENGE! You're LIQUID LIGHTNING! FLOW to greatness! NOTHING can match your will!",
      "INCINERATE THIS FINAL PUSH! You're PURE DETERMINATION! BURN through to glory! You're ABSOLUTELY UNSTOPPABLE!",
      "OBLITERATE THIS MOMENT! You're DESTINY INCARNATE! TRANSCEND into legend! This is YOUR time to SHINE!"
    ];

    final List<String> onPacePrompts = [
      "Perfect harmony, beautiful soul. You're flowing like poetry in motion. This rhythm is pure magic.",
      "Absolutely sublime! Your body and spirit are dancing together perfectly. Stay in this gorgeous flow.",
      "You're in the zone, magnificent athlete. This cadence is pure art. Feel the beauty of your movement.",
      "Breathtaking rhythm! You're gliding like you were born to run. This is your natural state of grace.",
      "Pure perfection! Your body knows exactly what to do. Trust this beautiful rhythm you've created.",
      "Exquisite form, graceful runner. You're moving with the elegance of a gazelle. This is your sweet spot.",
      "Magnificent cadence! Your body is singing with perfect timing. Stay locked into this beautiful rhythm.",
      "Flawless execution, champion. You're flowing like water over stones. This pace is absolutely divine.",
      "Stunning precision! Your movement is like watching art in motion. Hold this perfect synchronization.",
      "Incredible balance, warrior. You're gliding with the grace of an eagle. This rhythm is your masterpiece.",
      "Seamless flow, beautiful athlete. Your body is humming with perfect efficiency. This is running nirvana.",
      "Gorgeous tempo! You're moving with the fluidity of silk. Stay embraced in this perfect cadence.",
      "Sublime execution, champion. Your stride is like music made visible. This rhythm is pure poetry.",
      "Effortless grace, magnificent runner. You're floating with the lightness of air. This pace is perfection.",
      "Harmonious movement, strong soul. Your body is dancing with perfect timing. This is your natural rhythm.",
      "Elegant precision! You're flowing like a river finding its course. Stay connected to this beautiful pace.",
      "Transcendent form, graceful warrior. Your movement is like watching meditation in motion. Pure bliss.",
      "Serene power, beautiful runner. You're gliding with the calmness of still water. This rhythm is sacred.",
      "Perfect synchronization! Your body is operating like a finely tuned instrument. This is running zen.",
      "Divine cadence, magnificent athlete. You're moving with the grace of nature itself. This is your element."
    ];

    final List<String> generalPrompts = [
      "Find your center, strong one. Let your breath guide you to that sweet spot where everything clicks.",
      "Settle into your power, champion. Your body is wise and knows the perfect pace for greatness.",
      "Breathe into your strength. Feel your body finding its natural, sustainable rhythm of excellence.",
      "Trust your instincts, warrior. Your body is calibrating to the perfect balance of power and endurance.",
      "Flow with your breath, beautiful runner. Let your body teach you the rhythm of sustained excellence.",
      "Connect with your inner compass, athlete. Your body holds the wisdom of perfect pacing. Listen deeply.",
      "Embrace your natural rhythm, champion. Your cardiovascular system knows exactly what it needs. Trust it.",
      "Breathe into your power center, warrior. Your body is finding its optimal zone of performance. Feel it.",
      "Align with your body's intelligence, runner. Your heart and lungs are calibrating to perfection. Allow it.",
      "Sink into your sustainable strength, champion. Your body is teaching you the art of endurance. Learn from it.",
      "Flow with your internal metronome, athlete. Your body's rhythm is guiding you to excellence. Follow it.",
      "Trust your body's feedback, warrior. Your cardiovascular system is fine-tuning for optimal performance. Respect it.",
      "Breathe into your zone of power, runner. Your body knows the perfect balance of effort and efficiency. Embrace it.",
      "Connect with your running soul, champion. Your body is finding its natural state of flowing strength. Feel it.",
      "Settle into your body's wisdom, athlete. Your heart rate is teaching you the rhythm of sustained power. Listen.",
      "Flow with your breath's guidance, warrior. Your body is calibrating to its most efficient operating zone. Trust it.",
      "Embrace your body's intelligence, runner. Your cardiovascular system is finding its sweet spot of performance. Allow it.",
      "Breathe into your center of strength, champion. Your body knows how to sustain this beautiful effort. Believe in it.",
      "Trust your internal guidance system, athlete. Your body is teaching you the art of intelligent pacing. Learn from it.",
      "Flow with your natural cadence, warrior. Your body's rhythm is leading you to sustained excellence. Follow its wisdom."
    ];

    String line;
    if (high) {
      line = highHrPrompts[_rng.nextInt(highHrPrompts.length)];
    } else if (low && !onPace) {
      line = lowHrSlowPrompts[_rng.nextInt(lowHrSlowPrompts.length)];
    } else {
      final double remain = (goalDistanceKm - distanceKm).clamp(0.0, goalDistanceKm);
      if (remain <= 1.0) {
        line = finalPushPrompts[_rng.nextInt(finalPushPrompts.length)];
      } else if (onPace) {
        line = onPacePrompts[_rng.nextInt(onPacePrompts.length)];
      } else {
        line = generalPrompts[_rng.nextInt(generalPrompts.length)];
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

  void _showSettingsDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: const Color(0xFF1E1E1E),
              title: const Text('Settings', style: TextStyle(color: Colors.white)),
              content: SizedBox(
                width: 400,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Voice Selection', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white70)),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.white24),
                      ),
                      child: DropdownButton<String>(
                        value: _selectedVoice,
                        isExpanded: true,
                        dropdownColor: const Color(0xFF2E2E2E),
                        style: const TextStyle(color: Colors.white),
                        underline: Container(),
                        items: _voices.entries.map((entry) {
                          return DropdownMenuItem<String>(
                            value: entry.key,
                            child: Text(entry.value, style: const TextStyle(color: Colors.white)),
                          );
                        }).toList(),
                        onChanged: (String? newValue) async {
                          if (newValue != null) {
                            setDialogState(() {
                              _selectedVoice = newValue;
                            });
                            setState(() {
                              _selectedVoice = newValue;
                            });
                            
                            // Immediately save the voice selection
                            final prefs = await SharedPreferences.getInstance();
                            await prefs.setString('selected_voice', newValue);
                            
                            // Test the new voice
                            await _speak("Voice changed to ${_voices[newValue]}. This is how I sound!");
                          }
                        },
                      ),
                    ),
                    const SizedBox(height: 20),
                    const Text('TTS Server URL', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white70)),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _serverCtrl,
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        hintText: 'Enter TTS server URL',
                        hintStyle: const TextStyle(color: Colors.white54),
                        helperText: 'Default: ElevenLabs via Replit server',
                        helperStyle: const TextStyle(color: Colors.white38, fontSize: 12),
                        filled: true,
                        fillColor: Colors.white.withOpacity(0.1),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: const BorderSide(color: Colors.white24),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: const BorderSide(color: Colors.white24),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: const BorderSide(color: Colors.blueAccent),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () {
                              _serverCtrl.text = 'https://63d0b674-9d16-478b-a272-e0513423bcfb-00-1pmi0mctu0qbh.janeway.replit.dev/';
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.purple.withOpacity(0.2),
                              foregroundColor: Colors.purpleAccent,
                            ),
                            child: const Text('Reset Default'),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton(
                            onPressed: _testAudio,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green.withOpacity(0.2),
                              foregroundColor: Colors.greenAccent,
                            ),
                            child: const Text('Test Audio'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () async {
                              final prefs = await SharedPreferences.getInstance();
                              await prefs.setString('server_url', _serverCtrl.text);
                              await prefs.setString('selected_voice', _selectedVoice);
                              setState(() {
                                _serverUrl = _serverCtrl.text;
                              });
                              Navigator.of(context).pop();
                              
                              // Show confirmation
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('✅ Settings saved! Voice: ${_voices[_selectedVoice]}'),
                                  backgroundColor: Colors.green.withOpacity(0.8),
                                  duration: const Duration(seconds: 2),
                                ),
                              );
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blue.withOpacity(0.2),
                              foregroundColor: Colors.blueAccent,
                            ),
                            child: const Text('Save'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Close', style: TextStyle(color: Colors.white70)),
                ),
              ],
            );
          },
        );
      },
    );
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
            icon: const Icon(Icons.settings),
            onPressed: _showSettingsDialog,
            tooltip: 'Settings',
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
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildWorkoutTab(),
          _buildCalorieTab(),
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
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _metricCard(
                  icon: Icons.local_fire_department,
                  title: 'Calories',
                  value: '$_caloriesBurned CAL',
                  color: Colors.deepOrangeAccent,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _metricCard(
                  icon: Icons.trending_up,
                  title: 'Net Balance',
                  value: '${(_dailyCalorieGoal - _caloriesConsumed + _caloriesBurned).clamp(0, _dailyCalorieGoal)} CAL',
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

  Widget _buildCalorieTab() {
    final int remainingCalories = (_dailyCalorieGoal - _caloriesConsumed + _caloriesBurned).clamp(0, _dailyCalorieGoal);

    return Padding(
      padding: const EdgeInsets.all(16),
      child: ListView(
        children: [
          const SizedBox(height: 6),
          const Center(
            child: Column(
              children: [
                Text('Daily Calorie Tracking', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700)),
                SizedBox(height: 6),
                Text('Monitor your daily calorie balance', style: TextStyle(color: Colors.white70)),
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
                const Text("Voice Selection", style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
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
                    }
                  },
                ),
                const SizedBox(height: 16),
                const Text("Test Voice Prompts", style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.blue.withOpacity(0.3)),
                  ),
                  child: const Text(
                    '🔊 Audio uses browser speech synthesis. Click any button below to test.',
                    style: TextStyle(fontSize: 12, color: Colors.blue),
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () => _testAudio(),
                    icon: const Icon(Icons.volume_up),
                    label: const Text('🔊 Test Audio System'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green.withOpacity(0.2),
                      foregroundColor: Colors.green,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    ElevatedButton.icon(
                      onPressed: () => _speak("Welcome to FitCoach! Let's get started with your workout."),
                      icon: const Icon(Icons.waving_hand, size: 16),
                      label: const Text('Welcome'),
                    ),
                    ElevatedButton.icon(
                      onPressed: () => _speak("Great pace! You're ahead of your target. Keep this rhythm."),
                      icon: const Icon(Icons.thumb_up, size: 16),
                      label: const Text('Motivation'),
                    ),
                    ElevatedButton.icon(
                      onPressed: () => _speak("Ease it back a touch. Breathe, relax your shoulders."),
                      icon: const Icon(Icons.trending_down, size: 16),
                      label: const Text('Slow Down'),
                    ),
                    ElevatedButton.icon(
                      onPressed: () => _speak("You've got more in you. Lift the knees, quicken the turnover."),
                      icon: const Icon(Icons.trending_up, size: 16),
                      label: const Text('Speed Up'),
                    ),
                    ElevatedButton.icon(
                      onPressed: () => _speak("Final push! Less than a kilometer to go. Strong finish!"),
                      icon: const Icon(Icons.flag, size: 16),
                      label: const Text('Final Push'),
                    ),
                    ElevatedButton.icon(
                      onPressed: () => _speak("Perfect rhythm. You're right on target. Keep this smooth cadence."),
                      icon: const Icon(Icons.track_changes, size: 16),
                      label: const Text('On Target'),
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
                const Text("Server Configuration", style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
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