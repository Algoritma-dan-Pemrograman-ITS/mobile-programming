# Showing Tweets with Author Info in Firebase

You have two Firestore collections: `users` and `tweets`. Each tweet has a `userId` field. You want to display a feed where every tweet shows the author's name and photo.

There are four ways to do this. One will wreck your app's performance before you even launch. This guide walks through all four so you know which to reach for and why.

---

## 📋 Table of Contents

- [Quick Comparison](#-quick-comparison)
- [Approach 1: The Loop ❌](#approach-1-the-loop-)
- [Approach 2: Fetch in Parallel ✅](#approach-2-fetch-in-parallel-)
- [Approach 3: Small User Cards ✅](#approach-3-small-user-cards-)
- [Approach 4: Copy Author Into the Tweet ⚡](#approach-4-copy-author-into-the-tweet-)
- [Which One Should You Use?](#-which-one-should-you-use)

---

## 📊 Quick Comparison

| | Approach | DB reads | Always fresh? | Extra setup? |
|--|----------|----------|---------------|--------------|
| ❌ | Loop one by one | 1 + N | Yes | None |
| ✅ | Fetch in parallel | 1 + unique users | Yes | None |
| ✅ | Small user cards | 1 + unique users (tiny) | Yes | New collection |
| ⚡ | Copy author into tweet | 1 total | Almost | Cloud Function |

---

## Approach 1: The Loop ❌

### The problem

Think of it like this: you need to send 30 packages. Instead of loading them all into a van and making one trip, you drive to the post office 30 times, once per package.

That's exactly what this code does:

```js
// Step 1: get all tweets
const tweetsSnap = await db.collection('tweets').get();

// Step 2: for EVERY tweet, make a separate DB call
for (const tweet of tweetsSnap.docs) {
  const user = await db.collection('users')
    .doc(tweet.data().userId)
    .get();
  // ⚠️ Each await blocks until the previous one finishes
}
```

### Why it's slow

- 30 tweets × 80ms per request = **~2.4 seconds** just to load the feed
- 100 tweets = **~8 seconds**
- Users leave after 3 seconds

### When to use it

Only for understanding what's happening under the hood. Never ship this.

---

## Approach 2: Fetch in Parallel ✅

### The idea

Same 30 packages. This time you load them all into the van and make one trip. That's what `Promise.all` does.

Key observation: a feed with 200 tweets might only have 30 unique authors. Instead of 200 user fetches, you need at most 30. Fire them all at once.

### The code

```js
// Step 1: get the tweets
const snap = await db.collection('tweets')
  .orderBy('createdAt', 'desc')
  .limit(20)
  .get();

const tweets = snap.docs.map(d => ({ id: d.id, ...d.data() }));

// Step 2: collect unique author IDs
// new Set() removes duplicates automatically
const uniqueUserIds = [...new Set(tweets.map(t => t.userId))];
// Example: 20 tweets, 5 unique authors = only 5 fetches needed

// Step 3: fetch all authors at the same time
const userDocs = await Promise.all(
  uniqueUserIds.map(id => db.collection('users').doc(id).get())
);

// Step 4: build a lookup map { userId: userData }
const usersMap = {};
userDocs.forEach(doc => {
  usersMap[doc.id] = doc.data();
});

// Step 5: attach the author to each tweet
const feed = tweets.map(tweet => ({
  ...tweet,
  author: usersMap[tweet.userId],
}));

// Usage: feed[0].author.name, feed[0].author.photoURL
```

### ✅ Good when

- You're building a class project or a standard app
- Your Firestore structure is already set up. Nothing to change.
- You want two round trips max, regardless of how many tweets you load

### ❌ Breaks when

- Your `users` documents are large (10+ fields) and you're fetching many of them. You're pulling data the feed doesn't need on every load.

### When to use it

Your default. Start here.

---

## Approach 3: Small User Cards ✅

### The idea

Approach 2 with one small upgrade.

A `users` document might carry a lot: name, email, bio, address, settings, notification preferences. But the feed only needs two things: the author's name and their photo.

Firestore charges per document read, not per field. Reading a 2-field document costs the same as reading a 20-field document. But it transfers less data and loads faster on mobile.

So you keep a second, lightweight collection called `userSummaries`:

```
users/{uid}
  ├── name: "Yuta"
  ├── email: "yuta@jjh-tokyo.ac.jp"
  ├── bio: "Mobile dev student"
  ├── address: "Sendai"
  └── notificationSettings: { ... }   <- not needed in the feed

userSummaries/{uid}                   <- lean copy, just for feeds
  ├── name: "Yuta"
  └── photoURL: "https://..."
```

### Keeping both in sync

When a user updates their profile, write to both collections:

```dart
Future<void> updateProfile(String uid, String name, String photoURL) async {
  // Full profile, for the profile page
  await FirebaseFirestore.instance.collection('users').doc(uid).update({
    'name': name,
    'photoURL': photoURL,
    // ... all other fields
  });

  // Lean summary, for feeds
  await FirebaseFirestore.instance.collection('userSummaries').doc(uid).set({
    'name': name,
    'photoURL': photoURL,
  });
}
```

### Reading the feed

Same logic as Approach 2, different collection:

```js
const userDocs = await Promise.all(
  uniqueUserIds.map(id =>
    db.collection('userSummaries').doc(id).get() // small doc, fast
  )
);
```

### ✅ Good when

- Your user profiles have 10+ fields
- You care about bandwidth (mobile users on slow connections)
- You're setting up the project from scratch. Much easier to start lean than to add this later.

### ❌ Trade-off

- You write to two collections every time a user updates their profile
- If you forget to update `userSummaries`, the feed shows stale author data

---

## Approach 4: Copy Author Into the Tweet ⚡

### The idea

Instead of looking up the author when you *read* a tweet, you copy their info into the tweet when you *write* it.

Think of a printed newspaper. The journalist's name and photo are right there on the article. No lookup needed. The info travels with the content.

```
tweets/{id}
  ├── text: "Been loving my new domain, time to expand it."
  ├── userId: "user_001"            <- keep for reference
  ├── authorName: "Yuta"            <- copied at write time
  └── authorPhoto: "https://..."    <- copied at write time
```

### Creating a tweet

```dart
Future<void> createTweet(String userId, String text) async {
  // Get the author's current info
  final userDoc = await FirebaseFirestore.instance
    .collection('users')
    .doc(userId)
    .get();

  await FirebaseFirestore.instance.collection('tweets').add({
    'text': text,
    'userId': userId,
    'authorName': userDoc['name'],
    'authorPhoto': userDoc['photoURL'],
    'createdAt': FieldValue.serverTimestamp(),
  });
}
```

### Reading the feed

One query. No second round trip:

```dart
final snap = await FirebaseFirestore.instance
  .collection('tweets')
  .orderBy('createdAt', descending: true)
  .limit(20)
  .get();

// Every document already has authorName and authorPhoto
```

### The catch: stale author info

If Yuta changes his display name, older tweets still show the old name. You fix this with a Cloud Function that runs automatically whenever a user document changes:

```js
exports.syncAuthorToTweets = functions.firestore
  .document('users/{userId}')
  .onUpdate(async (change, context) => {
    const before = change.before.data();
    const after  = change.after.data();

    // Nothing changed that affects the feed, skip
    if (before.name === after.name && before.photoURL === after.photoURL) {
      return null;
    }

    // Find all tweets by this user
    const tweetsSnap = await db.collection('tweets')
      .where('userId', '==', context.params.userId)
      .get();

    // Update all of them at once (all succeed or all fail)
    const batch = db.batch();
    tweetsSnap.docs.forEach(doc => {
      batch.update(doc.ref, {
        authorName:  after.name,
        authorPhoto: after.photoURL,
      });
    });

    return batch.commit();
  });
```

The sync takes a few seconds. For a social feed, that's fine. Nobody notices a 3-second delay when someone renames themselves. For a banking app where accuracy matters immediately, this is not the right call.

### ✅ Good when

- Building a public app with heavy read traffic
- Author names rarely change
- You can set up the Cloud Function before launch

### ❌ Breaks when

- Your use case needs the author name to be immediately accurate after a change
- You forget to deploy the Cloud Function. Feeds will silently show stale data.

---

## 🧭 Which One Should You Use?

```
Just learning, or building a class project?
  └── Approach 2: nothing to configure, works with your existing structure

User profile documents are large (10+ fields)?
  ├── No  → Approach 2
  └── Yes → Approach 3 (set it up from the start, harder to add later)

Building a public app with heavy read traffic?
  └── Approach 4: one read per feed load, set up the Cloud Function early
```

### The general rule

Think about how often data gets read vs. how often it gets written:
- A tweet is read potentially thousands of times, written once
- An author's name changes maybe once a year

When reads far outnumber writes, do extra work at write time to make reads cheap. That's the logic behind Approaches 3 and 4.

---

## 📌 Side-by-Side

| | N+1 Loop | Parallel Fetch | userSummaries | Denormalize |
|--|---------|----------------|---------------|-------------|
| Total reads | 1 + N | 1 + unique | 1 + unique (small) | 1 |
| Data always fresh? | Yes | Yes | Yes | Mostly (few sec delay) |
| Extra setup needed | None | None | New collection | Cloud Function |
| Write complexity | None | None | Write to 2 collections | Write author into tweet |
| Best for | Learning only | Most projects | Budget-conscious apps | High-traffic feeds |
