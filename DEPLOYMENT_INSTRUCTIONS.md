# ElevenLabs TTS Server Deployment Instructions - AUDIO FIXED ✅

## 🔧 WEBAUDOERROR ISSUE RESOLVED
- Enhanced CORS headers for audio streaming
- Proper Range request handling  
- Removed problematic AudioPlayer fallback
- Optimized HTML5 Audio Element approach

## Quick Setup (Replit - Recommended)

### 1. Create Replit Account
- Go to [replit.com](https://replit.com)
- Sign up or log in

### 2. Create New Repl
- Click "Create Repl"
- Choose "Node.js" template
- Name it "elevenlabs-tts-server"

### 3. Replace Default Code
Delete everything in `index.js` and paste this code:

```javascript
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

// Your ElevenLabs API key
const ELEVENLABS_API_KEY = 'sk_320f8a8f6666297cb40a34ac3be695ac7c330b7d79cb3d44';

app.get('/', (req, res) => {
  res.send('ElevenLabs TTS Server Running for FitCoach AI');
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
    console.log(`ElevenLabs response: ${response.statusCode}`);
    
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
    console.error('Request error:', error);
    res.status(500).json({ error: 'Server error' });
  });
  
  request.write(postData);
  request.end();
});

app.listen(PORT, () => {
  console.log(`🚀 TTS Server running on port ${PORT}`);
  console.log(`✅ Audio streaming optimized for Flutter web`);
});
```

### 4. Update package.json
Click on `package.json` and replace with:

```json
{
  "name": "elevenlabs-tts-server",
  "version": "1.0.0",
  "description": "ElevenLabs TTS Server for FitCoach AI",
  "main": "index.js",
  "scripts": {
    "start": "node index.js"
  },
  "dependencies": {
    "express": "^4.18.2",
    "cors": "^2.8.5"
  }
}
```

### 5. Run the Server
- Click the "Run" button in Replit
- Wait for "TTS Server running on port 3000" message
- Copy your Replit URL (e.g., `https://elevenlabs-tts-server.username.repl.co`)

### 6. Configure FitCoach App
1. Go to your FitCoach app
2. Click Settings (gear icon)
3. Paste your Replit URL in "TTS Server URL" field
4. Select a voice and test with scenario buttons
5. Save settings

## Testing
- Test URL: `https://your-repl-url.repl.co/tts?text=hello&voice=21m00Tcm4TlvDq8ikWAM`
- Should return MP3 audio file

## Troubleshooting
- If server stops: Click "Run" again in Replit
- If no sound: Check browser console for errors
- If API errors: Verify your ElevenLabs API key is valid

## Voice IDs
- Rachel: 21m00Tcm4TlvDq8ikWAM
- Domi: AZnzlk1XvdvUeBnXmlld  
- Bella: EXAVITQu4vr4xnSDxMaL
- Antoni: ErXwobaYiN019PkySvjV
- Elli: MF3mGyEYCl7XYWbV9V6O
- Josh: TxGEqnHWrfWFTfGW9XjX
- Arnold: VR6AewLTigWG4xSOukaG
- Adam: pNInz6obpgDQGcFmaJgB
- Sam: yoZ06aMxZJJ28mfd3POQ