# 07. Relational Database

[Previous](/06.%20CRUD%20Local%20Database/) | [Main Page](/) | [Next](/07.%20Awesome%20Notifications/)

## Content Outline

- [One-to-one](#one-to-one-relationship)
- [One-to-many](#one-to-many-relationship)
- [Many-to-many](#many-to-many-relationship)

This module covers relationship between two objects in database Isar.

## One-to-one relationship

In a one-to-one relationship, one object in a collection is related to only one object in another collection and vice versa. In example, a `User` has one `Profile`, and each `Profile` belongs to one `User`.

To model this, we use `IsarLink<T>` type to link between two classes.

```dart
@Collection()
class User {
  Id id = Isar.autoIncrement;

  late String name;

  // One-to-one link to Profile
  final profile = IsarLink<Profile>();
}

@Collection()
class Profile {
  Id id = Isar.autoIncrement;

  late String bio;
  late String avatarUrl;
}
```

`User` has a profile property of type `IsarLink<Profile>()`.

Here is the example how to use this relationship

```dart
// Create object relation
final user = User()..name = 'Alice';
final profile = Profile()
  ..bio = 'Hello!'
  ..avatarUrl = 'https://image.url';

// Link them together
user.profile.value = profile;

await isar.writeTxn(() async {
  await isar.profiles.put(profile); // save the profile first
  await isar.users.put(user); // then save the user
});
```

```dart
// How to access the linked profile
final loadedUser = await isar.users.get(user.id);

// Load the linked profile
await loadedUser!.profile.load();

print(loadedUser.profile.value?.bio); // Output: Hello!

```

```dart
// How to remove the link
user.profile.value = null;

await isar.writeTxn(() async {
  await isar.users.put(user); // Update the link
});
```

## One-to-many relationship

In a one-to-many relationship, one object in a collection is related to many one object in another collection. In example, a `User` can have many `Post`s, but each `Post` belongs to one `User`.

In Isar, One-to-Many is modeled using a reverse link from the “many” side with `IsarLink<T>`.

```dart
@Collection()
class User {
  Id id = Isar.autoIncrement;

  late String name;
  // No need to explicitly define the one-to-many here
}

@Collection()
class Post {
  Id id = Isar.autoIncrement;

  late String title;
  late String content;

  final user = IsarLink<User>(); // Many-to-One link
}

```

Here is the example how to use this relationship

```dart
// Create object relation
final user = User()..name = 'Alice';

final post1 = Post()
  ..title = 'My First Post'
  ..content = 'Hello world!'
  ..user.value = user;

final post2 = Post()
  ..title = 'Another Post'
  ..content = 'More content here'
  ..user.value = user;

await isar.writeTxn(() async {
  await isar.users.put(user); // Save the user first
  await isar.posts.putAll([post1, post2]); // Then the posts
});

```

```dart
// Get all posts for a user

final userId = user.id;

final posts = await isar.posts
    .filter()
    .user((q) => q.idEqualTo(userId))
    .findAll();

for (final post in posts) {
  print(post.title);
}
```

### Many-to-many relationship

In a many-to-many relationship, many object in a collection is related to many one object in another collection. In example, a `Student` can enroll to many `Course`s, and a `Course` can have many `Student`s.

In Isar, you use `IsarLinks<T>` on both sides of the relationship.

```dart
@Collection()
class Student {
  Id id = Isar.autoIncrement;

  late String name;

  final courses = IsarLinks<Course>(); // Many-to-Many
}

@Collection()
class Course {
  Id id = Isar.autoIncrement;

  late String title;

  final students = IsarLinks<Student>(); // Many-to-Many
}

```

Here is the example how to use this relationship

```dart
final math = Course()..title = 'Math';
final science = Course()..title = 'Science';

final alice = Student()..name = 'Alice';
final bob = Student()..name = 'Bob';

// Link students to courses
alice.courses.addAll([math, science]);
bob.courses.add(math);

// Link courses to students (optional but recommended for bi-directional access)
math.students.addAll([alice, bob]);
science.students.add(alice);

await isar.writeTxn(() async {
  await isar.courses.putAll([math, science]);
  await isar.students.putAll([alice, bob]);

  // Save the links
  await alice.courses.save();
  await bob.courses.save();
  await math.students.save();
  await science.students.save();
});

```

## Firestore relation

Firestore is based on non-relational database, so it does not support relational database concepts like one-to-one, one-to-many, and many-to-many relationships. However, we can simulate these relationships using Firestore's features.

### ID Based Reference 

This is the simplest way to model relationships in Firestore. We store the ID of the related document in the parent document.

For example we have Post model and User model, each of the post has relation to a user. We can model this relationship as follows:



```dart
class Post {
  final String title;
  final String content;
  final String userId;

  Post({
    required this.title,
    required this.content,
    required this.userId,
  });
}
```

If we want to get the user data, we need to query the users collection with the userId.

```dart
// query post with user id
final posts = await firestore
    .collection('posts')
    .where('userId', isEqualTo: userId)
    .get();

// query user with post id
final users = await firestore
    .collection('users')
    .where('id', isEqualTo: postId)
    .get();
```

The stored data will be look like this:

```json
{
  "title": "My First Post",
  "content": "Hello world!",
  "userId": "user123"
}
```

### Document Reference

This is a more advanced way to model relationships in Firestore. We store the document reference of the related document in the parent document.

For example we have Post model and User model, each of the post has relation to a user. We can model this relationship as follows:

```dart
class Post {
  final String title;
  final String content;
  final DocumentReference user;

  Post({
    required this.title,
    required this.content,
    required this.user,
  });
}
```

If we want to get the user data, we can use the stored `DocumentReference` to fetch the related document directly.

```dart
// Get the user DocumentReference from Firestore
final userRef = firestore.collection('users').doc('user123');

// Create a post with a DocumentReference
final post = Post(
  title: 'My First Post',
  content: 'Hello world!',
  user: userRef,
);

// Save post to Firestore
await firestore.collection('posts').add({
  'title': post.title,
  'content': post.content,
  'user': post.user, // stores the DocumentReference
});

// Fetch the post and resolve the user reference
final postSnapshot = await firestore.collection('posts').doc('post123').get();
final postData = postSnapshot.data()!;

final DocumentReference resolvedUserRef = postData['user'] as DocumentReference;
final userSnapshot = await resolvedUserRef.get();

print(userSnapshot.data()); // Output: { name: 'Alice', ... }
```

The stored data will look like this:

```json
{
  "title": "My First Post",
  "content": "Hello world!",
  "user": "/users/user123"
}
```

### Many-to-many Relationship

Firestore does not have a native join table, so many-to-many relationships are modeled by storing an **array of related IDs** (or `DocumentReference`s) inside each document.

For example, a `Student` can enroll in many `Course`s, and a `Course` can have many `Student`s. We can model this as follows:

```dart
class Student {
  final String id;
  final String name;
  final List<String> courseIds; // IDs of enrolled courses

  Student({
    required this.id,
    required this.name,
    required this.courseIds,
  });
}

class Course {
  final String id;
  final String title;
  final List<String> studentIds; // IDs of enrolled students

  Course({
    required this.id,
    required this.title,
    required this.studentIds,
  });
}
```

Here is an example of how to use this relationship:

```dart
// Enroll Alice in Math and Science
await firestore.collection('students').doc('alice').set({
  'name': 'Alice',
  'courseIds': ['math', 'science'],
});

// Save courses with their student lists
await firestore.collection('courses').doc('math').set({
  'title': 'Math',
  'studentIds': ['alice', 'bob'],
});

await firestore.collection('courses').doc('science').set({
  'title': 'Science',
  'studentIds': ['alice'],
});
```

```dart
// Query all courses that Alice is enrolled in
final studentSnapshot = await firestore.collection('students').doc('alice').get();
final List<String> courseIds = List<String>.from(studentSnapshot['courseIds']);

final courses = await Future.wait(
  courseIds.map((id) => firestore.collection('courses').doc(id).get()),
);

for (final course in courses) {
  print(course['title']); // Output: Math, Science
}
```

```dart
// Query all students enrolled in Math
final mathSnapshot = await firestore.collection('courses').doc('math').get();
final List<String> studentIds = List<String>.from(mathSnapshot['studentIds']);

final students = await Future.wait(
  studentIds.map((id) => firestore.collection('students').doc(id).get()),
);

for (final student in students) {
  print(student['name']); // Output: Alice, Bob
}
```

The stored data will look like this:

```json
// students/alice
{
  "name": "Alice",
  "courseIds": ["math", "science"]
}

// courses/math
{
  "title": "Math",
  "studentIds": ["alice", "bob"]
}
```

> **Note:** Because Firestore does not support cross-collection joins, you need to maintain both sides of the relationship manually. When a student enrolls in a course, update `courseIds` in the student document **and** `studentIds` in the course document to keep them in sync.

### Subcollections

A **subcollection** is a collection nested inside a document. This is useful when there is a clear ownership or hierarchy between data — the child data only makes sense in the context of its parent.

For example, a `User` can have many `Post`s. Instead of storing posts in a top-level collection, we nest them directly under each user document.

```
firestore
└── users (collection)
    └── alice (document)
        ├── name: "Alice"
        └── posts (subcollection)
            ├── post1 (document)
            │   ├── title: "My First Post"
            │   └── content: "Hello world!"
            └── post2 (document)
                ├── title: "Another Post"
                └── content: "More content here"
```

Here is an example of how to use subcollections:

```dart
// Write: add a post under a specific user
await firestore
    .collection('users')
    .doc('alice')
    .collection('posts')
    .add({
      'title': 'My First Post',
      'content': 'Hello world!',
      'createdAt': FieldValue.serverTimestamp(),
    });
```

```dart
// Read: get all posts belonging to a user
final postsSnapshot = await firestore
    .collection('users')
    .doc('alice')
    .collection('posts')
    .get();

for (final post in postsSnapshot.docs) {
  print(post['title']); // Output: My First Post, Another Post
}
```

```dart
// Read: get a single post from a user
final postSnapshot = await firestore
    .collection('users')
    .doc('alice')
    .collection('posts')
    .doc('post1')
    .get();

print(postSnapshot['title']); // Output: My First Post
```

```dart
// Delete: remove a post from a user's subcollection
await firestore
    .collection('users')
    .doc('alice')
    .collection('posts')
    .doc('post1')
    .delete();
```

The stored data structure will look like this:

```json
// users/alice
{
  "name": "Alice"
}

// users/alice/posts/post1
{
  "title": "My First Post",
  "content": "Hello world!",
  "createdAt": "2024-01-01T00:00:00Z"
}
```

> **Note:** Deleting a parent document does **not** automatically delete its subcollections. You must delete subcollection documents explicitly, or use a Cloud Function to handle cascading deletes.

## Working Project Example

If you want to see all of the above relationships and Firestore patterns implemented in a real Flutter project, check out this example repository:

**[isar-firestore-example](https://github.com/mikungg/isar-firestore-example)**

This project demonstrates how to combine:

- Isar local database
- Firebase Firestore cloud database
- One-to-one relationships
- One-to-many relationships
- Many-to-many relationships
- Firestore document references
- Firestore subcollections
- CRUD operations with real Flutter UI

It can be used as a hands-on reference after finishing this module.
