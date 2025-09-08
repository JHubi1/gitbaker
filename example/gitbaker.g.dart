// GitBaker v0.1.0 <https://pub.dev/packages/gitbaker>

// This is an automatically generated file by GitBaker. Do not modify manually.
// To regenerate this file, please rerun the command 'dart run gitbaker'

/// Generated Git history and metadata for the current Git repository.
///
/// See <https://pub.dev/packages/gitbaker> for more information. To update or
/// regenerate this file, run `dart run gitbaker` somewhere in this repository.
library;

/// Represents the type of remote operation for a Git repository.
enum RemoteType { fetch, push, unknown }

/// A class representing a remote repository or connection.
final class Remote {
  final String name;
  final RemoteType type;

  final String _uri;
  Uri get uri => Uri.parse(_uri);

  const Remote._({required this.name, required this.type, required String uri})
    : _uri = uri;
}

/// A class representing a contributor to the repository.
///
/// Each user is uniquely identified by their email address. Multiple users
/// may share the same name, but not the same email.
final class User {
  final String name;
  final String email;

  const User._({required this.name, required this.email});
}

/// A class representing a Git branch.
final class Branch {
  final String name;

  /// The number of commits in this branch, following only the first parent.
  ///
  /// This value can be used to determine the relative age of branches, but
  /// should not be used to determine the absolute number of commits, as it
  /// only follows the first parent and does not count merge commits.
  final int revision;

  final Set<String> _commits;
  Set<Commit> get commits =>
      _commits
          .map((h) => GitBaker.commits.singleWhere((c) => c.hash == h))
          .toSet();

  bool get isCurrent => this == GitBaker.currentBranch;
  bool get isDefault => this == GitBaker.defaultBranch;

  const Branch._({
    required this.name,
    required this.revision,
    required Set<String> commits,
  }) : _commits = commits;
}

/// A class representing a Git tag.
///
/// You may use the [commit] property's message as a description of the tag
/// next to its name.
final class Tag {
  final String name;

  final String _commit;
  Commit get commit => GitBaker.commits.singleWhere((c) => c.hash == _commit);

  const Tag._({required this.name, required String commit}) : _commit = commit;
}

/// A class representing a single commit in the Git repository.
final class Commit {
  final String hash;
  final String hashAbbreviated;

  final String message;
  final DateTime date;

  /// Whether the commit has been signed.
  ///
  /// ***Careful:*** Not whether the signature is valid, only whether it
  /// exists. Git is unable to verify signatures without access to the public
  /// key of the signer, which is not stored in the repository.
  final bool signed;

  /// The branches that contain this commit.
  ///
  /// This may be empty if the commit is not present in any branch (e.g. if it
  /// is only present in tags or is an orphaned commit).
  Set<Branch> get presentIn =>
      GitBaker.branches.where((b) => b.commits.contains(this)).toSet();

  final String _author;
  User get author => GitBaker.members.singleWhere((e) => e.email == _author);

  final String _committer;
  User get committer =>
      GitBaker.members.singleWhere((e) => e.email == _committer);

  const Commit._(
    this.hash, {
    required this.hashAbbreviated,
    required this.message,
    required this.date,
    required this.signed,
    required String author,
    required String committer,
  }) : _author = author,
       _committer = committer;
}

final class GitBaker {
  // possibility of null if no description is set
  // ignore: unnecessary_nullable_for_final_variable_declarations
  static const String? description = null;

  /// The most likely remote to be used for fetching and pushing.
  ///
  /// This is determined by first looking for a remote named "origin" with type
  /// [RemoteType.fetch]. If no such remote exists, the first remote with type
  /// [RemoteType.fetch] is used, regardless of its name. If no such remote
  /// exists, the first remote in [remotes] is used.
  static Remote get remote => remotes.firstWhere(
    (r) => r.name == "origin" && r.type == RemoteType.fetch,
    orElse:
        () => remotes.firstWhere(
          (r) => r.type == RemoteType.fetch,
          orElse: () => remotes.first,
        ),
  );

  /// All remotes configured for this repository.
  ///
  /// This includes remotes for fetching and pushing, as well as any other types
  /// of remotes that may be configured.
  ///
  /// Note that multiple remotes may have the same [name] and [uri], but different
  /// [type]s. For example, a remote may be configured for both fetching and
  /// pushing.
  static const Set<Remote> remotes = {
    Remote._(
      name: "origin",
      type: RemoteType.fetch,
      uri: "https://github.com/JHubi1/gitbaker.git",
    ),
    Remote._(
      name: "origin",
      type: RemoteType.push,
      uri: "https://github.com/JHubi1/gitbaker.git",
    ),
  };

