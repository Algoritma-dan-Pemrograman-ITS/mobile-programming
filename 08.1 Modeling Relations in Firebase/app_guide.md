# Flutter + Firebase: MiniTweet
*A hands-on project for CS undergrads. Takes about 45 minutes.*

---

## What We're Building

A simple Twitter-like app with three screens: Login, Feed, and Post Tweet. Nothing fancy. The point is to build something real while applying every Firestore pattern from the README.

- Root collection (tweets)
- Intermediate collection with composite ID (hearts)
- Aggregate field (heartCount)
- Foreign key pattern (userId on tweets)

---

## 1. Firebase Setup (10 min)

### 1.1 Create Firebase Project
1. Go to [console.firebase.google.com](https://console.firebase.google.com)
2. **Add project** → name it `MiniTweet` → disable Google Analytics → **Create**
3. In the left sidebar: **Authentication** → Get Started → Enable **Email/Password**
4. In the left sidebar: **Firestore Database** → Create database → **Start in test mode** → choose a region → Done

### 1.2 Register Your Flutter App
1. In Firebase console: click the Flutter icon `</>` → register app
2. Follow the **FlutterFire CLI** instructions shown on screen:

```bash
# Install FlutterFire CLI (run once)
dart pub global activate flutterfire_cli

# In your Flutter project root:
flutterfire configure
```

Pick your `MiniTweet` project when prompted. It will generate `firebase_options.dart` automatically.

### 1.3 Flutter Dependencies

In `pubspec.yaml`:

```yaml
dependencies:
  flutter:
    sdk: flutter
  firebase_core: ^3.0.0
  firebase_auth: ^5.0.0
  cloud_firestore: ^5.0.0
```

```bash
flutter pub get
```

---

## 2. Data Model

Three collections. That's the whole database.

```
Firestore
 ├── users/
 │    └── {uid}
 │         ├── name: "Yuta"
 │         └── email: "yuta@example.com"
 │
 ├── tweets/                          ← Root collection (queryable across all users)
 │    └── {tweetId}
 │         ├── userId: "abc123"
 │         ├── authorName: "Yuta"     ← Duplicated on purpose (avoid extra reads)
 │         ├── text: "Hello world!"
 │         ├── heartCount: 5          ← Aggregate field (updated on write)
 │         └── createdAt: Timestamp
 │
 └── hearts/                          ← Intermediate collection (many-to-many)
      └── "{userId}_{tweetId}"        ← Composite ID = uniqueness for free
           ├── userId: "abc123"
           └── tweetId: "xyz789"
```

---

## 3. Security Rules

In Firebase Console → Firestore → **Rules** tab, paste this:

```
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {

    // Users can only read/write their own profile
    match /users/{uid} {
      allow read, write: if request.auth.uid == uid;
    }

    // Anyone logged in can read tweets; only the author can delete
    match /tweets/{tweetId} {
      allow read: if request.auth != null;
      allow create: if request.auth != null;
      allow update: if request.auth != null; // for heartCount updates
      allow delete: if request.auth.uid == resource.data.userId;
    }

    // Anyone logged in can manage their own hearts
    match /hearts/{heartId} {
      allow read: if request.auth != null;
      allow write: if request.auth != null
        && heartId == request.auth.uid + '_' + request.resource.data.tweetId;
    }
  }
}
```

Click **Publish**.

---

## 4. Flutter App

### Project Structure
```
lib/
 ├── main.dart
 ├── services/
 │    ├── auth_service.dart
 │    └── firestore_service.dart
 └── screens/
      ├── login_screen.dart
      └── feed_screen.dart
```

---

### `main.dart`

```dart
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'firebase_options.dart';
import 'screens/login_screen.dart';
import 'screens/feed_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'MiniTweet',
      home: StreamBuilder<User?>(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, snapshot) {
          if (snapshot.hasData) return const FeedScreen();
          return const LoginScreen();
        },
      ),
    );
  }
}
```

---

### `services/auth_service.dart`

```dart
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AuthService {
  final _auth = FirebaseAuth.instance;
  final _db = FirebaseFirestore.instance;

  Future<void> register(String name, String email, String password) async {
    final cred = await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );
    // Save user profile to Firestore
    await _db.collection('users').doc(cred.user!.uid).set({
      'name': name,
      'email': email,
    });
  }

  Future<void> login(String email, String password) async {
    await _auth.signInWithEmailAndPassword(email: email, password: password);
  }

  Future<void> logout() async => await _auth.signOut();

  User? get currentUser => _auth.currentUser;
}
```

---

### `services/firestore_service.dart`

All Firestore logic lives in one place. Pay attention to `toggleHeart`: heartCount is updated at write time, not counted on read. That's the pattern that keeps your bill sane at scale.

```dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class FirestoreService {
  final _db = FirebaseFirestore.instance;

  // ── TWEETS ──────────────────────────────────────────────

  // Global feed: all tweets, newest first
  Stream<QuerySnapshot> getTweets() {
    return _db
        .collection('tweets')
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  // Post a new tweet
  Future<void> postTweet(String text, String authorName) async {
    final uid = FirebaseAuth.instance.currentUser!.uid;
    await _db.collection('tweets').add({
      'userId': uid,
      'authorName': authorName,   // duplicated intentionally — avoids extra read
      'text': text,
      'heartCount': 0,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  // ── HEARTS ──────────────────────────────────────────────

  // Composite ID = uniqueness for free (no duplicate hearts possible)
  String _heartId(String tweetId) =>
      '${FirebaseAuth.instance.currentUser!.uid}_$tweetId';

  // Check if current user already hearted a tweet (one read, no query)
  Future<bool> hasHearted(String tweetId) async {
    final doc = await _db.collection('hearts').doc(_heartId(tweetId)).get();
    return doc.exists;
  }

  // Toggle heart: use a transaction so heartCount stays accurate
  Future<void> toggleHeart(String tweetId, bool currentlyHearted) async {
    final uid = FirebaseAuth.instance.currentUser!.uid;
    final heartRef = _db.collection('hearts').doc(_heartId(tweetId));
    final tweetRef = _db.collection('tweets').doc(tweetId);

    await _db.runTransaction((tx) async {
      if (currentlyHearted) {
        // Remove heart → decrement count
        tx.delete(heartRef);
        tx.update(tweetRef, {'heartCount': FieldValue.increment(-1)});
      } else {
        // Add heart → increment count
        tx.set(heartRef, {'userId': uid, 'tweetId': tweetId});
        tx.update(tweetRef, {'heartCount': FieldValue.increment(1)});
      }
    });
  }
}
```

> `runTransaction` makes the heart document and the heartCount update happen together. If the app crashes halfway through, neither write sticks. Without it, your counts will drift over time.

---

### `screens/login_screen.dart`

```dart
import 'package:flutter/material.dart';
import '../services/auth_service.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _auth = AuthService();
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  bool _isLogin = true;

  Future<void> _submit() async {
    try {
      if (_isLogin) {
        await _auth.login(_emailCtrl.text.trim(), _passCtrl.text.trim());
      } else {
        await _auth.register(
          _nameCtrl.text.trim(),
          _emailCtrl.text.trim(),
          _passCtrl.text.trim(),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(e.toString())));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(_isLogin ? 'Login' : 'Register')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (!_isLogin)
              TextField(
                controller: _nameCtrl,
                decoration: const InputDecoration(labelText: 'Name'),
              ),
            TextField(
              controller: _emailCtrl,
              decoration: const InputDecoration(labelText: 'Email'),
            ),
            TextField(
              controller: _passCtrl,
              decoration: const InputDecoration(labelText: 'Password'),
              obscureText: true,
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _submit,
              child: Text(_isLogin ? 'Login' : 'Register'),
            ),
            TextButton(
              onPressed: () => setState(() => _isLogin = !_isLogin),
              child: Text(_isLogin
                  ? "Don't have an account? Register"
                  : 'Already have an account? Login'),
            ),
          ],
        ),
      ),
    );
  }
}
```

---

### `screens/feed_screen.dart`

```dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/auth_service.dart';
import '../services/firestore_service.dart';

class FeedScreen extends StatelessWidget {
  const FeedScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = AuthService();
    final fs = FirestoreService();

    return Scaffold(
      appBar: AppBar(
        title: const Text('MiniTweet'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: auth.logout,
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: fs.getTweets(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const CircularProgressIndicator();
          final tweets = snapshot.data!.docs;
          return ListView.builder(
            itemCount: tweets.length,
            itemBuilder: (context, i) {
              final data = tweets[i].data() as Map<String, dynamic>;
              final tweetId = tweets[i].id;
              return _TweetCard(data: data, tweetId: tweetId, fs: fs);
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showPostDialog(context, auth, fs),
        child: const Icon(Icons.add),
      ),
    );
  }

  void _showPostDialog(
      BuildContext context, AuthService auth, FirestoreService fs) {
    final ctrl = TextEditingController();
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('New Tweet'),
        content: TextField(
          controller: ctrl,
          decoration: const InputDecoration(hintText: "What's on your mind?"),
          maxLines: 3,
        ),
        actions: [
          TextButton(
            onPressed: () async {
              // Get author name from Firestore (one-time read)
              final uid = auth.currentUser!.uid;
              final userDoc = await FirebaseFirestore.instance
                  .collection('users')
                  .doc(uid)
                  .get();
              final name = userDoc.data()?['name'] ?? 'Anonymous';
              await fs.postTweet(ctrl.text.trim(), name);
              if (context.mounted) Navigator.pop(context);
            },
            child: const Text('Post'),
          ),
        ],
      ),
    );
  }
}

class _TweetCard extends StatefulWidget {
  final Map<String, dynamic> data;
  final String tweetId;
  final FirestoreService fs;
  const _TweetCard(
      {required this.data, required this.tweetId, required this.fs});

  @override
  State<_TweetCard> createState() => _TweetCardState();
}

class _TweetCardState extends State<_TweetCard> {
  bool _hearted = false;

  @override
  void initState() {
    super.initState();
    widget.fs.hasHearted(widget.tweetId).then((v) {
      if (mounted) setState(() => _hearted = v);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: ListTile(
        title: Text(widget.data['text'] ?? ''),
        subtitle: Text(widget.data['authorName'] ?? ''),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: Icon(
                _hearted ? Icons.favorite : Icons.favorite_border,
                color: _hearted ? Colors.red : null,
              ),
              onPressed: () async {
                await widget.fs.toggleHeart(widget.tweetId, _hearted);
                setState(() => _hearted = !_hearted);
              },
            ),
            Text('${widget.data['heartCount'] ?? 0}'),
          ],
        ),
      ),
    );
  }
}
```

---

## 5. Run the App

```bash
flutter run
```

No backend server to set up. Firebase handles auth, database, and rules.

---

## Pattern Summary

| Pattern | Where it appears |
|---|---|
| Root collection + foreign key | `tweets/` with `userId` field |
| Cross-parent query | `getTweets()` queries all users' tweets at once |
| Intermediate collection + composite ID | `hearts/{uid}_{tweetId}` prevents duplicate hearts |
| Aggregate field, updated on write | `heartCount` incremented via transaction, never counted on read |
| Intentional data duplication | `authorName` stored on tweet to skip a second `users/` read |
| Design backwards from the screen | Feed needs all tweets, so root collection. Heart icon needs an instant check, so direct doc lookup by composite ID |

---

## Common Mistakes

**Putting tweets in a subcollection** (`users/{uid}/tweets/`) is the most common one. It feels natural at first, but you can never build a global feed that way. Start with a root collection.

**Counting hearts by reading the `hearts/` collection** costs one read per document. With enough users, that adds up fast. Store `heartCount` on the tweet and update it on write instead.

**Auto-generating heart document IDs** means you lose the two things that make this pattern work: duplicate prevention and instant lookup. Use `{uid}_{tweetId}` as the ID.

**Fetching the author's name on every tweet render** means an extra Firestore read per card, every time the screen loads. Store `authorName` on the tweet at post time. One extra field, saved once.
