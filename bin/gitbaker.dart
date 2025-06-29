import 'dart:convert';
import 'dart:io';

import 'package:cli_spin/cli_spin.dart';
import 'package:dart_style/dart_style.dart';
import 'package:yaml/yaml.dart';

import 'generated/pubspec.g.dart' as info;

CliSpin? spinner;
Map<String, dynamic> config = {"output": "lib/generated"};
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
  return text
      .replaceAll('"', '\\"')
      .replaceAll("\n", "\\n")
      .replaceAll("\r", "\\r")
      .replaceAll("\$", "\\\$")
      .replaceAll("\t", "\\t");
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

  var gitRoot = Directory(
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

  if (pubspec != null && pubspec.containsKey("gitbaker")) {
    for (var key in config.keys) {
      if (pubspec["gitbaker"].containsKey(key)) {
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

  var outputFile = File("${outputDir.path}/gitbaker.g.dart");
  var outputFileExisted = outputFile.existsSync();
  var write = outputFile.openSync(mode: FileMode.write);
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

    out("\nenum RemoteType { fetch, push }");
    out(
      "\nfinal class Remote {\n\tfinal String name;\n\tfinal Uri url;\n\tfinal RemoteType type;\n\n\tRemote._({required this.name, required this.url, required this.type});\n}",
    );
    out(
      "\nfinal class User {\n\tfinal String name;\n\tfinal String email;\n\n\tUser._({required this.name, required this.email});\n}",
    );
    out(
      "\nfinal class Commit {\n\tfinal String hash;\n\tfinal String message;\n\tfinal DateTime date;\n\n\t/// Whether the commit has been signed.\n\t/// Careful: not whether the signature is valid!\n\tfinal bool signed;\n\n\tfinal String _branch;\n\tBranch get branch => GitBaker.branches.singleWhere((e) => e.name == _branch);\n\n\tfinal String _author;\n\tUser get author => GitBaker.contributors.singleWhere((e) => e.email == _author);\n\n\tCommit._(this.hash, {required this.message, required this.date, required this.signed, required String branch, required String author}) : _branch = branch, _author = author;\n}",
    );
    out(
      "\nfinal class Branch {\n\tfinal String hash;\n\tfinal String name;\n\tfinal List<Commit> commits;\n\n\tbool get isCurrent => this == GitBaker.currentBranch;\n\tbool get isDefault => this == GitBaker.defaultBranch;\n\n\tBranch._(this.hash, {required this.name, required this.commits});\n}",
    );
    out(
      "\nfinal class Tag {\n\tfinal String hash;\n\tfinal String name;\n\tfinal String description;\n\n\tTag._(this.hash, {required this.name, required this.description});\n}",
    );

    out("\nfinal class GitBaker {");

    var descriptionFile = File("${gitRoot.path}/.git/description");
    var description =
        descriptionFile.existsSync()
            ? escape(descriptionFile.readAsStringSync().trim())
            : null;
    if (description ==
        "Unnamed repository; edit this file 'description' to name the repository.") {
      description = null;
    }
    out(
      "\tstatic final String? description = ${description == null ? "null" : "r\"$description\""};",
    );

    out("\n\tstatic final Set<Remote> remotes = {");
    for (var remote in (await run("git", [
      "remote",
      "-v",
    ])).stdout.toString().split("\n").where((e) => e.isNotEmpty)) {
      var parts =
          remote
              .replaceAll(RegExp(r'\s+'), " ")
              .split(" ")
              .map((e) => e.trim().replaceAll('"', '\\"'))
              .toList();
      parts[2] = parts[2] == "(fetch)" ? "RemoteType.fetch" : "RemoteType.push";
      out(
        "\t\tRemote._(name: r\"${parts[0]}\", url: Uri.parse(r\"${parts[1]}\"), type: ${parts[2]}),",
      );
    }
    out("\t};");

    out("\n\tstatic final Set<User> contributors = {");
    for (var commit
        in (await run("git", ["log", "--pretty=format:%an|%ae", "--all"]))
            .stdout
            .toString()
            .split("\n")
            .where((e) => e.isNotEmpty)
            .toSet()
            .toList()) {
      var parts = commit.split("|").map((e) => e.trim()).toList();
      out(
        "\t\tUser._(name: r\"${escape(parts[0])}\", email: r\"${parts[1]}\"),",
      );
    }
    out("\t};");

    out(
      "\n\tstatic final Branch defaultBranch = branches.singleWhere((e) => e.name == r\"${((await run("git", ["rev-parse", "--abbrev-ref", "origin/HEAD"])).stdout.toString().trim().split("/")..removeWhere((e) => e == "origin")).join("/")}\");",
    );
    out(
      "\tstatic final Branch currentBranch = branches.singleWhere((e) => e.name == r\"${((await run("git", ["rev-parse", "--abbrev-ref", "HEAD"])).stdout.toString().trim().split("/")..removeWhere((e) => e == "origin")).join("/")}\");",
    );

    out("\n\tstatic final Set<Branch> branches = {");
    for (var branch in (await run("git", [
      "branch",
      "--list",
    ])).stdout.toString().split("\n").where((e) => e.isNotEmpty)) {
      var branchName = branch.substring(2);
      out(
        "\t\tBranch._(r\"${(await run("git", ["rev-parse", branchName])).stdout.toString().trim()}\", name: r\"$branchName\", commits: [",
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
        var parts =
            commit
                .split("|")
                .map((e) => e.trim().replaceAll('"', '\\"'))
                .toList();
        var date = DateTime.fromMillisecondsSinceEpoch(
          (int.tryParse(parts[3]) ?? 0) * 1000,
          isUtc: true,
        );
        out(
          "\t\t\tCommit._(r\"${parts[0]}\", message: r\"${escape(parts[1])}\", date: DateTime.fromMillisecondsSinceEpoch(${date.millisecondsSinceEpoch}), // ${date.toIso8601String()}\nsigned: ${(await run("git", ["verify-commit", parts[0]])).stderr.toString().trim().isEmpty ? "false" : "true"}, branch: r\"${branchName.replaceAll('"', '\\"')}\", author: r\"${parts[2]}\"),",
        );
      }
      out("\t\t]),");
    }
    out("\t};");

    out("\n\tstatic final Set<Tag> tags = {");
    for (var tag in (await run("git", [
      "tag",
      "-ln9",
    ])).stdout.toString().split("\n").where((e) => e.isNotEmpty)) {
      var parts = tag.split(" ")..removeWhere((e) => e.trim().isEmpty);
      out(
        "\t\tTag._(r\"${(await run("git", ["rev-parse", parts[0]])).stdout.toString().trim()}\", name: r\"${parts[0]}\", description: r\"${escape((parts..removeAt(0)).join(" "))}\"),",
      );
    }
    out("\t};");

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
