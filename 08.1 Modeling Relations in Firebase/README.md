# Modeling Relational Data in Firestore


[![Reference Video](https://img.youtube.com/vi/jm66TSlVtcc/0.jpg)](https://www.youtube.com/watch?v=jm66TSlVtcc)

[![Visualization Page](https://github.com/user-attachments/assets/03d37f27-cd2f-452a-98d7-a82b25a379b6)](https://htmlpreview.github.io/?https://github.com/Algoritma-dan-Pemrograman-ITS/mobile-programming/blob/main/08.1%20Modeling%20Relations%20in%20Firebase/visualization.html)

---

## Table of Contents

1. [Why This Matters](#-why-this-matters)
2. [Forget SQL. Think in Documents](#-forget-sql-think-in-documents)
3. [Three Ways to Store Data](#-three-ways-to-store-data)
4. [One-to-One: Just Embed It](#-one-to-one-just-embed-it)
5. [One-to-Many: The One You'll Use Most](#-one-to-many-the-one-youll-use-most)
6. [Real Example: A Twitter-Like Feed](#-real-example-a-twitter-like-feed)
7. [Many-to-Many: Hearts (Likes)](#-many-to-many-hearts-likes)
8. [Counting Without Reading Everything](#-counting-without-reading-everything)
9. [How to Pick the Right Approach](#-how-to-pick-the-right-approach)
10. [Trade-offs at a Glance](#-trade-offs-at-a-glance)
11. [The Parts That Trip Everyone Up](#-the-parts-that-trip-everyone-up)

---

## 💡 Why This Matters

Your app has connected data whether you plan for it or not:

- Users write posts
- Posts get comments
- Students enroll in courses
- Orders belong to customers

The problem isn't storing it. Firestore will hold whatever you throw at it. The problem is *how* you store it.

**Bad structure costs you:**
- Slow queries that make your UI feel broken
- A surprise Firebase bill (Firestore charges per document read)
- Code that's hard to fix once your data is already in production

Read 2 million documents just to count likes? That's real money gone. Get this right early, moving data later is painful.

---

## 🧠 Forget SQL. Think in Documents

If you've taken a databases course, your instinct is to reach for tables and JOINs. Firestore doesn't work that way. There are no JOINs. No rows. Just collections and documents.

| SQL | Firestore | Notes |
|---|---|---|
| Table | Collection | Just a folder of documents |
| Row | Document | A JSON object with fields |
| Column | Field | A key-value pair on a document |
| Foreign Key | Document ID as a string | You store the ID manually |
| JOIN | ❌ Doesn't exist | Make two separate queries instead |

**The one rule worth memorizing:**
- Documents stay **small** (under 1 MB each)
- Collections can grow **huge** (millions of documents, no problem)

---

## 📦 Three Ways to Store Data

Every model you build uses some combination of these three. Learn them well.

### 1. Root Collection

A collection at the top level of your database. The most common one you'll use.

<p align="center">
 <img height="400" alt="image" src="https://github.com/user-attachments/assets/6e4ce6d0-43c7-4d17-851e-3692685bd2df" />
</p>

```
Firestore Root
 └── users/
      ├── user_001
      ├── user_002
      └── user_003
```

**When to use it:** Almost always. Default to this until you have a reason not to.

---

### 2. Embedded Data

Nest extra data directly inside a document as a map. Same as nesting objects in JSON.

<p align="center">
  <img height="400" alt="image" src="https://github.com/user-attachments/assets/be53438a-510f-455b-ad23-b44f85f3774b" />
  <img height="300" alt="image" src="https://github.com/user-attachments/assets/8206d9a7-8739-40f1-9358-475f19904c5a" />
</p>

```
user_001
 ├── name: "Yuta"
 ├── email: "yuta@jjh-tokyo.ac.jp"
 └── address: {
      city: "Sendai",
      zip: "9800811"
     }
```

**When to use it:** The data is small, always loaded with its parent, and won't grow past 1 MB.

---

### 3. Subcollection

A collection that lives *inside* a document. Creates a parent-child relationship.

<p align="center">
 <img height="400" alt="image" src="https://github.com/user-attachments/assets/fcbc84b3-906d-4f7e-bee8-456dcfe9254c" />
</p>

```
users/
 └── user_001
      ├── name: "Yuta"
      └── submissions/
           ├── submission_001
           └── submission_002
```

**When to use it:** When the child data could grow large but you only ever need it for one specific parent at a time.

---

## 1️⃣ One-to-One: Just Embed It

**Example:** Each student has exactly one academic info object.

Just put it directly on the user document:

<p align="center">
 <img height="400" alt="image" src="https://github.com/user-attachments/assets/13356618-2666-42e6-a911-e841c367bdf3" />
</p>

```
user_001
 ├── name: "Yuta"
 ├── email: "yuta@jjh-tokyo.ac.jp"
 └── academicInfo: {
      gpa: 4.0,
      major: "Computer Science",
      semester: 6,
      studentId: "CS2021042"
     }
```

**Why this works:**
- One read gets you the user *and* their academic info
- If objects are small, then the 1 MB cap is not a concern
- No extra query needed
- This pattern breaks down only if the embedded data could *somehow grow without bound*.

---

## 🔁 One-to-Many: The One You'll Use Most

**Example:** A student receives scores for multiple courses (one user → many scores).

You have three options. Which one you pick depends entirely on what queries your app needs to run.

---

### Option A — Embed It

<p align="center">
 <img height="400" alt="image" src="https://github.com/user-attachments/assets/f9ee603a-8bae-4592-a4a9-17f66d8637ab" />
</p>

```
user_001
 ├── name: "Yuta"
 └── scores: {
      framework_programming: 88,
      object_oriented_programming: 75,
      mobile_programming: 91
     }
```

**✅ Good when:**
- The list is small and predictable
- You only ever need this data for that one user

**❌ Breaks when:**
- You need to search across users (e.g. "find all users who scored above 90 in Mobile Programming")
- To do that cross-user query, you'd have to load *every* user document and filter in your app, slow and expensive

---

### Option B — Subcollection

<p align="center">
 <img height="400" alt="image" src="https://github.com/user-attachments/assets/7e1f86df-6e5f-4292-accb-12e463637888" />
</p>

```
users/
 └── user_001
      └── scores/
           ├── framework_programming → { score: 88 }
           └── object_oriented_programming → { score: 75 }
```

**✅ Good when:**
- Scores could grow to thousands per user
- You only ever need them for one user at a time (e.g. "show this user's scores on their profile")

**❌ Breaks when:**
- You need to query across all users, subcollections are locked to their parent
- "All students who passed Framework Programming" is impossible from a subcollection

---

### Option C — Root Collection + Foreign Key ⭐ Most flexible

<p align="center">
 <img height="400" alt="image" src="https://github.com/user-attachments/assets/6d019e63-ee78-4b7c-94f1-e4a2c056fc3a" />
</p>

```
scores/
 ├── user_001_framework_programming → { userId: "user_001", courseId: "framework_programming", score: 88 }
 ├── user_001_object_oriented_programming → { userId: "user_001", courseId: "object_oriented_programming", score: 75 }
 └── user_002_framework_programming → { userId: "user_002", courseId: "framework_programming", score: 91 }
```

Pull scores into their own root collection and store `userId` on each document. It's the same idea as a foreign key in SQL, just without the JOIN. You query `where userId == "user_001"` as a separate call.

**✅ Good when:**
- You need to filter or search across all users
- "All Framework Programming scores above 90" → `where course == "framework_programming" AND score >= 90`
- You need flexibility to add new query patterns later

**❌ Trade-off:**
- You manage the relationship yourself through the `userId` field
- Requires a second query to get data from a related collection

---

## 🐦 Real Example: A Twitter-Like Feed

Users post tweets. You need two screens:

1. **Profile screen**: show one user's tweets
2. **Global feed**: show everyone's recent tweets

**First instinct:** subcollection.

<p align="center">
 <img height="400" alt="image" src="https://github.com/user-attachments/assets/655677a5-d7d0-4437-b3e5-407fe5ea2ce6" />
</p>

```
users/
 └── user_001
      └── tweets/
           └── { text: "Hello world", createdAt: ... }
```

- ✅ Profile screen works fine
- ❌ Global feed is impossible, you can't query tweets across different users when they're locked in subcollections

**The fix:** move tweets to a root collection.

<p align="center">
 <img height="388" alt="image" src="https://github.com/user-attachments/assets/8215e72b-99eb-4e7d-a54d-3f549e4ebe2e" />
</p>

```
tweets/
 ├── { userId: "user_001", text: "Hello world!", createdAt: ... }
 ├── { userId: "user_002", text: "We're winning too much, it's just not fair!", createdAt: ... }
 └── { userId: "user_001", text: "Good morning!", createdAt: ... }
```

Now both screens work with simple queries:

```dart
// Global feed: all tweets from today
firestore.collection('tweets')
    .where('createdAt', isGreaterThanOrEqualTo: today)

// Profile: just this user's tweets
firestore.collection('tweets')
    .where('userId', isEqualTo: 'user_001')

// Compound: one user's tweets from today
firestore.collection('tweets')
    .where('userId', isEqualTo: 'user_001')
    .where('createdAt', isGreaterThanOrEqualTo: today)
```

---

## ❤️ Many-to-Many: Hearts (Likes)

**The situation:**
- A user can heart many tweets
- A tweet can be hearted by many users
- Nobody should be able to heart the same tweet twice

**The solution:** an intermediate collection, same concept as a join table in SQL.

<p align="center">
 <img height="400" alt="image" src="https://github.com/user-attachments/assets/609ddc28-5578-4472-b413-96b9aef16b87" />
</p>

```
hearts/
 ├── "user_001_tweet_001" → { userId: "user_001", tweetId: "tweet_001" }
 ├── "user_001_tweet_002" → { userId: "user_001", tweetId: "tweet_002" }
 └── "user_002_tweet_001" → { userId: "user_002", tweetId: "tweet_001" }
```

Notice the document IDs: `userId_tweetId`, not auto-generated. You get two things for free:

**1. Uniqueness is automatic**
- Firestore doesn't allow duplicate document IDs in a collection
- If user_001 tries to heart tweet_001 again, it just overwrites the same document
- No duplicate. No extra check needed.

**2. Instant lookups**
- You already know what the ID would be
- Don't query the whole collection, read the document directly by ID

```dart
// Check if a user already hearted a tweet (one read, no query)
final docRef = firestore.collection('hearts').doc('${userId}_${tweetId}');
final doc = await docRef.get();
bool alreadyHearted = doc.exists;

// Get all hearts on a specific tweet
firestore.collection('hearts')
    .where('tweetId', isEqualTo: 'tweet_001')
```

---

## 🔢 Counting Without Reading Everything

**The problem:** a tweet goes viral and gets 2 million hearts. To show the count, do you read 2 million documents?

No. That would be:
- Slow, loading 2M docs takes time
- Expensive, that's 2 million document reads billed to your account
- Gets worse as the app grows

**The fix:** store a running total directly on the tweet document.

<p align="center">
 <img height="378" alt="image" src="https://github.com/user-attachments/assets/ba72fbde-598a-4e8f-a634-575c6b72ef54" />
</p>

```
tweet_001
 ├── text: "Been loving my new domain, time to expand it. Just implemented authentic user flows with mutual session handling"
 ├── userId: "user_001"
 └── heartCount: 249
```

**How to keep it accurate:**
1. User hearts a tweet → new document created in `hearts/`
2. A Cloud Function fires on that write → increments `heartCount` by 1
3. User removes heart → Cloud Function subtracts 1
4. All happens in the background. Your app just reads the number.

```dart
// Showing heart count = one document read
final tweet = await firestore.collection('tweets').doc('tweet_001').get();
int hearts = tweet.data()?['heartCount'] ?? 0;
```

> **Rule of thumb:** Don't count on read. Count on write.

Use this for anything you display often: like counts, follower counts, comment counts, message counts.

---

## 🗺️ How to Pick the Right Approach

When you're designing a new feature, walk through these questions in order:

| Question | Answer | Pattern to use |
|---|---|---|
| Is the data small? Always loaded with the parent? | Yes | Embedded object |
| Could it grow large? Only accessed one parent at a time? | Yes | Subcollection |
| Need to query across multiple parents? | Yes | Root collection + foreign key |
| Can A relate to many B, and B relate to many A? | Yes | Intermediate collection + composite ID |
| Need to display a count frequently? | Yes | Store aggregate field, update on write |

**Real examples mapped to patterns:**
- User settings → embed
- A user's order history → subcollection
- Tweets, posts, reviews → root collection
- Likes, enrollments, followers → intermediate collection
- Heart count, follower count → aggregate field

---

## 📊 Trade-offs at a Glance

| Technique | Scales | Cross-parent query | Complexity | Best for |
|---|---|---|---|---|
| Embedded object | ❌ (1 MB cap) | ❌ | Low | Small, tightly-bound data |
| Subcollection | ✅ | ❌ | Low | Large data, one parent at a time |
| Root collection + foreign key | ✅ | ✅ | Medium | Flexible one-to-many |
| Intermediate collection + composite ID | ✅ | ✅ | Medium | Many-to-many |
| Aggregate field (e.g. heartCount) | ✅ | ✅ | Needs Cloud Function | Frequent counts |

---

## ⚠️ The Parts That Trip Everyone Up

### No JOINs
The biggest shift from SQL. In Firestore you:
- Store document IDs as plain strings
- Make two separate queries to connect related data
- Accept two reads instead of one joined query

That's the trade Firestore makes for speed and scale. Get used to it.

### Subcollection walls
You **cannot** query a subcollection across different parent documents. This one catches people every time.

> If there's even a small chance you'll need cross-parent queries later, use a root collection from the start. Migrating data after users are in production is a nightmare.

### Duplicating data is intentional
In SQL, storing the same value in two places is a design mistake. In Firestore, you do it on purpose.

**Example:** Your tweet feed needs to show the author's display name next to each tweet. Instead of making a second round trip to `users/` for every tweet, just store `authorName` directly on the tweet document. Yes, it's duplicated. That's fine.

### Design backwards from the screen
- **SQL approach:** design the schema first, then build queries around it
- **Firestore approach:** look at what each screen needs to display, then build the data model that makes those reads as cheap and simple as possible

Ask yourself: *"What does this screen need?"*, then model the data to answer that question in as few reads as possible.
