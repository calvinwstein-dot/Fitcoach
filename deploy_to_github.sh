#!/bin/bash

# 🚀 Deploy FitCoach to GitHub Pages
echo "🚀 Deploying FitCoach to GitHub Pages..."

# Check if git is available
if ! command -v git &> /dev/null; then
    echo "❌ Git is not installed. Please install git first."
    exit 1
fi

# Clone the repository
echo "📥 Cloning your GitHub repository..."
if [ -d "temp_fitcoach_deploy" ]; then
    rm -rf temp_fitcoach_deploy
fi

git clone https://github.com/calvinwstein-dot/Fitcoach.git temp_fitcoach_deploy

if [ $? -ne 0 ]; then
    echo "❌ Failed to clone repository. Check your GitHub access."
    exit 1
fi

# Copy the working files
echo "📁 Copying working FitCoach files..."
cd temp_fitcoach_deploy

# Remove old files (keep .git)
find . -maxdepth 1 -not -name '.git' -not -name '.' -not -name '..' -exec rm -rf {} +

# Copy new files
cp -r ../github_pages_deploy/* .

# Add and commit
echo "💾 Committing changes..."
git add .
git commit -m "Deploy working FitCoach app with ElevenLabs TTS

✅ Restored working version from Gitpod
✅ ElevenLabs TTS integration working
✅ All 106 voice prompts included
✅ Replit server configured
✅ AudioPlayer + HTML5 Audio approach

Server: https://63d0b674-9d16-478b-a272-e0513423bcfb-00-1pmi0mctu0qbh.janeway.replit.dev
Model: eleven_multilingual_v2
API Key: Configured in Replit server

Co-authored-by: Ona <no-reply@ona.com>"

# Push to GitHub
echo "🚀 Pushing to GitHub..."
git push origin main

if [ $? -eq 0 ]; then
    echo "✅ Successfully deployed to GitHub Pages!"
    echo "🌐 Your app will be live at: https://calvinwstein-dot.github.io/Fitcoach/"
    echo "⏱️ GitHub Pages may take 1-2 minutes to update"
    echo "🔄 Hard refresh (Ctrl+F5) if you see old version"
else
    echo "❌ Failed to push to GitHub. Check your permissions."
    exit 1
fi

# Cleanup
cd ..
rm -rf temp_fitcoach_deploy

echo "🎉 Deployment complete!"
echo ""
echo "🧪 Test your app:"
echo "1. Wait 1-2 minutes for GitHub Pages to update"
echo "2. Visit: https://calvinwstein-dot.github.io/Fitcoach/"
echo "3. Go to Settings and test voice buttons"
echo "4. Should work with ElevenLabs voices!"