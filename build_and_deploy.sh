#!/bin/bash

# 🚀 Flutter Build and Deploy Script - WebAudioError Fixed
# Run this script from your local machine where Flutter is installed

echo "🚀 Starting Flutter build process..."

# Navigate to Flutter project
cd fitcoach || { echo "❌ fitcoach directory not found!"; exit 1; }

echo "🧹 Cleaning previous builds..."
flutter clean

echo "📦 Getting dependencies (audioplayers excluded)..."
flutter pub get

echo "🔨 Building for web with HTML renderer..."
flutter build web --web-renderer html

if [ $? -eq 0 ]; then
    echo "✅ Build successful!"
    echo "📁 Built files are in: fitcoach/build/web/"
    
    echo "🚀 Deploying to current directory..."
    cd ..
    cp -r fitcoach/build/web/* .
    
    echo "✅ Deployment complete!"
    echo ""
    echo "🧪 Test your app:"
    echo "1. Open your FitCoach app"
    echo "2. Open browser console (F12)"
    echo "3. Try any voice button"
    echo "4. Look for: '🔊 HTML5 Audio Only - Attempting TTS'"
    echo ""
    echo "🎯 Expected: No more WebAudioError!"
    
else
    echo "❌ Build failed! Check the error messages above."
    exit 1
fi