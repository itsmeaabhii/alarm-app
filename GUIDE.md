# Alarm App - User Guide

## Features Overview

### 1. View Alarms
- All your alarms are displayed on the home screen
- Sorted by time (earliest to latest)
- Shows time, label, and repeat schedule
- Color-coded: active alarms are vibrant, disabled alarms are greyed out

### 2. Create New Alarm
1. Tap the **+** button at the bottom right
2. Set your desired time by tapping on the time display
3. Add an optional label (e.g., "Wake up", "Meeting")
4. Select repeat days:
   - Tap individual day circles to select/deselect
   - Use quick presets: Weekdays, Weekends, Every day
   - Leave all days unselected for a one-time alarm
5. Tap **SAVE** to create the alarm

### 3. Edit Alarm
- Tap on any alarm card to edit it
- Change the time, label, or repeat schedule
- Tap **SAVE** to update

### 4. Enable/Disable Alarm
- Use the switch on the right side of each alarm
- Disabled alarms are kept but won't ring

### 5. Delete Alarm
- Tap the trash icon on the alarm card
- Confirm deletion in the dialog

## Quick Tips

- **Weekdays preset**: Sets alarm for Monday-Friday
- **Weekends preset**: Sets alarm for Saturday-Sunday  
- **Every day preset**: Sets alarm for all 7 days
- **Clear preset**: Removes all repeat days (one-time alarm)

## Technical Features

- ✅ Persistent storage - alarms saved even after closing the app
- ✅ Clean Material Design 3 UI
- ✅ Sort alarms by time automatically
- ✅ Intuitive time picker
- ✅ Flexible repeat scheduling
- ✅ Toggle alarms on/off without deleting

## Running the App

### First Time Setup
```bash
# Navigate to the project directory
cd /Users/abhishek/Desktop/alram

# Get dependencies
flutter pub get

# Run the app
flutter run
```

### Platform-Specific Commands
```bash
# Run on iOS
flutter run -d ios

# Run on Android
flutter run -d android

# Run on Chrome (web)
flutter run -d chrome

# Run on macOS
flutter run -d macos
```

### Testing
```bash
# Run unit tests
flutter test

# Run specific test file
flutter test test/alarm_test.dart
```

### Building
```bash
# Build APK for Android
flutter build apk

# Build iOS app
flutter build ios

# Build web app
flutter build web
```

## Troubleshooting

### Issue: Dependencies not found
**Solution**: Run `flutter pub get`

### Issue: Build fails
**Solution**: 
1. Run `flutter clean`
2. Run `flutter pub get`
3. Try building again

### Issue: App crashes on startup
**Solution**: Make sure you have the latest Flutter SDK installed
```bash
flutter upgrade
```

## Future Enhancements (Ideas)

- [ ] Sound/vibration settings
- [ ] Snooze functionality
- [ ] Multiple alarm tones
- [ ] Alarm history
- [ ] Dark mode
- [ ] Alarm notes/descriptions
- [ ] Volume control per alarm
- [ ] Fade-in alarm sound
- [ ] Math puzzles to dismiss alarm
