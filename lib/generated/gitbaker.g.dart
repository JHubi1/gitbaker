// GitBaker v0.0.6 <https://pub.dev/packages/gitbaker>

// This is an automatically generated file by GitBaker. Do not modify manually.
// To regenerate this file, please rerun the command 'dart run gitbaker'

// ignore_for_file: unnecessary_nullable_for_final_variable_declarations

library;

enum RemoteType { fetch, push, unknown }

final class Remote {
  final String name;
  final Uri url;
  final RemoteType type;

  Remote._({required this.name, required this.url, required this.type});
}

final class User {
  final String name;
  final String email;

  User._({required this.name, required this.email});
}

final class Commit {
  final String hash;
  final String message;
  final DateTime date;

  /// Whether the commit has been signed.
  /// Careful: not whether the signature is valid!
  final bool signed;

  final String _branch;
  Branch get branch => GitBaker.branches.singleWhere((e) => e.name == _branch);

  final String _author;
  User get author =>
      GitBaker.contributors.singleWhere((e) => e.email == _author);

  Commit._(
    this.hash, {
    required this.message,
    required this.date,
    required this.signed,
    required String branch,
    required String author,
  }) : _branch = branch,
       _author = author;
}

final class Branch {
  final String hash;
  final String name;
  final List<Commit> commits;

  bool get isCurrent => this == GitBaker.currentBranch;
  bool get isDefault => this == GitBaker.defaultBranch;

  Branch._(this.hash, {required this.name, required this.commits});
}

final class Tag {
  final String hash;
  final String name;
  final String description;

  Tag._(this.hash, {required this.name, required this.description});
}

final class GitBaker {
  static final String? description = null;

  static Remote get remote => remotes.firstWhere(
    (r) => r.name == 'origin' && r.type == RemoteType.fetch,
    orElse:
        () => remotes.firstWhere(
          (r) => r.type == RemoteType.fetch,
          orElse: () => remotes.first,
        ),
  );
  static final Set<Remote> remotes = {
    Remote._(
      name: "origin",
      url: Uri.parse("https://github.com/JHubi1/gitbaker.git"),
      type: RemoteType.fetch,
    ),
    Remote._(
      name: "origin",
      url: Uri.parse("https://github.com/JHubi1/gitbaker.git"),
      type: RemoteType.push,
    ),
  };

  static final Set<User> contributors = {
    User._(name: "JHubi1", email: "me@jhubi1.com"),
    User._(name: "Hudson Afonso", email: "hudson.afonso@gmail.com"),
  };

  static final Branch defaultBranch = branches.singleWhere(
    (e) => e.name == "main",
  );
  static final Branch currentBranch = branches.singleWhere(
    (e) => e.name == "main",
  );

