// ElevenLabs v3 TTS Server with highest quality settings
const express = require('express');
const cors = require('cors');
const fetch = require('node-fetch');

const app = express();
const PORT = process.env.PORT || 3000;

// Enable CORS for all origins
app.use(cors());
app.use(express.json());

// ElevenLabs API configuration
const ELEVENLABS_API_KEY = process.env.ELEVENLABS_API_KEY;
const ELEVENLABS_API_URL = 'https://api.elevenlabs.io/v1';

// High-quality voice settings for maximum realism
const VOICE_SETTINGS = {
  stability: 0.75,           // Consistent voice
  similarity_boost: 0.85,    // More realistic
  style: 0.2,               // Natural expression
  use_speaker_boost: true    // Clearer audio
};

// Premium voice IDs for ElevenLabs v3 (most realistic)
const VOICES = {
  '21m00Tcm4TlvDq8ikWAM': 'Rachel',      // Premium female
  'AZnzlk1XvdvUeBnXmlld': 'Domi',        // Premium female
  'EXAVITQu4vr4xnSDxMaL': 'Bella',       // Premium female
  'ErXwobaYiN019PkySvjV': 'Antoni',      // Premium male
  'MF3mGyEYCl7XYWbV9V6O': 'Elli',        // Premium female
  'TxGEqnHWrfWFTfGW9XjX': 'Josh',        // Premium male
  'VR6AewLTigWG4xSOukaG': 'Arnold',      // Premium male
  'pNInz6obpgDQGcFmaJgB': 'Adam',        // Premium male
  'yoZ06aMxZJJ28mfd3POQ': 'Sam'          // Premium male
};

app.get('/', (req, res) => {
  res.send('ElevenLabs v3 TTS Server - Ultra High Quality Voices');
});

app.get('/voices', (req, res) => {
  res.json(VOICES);
});

app.get('/tts', async (req, res) => {
  try {
    const { text, voice } = req.query;
    
    if (!text) {
      return res.status(400).json({ error: 'Text parameter is required' });
    }
    
    const voiceId = voice || '21m00Tcm4TlvDq8ikWAM'; // Default to Rachel
    
    if (!VOICES[voiceId]) {
      return res.status(400).json({ error: 'Invalid voice ID' });
    }
    
    if (!ELEVENLABS_API_KEY) {
      return res.status(500).json({ error: 'ElevenLabs API key not configured' });
    }
    
    console.log(`🔊 Generating TTS: "${text}" with voice ${VOICES[voiceId]} (${voiceId})`);
    
    // Call ElevenLabs v3 API with highest quality settings
    const response = await fetch(`${ELEVENLABS_API_URL}/text-to-speech/${voiceId}`, {
      method: 'POST',
      headers: {
        'Accept': 'audio/mpeg',
        'Content-Type': 'application/json',
        'xi-api-key': ELEVENLABS_API_KEY
      },
      body: JSON.stringify({
        text: text,
        model_id: 'eleven_turbo_v2_5',  // Latest high-quality model
        voice_settings: VOICE_SETTINGS
      })
    });
    
    if (!response.ok) {
      const errorText = await response.text();
      console.error('ElevenLabs API error:', response.status, errorText);
      return res.status(response.status).json({ 
        error: 'ElevenLabs API error', 
        details: errorText 
      });
    }
    
    // Stream the audio response
    res.set({
      'Content-Type': 'audio/mpeg',
      'Content-Disposition': 'inline; filename="tts.mp3"',
      'Access-Control-Allow-Origin': '*',
      'Access-Control-Allow-Methods': 'GET, OPTIONS',
      'Access-Control-Allow-Headers': 'Content-Type'
    });
    
    response.body.pipe(res);
    
  } catch (error) {
    console.error('TTS Error:', error);
    res.status(500).json({ error: 'Internal server error', details: error.message });
  }
});

app.listen(PORT, () => {
  console.log(`🚀 ElevenLabs v3 TTS Server running on port ${PORT}`);
  console.log(`📢 Available voices:`, Object.values(VOICES).join(', '));
  console.log(`🎯 Using model: eleven_turbo_v2_5 (Ultra High Quality)`);
});