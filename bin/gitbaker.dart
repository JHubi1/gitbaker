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

class RunResult {
  final dynamic stdout;
  final dynamic stderr;

  RunResult(this.stdout, this.stderr);
}

String escape(String text) {
  return jsonEncode(text).replaceAll(r"$", r"\$");
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

// ignore_for_file: unnecessary_nullable_for_final_variable_declarations

library;""");

    out("\nenum RemoteType { fetch, push, unknown }");
    out(
      "\nfinal class Remote {\nfinal String name;\nfinal Uri url;\nfinal RemoteType type;\n\nRemote._({required this.name, required this.url, required this.type});\n}",
    );
    out(
      "\nfinal class User {\nfinal String name;\nfinal String email;\n\nUser._({required this.name, required this.email});\n}",
    );
    out(
      "\nfinal class Commit {\nfinal String hash;\nfinal String message;\nfinal DateTime date;\n\n/// Whether the commit has been signed.\n/// Careful: not whether the signature is valid!\nfinal bool signed;\n\nfinal String _branch;\nBranch get branch => GitBaker.branches.singleWhere((e) => e.name == _branch);\n\nfinal String _author;\nUser get author => GitBaker.contributors.singleWhere((e) => e.email == _author);\n\nCommit._(this.hash, {required this.message, required this.date, required this.signed, required String branch, required String author}) : _branch = branch, _author = author;\n}",
    );
    out(
      "\nfinal class Branch {\nfinal String hash;\nfinal String name;\nfinal List<Commit> commits;\n\nbool get isCurrent => this == GitBaker.currentBranch;\nbool get isDefault => this == GitBaker.defaultBranch;\n\nBranch._(this.hash, {required this.name, required this.commits});\n}",
    );
    out(
      "\nfinal class Tag {\nfinal String hash;\nfinal String name;\nfinal String description;\n\nTag._(this.hash, {required this.name, required this.description});\n}",
    );

    out("\nfinal class GitBaker {");

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
      "static final String? description = ${description == null ? "null" : escape(description)};",
    );

    out(
      "\nstatic Remote get remote => remotes.firstWhere((r) => r.name == 'origin' && r.type == RemoteType.fetch, orElse: () => remotes.firstWhere((r) => r.type == RemoteType.fetch, orElse: () => remotes.first));",
    );
    out("static final Set<Remote> remotes = {");
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
        "Remote._(name: ${escape(parts[0])}, url: Uri.parse(${escape(parts[1])}), type: ${parts[2]}),",
      );
    }
    out("};");

    out("\nstatic final Set<User> contributors = {");
    for (var commit
        in (await run("git", ["log", "--pretty=format:%an|%ae", "--all"]))
            .stdout
            .toString()
            .split("\n")
            .where((e) => e.isNotEmpty)
            .toSet()
            .toList()) {
      final parts = commit.split("|").map((e) => e.trim()).toList();
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
      "\nstatic final Branch defaultBranch = branches.singleWhere((e) => e.name == ${escape(defaultBranch)});",
    );

    final currentBranch = ((await run("git", [
        "rev-parse",
        "--abbrev-ref",
        "HEAD",
      ])).stdout.toString().trim().split("/")
      ..removeWhere((e) => e == "origin")).join("/");
    out(
      "static final Branch currentBranch = branches.singleWhere((e) => e.name == ${escape(currentBranch)});",
    );

    List<RegExp> regex = [];
    for (var r in config["branches"]) {
      try {
        regex.add(RegExp(r, caseSensitive: false));
      } catch (_) {}
    }

    out("\nstatic final Set<Branch> branches = {");
    for (var branch in (await run("git", [
      "branch",
      "--list",
    ])).stdout.toString().split("\n").where((e) => e.isNotEmpty)) {
      final branchName = branch.substring(2);
      if (![defaultBranch, currentBranch].contains(branchName) &&
          !regex.any((e) => e.hasMatch(branchName))) {
        continue;
      }

      out(
        "Branch._(${escape((await run("git", ["rev-parse", branchName])).stdout.toString().trim())}, name: ${escape(branchName)}, commits: [",
      );
      for (var commit
          in (await run("git", [
                "log",
                "--pretty=format:%H|%s|%ae|%at",
                branchName,
              ])).stdout
              .toString()
              .split("\n")
              .reversed
              .where((element) => element.isNotEmpty)
              .toList()) {
        final parts = commit.split("|").map((e) => e.trim()).toList();
        final date = DateTime.fromMillisecondsSinceEpoch(
          (int.tryParse(parts[3]) ?? 0) * 1000,
          isUtc: true,
        );
        out(
          "Commit._(${escape(parts[0])}, message: ${escape(parts[1])}, date: DateTime.fromMillisecondsSinceEpoch(${date.millisecondsSinceEpoch}, isUtc: true), // ${date.toIso8601String()}\nsigned: ${(await run("git", ["verify-commit", parts[0]])).stderr.toString().trim().isEmpty ? "false" : "true"}, branch: ${escape(branchName)}, author: ${escape(parts[2])}),",
        );
      }
      out("]),");
    }
    out("};");

    out("\nstatic final Set<Tag> tags = {");
    for (var tag in (await run("git", [
      "tag",
      "-ln9",
    ])).stdout.toString().split("\n").where((e) => e.isNotEmpty)) {
      final parts = tag.split(" ")..removeWhere((e) => e.trim().isEmpty);
      out(
        "Tag._(${escape((await run("git", ["rev-parse", parts[0]])).stdout.toString().trim())}, name: ${escape(parts[0])}, description: ${escape((parts..removeAt(0)).join(" "))}),",
      );
    }
    out("};");

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

    print(
      AnsiEscape.red.format(
        "\u{26A0} Error occurred during GitBaker generation. ${outputFileExisted ? "The original file content was not modified." : "The file was not created."}",
      ),
    );
    print("$spacer ${e.toString().replaceAll("\n", "\n$spacer ")}");
    print("$spacer ${s.toString().trim().replaceAll("\n", "\n$spacer ")}");
  }
}
