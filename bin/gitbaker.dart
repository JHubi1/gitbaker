import 'dart:math' as math;
import 'dart:convert';
import 'dart:io';

import 'package:cli_spin/cli_spin.dart';
import 'package:dart_style/dart_style.dart';
import 'package:yaml/yaml.dart';

import 'generated/pubspec.g.dart' as info;

CliSpin? spinner;
Map<String, dynamic> config = {
  "output": "lib/generated",
  "branches": [],
  "anonymize": false,
};
DateTime? start;

class AnsiEscape {
  String _value = "\x1B[0m";

  @override
  String toString() => _value;
  String format(String text) => "$_value$text$reset";

  AnsiEscape(Object value) {
    if (value is int) {
      _value = "\x1B[${value}m";
    } else if (value is List<int>) {
      _value = "\x1B[${value.join(";")}m";
    }
  }

  static AnsiEscape get reset => AnsiEscape(0);
  static AnsiEscape get bold => AnsiEscape(1);
  static AnsiEscape get faint => AnsiEscape(2);
  static AnsiEscape get italic => AnsiEscape(3);
  static AnsiEscape get underline => AnsiEscape(4);

  static AnsiEscape get red => AnsiEscape(91);
  static AnsiEscape get green => AnsiEscape(92);
  static AnsiEscape get yellow => AnsiEscape(93);
}

const s = "\x1E";
String escape(String text) => jsonEncode(text).replaceAll(r"$", r"\$");

class RunResult {
  final dynamic stdout;
  final dynamic stderr;

  RunResult(this.stdout, this.stderr);
}

Future<RunResult> run(String executable, List<String> arguments) async {
  final run = await Process.run(
    executable,
    arguments,
    stdoutEncoding: null,
    stderrEncoding: null,
  );
  return RunResult(
    utf8.decode(run.stdout as List<int>, allowMalformed: true),
    utf8.decode(run.stderr as List<int>, allowMalformed: true),
  );
}

