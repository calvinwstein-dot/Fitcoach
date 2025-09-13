// ElevenLabs TTS Server - Fixed for Flutter Web Audio
const express = require('express');
const cors = require('cors');
const https = require('https');

const app = express();
const PORT = process.env.PORT || 3000;

// Enhanced CORS for audio streaming
app.use(cors({
  origin: '*',
  methods: ['GET', 'POST', 'OPTIONS'],
  allowedHeaders: ['Content-Type', 'Authorization', 'Range'],
  exposedHeaders: ['Content-Length', 'Content-Range', 'Accept-Ranges']
}));

// Your ElevenLabs API key (secure on server)
const ELEVENLABS_API_KEY = 'sk_320f8a8f6666297cb40a34ac3be695ac7c330b7d79cb3d44';

app.get('/', (req, res) => {
  res.send('ElevenLabs TTS Server Running for FitCoach AI - Audio Fixed');
});

app.get('/tts', async (req, res) => {
  const { text, voice } = req.query;
  
  if (!text) {
    return res.status(400).json({ error: 'Text parameter required' });
  }
  
  const voiceId = voice || '21m00Tcm4TlvDq8ikWAM';
  
  console.log(`🔊 TTS Request: "${text}" with voice ${voiceId}`);
  
  const postData = JSON.stringify({
    text: text,
    model_id: 'eleven_multilingual_v2',
    voice_settings: {
      stability: 0.75,
      similarity_boost: 0.85,
      style: 0.2,
      use_speaker_boost: true
    }
  });
  
  const options = {
    hostname: 'api.elevenlabs.io',
    port: 443,
    path: `/v1/text-to-speech/${voiceId}`,
    method: 'POST',
    headers: {
      'Accept': 'audio/mpeg',
      'Content-Type': 'application/json',
      'xi-api-key': ELEVENLABS_API_KEY,
      'Content-Length': Buffer.byteLength(postData)
    }
  };
  
  const request = https.request(options, (response) => {
    if (response.statusCode === 200) {
      // Enhanced headers for web audio compatibility
      res.set({
        'Content-Type': 'audio/mpeg',
        'Access-Control-Allow-Origin': '*',
        'Access-Control-Allow-Methods': 'GET, POST, OPTIONS',
        'Access-Control-Allow-Headers': 'Content-Type, Authorization, Range',
        'Access-Control-Expose-Headers': 'Content-Length, Content-Range, Accept-Ranges',
        'Cache-Control': 'no-cache, no-store, must-revalidate',
        'Pragma': 'no-cache',
        'Expires': '0',
        'Accept-Ranges': 'bytes'
      });
      
      // Handle range requests for better audio streaming
      const range = req.headers.range;
      if (range) {
        res.set('Content-Range', `bytes 0-/*`);
        res.status(206);
      }
      
      response.pipe(res);
    } else {
      console.error(`ElevenLabs API error: ${response.statusCode}`);
      res.status(response.statusCode).json({ error: 'ElevenLabs API error' });
    }
  });
  
  request.on('error', (error) => {
    console.error('Server error:', error);
    res.status(500).json({ error: 'Server error' });
  });
  
  request.write(postData);
  request.end();
});

app.listen(PORT, () => {
  console.log(`🚀 TTS Server running on port ${PORT}`);
  console.log(`✅ Audio streaming optimized for Flutter web`);
});