  /// All members to this repository.
  ///
  /// Each user is uniquely identified by their email address. Multiple users may
  /// share the same name, but not the same email.
  static const Set<User> members = {
    User._(name: "JHubi1", email: "me@jhubi1.com"),
    User._(name: "Hudson Afonso", email: "hudson.afonso@gmail.com"),
    User._(name: "GitHub", email: "noreply@github.com"),
  };

  /// The default branch of the repository, usually "main" or "master".
  static final Branch defaultBranch = branches.singleWhere(
    (e) => e.name == "main",
  );

  /// The currently checked out branch of the repository.
  static final Branch currentBranch = branches.singleWhere(
    (e) => e.name == "main",
  );

  /// All branches in the repository.
  ///
  /// If the configuration sets the list `branches`, only branches matching any of
  /// the provided regular expressions are included. If it is empty or not set,
  /// all branches are included.
  static const Set<Branch> branches = {
    Branch._(
      name: "main",
      revision: 21,
      commits: {
        "c1ed74ebd5953ca7cd2cae336465e8ba6b7bafe8",
        "c9415e474684b460eb55f934c45348e97bf03b63",
        "1a6ed49e2258b7d7d444ec8d33862c34d6341d05",
        "c8ea80bba981db8fdfab32df3d415ef49ff7be1e",
        "31431b8bc1b0049d343ef0c0faeaad09757a5e7e",
        "35123038e89c6cd100febf021a1f4163bbe0c829",
        "586d7ac0a7c41cdf75d8dd24f44f3b2d1eb57587",
        "38b6662cfe57e1e24f865b4ac23709e3e432a61a",
        "239e300ab93800cb3a6cf8eb2477c8830bc558c8",
        "c97517c4d4819db244fce8489841181778da8cb8",
        "8728a580d22533955ca0fb7ab957aaf8da31b6d4",
        "86357fa20a31fcabfdff00774cd78024824a7e56",
        "33fa570fef9ef2243cb105293e668d622785d75c",
        "7ab5685f0cbeeec29bb2b0a5523561408aa75cd0",
        "64bcf42e6825365a235ca7bb26ae2f45ff345875",
        "44337dcba6725482e5b0b449caa35d1d428da727",
        "0137281f606832ee5567b5e5d938040ffe1144e9",
        "34f2ba206d6980e36ca4200cc1e2bb81f0a09cad",
        "71b769101fe00ee91135feaa29bcaee09854197e",
        "b0c29dcfc83fa9a02b92214790ca8b5257bc1f97",
        "86db04bf378d50fe66f929767a98f44fa3f9e5f1",
        "777235d62342f93d8e89f989e0884ab1cb65822d",
      },
    ),
  };

  /// All tags in the repository.
  ///
  /// [Tag.commit.message] may be used as a description of a tag.
  ///
  /// Note that this won't get the release notes of Git hosting services like
  /// GitHub or GitLab, but only the tag name.
  static const Set<Tag> tags = {
    Tag._(name: "0.0.2", commit: "31431b8bc1b0049d343ef0c0faeaad09757a5e7e"),
    Tag._(name: "0.0.3", commit: "586d7ac0a7c41cdf75d8dd24f44f3b2d1eb57587"),
    Tag._(name: "0.0.4", commit: "38b6662cfe57e1e24f865b4ac23709e3e432a61a"),
    Tag._(name: "0.0.5", commit: "33fa570fef9ef2243cb105293e668d622785d75c"),
    Tag._(name: "0.0.6", commit: "64bcf42e6825365a235ca7bb26ae2f45ff345875"),
    Tag._(name: "0.0.7", commit: "34f2ba206d6980e36ca4200cc1e2bb81f0a09cad"),
    Tag._(name: "0.0.8", commit: "71b769101fe00ee91135feaa29bcaee09854197e"),
    Tag._(name: "0.1.0", commit: "86db04bf378d50fe66f929767a98f44fa3f9e5f1"),
  };

