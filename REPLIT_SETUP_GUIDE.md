# 🚀 REPLIT TTS SERVER SETUP - STEP BY STEP

## ⚠️ IMPORTANT: No existing server found - you need to create one!

### 📋 **STEP 1: Create Replit Account & Project**

1. **Go to [replit.com](https://replit.com)**
2. **Sign up/Login** to your account
3. **Click "Create Repl"**
4. **Select "Node.js"** template
5. **Name it:** `fitcoach-tts-server` (or any name you prefer)
6. **Click "Create Repl"**

### 📋 **STEP 2: Replace index.js with FIXED Code**

**Delete everything in `index.js` and paste this EXACT code:**

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

// Your ElevenLabs API key (secure on server)
const ELEVENLABS_API_KEY = 'sk_320f8a8f6666297cb40a34ac3be695ac7c330b7d79cb3d44';

app.get('/', (req, res) => {
  res.send('✅ ElevenLabs TTS Server Running for FitCoach AI - Audio Fixed');
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
```

### 📋 **STEP 3: Update package.json**

**Click on `package.json` and replace with:**

```json
{
  "name": "fitcoach-tts-server",
  "version": "1.0.0",
  "description": "ElevenLabs TTS Server for FitCoach AI - Audio Fixed",
  "main": "index.js",
  "scripts": {
    "start": "node index.js"
  },
  "dependencies": {
    "express": "^4.18.2",
    "cors": "^2.8.5"
  },
  "engines": {
    "node": ">=14.0.0"
  },
  "keywords": ["elevenlabs", "tts", "fitcoach", "audio", "streaming"],
  "author": "FitCoach AI",
  "license": "MIT"
}
```

### 📋 **STEP 4: Run the Server**

1. **Click the green "Run" button** in Replit
2. **Wait for installation** (you'll see npm installing packages)
3. **Look for this message:** `🚀 TTS Server running on port 3000`
4. **Copy your Replit URL** from the address bar (e.g., `https://your-repl-name.username.repl.co`)

### 📋 **STEP 5: Test Your Server**

**Open a new tab and go to:** `https://your-repl-url.repl.co`

**You should see:** `✅ ElevenLabs TTS Server Running for FitCoach AI - Audio Fixed`

### 📋 **STEP 6: Update FitCoach App**

1. **Copy your Replit URL** (the full https://... address)
2. **Open your FitCoach app**
3. **Go to Settings** (gear icon)
4. **Paste your Replit URL** in the TTS Server URL field
5. **Click Save**
6. **Test any voice button** - should work without WebAudioError!

---

## 🔧 **TROUBLESHOOTING**

### If you see "Service Unavailable":
- Wait 30 seconds and try again (ElevenLabs rate limiting)
- Check the Replit console for error messages

### If audio still doesn't work:
- Hard refresh your FitCoach app (Ctrl+F5)
- Make sure you copied the EXACT server code above
- Check that your Replit is still running (green dot)

### If Replit goes to sleep:
- Click "Run" again to wake it up
- Consider upgrading to Replit Pro for always-on servers

---

## ✅ **EXPECTED RESULT**

After following these steps, you should have:
- ✅ Working Replit TTS server with your API key
- ✅ No more WebAudioError in Flutter app
- ✅ Realistic ElevenLabs voices working properly
- ✅ 9 different voice options available

**Your server URL will look like:** `https://fitcoach-tts-server.username.repl.co`