  static final Set<Branch> branches = {
    Branch._(
      "64bcf42e6825365a235ca7bb26ae2f45ff345875",
      name: "main",
      commits: [
        Commit._(
          "c1ed74ebd5953ca7cd2cae336465e8ba6b7bafe8",
          message: "Initial commit",
          date: DateTime.fromMillisecondsSinceEpoch(
            1735264927000,
            isUtc: true,
          ), // 2024-12-27T02:02:07.000Z
          signed: true,
          branch: "main",
          author: "me@jhubi1.com",
        ),
        Commit._(
          "c9415e474684b460eb55f934c45348e97bf03b63",
          message: "Updated changelog, added GHA",
          date: DateTime.fromMillisecondsSinceEpoch(
            1735265093000,
            isUtc: true,
          ), // 2024-12-27T02:04:53.000Z
          signed: true,
          branch: "main",
          author: "me@jhubi1.com",
        ),
        Commit._(
          "1a6ed49e2258b7d7d444ec8d33862c34d6341d05",
          message: "Various bug fixes and improvements",
          date: DateTime.fromMillisecondsSinceEpoch(
            1735309319000,
            isUtc: true,
          ), // 2024-12-27T14:21:59.000Z
          signed: true,
          branch: "main",
          author: "me@jhubi1.com",
        ),
        Commit._(
          "c8ea80bba981db8fdfab32df3d415ef49ff7be1e",
          message: "Updated readme and added example",
          date: DateTime.fromMillisecondsSinceEpoch(
            1735309610000,
            isUtc: true,
          ), // 2024-12-27T14:26:50.000Z
          signed: true,
          branch: "main",
          author: "me@jhubi1.com",
        ),
        Commit._(
          "31431b8bc1b0049d343ef0c0faeaad09757a5e7e",
          message: "Tweaks",
          date: DateTime.fromMillisecondsSinceEpoch(
            1735309934000,
            isUtc: true,
          ), // 2024-12-27T14:32:14.000Z
          signed: true,
          branch: "main",
          author: "me@jhubi1.com",
        ),
        Commit._(
          "35123038e89c6cd100febf021a1f4163bbe0c829",
          message: "Removed version dependency",
          date: DateTime.fromMillisecondsSinceEpoch(
            1735310063000,
            isUtc: true,
          ), // 2024-12-27T14:34:23.000Z
          signed: true,
          branch: "main",
          author: "me@jhubi1.com",
        ),
        Commit._(
          "586d7ac0a7c41cdf75d8dd24f44f3b2d1eb57587",
          message: "Support git encoding",
          date: DateTime.fromMillisecondsSinceEpoch(
            1735311357000,
            isUtc: true,
          ), // 2024-12-27T14:55:57.000Z
          signed: true,
          branch: "main",
          author: "me@jhubi1.com",
        ),
        Commit._(
          "38b6662cfe57e1e24f865b4ac23709e3e432a61a",
          message: "Contributors and signed commits",
          date: DateTime.fromMillisecondsSinceEpoch(
            1736119504000,
            isUtc: true,
          ), // 2025-01-05T23:25:04.000Z
          signed: true,
          branch: "main",
          author: "me@jhubi1.com",
        ),
        Commit._(
          "239e300ab93800cb3a6cf8eb2477c8830bc558c8",
          message: "Added platform suggestion",
          date: DateTime.fromMillisecondsSinceEpoch(
            1736120007000,
            isUtc: true,
          ), // 2025-01-05T23:33:27.000Z
          signed: true,
          branch: "main",
          author: "me@jhubi1.com",
        ),
        Commit._(
          "c97517c4d4819db244fce8489841181778da8cb8",
          message: "Update README.md",
          date: DateTime.fromMillisecondsSinceEpoch(
            1736729005000,
            isUtc: true,
          ), // 2025-01-13T00:43:25.000Z
          signed: true,
          branch: "main",
          author: "hudson.afonso@gmail.com",
        ),
        Commit._(
          "8728a580d22533955ca0fb7ab957aaf8da31b6d4",
          message: "Merge pull request #1 from HudsonAfonso/patch-1",
          date: DateTime.fromMillisecondsSinceEpoch(
            1741101801000,
            isUtc: true,
          ), // 2025-03-04T15:23:21.000Z
          signed: true,
          branch: "main",
          author: "me@jhubi1.com",
        ),
        Commit._(
          "86357fa20a31fcabfdff00774cd78024824a7e56",
          message: "Private constructors, formatting, better CLI",
          date: DateTime.fromMillisecondsSinceEpoch(
            1745015328000,
            isUtc: true,
          ), // 2025-04-18T22:28:48.000Z
          signed: true,
          branch: "main",
          author: "me@jhubi1.com",
        ),
        Commit._(
          "33fa570fef9ef2243cb105293e668d622785d75c",
          message: "Updated version",
          date: DateTime.fromMillisecondsSinceEpoch(
            1745015362000,
            isUtc: true,
          ), // 2025-04-18T22:29:22.000Z
          signed: true,
          branch: "main",
          author: "me@jhubi1.com",
        ),
        Commit._(
          "7ab5685f0cbeeec29bb2b0a5523561408aa75cd0",
          message: "Encoding, final classes, no `intl` dependency",
          date: DateTime.fromMillisecondsSinceEpoch(
            1751190679000,
            isUtc: true,
          ), // 2025-06-29T09:51:19.000Z
          signed: true,
          branch: "main",
          author: "me@jhubi1.com",
        ),
        Commit._(
          "64bcf42e6825365a235ca7bb26ae2f45ff345875",
          message: "Typo",
          date: DateTime.fromMillisecondsSinceEpoch(
            1751190792000,
            isUtc: true,
          ), // 2025-06-29T09:53:12.000Z
          signed: true,
          branch: "main",
          author: "me@jhubi1.com",
        ),
      ],
    ),
  };

  static final Set<Tag> tags = {
    Tag._(
      "31431b8bc1b0049d343ef0c0faeaad09757a5e7e",
      name: "0.0.2",
      description: "Tweaks",
    ),
    Tag._(
      "586d7ac0a7c41cdf75d8dd24f44f3b2d1eb57587",
      name: "0.0.3",
      description: "Support git encoding",
    ),
    Tag._(
      "38b6662cfe57e1e24f865b4ac23709e3e432a61a",
      name: "0.0.4",
      description: "Contributors and signed commits",
    ),
    Tag._(
      "33fa570fef9ef2243cb105293e668d622785d75c",
      name: "0.0.5",
      description: "Updated version",
    ),
    Tag._(
      "64bcf42e6825365a235ca7bb26ae2f45ff345875",
      name: "0.0.6",
      description: "Typo",
    ),
  };
}
