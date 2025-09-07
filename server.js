// server.js — final (works in Gitpod on iPad)
const express = require("express");

const app = express();
const PORT = 8787;

// Health check
app.get("/", (_req, res) => res.send("TTS server up"));

// ElevenLabs proxy: /tts?text=Hello%20world&voice=<optionalVoiceId>
app.get("/tts", async (req, res) => {
  try {
    const text = (req.query.text || "").toString();
    if (!text.trim()) return res.status(400).send("No text");

    const voiceId = (req.query.voice || "21m00Tcm4TlvDq8ikWAM").toString(); // Rachel

    const r = await fetch(`https://api.elevenlabs.io/v1/text-to-speech/${voiceId}`, {
      method: "POST",
      headers: {
        "xi-api-key": process.env.ELEVEN_API_KEY || "",
        "accept": "audio/mpeg",
        "content-type": "application/json"
      },
      body: JSON.stringify({
        text,
        model_id: "eleven_multilingual_v2",
        voice_settings: { stability: 0.4, similarity_boost: 0.85 }
      })
    });

    if (!r.ok) {
      const msg = await r.text();
      return res.status(500).send(`ElevenLabs error: ${msg}`);
    }

    // CORS for Flutter web
    res.setHeader("Access-Control-Allow-Origin", "*");
    res.setHeader("Content-Type", "audio/mpeg");

    r.body.pipe(res);
  } catch (e) {
    res.status(500).send(String(e));
  }
});

// IMPORTANT: bind to 0.0.0.0 so Gitpod exposes it
app.listen(PORT, "0.0.0.0", () => console.log(`TTS server running on ${PORT}`));