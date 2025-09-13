# 📍 Exact Prompt Locations in Code

## 🗂️ **Main Prompt Arrays**

### **File:** `fitcoach/lib/main.dart`

| **Category** | **Start Line** | **Variable Name** | **Count** |
|--------------|----------------|-------------------|-----------|
| High Heart Rate | **Line 327** | `highHrPrompts` | 20 prompts |
| Low HR/Slow Pace | **Line 350** | `lowHrSlowPrompts` | 20 prompts |
| Final Push | **Line 373** | `finalPushPrompts` | 20 prompts |
| On Pace | **Line 396** | `onPacePrompts` | 20 prompts |
| General | **Line 419** | `generalPrompts` | 20 prompts |

---

## 🧪 **Test Button Prompts (Settings Menu)**

| **Button** | **Line** | **Prompt Text** |
|------------|----------|-----------------|
| Welcome | **Line 571** | "Welcome to your fitness journey! I'm here to guide you every step of the way." |
| Heart Rate High | **Line 580** | "Easy does it! Bring that heart rate down. Focus on your breathing and find your rhythm." |
| Pace Too Slow | **Line 589** | "Time to pick up the pace! You've got more in you. Let's see that power!" |
| Last KM | **Line 598** | "This is it! Final kilometer! You're almost there! Give me everything you've got!" |
| On Target | **Line 607** | "Perfect rhythm. You're right on target. Keep this smooth cadence." |
| Motivation | **Line 616** | "You're doing amazing! Your body is a powerhouse of strength and endurance. Keep pushing!" |

---

## 🔄 **Prompt Selection Logic**

| **Logic Line** | **Code** |
|----------------|----------|
| **Line 444** | `line = highHrPrompts[_rng.nextInt(highHrPrompts.length)];` |
| **Line 446** | `line = lowHrSlowPrompts[_rng.nextInt(lowHrSlowPrompts.length)];` |
| **Line 450** | `line = finalPushPrompts[_rng.nextInt(finalPushPrompts.length)];` |
| **Line 452** | `line = onPacePrompts[_rng.nextInt(onPacePrompts.length)];` |
| **Line 454** | `line = generalPrompts[_rng.nextInt(generalPrompts.length)];` |

---

## 🎯 **Trigger Conditions**

### **Located around Lines 320-325:**
```dart
const int maxHr = 190;
final bool high = heartRate > (0.90 * maxHr);  // >171 BPM
final bool low = heartRate < (0.72 * maxHr);   // <137 BPM
final bool onPace = (elapsedSec / goalTimeSec) <= (distanceKm / goalDistanceKm) + 0.03;
```

### **Distance Check (Line 448):**
```dart
final double remain = (goalDistanceKm - distanceKm).clamp(0.0, goalDistanceKm);
if (remain <= 1.0) {  // Final kilometer
```

---

## ✏️ **Quick Edit Guide**

### **To Edit a Specific Prompt:**
1. **Open:** `fitcoach/lib/main.dart`
2. **Go to line:** (see table above)
3. **Find the prompt** in the array
4. **Edit the text** between quotes
5. **Save and rebuild**

### **Example Edit:**
```dart
// Line 327 - High Heart Rate Prompts
final List<String> highHrPrompts = [
  "Breathe deep, warrior! Control that fire inside you...", // ← Edit this
  "Easy now, champion! Your heart is roaring with strength...", // ← Or this
  // ... more prompts
];
```

### **To Add New Prompts:**
```dart
final List<String> highHrPrompts = [
  "Existing prompt...",
  "Your new custom prompt here!", // ← Add new ones
  "Another new prompt!",          // ← Like this
];
```

---

## 🔧 **After Making Changes:**

```bash
# Rebuild the app
cd fitcoach
flutter build web --web-renderer html

# Deploy the changes
cp -r build/web/* ../
```

**Your changes will be live immediately after rebuild!**