import 'dart:convert';
import 'dart:io';

import 'package:cli_spin/cli_spin.dart';
import 'package:dart_style/dart_style.dart';
import 'package:yaml/yaml.dart';

import 'generated/pubspec.g.dart' as info;

CliSpin? spinner;
Map<String, dynamic> config = {"output": "lib/generated", "branches": []};
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
library;""");

    out("""
/// Represents the type of remote operation for a Git repository.
enum RemoteType { fetch, push, unknown }""");
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

  final Set<String> _commits;
  Set<Commit> get commits => _commits.map((h) => GitBaker.commits.singleWhere((c) => c.hash == h)).toSet();

  bool get isCurrent => this == GitBaker.currentBranch;
  bool get isDefault => this == GitBaker.defaultBranch;

  const Branch._({required this.name, required this.revision, required Set<String> commits}) : _commits = commits;

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
  Set<Branch> get presentIn => GitBaker.branches.where((b) => b.commits.contains(this)).toSet();

  final String _author;
  User get author => GitBaker.members.singleWhere((e) => e.email == _author);

  final String _committer;
  User get committer => GitBaker.members.singleWhere((e) => e.email == _committer);

  const Commit._(this.hash, {required this.hashAbbreviated, required this.message, required this.date, required this.signed, required String author, required String committer}) : _author = author, _committer = committer;

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
static final Set<Remote> remotes = Set.unmodifiable({""");
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
    out("});");

    out("""
  /// All members to this repository.
  /// 
  /// Each user is uniquely identified by their email address. Multiple users
  /// may share the same name, but not the same email.
static const Set<User> members = {""");
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
    out("};");

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
static const Set<Branch> branches = {""");
    for (var branch
        in (await run("git", ["branch", "--list"])).stdout
            .toString()
            .split("\n")
            .where((e) => e.isNotEmpty)
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

      out("Branch._(name: ${escape(branch)}, revision: $revision, commits: {");
      for (var commit
          in (await run("git", ["rev-list", branch])).stdout
              .toString()
              .split("\n")
              .reversed
              .where((element) => element.isNotEmpty)
              .toList()) {
        out("${escape(commit)},");
      }
      out("}),");
    }
    out("};");

    out("""
  /// All tags in the repository.
  /// 
  /// [Tag.commit.message] may be used as a description of a tag.
  /// 
  /// Note that this won't get the release notes of Git hosting services like
  /// GitHub or GitLab, but only the tag name.
static const Set<Tag> tags = {""");
    for (var tag in (await run("git", [
      "tag",
      "-ln9",
    ])).stdout.toString().split("\n").where((e) => e.isNotEmpty)) {
      final parts = tag.split(" ")..removeWhere((e) => e.trim().isEmpty);
      out(
        "Tag._(name: ${escape(parts[0])}, commit: ${escape((await run("git", ["rev-parse", parts[0]])).stdout.toString().trim())}),",
      );
    }
    out("};");

    out("""
  /// All commits in the repository, ordered from oldest to newest.
static final Set<Commit> commits = Set.unmodifiable({""");
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
      out(
        "Commit._(${escape(parts[0])}, hashAbbreviated: ${escape(parts[1])}, message: ${escape(parts[2])}, date: DateTime.parse(${escape(date.toIso8601String())}), signed: ${["G", "U", "E"].contains(parts[7])}, author: ${escape(parts[3])}, committer: ${escape(parts[5])}),",
      );
    }
    out("});");

    out("""

static Map<String, Object?> toJson() => {
  "description": description,
  "remote": remote.toJson(),
  "remotes": remotes.map((r) => r.toJson()).toList(),
  "members": members.map((m) => m.toJson()).toList(),
  "defaultBranch": defaultBranch.name,
  "currentBranch": currentBranch.name,
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
