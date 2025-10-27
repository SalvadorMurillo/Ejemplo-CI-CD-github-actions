# Theme Persistence Implementation

## Overview

This document explains how theme persistence is implemented in the SControl Flutter app, supporting both mobile and web platforms.

## How It Works

### Technology Stack

- **Package**: `shared_preferences` (v2.3.2)
- **Storage**:
  - **Mobile (iOS/Android)**: Native platform preferences
  - **Web**: Browser's `localStorage` API

### Implementation Details

#### ThemeProvider (`lib/providers/theme_provider.dart`)

The `ThemeProvider` class manages theme state and persistence:

```dart
class ThemeProvider extends ChangeNotifier {
  static const String _themeKey = 'theme_mode';
  ThemeMode _themeMode = ThemeMode.light;
  bool _isInitialized = false;

  // Loads saved theme on initialization
  // Saves theme automatically when changed
  // Supports both mobile and web platforms
}
```

#### Key Methods

1. **`_loadThemeFromPrefs()`**: Loads the saved theme preference on app start
2. **`toggleTheme()`**: Toggles between light and dark themes
3. **`setThemeMode(ThemeMode)`**: Sets a specific theme mode
4. **`_saveThemeToPrefs()`**: Persists the current theme to storage
5. **`clearThemePreference()`**: Clears saved preference (debug only)

### Platform-Specific Behavior

#### Mobile (iOS/Android)

- Uses native platform preferences
- Data persists across app restarts
- Survives app updates (unless app data is cleared)
- Fast and reliable

#### Web

- Uses browser's `localStorage`
- Data persists per domain/origin
- Survives browser restarts
- Cleared when user clears browser data
- Works in private/incognito mode but doesn't persist after closing

### Debug Logging

When running in debug mode, the app logs theme operations:

```
Theme loaded from preferences (Web/Mobile): Dark/Light
Theme saved to preferences (Web/Mobile): Dark/Light - Success: true
```

## Testing Theme Persistence

### Option 1: Using the Test Widget

Add the `ThemeTestWidget` to any screen:

```dart
import 'package:scontrol/widgets/theme_test_widget.dart';

// In your screen's build method:
Column(
  children: [
    // Your existing widgets
    ThemeTestWidget(), // Add this for testing
  ],
)
```

### Option 2: Manual Testing

#### Mobile Testing

1. Open the app on your mobile device
2. Toggle the theme using the theme button in the UI
3. Close the app completely (swipe away from recent apps)
4. Reopen the app
5. **Expected**: The theme should be the same as when you closed it

#### Web Testing

1. Open the app in your web browser
2. Toggle the theme using the theme button
3. Refresh the page (F5 or Ctrl+R)
4. **Expected**: Theme should persist after refresh
5. Close the browser tab
6. Open the app in a new tab
7. **Expected**: Theme should persist in new tab
8. Open browser DevTools (F12) → Application → Local Storage
9. Look for the key `flutter.theme_mode`
10. **Expected**: You should see `true` (dark) or `false` (light)

### Verifying in Browser DevTools

To check stored values in web:

1. Open DevTools (F12)
2. Go to **Application** (Chrome) or **Storage** (Firefox)
3. Expand **Local Storage**
4. Select your app's domain
5. Look for: `flutter.theme_mode`
6. Value should be `true` (dark mode) or `false` (light mode)

## Common Issues & Solutions

### Issue: Theme not persisting on mobile

**Possible causes:**

- App data was cleared
- Device storage is full
- Permissions issue (rare)

**Solution:**

- Ensure `shared_preferences` package is properly installed
- Check debug logs for error messages
- Verify storage permissions in `AndroidManifest.xml` (should be automatic)

### Issue: Theme not persisting on web

**Possible causes:**

- Browser is in incognito/private mode (expected behavior)
- Browser settings block localStorage
- User cleared browser data

**Solution:**

- Test in regular browser window (not incognito)
- Check browser console for errors
- Verify localStorage is enabled in browser settings
- Try a different browser

### Issue: Theme resets randomly

**Possible causes:**

- App crash during save
- Race condition in async operations

**Solution:**

- Check debug logs for save failures
- Ensure `toggleTheme()` completes before closing app

## Browser Compatibility

### Full Support

- ✅ Chrome/Edge (latest)
- ✅ Firefox (latest)
- ✅ Safari (latest)
- ✅ Chrome on Android
- ✅ Safari on iOS

### Notes

- Private/Incognito mode: Works but doesn't persist after closing
- Very old browsers: May not support localStorage (rare in 2025)

## Implementation Checklist

✅ `shared_preferences` package added to `pubspec.yaml`  
✅ `ThemeProvider` created with load/save functionality  
✅ Provider registered in `main.dart`  
✅ Theme toggle buttons added to UI  
✅ Debug logging implemented  
✅ Works on mobile platforms  
✅ Works on web platform  
✅ Async initialization handled properly

## Code Examples

### Toggle Theme from Any Widget

```dart
import 'package:provider/provider.dart';
import 'package:scontrol/providers/theme_provider.dart';

// In your widget:
IconButton(
  icon: Icon(
    context.watch<ThemeProvider>().isDarkMode
      ? Icons.light_mode
      : Icons.dark_mode,
  ),
  onPressed: () {
    context.read<ThemeProvider>().toggleTheme();
  },
)
```

### Set Specific Theme

```dart
// Set to dark mode
context.read<ThemeProvider>().setThemeMode(ThemeMode.dark);

// Set to light mode
context.read<ThemeProvider>().setThemeMode(ThemeMode.light);
```

### Check Current Theme

```dart
final themeProvider = context.watch<ThemeProvider>();
bool isDark = themeProvider.isDarkMode;
ThemeMode mode = themeProvider.themeMode;
```

## Additional Resources

- [shared_preferences package](https://pub.dev/packages/shared_preferences)
- [Flutter theming guide](https://docs.flutter.dev/cookbook/design/themes)
- [Provider state management](https://pub.dev/packages/provider)

## Maintenance Notes

- The theme preference key is: `'theme_mode'`
- Storage key can be changed in `ThemeProvider._themeKey`
- Default theme is light mode
- No manual cleanup needed - handled automatically
