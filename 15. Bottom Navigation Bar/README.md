# 15. Bottom Navigation Bar

[Previous](/14.%20Vibe%20Coding%20(Bonus)/) | [Main Page](/)

## Content Outline

- [What is a Bottom Navigation Bar?](#what-is-a-bottom-navigation-bar)
- [Page Navigation Basics in Flutter](#page-navigation-basics-in-flutter)
- [Implementing a Bottom Navigation Bar](#implementing-a-bottom-navigation-bar)
- [Alternative Packages (Fluttergems)](#alternative-packages-fluttergems)
- [Tips & Best Practices](#tips--best-practices)
- [References](#references)

In this module we will learn how to build a **Bottom Navigation Bar** in Flutter — one of the most common navigation components in mobile apps.

---

## What is a Bottom Navigation Bar?

A **Bottom Navigation Bar** is a row of buttons (`BottomNavigationBarItem`) anchored to the bottom of the screen. Each item usually consists of an **icon** and a **label**, and tapping one switches the displayed page.

Almost every modern mobile app (Instagram, YouTube, WhatsApp, Spotify, Gojek) uses a bottom navigation bar to switch between primary pages. Flutter provides the built-in [`BottomNavigationBar`](https://api.flutter.dev/flutter/material/BottomNavigationBar-class.html) widget — highly flexible, easily styled, and works with several different navigation approaches.

Material Design guidelines:

| Rule | Description |
|------|-------------|
| Top-level destinations | Use only for main pages, not sub-pages |
| Consistent | The bar should be visible across all main pages |
| Not nested | Don't put a navigation bar inside another navigation bar |
| Number of items | 3 to 5 items (recommended) |

> **Note:** For apps following Material 3 (Material You), Flutter also provides the newer [`NavigationBar`](https://api.flutter.dev/flutter/material/NavigationBar-class.html) widget. In this module we focus on `BottomNavigationBar` because it is still the most widely used.

---

## Page Navigation Basics in Flutter

Before building a bottom navigation bar, it's important to understand **page navigation** in Flutter. Flutter manages pages using a **stack** structure: new pages are pushed on top of old ones, and closing a page pops the top of the stack.

### Navigator.push & Navigator.pop

The basic way to switch pages in Flutter:

```dart
// Push SecondPage onto the stack
Navigator.push(
  context,
  MaterialPageRoute(builder: (context) => const SecondPage()),
);

// Pop back to the previous page
Navigator.pop(context);
```

| Method | Function |
|--------|----------|
| `Navigator.push` | Pushes a new page onto the stack |
| `Navigator.pop` | Removes the top page from the stack |
| `Navigator.pushReplacement` | Replaces the current page with a new one |
| `Navigator.pushAndRemoveUntil` | Pushes a new page while removing others |

### Navigation Inside a Bottom Navigation Bar

Unlike `Navigator.push`, which **opens a new page on top of the current one**, navigation inside a bottom navigation bar is **switching/tab-based** — we simply swap the **body content** based on the selected item, without stacking pages.

There are three common approaches:

#### 1. IndexedStack

`IndexedStack` keeps **all pages** in memory but displays only one at a time based on its index. Each page's state **is preserved** when switching tabs.

```dart
body: IndexedStack(
  index: _selectedIndex,
  children: const [HomePage(), SearchPage(), ProfilePage()],
),
```

✅ State is preserved when switching tabs <br>
❌ All pages are built up front (slightly higher memory usage)

#### 2. List Switching (Simple)

Just display a single widget from a list based on the index.

```dart
final List<Widget> _pages = [HomePage(), SearchPage(), ProfilePage()];

body: _pages[_selectedIndex],
```

✅ Simple <br>
❌ Page state is **reset** every time you switch tabs

#### 3. Nested Navigator (Advanced)

Each tab has its own `Navigator`, so each tab maintains its own history stack. Best for complex apps.

```dart
body: IndexedStack(
  index: _selectedIndex,
  children: [
    Navigator(onGenerateRoute: ...),  // Stack for Home tab
    Navigator(onGenerateRoute: ...),  // Stack for Search tab
    Navigator(onGenerateRoute: ...),  // Stack for Profile tab
  ],
),
```

✅ Each tab keeps its own history (like Instagram) <br>
❌ More complex setup

---

## Implementing a Bottom Navigation Bar

### Setup Pages

First, create three simple pages that will be displayed in each tab. Create a `lib/pages/` folder and add the following three files:

**`lib/pages/home_page.dart`**

```dart
import 'package:flutter/material.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text(
        'Home Page',
        style: TextStyle(fontSize: 24),
      ),
    );
  }
}
```

**`lib/pages/search_page.dart`**

```dart
import 'package:flutter/material.dart';

class SearchPage extends StatelessWidget {
  const SearchPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text(
        'Search Page',
        style: TextStyle(fontSize: 24),
      ),
    );
  }
}
```

**`lib/pages/profile_page.dart`**

```dart
import 'package:flutter/material.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text(
        'Profile Page',
        style: TextStyle(fontSize: 24),
      ),
    );
  }
}
```

### Full Code with IndexedStack

Next, build the `MainScreen` containing a `Scaffold` with a `BottomNavigationBar`.

**`lib/main.dart`**

```dart
import 'package:flutter/material.dart';
import 'pages/home_page.dart';
import 'pages/search_page.dart';
import 'pages/profile_page.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Bottom Nav Demo',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: const MainScreen(),
    );
  }
}

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;

  // List of pages to display
  static const List<Widget> _pages = [
    HomePage(),
    SearchPage(),
    ProfilePage(),
  ];

  // AppBar titles for each tab
  static const List<String> _titles = [
    'Home',
    'Search',
    'Profile',
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_titles[_selectedIndex]),
      ),
      body: IndexedStack(
        index: _selectedIndex,
        children: _pages,
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        type: BottomNavigationBarType.fixed,
        selectedItemColor: Colors.blue,
        unselectedItemColor: Colors.grey,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.search),
            label: 'Search',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}
```

#### Code Flow Explained

1. `_selectedIndex` stores which tab is currently active (defaults to `0` = Home).
2. `IndexedStack` displays the page from `_pages` matching `_selectedIndex`.
3. When the user taps an item in the `BottomNavigationBar`, the `onTap` callback fires with the new `index`.
4. `setState` updates `_selectedIndex` and triggers a UI rebuild.
5. The `AppBar` title changes as well because it also reads from `_selectedIndex`.


> For the complete property list, see the [official BottomNavigationBar documentation](https://api.flutter.dev/flutter/material/BottomNavigationBar-class.html).

---

## Alternative Packages (Fluttergems)

Flutter's built-in `BottomNavigationBar` is already powerful, but for more unique styles (curved, floating, animated, etc.) we can turn to **third-party packages**.

The best place to discover bottom navigation bar styles is:

🔗 **[Fluttergems - Bottom Navigation Bar](https://fluttergems.dev/bottom-navigation-bar/)**

It lists dozens of packages ranked by likes and popularity. A few of the most popular:

| Package | Style | Link |
|---------|-------|------|
| `google_nav_bar` | Modern, similar to Google apps | [pub.dev](https://pub.dev/packages/google_nav_bar) |
| `convex_bottom_bar` | Convex (bulging) center item | [pub.dev](https://pub.dev/packages/convex_bottom_bar) |
| `salomon_bottom_bar` | Persistent labels with smooth animation | [pub.dev](https://pub.dev/packages/salomon_bottom_bar) |
| `curved_navigation_bar` | Animated curve following the active item | [pub.dev](https://pub.dev/packages/curved_navigation_bar) |
| `bottom_navy_bar` | Bouncy and colorful | [pub.dev](https://pub.dev/packages/bottom_navy_bar) |
| `animated_bottom_navigation_bar` | Notch + custom animations | [pub.dev](https://pub.dev/packages/animated_bottom_navigation_bar) |

### Example Using `google_nav_bar`

Add it to `pubspec.yaml`:

```bash
flutter pub add google_nav_bar
```
or
```yaml
dependencies:
  google_nav_bar: ^5.0.6
```

Then use it:

```dart
import 'package:google_nav_bar/google_nav_bar.dart';

bottomNavigationBar: Padding(
  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
  child: GNav(
    selectedIndex: _selectedIndex,
    onTabChange: _onItemTapped,
    backgroundColor: Colors.white,
    color: Colors.black,
    activeColor: Colors.white,
    tabBackgroundColor: Colors.blue,
    gap: 8,
    padding: const EdgeInsets.all(12),
    tabs: const [
      GButton(icon: Icons.home, text: 'Home'),
      GButton(icon: Icons.search, text: 'Search'),
      GButton(icon: Icons.person, text: 'Profile'),
    ],
  ),
),
```

> The basic pattern is the same: pick a package, install it, then swap out `BottomNavigationBar` for the widget from the package. The `_selectedIndex` and `_onItemTapped` logic still applies.

---

## Tips & Best Practices

1. **Use `IndexedStack`** if each tab's state matters (e.g. scroll position, form input).
2. **Avoid nesting** a bottom navigation bar inside another page.
3. **Test on different screen sizes** — the bar can look different on tablets vs phones.

---

## References

- [Flutter Documentation - BottomNavigationBar](https://api.flutter.dev/flutter/material/BottomNavigationBar-class.html)
- [Flutter Documentation - BottomNavigationBarItem](https://api.flutter.dev/flutter/material/BottomNavigationBarItem-class.html)
- [Flutter Documentation - Navigator](https://api.flutter.dev/flutter/widgets/Navigator-class.html)
- [Fluttergems - Bottom Navigation Bar Collection](https://fluttergems.dev/bottom-navigation-bar/)
- [Material Design - Bottom Navigation Guidelines](https://m3.material.io/components/navigation-bar/overview)

---