void main(_) async {
  start = DateTime.now();
  spinner = CliSpin(text: "Acquainting workspace").start();

  try {
    run("git", ["--version"]);
  } catch (e) {
    spinner!.fail(
      "Git installation check failed. Is Git installed and in path?",
    );
    exit(1);
  }

  try {
    if ((await run("git", [
          "rev-parse",
          "--is-inside-work-tree",
        ])).stdout.toString().trim() !=
        "true") {
      throw Exception();
    }
  } catch (e) {
    spinner!.fail(
      "Could not find Git repository in tree. Is this a Git repository?",
    );
    exit(1);
  }

  final gitRoot = Directory(
    (await run("git", [
      "rev-parse",
      "--show-toplevel",
    ])).stdout.toString().trim(),
  );
  spinner!.success("Git version checked and repository found");

  spinner = CliSpin(text: "Loading configuration").start();
  var pubspecFile = File("${gitRoot.path}/pubspec.yaml");
  Map? pubspec;

  if (pubspecFile.existsSync()) {
    spinner!.success(
      "Using config from pubspec.yaml in Git root ${AnsiEscape.faint.format("(${pubspecFile.path})")}",
    );
    Directory.current = pubspecFile.parent;
    pubspec = loadYaml(pubspecFile.readAsStringSync());
  } else {
    pubspecFile = File("pubspec.yaml");
    if (pubspecFile.existsSync()) {
      spinner!.success(
        "Using config from pubspec.yaml in working directory ${AnsiEscape.faint.format("(${pubspecFile.path})")}",
      );
      Directory.current = pubspecFile.parent;
      pubspec = loadYaml(pubspecFile.readAsStringSync());
    } else {
      spinner!.info("pubspec.yaml not found, skipping configuration loading");
    }
  }

  if (pubspec != null &&
      pubspec.containsKey("gitbaker") &&
      pubspec["gitbaker"] is Map) {
    for (var key in config.keys) {
      if (pubspec["gitbaker"].containsKey(key)) {
        Object? value;
        final configValue = config[key];
        if (configValue is String) {
          value = pubspec["gitbaker"][key].toString();
        } else if (configValue is int) {
          final pubspecValue = pubspec["gitbaker"][key];
          if (pubspecValue is int) {
            value = pubspecValue;
          } else if (pubspecValue is String) {
            value = int.tryParse(pubspecValue);
          }
        } else if (configValue is bool) {
          final pubspecValue = pubspec["gitbaker"][key];
          if (pubspecValue is bool) {
            value = pubspecValue;
          } else if (pubspecValue is String) {
            value = bool.tryParse(pubspecValue, caseSensitive: false);
          }
        } else if (configValue is List) {
          final pubspecValue = pubspec["gitbaker"][key];
          if (pubspecValue is YamlList) {
            value = pubspecValue.toList();
          } else if (pubspecValue is String) {
            value = [pubspecValue];
          }
        }
        if (value == null) continue;
        config[key] = pubspec["gitbaker"][key];
      }
    }
  }

  spinner = CliSpin(text: "Locating output file").start();
  Directory outputDir = Directory(config["output"]);
  if (!outputDir.existsSync()) {
    if (pubspec == null) {
      spinner!.fail(
        "Unable to determine output directory with certainty, ${AnsiEscape.italic.format("panicked")}",
      );
      print(
        "This may be because:\n"
        " 1) You are not executing this command within a valid Dart project, or\n"
        " 2) There is no pubspec.yaml file in your project\n"
        "Please specify the output directory manually using the --output option or create a file called pubspec.yaml",
      );
      exit(1);
    }
    outputDir.createSync(recursive: true);
  }

  final outputFile = File("${outputDir.path}/gitbaker.g.dart");
  final outputFileExisted = outputFile.existsSync();
  final outputFileOldContent =
      outputFileExisted ? outputFile.readAsStringSync() : null;
  final write = outputFile.openSync(mode: FileMode.write);
  write.lockSync(FileLock.blockingExclusive);
  spinner!.success(
    "Output file located at ${outputFile.absolute.path.replaceAll("\\", "/")}",
  );

  spinner = CliSpin(text: "Generating GitBaker file").start();
  String content = "";

  void out([String? object = ""]) {
    content += "${object ?? ""}\n";
  }

  try {
    out("""// GitBaker v${info.version} <https://pub.dev/packages/gitbaker>

// This is an automatically generated file by GitBaker. Do not modify manually.
// To regenerate this file, please rerun the command 'dart run gitbaker'

/// Generated Git history and metadata for the current Git repository.
/// 
/// See <https://pub.dev/packages/gitbaker> for more information. To update or
/// regenerate this file, run `dart run gitbaker` somewhere in this repository.
/// 
/// Last generated: ${DateTime.now().toIso8601String().split(".").first}
library;""");

    out("enum RemoteType { fetch, push, unknown }");
    out("""
/// A class representing a remote repository or connection.
final class Remote {
  final String name;
  final RemoteType type;
  final Uri uri;

  const Remote._({required this.name, required this.type, required this.uri});

  Map<String, Object?> toJson() => {
    "name": name,
    "type": type.name,
    "uri": uri.toString(),
  };
}""");
    out("""
/// A class representing a contributor to the repository.
/// 
/// Each user is uniquely identified by their email address. Multiple users
/// may share the same name, but not the same email.
final class User {
  final String name;
  final String email;

  const User._({required this.name, required this.email});

  List<Commit> get contributions => List.unmodifiable(GitBaker.commits.where((c) => c.author == this).toList());

  Map<String, Object?> toJson() => {
    "name": name,
    "email": email,
  };
}""");
    out("""
/// A class representing a Git branch.
final class Branch {
  final String name;

  /// The number of commits in this branch, following only the first parent.
  /// 
  /// This value can be used to determine the relative age of branches, but
  /// should not be used to determine the absolute number of commits. For that,
  /// use [commits].length instead.
  final int revision;

  final int ahead;
  final int behind;

  final List<String> _commits;
  List<Commit> get commits => List.unmodifiable(_commits.map((h) => GitBaker.commits.singleWhere((c) => c.hash == h)).toList());

  bool get isCurrent => this == GitBaker.currentBranch;
  bool get isDefault => this == GitBaker.defaultBranch;

  const Branch._({required this.name, required this.revision, required this.ahead, required this.behind, required List<String> commits}) : _commits = commits;

  Map<String, Object?> toJson() => {
    "name": name,
    "revision": revision,
    "commits": _commits.toList(),
  };
}""");
    out("""
/// A class representing a Git tag.
/// 
/// You may use the [commit] property's message as a description of the tag
/// next to its name.
final class Tag {
  final String name;

  final String _commit;
  Commit get commit => GitBaker.commits.singleWhere((c) => c.hash == _commit);

  const Tag._({required this.name, required String commit}) : _commit = commit;

  Map<String, Object?> toJson() => {
    "name": name,
    "commit": _commit,
  };
}""");
    out("""
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
  List<Branch> get presentIn => List.unmodifiable(GitBaker.branches.where((b) => b.commits.contains(this)).toList());

  final String _author;
  User get author => GitBaker.members.singleWhere((e) => e.email == _author);

  final String _committer;
  User get committer => GitBaker.members.singleWhere((e) => e.email == _committer);

  const Commit._(this.hash, {required this.hashAbbreviated, required this.message, required this.date, required this.signed, required String author, required String committer}) : _author = author, _committer = committer;

  @override
  bool operator ==(Object other) => identical(this, other) || (other is Commit && other.hash == hash);
  @override
  int get hashCode => hash.hashCode;

  Map<String, Object?> toJson() => {
    "hash": hash,
    "hashAbbreviated": hashAbbreviated,
    "message": message,
    "date": date.toIso8601String(),
    "signed": signed,
    "author": _author,
    "committer": _committer,
  };
}""");

    out("""
/// Represents the status of a working tree entry.
enum WorkspaceEntryStatusPart {
  unmodified,
  modified("M"),
  fileTypeChanged("T"),
  added("A"),
  deleted("D"),
  renamed("R"),
  copied("C"),
  updatedButUnmerged("U");

  final String letter;
  const WorkspaceEntryStatusPart([this.letter = "."]);

  factory WorkspaceEntryStatusPart._fromLetter(String letter) {
    return WorkspaceEntryStatusPart.values.firstWhere(
      (e) => e.letter == letter,
      orElse: () => WorkspaceEntryStatusPart.unmodified,
    );
  }
}""");
    out("""
/// Represents the combined status of a working tree entry.
/// 
/// A status is always a combination of two [WorkspaceEntryStatusPart]s, one
/// for the index status (X) and one for the working tree status (Y).
/// 
/// https://git-scm.com/docs/git-status#_output
final class WorkspaceEntryStatus {
  /// The status of the entry in the index.
  /// 
  /// The index is the staging area, where changes are prepared for the next
  /// commit. Meaning that if this has a value, there are changes to this file
  /// that are not yet committed, but already staged.
  final WorkspaceEntryStatusPart x;

  /// The status of the entry in the working tree.
  /// 
  /// The working tree is the current state of the files in the repository.
  /// Meaning that if this has a value, there are changes to this file that are
  /// not yet committed, and not yet staged.
  final WorkspaceEntryStatusPart y;

  WorkspaceEntryStatus._fromLetters(String x, String y) : x = WorkspaceEntryStatusPart._fromLetter(x), y = WorkspaceEntryStatusPart._fromLetter(y);

  Map<String, Object?> toJson() => {
    "x": x.name,
    "y": y.name,
  };
}""");
    out("""
/// Represents the state of a submodule in the working tree.
final class WorkspaceEntrySubmoduleState {
  final bool commitChanged;
  final bool hasTrackedChanges;
  final bool hasUntrackedChanges;

  const WorkspaceEntrySubmoduleState._({required this.commitChanged, required this.hasTrackedChanges, required this.hasUntrackedChanges});

  Map<String, Object?> toJson() => {
    "commitChanged": commitChanged,
    "hasTrackedChanges": hasTrackedChanges,
    "hasUntrackedChanges": hasUntrackedChanges,
  };
}""");
    out("""
/// A class representing a single entry in the working tree of the repository.
/// 
/// You may use the subclasses to determine the type of entry:
/// - [WorkspaceEntryChange] for changed entries
/// - [WorkspaceEntryRenameCopy] for renamed or copied entries
/// - [WorkspaceEntryUntracked] for untracked entries
/// - [WorkspaceEntryIgnored] for ignored entries
/// 
/// https://git-scm.com/docs/git-status#_porcelain_format_version_2
abstract final class WorkspaceEntry {
  /// Path relative to the repository root of this entry.
  final String path;

  final bool _isUntracked;
  final bool _isIgnored;
  const WorkspaceEntry._(this.path) : _isUntracked = false, _isIgnored = false;
  const WorkspaceEntry._untracked(this.path) : _isUntracked = true, _isIgnored = false;
  const WorkspaceEntry._ignored(this.path) : _isUntracked = false, _isIgnored = true;

  @override
  bool operator ==(Object other) => identical(this, other) || (other is WorkspaceEntry && other.path == path && other._isUntracked == _isUntracked && other._isIgnored == _isIgnored);
  @override
  int get hashCode => Object.hash(path, _isUntracked, _isIgnored);

  Map<String, Object?> toJson() => {
    "type": _isUntracked ? "untracked" : (_isIgnored ? "ignored" : throw UnimplementedError()),
    "path": path,
  };
}

/// A class representing a changed entry in the working tree.
final class WorkspaceEntryChange extends WorkspaceEntry {
  final WorkspaceEntryStatus status;
  final WorkspaceEntrySubmoduleState submoduleState;

  const WorkspaceEntryChange._(super.path, {required this.status, required this.submoduleState}) : super._();

  @override
  bool operator ==(Object other) => identical(this, other) || (other is WorkspaceEntryChange && other.path == path && other.status == status && other.submoduleState == submoduleState);
  @override
  int get hashCode => Object.hash(path, status, submoduleState);

  @override
  Map<String, Object?> toJson() => {
    "type": "change",
    "path": path,
    "status": status.toJson(),
    "submoduleState": submoduleState.toJson(),
  };
}

/// A class representing a renamed or copied entry in the working tree.
final class WorkspaceEntryRenameCopy extends WorkspaceEntryChange {
  final double score;
  final String oldPath;

  const WorkspaceEntryRenameCopy._(super.path, {required super.status, required super.submoduleState, required this.score, required this.oldPath}) : super._();

  @override
  bool operator ==(Object other) => identical(this, other) || (other is WorkspaceEntryRenameCopy && other.path == path && other.score == score && other.oldPath == oldPath);
  @override
  int get hashCode => Object.hash(path, score, oldPath);

  @override
  Map<String, Object?> toJson() => {
    "type": "rename/copy",
    "path": path,
    "status": status.toJson(),
    "submoduleState": submoduleState.toJson(),
    "score": score,
    "oldPath": oldPath,
  };
}

/// A class representing an untracked entry in the working tree.
final class WorkspaceEntryUntracked extends WorkspaceEntry {
  const WorkspaceEntryUntracked._(super.path) : super._untracked();
}

/// A class representing an ignored entry in the working tree.
final class WorkspaceEntryIgnored extends WorkspaceEntry {
  const WorkspaceEntryIgnored._(super.path) : super._ignored();
}""");

    out("""
final class GitBaker {
GitBaker._();
""");

    final descriptionFile = File("${gitRoot.path}/.git/description");
    var description =
        descriptionFile.existsSync()
            ? descriptionFile.readAsStringSync().trim()
            : null;
    if (description ==
        "Unnamed repository; edit this file 'description' to name the repository.") {
      description = null;
    }
    out(
      """
  // possibility of null if no description is set
  // ignore: unnecessary_nullable_for_final_variable_declarations
static const String? description = ${description == null ? "null" : escape(description)};""",
    );

    out(
      """
  /// The most likely remote to be used for fetching and pushing.
  /// 
  /// This is determined by first looking for a remote named "origin" with type
  /// [RemoteType.fetch]. If no such remote exists, the first remote with type
  /// [RemoteType.fetch] is used, regardless of its name. If no such remote
  /// exists, the first remote in [remotes] is used.
static Remote get remote => remotes.firstWhere((r) => r.name == "origin" && r.type == RemoteType.fetch, orElse: () => remotes.firstWhere((r) => r.type == RemoteType.fetch, orElse: () => remotes.first));""",
    );
    out("""
  /// All remotes configured for this repository.
  /// 
  /// This includes remotes for fetching and pushing, as well as any other types
  /// of remotes that may be configured.
  /// 
  /// Note that multiple remotes may have the same [name] and [uri], but
  /// different [type]s. For example, a remote may be configured for both
  /// fetching and pushing.
static final List<Remote> remotes = List.unmodifiable([""");
    for (var remote in (await run("git", [
      "remote",
      "-v",
    ])).stdout.toString().split("\n").where((e) => e.isNotEmpty)) {
      var parts =
          remote
              .replaceAll(RegExp(r'\s+'), " ")
              .split(" ")
              .map((e) => e.trim())
              .toList();
      parts[2] =
          (parts[2] == "(fetch)")
              ? "RemoteType.fetch"
              : (parts[2] == "(push)")
              ? "RemoteType.push"
              : "RemoteType.unknown";
      out(
        "Remote._(name: ${escape(parts[0])}, type: ${parts[2]}, uri: Uri.parse(${escape(parts[1])})),",
      );
    }
    out("]);");

    out("""
  /// All members to this repository.
  /// 
  /// Each user is uniquely identified by their email address. Multiple users
  /// may share the same name, but not the same email.
static const List<User> members = [""");
    if (config["anonymize"] == true) {
      out(
        "User._(name: ${escape("Anonymous")}, email: ${escape("anonymous@example.com")}),",
      );
    } else {
      for (var commit
          in <String>{}
            ..addAll(
              (await run("git", [
                "log",
                "--pretty=format:%an$s%ae",
                "--all",
              ])).stdout.toString().split("\n").where((e) => e.isNotEmpty),
            )
            ..addAll(
              (await run("git", [
                "log",
                "--pretty=format:%cn$s%ce",
                "--all",
              ])).stdout.toString().split("\n").where((e) => e.isNotEmpty),
            )) {
        final parts = commit.split(s).map((e) => e.trim()).toList();
        out("User._(name: ${escape(parts[0])}, email: ${escape(parts[1])}),");
      }
    }
    out("];");

    final defaultBranch = ((await run("git", [
        "rev-parse",
        "--abbrev-ref",
        "origin/HEAD",
      ])).stdout.toString().trim().split("/")
      ..removeWhere((e) => e == "origin")).join("/");
    out(
      """
  /// The default branch of the repository, usually "main" or "master".
static final Branch defaultBranch = branches.singleWhere((e) => e.name == ${escape(defaultBranch)});""",
    );

    final currentBranch = ((await run("git", [
        "rev-parse",
        "--abbrev-ref",
        "HEAD",
      ])).stdout.toString().trim().split("/")
      ..removeWhere((e) => e == "origin")).join("/");
    out(
      """
  /// The currently checked out branch of the repository.
static final Branch currentBranch = branches.singleWhere((e) => e.name == ${escape(currentBranch)});""",
    );

    out("""
/// List of uncommitted changes in the working tree of the repository.
static final List<WorkspaceEntry> workspace = List.unmodifiable([""");
    for (var entry in (await run("git", [
      "status",
      "--porcelain=2",
    ])).stdout.toString().split("\n").where((e) => e.trim().isNotEmpty)) {
      switch (entry[0]) {
        case "1":
          final match = RegExp(
            r"^1 (?<XY>[ \.MTADRCU]{2}) (?<sub>(?:N\.\.\.|S[\.C][\.M][\.U])) (?:[^ ]* ){5}(?<path>.*)$",
          ).firstMatch(entry);
          if (match == null) continue;
          final x = match.namedGroup("XY")![0];
          final y = match.namedGroup("XY")![1];
          final sub =
              match.namedGroup("sub")!.startsWith("S")
                  ? match.namedGroup("sub")!
                  : null;
          final path = match.namedGroup("path")!;
          out(
            "WorkspaceEntryChange._(${escape(path)}, "
            "status: WorkspaceEntryStatus._fromLetters(${escape(x)}, ${escape(y)}), "
            "submoduleState: WorkspaceEntrySubmoduleState._(commitChanged: ${sub != null && sub[1] == "C"}, hasTrackedChanges: ${sub != null && sub[2] == "M"}, hasUntrackedChanges: ${sub != null && sub[3] == "U"})),",
          );
        case "2":
          final match = RegExp(
            r"^2 (?<XY>[ \.MTADRCU]{2}) (?<sub>(?:N\.\.\.|S[\.C][\.M][\.U])) (?:[^ ]* ){5}(?<score>[RC][0-9]+?) (?<path>.*?)" +
                RegExp.escape("\u{09}") +
                r"(?<oldPath>.*)$",
          ).firstMatch(entry);
          if (match == null) continue;
          final x = match.namedGroup("XY")![0];
          final y = match.namedGroup("XY")![1];
          final sub =
              match.namedGroup("sub")!.startsWith("S")
                  ? match.namedGroup("sub")!
                  : null;
          final score =
              math.min(
                math.max(
                  int.tryParse(match.namedGroup("score")!.substring(1)) ?? 0,
                  0,
                ),
                100,
              ) /
              100;
          final path = match.namedGroup("path")!;
          final oldPath = match.namedGroup("oldPath")!;
          out(
            "WorkspaceEntryRenameCopy._(${escape(path)}, "
            "status: WorkspaceEntryStatus._fromLetters(${escape(x)}, ${escape(y)}), "
            "submoduleState: WorkspaceEntrySubmoduleState._(commitChanged: ${sub != null && sub[1] == "C"}, hasTrackedChanges: ${sub != null && sub[2] == "M"}, hasUntrackedChanges: ${sub != null && sub[3] == "U"}), "
            "score: $score, "
            "oldPath: ${escape(oldPath)}),",
          );
        case "u":
          // unimplemented
          break;
        case "?" || "!":
          final isIgnored = entry[0] == "!";
          out(
            "${isIgnored ? "WorkspaceEntryIgnored" : "WorkspaceEntryUntracked"}._(${escape(entry.substring(2).trim())}),",
          );
      }
    }
    out("]);");

    List<RegExp> regex = [];
    for (var r in config["branches"]) {
      try {
        regex.add(RegExp(r, caseSensitive: false));
      } catch (_) {}
    }

    out("""
  /// All branches in the repository.
  /// 
  /// If the configuration sets the list `branches`, only branches matching any
  /// of the provided regular expressions are included. If it is empty or not
  /// set, all branches are included.
static const List<Branch> branches = [""");
    for (var branch
        in (await run("git", ["branch", "--list"])).stdout
            .toString()
            .split("\n")
            .where((e) => e.trim().isNotEmpty)
            .map((e) => e.trim().substring(2))
            .toList()
          ..sort()) {
      if (![defaultBranch, currentBranch].contains(branch) &&
          !regex.any((e) => e.hasMatch(branch))) {
        continue;
      }
      final revision =
          int.tryParse(
            (await run("git", [
              "rev-list",
              "--count",
              "--first-parent",
              branch,
            ])).stdout.toString().trim(),
          ) ??
          0;

      final aheadBehind =
          RegExp(r"\[(.*?)\]")
              .firstMatch(
                (await run("git", [
                  "branch",
                  "--list",
                  "-vv",
                  branch,
                ])).stdout.toString(),
              )!
              .group(1)!
              .split(":")
              .elementAtOrNull(1)
              ?.trim()
              .split(",")
              .map((e) => e.trim())
              .toList();
      final ahead =
          int.tryParse(
            aheadBehind
                    ?.firstWhere(
                      (e) => e.startsWith("ahead"),
                      orElse: () => "ahead 0",
                    )
                    .substring(6) ??
                "",
          ) ??
          0;
      final behind =
          int.tryParse(
            aheadBehind
                    ?.firstWhere(
                      (e) => e.startsWith("behind"),
                      orElse: () => "behind 0",
                    )
                    .substring(7) ??
                "",
          ) ??
          0;

      out(
        "Branch._(name: ${escape(branch)}, revision: $revision, ahead: $ahead, behind: $behind, commits: [",
      );
      for (var commit
          in (await run("git", ["rev-list", branch])).stdout
              .toString()
              .split("\n")
              .reversed
              .where((element) => element.isNotEmpty)
              .toList()) {
        out("${escape(commit)},");
      }
      out("])");
    }
    out("];");

    out("""
  /// All tags in the repository.
  /// 
  /// [Tag.commit.message] may be used as a description of a tag.
  /// 
  /// Note that this won't get the release notes of Git hosting services like
  /// GitHub or GitLab, but only the tag name.
static const List<Tag> tags = [""");
    for (var tag in (await run("git", [
      "tag",
      "-ln9",
    ])).stdout.toString().split("\n").where((e) => e.isNotEmpty)) {
      final parts = tag.split(" ")..removeWhere((e) => e.trim().isEmpty);
      out(
        "Tag._(name: ${escape(parts[0])}, commit: ${escape((await run("git", ["rev-parse", parts[0]])).stdout.toString().trim())}),",
      );
    }
    out("];");

    out("""
  /// All commits in the repository, ordered from oldest to newest.
static final List<Commit> commits = List.unmodifiable([""");
    for (var commit in (await run("git", [
      "log",
      "--reflog",
      "--pretty=format:%H$s%h$s%s$s%ae$s%at$s%ce$s%ct$s%G?",
    ])).stdout.toString().split("\n").reversed.where((e) => e.isNotEmpty)) {
      final parts = commit.split(s).map((e) => e.trim()).toList();
      final date = DateTime.fromMillisecondsSinceEpoch(
        (int.tryParse(parts[6]) ?? 0) * 1000,
        isUtc: true,
      );
      final authorEmail =
          config["anonymize"] == true ? "anonymous@example.com" : parts[3];
      final committerEmail =
          config["anonymize"] == true ? "anonymous@example.com" : parts[5];
      out(
        "Commit._(${escape(parts[0])}, hashAbbreviated: ${escape(parts[1])}, message: ${escape(parts[2])}, date: DateTime.parse(${escape(date.toIso8601String())}), signed: ${["G", "U", "E"].contains(parts[7])}, author: ${escape(authorEmail)}, committer: ${escape(committerEmail)}),",
      );
    }
    out("]);");

    out("""

static Map<String, Object?> toJson() => {
  "description": description,
  "remote": remote.toJson(),
  "remotes": remotes.map((r) => r.toJson()).toList(),
  "members": members.map((m) => m.toJson()).toList(),
  "defaultBranch": defaultBranch.name,
  "currentBranch": currentBranch.name,
  "workspace": workspace.map((e) => e.toJson()).toList(),
  "branches": branches.map((b) => b.toJson()).toList(),
  "tags": tags.map((t) => t.toJson()).toList(),
  "commits": commits.map((c) => c.toJson()).toList(),
};""");

    out("}");

    await write.writeString(
      await (() async => DartFormatter(
        languageVersion: DartFormatter.latestLanguageVersion,
      ).format(content))(),
    );
    await write.close();

    spinner!.stopAndPersist(
      symbol: AnsiEscape.green.format("\u{2192}"),
      text:
          "Finished generating GitBaker file in ${DateTime.now().difference(start!).inMilliseconds}ms",
    );
  } catch (e, s) {
    spinner?.fail();
    final spacer = "${AnsiEscape.faint}|${AnsiEscape.reset}";

    if (outputFileExisted && outputFileOldContent != null) {
      await write.writeString(outputFileOldContent);
      write.closeSync();
    } else {
      write.closeSync();
      outputFile.deleteSync();
    }

    print(
      AnsiEscape.red.format(
        "\u{26A0} Error occurred during GitBaker generation. ${outputFileExisted ? "The original file content was not modified." : "The file was not created."}",
      ),
    );
    print("$spacer ${e.toString().replaceAll("\n", "\n$spacer ")}");
    print("$spacer ${s.toString().trim().replaceAll("\n", "\n$spacer ")}");
  }
}