  /// All commits in the repository, ordered from oldest to newest.
  static final Set<Commit> commits = Set.unmodifiable({
    Commit._(
      "c1ed74ebd5953ca7cd2cae336465e8ba6b7bafe8",
      hashAbbreviated: "c1ed74e",
      message: "Initial commit",
      date: DateTime.fromMillisecondsSinceEpoch(
        1735264927000,
        isUtc: true,
      ), // 2024-12-27T02:02:07.000Z
      signed: true,
      author: "me@jhubi1.com",
      committer: "me@jhubi1.com",
    ),
    Commit._(
      "c9415e474684b460eb55f934c45348e97bf03b63",
      hashAbbreviated: "c9415e4",
      message: "Updated changelog, added GHA",
      date: DateTime.fromMillisecondsSinceEpoch(
        1735265093000,
        isUtc: true,
      ), // 2024-12-27T02:04:53.000Z
      signed: true,
      author: "me@jhubi1.com",
      committer: "me@jhubi1.com",
    ),
    Commit._(
      "1a6ed49e2258b7d7d444ec8d33862c34d6341d05",
      hashAbbreviated: "1a6ed49",
      message: "Various bug fixes and improvements",
      date: DateTime.fromMillisecondsSinceEpoch(
        1735309319000,
        isUtc: true,
      ), // 2024-12-27T14:21:59.000Z
      signed: true,
      author: "me@jhubi1.com",
      committer: "me@jhubi1.com",
    ),
    Commit._(
      "c8ea80bba981db8fdfab32df3d415ef49ff7be1e",
      hashAbbreviated: "c8ea80b",
      message: "Updated readme and added example",
      date: DateTime.fromMillisecondsSinceEpoch(
        1735309610000,
        isUtc: true,
      ), // 2024-12-27T14:26:50.000Z
      signed: true,
      author: "me@jhubi1.com",
      committer: "me@jhubi1.com",
    ),
    Commit._(
      "31431b8bc1b0049d343ef0c0faeaad09757a5e7e",
      hashAbbreviated: "31431b8",
      message: "Tweaks",
      date: DateTime.fromMillisecondsSinceEpoch(
        1735309934000,
        isUtc: true,
      ), // 2024-12-27T14:32:14.000Z
      signed: true,
      author: "me@jhubi1.com",
      committer: "me@jhubi1.com",
    ),
    Commit._(
      "35123038e89c6cd100febf021a1f4163bbe0c829",
      hashAbbreviated: "3512303",
      message: "Removed version dependency",
      date: DateTime.fromMillisecondsSinceEpoch(
        1735310063000,
        isUtc: true,
      ), // 2024-12-27T14:34:23.000Z
      signed: true,
      author: "me@jhubi1.com",
      committer: "me@jhubi1.com",
    ),
    Commit._(
      "586d7ac0a7c41cdf75d8dd24f44f3b2d1eb57587",
      hashAbbreviated: "586d7ac",
      message: "Support git encoding",
      date: DateTime.fromMillisecondsSinceEpoch(
        1735311357000,
        isUtc: true,
      ), // 2024-12-27T14:55:57.000Z
      signed: true,
      author: "me@jhubi1.com",
      committer: "me@jhubi1.com",
    ),
    Commit._(
      "38b6662cfe57e1e24f865b4ac23709e3e432a61a",
      hashAbbreviated: "38b6662",
      message: "Contributors and signed commits",
      date: DateTime.fromMillisecondsSinceEpoch(
        1736119504000,
        isUtc: true,
      ), // 2025-01-05T23:25:04.000Z
      signed: true,
      author: "me@jhubi1.com",
      committer: "me@jhubi1.com",
    ),
    Commit._(
      "239e300ab93800cb3a6cf8eb2477c8830bc558c8",
      hashAbbreviated: "239e300",
      message: "Added platform suggestion",
      date: DateTime.fromMillisecondsSinceEpoch(
        1736120007000,
        isUtc: true,
      ), // 2025-01-05T23:33:27.000Z
      signed: true,
      author: "me@jhubi1.com",
      committer: "me@jhubi1.com",
    ),
    Commit._(
      "c97517c4d4819db244fce8489841181778da8cb8",
      hashAbbreviated: "c97517c",
      message: "Update README.md",
      date: DateTime.fromMillisecondsSinceEpoch(
        1736729005000,
        isUtc: true,
      ), // 2025-01-13T00:43:25.000Z
      signed: true,
      author: "hudson.afonso@gmail.com",
      committer: "noreply@github.com",
    ),
    Commit._(
      "8728a580d22533955ca0fb7ab957aaf8da31b6d4",
      hashAbbreviated: "8728a58",
      message: "Merge pull request #1 from HudsonAfonso/patch-1",
      date: DateTime.fromMillisecondsSinceEpoch(
        1741101801000,
        isUtc: true,
      ), // 2025-03-04T15:23:21.000Z
      signed: true,
      author: "me@jhubi1.com",
      committer: "noreply@github.com",
    ),
    Commit._(
      "86357fa20a31fcabfdff00774cd78024824a7e56",
      hashAbbreviated: "86357fa",
      message: "Private constructors, formatting, better CLI",
      date: DateTime.fromMillisecondsSinceEpoch(
        1745015328000,
        isUtc: true,
      ), // 2025-04-18T22:28:48.000Z
      signed: true,
      author: "me@jhubi1.com",
      committer: "me@jhubi1.com",
    ),
    Commit._(
      "33fa570fef9ef2243cb105293e668d622785d75c",
      hashAbbreviated: "33fa570",
      message: "Updated version",
      date: DateTime.fromMillisecondsSinceEpoch(
        1745015362000,
        isUtc: true,
      ), // 2025-04-18T22:29:22.000Z
      signed: true,
      author: "me@jhubi1.com",
      committer: "me@jhubi1.com",
    ),
    Commit._(
      "7ab5685f0cbeeec29bb2b0a5523561408aa75cd0",
      hashAbbreviated: "7ab5685",
      message: "Encoding, final classes, no `intl` dependency",
      date: DateTime.fromMillisecondsSinceEpoch(
        1751190679000,
        isUtc: true,
      ), // 2025-06-29T09:51:19.000Z
      signed: true,
      author: "me@jhubi1.com",
      committer: "me@jhubi1.com",
    ),
    Commit._(
      "64bcf42e6825365a235ca7bb26ae2f45ff345875",
      hashAbbreviated: "64bcf42",
      message: "Typo",
      date: DateTime.fromMillisecondsSinceEpoch(
        1751190792000,
        isUtc: true,
      ), // 2025-06-29T09:53:12.000Z
      signed: true,
      author: "me@jhubi1.com",
      committer: "me@jhubi1.com",
    ),
    Commit._(
      "44337dcba6725482e5b0b449caa35d1d428da727",
      hashAbbreviated: "44337dc",
      message: "Escaping, global command, correct date, version",
      date: DateTime.fromMillisecondsSinceEpoch(
        1755096377000,
        isUtc: true,
      ), // 2025-08-13T14:46:17.000Z
      signed: true,
      author: "me@jhubi1.com",
      committer: "me@jhubi1.com",
    ),
    Commit._(
      "0137281f606832ee5567b5e5d938040ffe1144e9",
      hashAbbreviated: "0137281",
      message: "Update .gitignore",
      date: DateTime.fromMillisecondsSinceEpoch(
        1755096709000,
        isUtc: true,
      ), // 2025-08-13T14:51:49.000Z
      signed: true,
      author: "me@jhubi1.com",
      committer: "me@jhubi1.com",
    ),
    Commit._(
      "34f2ba206d6980e36ca4200cc1e2bb81f0a09cad",
      hashAbbreviated: "34f2ba2",
      message: "Delete gitbaker.g.dart",
      date: DateTime.fromMillisecondsSinceEpoch(
        1755096776000,
        isUtc: true,
      ), // 2025-08-13T14:52:56.000Z
      signed: true,
      author: "me@jhubi1.com",
      committer: "me@jhubi1.com",
    ),
    Commit._(
      "71b769101fe00ee91135feaa29bcaee09854197e",
      hashAbbreviated: "71b7691",
      message: "`hash` properties",
      date: DateTime.fromMillisecondsSinceEpoch(
        1755100733000,
        isUtc: true,
      ), // 2025-08-13T15:58:53.000Z
      signed: true,
      author: "me@jhubi1.com",
      committer: "me@jhubi1.com",
    ),
    Commit._(
      "b0c29dcfc83fa9a02b92214790ca8b5257bc1f97",
      hashAbbreviated: "b0c29dc",
      message: "Documentation, centralized commits, committers, …",
      date: DateTime.fromMillisecondsSinceEpoch(
        1756380811000,
        isUtc: true,
      ), // 2025-08-28T11:33:31.000Z
      signed: true,
      author: "me@jhubi1.com",
      committer: "me@jhubi1.com",
    ),
    Commit._(
      "86db04bf378d50fe66f929767a98f44fa3f9e5f1",
      hashAbbreviated: "86db04b",
      message: "Updated version",
      date: DateTime.fromMillisecondsSinceEpoch(
        1756380949000,
        isUtc: true,
      ), // 2025-08-28T11:35:49.000Z
      signed: true,
      author: "me@jhubi1.com",
      committer: "me@jhubi1.com",
    ),
    Commit._(
      "777235d62342f93d8e89f989e0884ab1cb65822d",
      hashAbbreviated: "777235d",
      message: "Create main.dart",
      date: DateTime.fromMillisecondsSinceEpoch(
        1756396943000,
        isUtc: true,
      ), // 2025-08-28T16:02:23.000Z
      signed: true,
      author: "me@jhubi1.com",
      committer: "me@jhubi1.com",
    ),
  });
}
