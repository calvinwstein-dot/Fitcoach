# 🎤 FitCoach Voice Prompts Reference Guide

## 📍 Location in Code
**File:** `fitcoach/lib/main.dart`  
**Function:** `_autoCue()` method (starts around line 318)

---

## 🔥 **1. HIGH HEART RATE PROMPTS** (20 prompts)
**Trigger:** When heart rate > 90% of max (171+ BPM)  
**Purpose:** Calm down, reduce intensity  
**Location:** Lines ~325-345

### Sample Prompts:
- "Breathe deep, warrior! Control that fire inside you..."
- "Easy now, champion! Your heart is roaring with strength..."
- "Slow it down, beast! You're burning too hot..."

---

## ⚡ **2. LOW HEART RATE / SLOW PACE PROMPTS** (20 prompts)
**Trigger:** When heart rate < 72% of max (137- BPM) AND pace is slow  
**Purpose:** Motivate to speed up, increase intensity  
**Location:** Lines ~350-370

### Sample Prompts:
- "WAKE UP THAT FIRE! You've got volcanic power inside you!"
- "TIME TO EXPLODE! Your body is capable of so much more!"
- "IGNITE THAT ENGINE! You're holding back greatness!"

---

## 🏁 **3. FINAL PUSH PROMPTS** (20 prompts)
**Trigger:** When distance remaining ≤ 1.0 km  
**Purpose:** Maximum motivation for final kilometer  
**Location:** Lines ~372-392

### Sample Prompts:
- "THIS IS IT! FINAL KILOMETER! You're a MACHINE!"
- "VICTORY IS YOURS! Less than 1K left! You're UNSTOPPABLE!"
- "FINISH STRONG, WARRIOR! Your body is pure power!"

---

## ✅ **4. ON-PACE PROMPTS** (20 prompts)
**Trigger:** When running at target pace  
**Purpose:** Maintain rhythm, stay in flow state  
**Location:** Lines ~394-414

### Sample Prompts:
- "Perfect harmony, beautiful soul. You're flowing like poetry..."
- "Absolutely sublime! Your body and spirit are dancing together..."
- "You're in the zone, magnificent athlete. This cadence is pure art..."

---

## 🎯 **5. GENERAL PROMPTS** (20 prompts)
**Trigger:** Default when no specific condition is met  
**Purpose:** General encouragement and pacing guidance  
**Location:** Lines ~416-436

### Sample Prompts:
- "Find your center, strong one. Let your breath guide you..."
- "Settle into your power, champion. Your body is wise..."
- "Breathe into your strength. Feel your body finding its natural rhythm..."

---

## 🧪 **6. TEST PROMPTS** (Settings Menu)
**Location:** Lines ~570-610  
**Purpose:** Manual testing of different scenarios

### Test Button Prompts:
1. **Welcome:** "Welcome to your fitness journey! I'm here to guide you every step of the way."
2. **Heart Rate High:** "Easy does it! Bring that heart rate down. Focus on your breathing and find your rhythm."
3. **Pace Too Slow:** "Time to pick up the pace! You've got more in you. Let's see that power!"
4. **Last KM:** "This is it! Final kilometer! You're almost there! Give me everything you've got!"
5. **On Target:** "Perfect rhythm. You're right on target. Keep this smooth cadence."
6. **Motivation:** "You're doing amazing! Your body is a powerhouse of strength and endurance. Keep pushing!"

---

## 🔧 **How to Edit Prompts**

### **Step 1: Locate the Prompt Category**
Find the appropriate `List<String>` in `fitcoach/lib/main.dart`:
- `highHrPrompts` - Lines ~325-345
- `lowHrSlowPrompts` - Lines ~350-370  
- `finalPushPrompts` - Lines ~372-392
- `onPacePrompts` - Lines ~394-414
- `generalPrompts` - Lines ~416-436

### **Step 2: Edit the Prompts**
```dart
final List<String> highHrPrompts = [
  "Your new prompt here...",
  "Another custom prompt...",
  // Add, remove, or modify prompts as needed
];
```

### **Step 3: Rebuild and Deploy**
```bash
cd fitcoach
flutter build web --web-renderer html
cp -r build/web/* ../
```

---

## 📊 **Prompt Selection Logic**

### **Priority Order:**
1. **High Heart Rate** (>90% max) → Calming prompts
2. **Low HR + Slow Pace** (<72% max + behind pace) → Motivational prompts  
3. **Final Push** (≤1km remaining) → Maximum intensity prompts
4. **On Pace** (meeting target) → Flow state prompts
5. **General** (default) → Balanced encouragement

### **Randomization:**
Each category randomly selects from its 20 prompts using:
```dart
line = categoryPrompts[_rng.nextInt(categoryPrompts.length)];
```

---

## 🎨 **Prompt Style Guidelines**

### **High Heart Rate:** Calm, controlled, breathing-focused
### **Low HR/Slow:** Explosive, energetic, action-oriented  
### **Final Push:** Maximum intensity, victory-focused
### **On Pace:** Flowing, artistic, zen-like
### **General:** Balanced, wisdom-focused, body-awareness

---

**Total Prompts: 106 (100 main + 6 test prompts)**