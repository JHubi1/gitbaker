import 'dart:convert';
import 'dart:io';

import 'package:yaml/yaml.dart';
import 'generated/pubspec.g.dart' as info;
import 'package:intl/intl.dart';

Map<String, dynamic> config = {"output": "lib/generated"};

ProcessResult run(String executable, List<String> arguments) {
  return Process.runSync(executable, arguments,
      stdoutEncoding: Encoding.getByName("utf-8"),
      stderrEncoding: Encoding.getByName("utf-8"));
}

void main(List<String> arguments) {
  try {
    run("git", ["--version"]);
  } catch (e) {
    print(
        "Git check failed, it may not be installed. Please install Git and try again.");
    exit(1);
  }

  try {
    if (run("git", ["rev-parse", "--is-inside-work-tree"])
            .stdout
            .toString()
            .trim() !=
        "true") {
      throw Exception();
    }
  } catch (e) {
    print(
        "This is not a Git repository. Please run this command in a Git repository.");
    exit(1);
  }

  var gitRoot = Directory(
      run("git", ["rev-parse", "--show-toplevel"]).stdout.toString().trim());
  var pubspecFile = File("${gitRoot.path}/pubspec.yaml");
  Map? pubspec;

  if (pubspecFile.existsSync()) {
    print("Using pubspec.yaml in Git root directory.");
    Directory.current = pubspecFile.parent;
    pubspec = loadYaml(pubspecFile.readAsStringSync());
  } else {
    pubspecFile = File("pubspec.yaml");
    if (pubspecFile.existsSync()) {
      print(
          "pubspec.yaml not found in Git root directory, falling back to working directory.");
      pubspec = loadYaml(pubspecFile.readAsStringSync());
    }
    {
      print(
          "pubspec.yaml not found in Git root directory or working directory, skipped.");
    }
  }

  if (pubspec != null) {
    for (var key in config.keys) {
      if (pubspec.containsKey("gitbaker") &&
          pubspec["gitbaker"].containsKey(key)) {
        config[key] = pubspec["gitbaker"][key];
      }
    }
  }

  var outputDir = Directory(config["output"]);
  if (!outputDir.existsSync()) {
    if (pubspec == null) {
      print("Not able to determine output directory, panicked.");
      print(
          "Please create a directory named 'generated' in lib or specify the output directory in pubspec.yaml.");
      exit(1);
    }
    outputDir.createSync(recursive: true);
  }

  var outputFile = File("${outputDir.path}/gitbaker.g.dart");
  var output = outputFile.openWrite();

  void out([Object? object = ""]) {
    output.writeln(object);
  }

  out("""// GitBaker v${info.version} <https://pub.dev/packages/gitbaker>
      
// This is an automatically generated file by GitBaker. Do not modify manually.
// To regenerate this file, please rerun the command 'dart run gitbaker'

// ignore_for_file: unnecessary_nullable_for_final_variable_declarations""");

  out("\nenum RemoteType { fetch, push }\nclass Remote {\n\tfinal String name;\n\tfinal String url;\n\tfinal RemoteType type;\n\n\tRemote(this.name, this.url, this.type);\n}");
  out("\nclass Commit {\n\tfinal String hash;\n\tfinal String message;\n\tfinal String author;\n\tfinal DateTime date;\n\n\tfinal String _branch;\n\tBranch get branch => GitBaker.branches.where((e) => e.name == _branch).toList().first;\n\n\tCommit(this.hash, this.message, this.author, this.date, this._branch);\n}");
  out("\nclass Branch {\n\tfinal String hash;\n\tfinal String name;\n\tfinal List<Commit> commits;\n\n\tfinal String? _currentCommit;\n\tCommit? get currentCommit => (_currentCommit == null)\n\t\t\t? null\n\t\t\t: commits.where((e) => e.hash == _currentCommit).toList().first;\n\n\tBranch(this.hash, this.name, this.commits, this._currentCommit);\n}");
  out("\nclass Tag {\n\tfinal String hash;\n\tfinal String name;\n\n\tTag(this.hash, this.name);\n}");

  out("\nclass GitBaker {");

  var descriptionFile = File("${gitRoot.path}/.git/description");
  var description = descriptionFile.existsSync()
      ? descriptionFile.readAsStringSync().trim().replaceAll('"', '\\"')
      : null;
  if (description ==
      "Unnamed repository; edit this file 'description' to name the repository.") {
    description = null;
  }
  out("\tstatic final String? description = ${description ?? "null"};");

  out("\n\tstatic final List<Remote> remotes = [");
  for (var remote in run("git", ["remote", "-v"])
      .stdout
      .toString()
      .split("\n")
      .where((e) => e.isNotEmpty)) {
    var parts = remote
        .replaceAll(RegExp(r'\s+'), " ")
        .split(" ")
        .map((e) => e.trim().replaceAll('"', '\\"'))
        .toList();
    parts[2] = parts[2] == "(fetch)" ? "RemoteType.fetch" : "RemoteType.push";
    output
        .writeln("\t\tRemote(\"${parts[0]}\", \"${parts[1]}\", ${parts[2]}),");
  }
  out("\t];");

  out("\n\tstatic final Branch defaultBranch = branches.where((e) => e.name == \"${(run("git", [
        "rev-parse",
        "--abbrev-ref",
        "origin/HEAD"
      ]).stdout.toString().trim().split("/")..removeWhere((e) => e == "origin")).join("/")}\").first;");
  out("\tstatic final Branch currentBranch = branches.where((e) => e.name == \"${(run("git", [
        "rev-parse",
        "--abbrev-ref",
        "HEAD"
      ]).stdout.toString().trim().split("/")..removeWhere((e) => e == "origin")).join("/")}\").first;");

  out("\n\tstatic final List<Branch> branches = [");
  for (var branch in run("git", ["branch", "--list"])
      .stdout
      .toString()
      .split("\n")
      .where((e) => e.isNotEmpty)) {
    var branchName = branch.substring(2);
    out("\t\tBranch(\"${run("git", [
          "rev-parse",
          branchName
        ]).stdout.toString().trim()}\", \"$branchName\", [");
    for (var commit
        in run("git", ["log", "--pretty=format:%H|%s|%an|%ad", branchName])
            .stdout
            .toString()
            .split("\n")
            .reversed
            .where((element) => element.isNotEmpty)
            .toList()) {
      var parts = commit
          .split("|")
          .map((e) => e.trim().replaceAll('"', '\\"'))
          .toList();

      var calc = parts[3].split(" ").last.substring(1);
      var sign = parts[3].split(" ").last.substring(0, 1) == "+" ? "-" : "+";
      parts[3] = (parts[3].split(" ")..removeLast()).join(" ");
      var date = DateFormat("E MMM d H:m:s y").parse(parts[3], true);

      out("\t\t\tCommit(\"${parts[0]}\", \"${parts[1]}\", \"${parts[2]}\", DateTime.fromMillisecondsSinceEpoch(${date.copyWith(hour: date.hour + int.parse(sign + calc.substring(0, 2)), minute: date.minute + int.parse(sign + calc.substring(2))).millisecondsSinceEpoch}), \"${branchName.replaceAll('"', '\\"')}\"),");
    }
    var currentCommit = run("git", ["log", "-n", "1", branchName])
        .stdout
        .toString()
        .split("\n")
        .first
        .split(" ");
    out("\t\t], ${currentCommit.length == 1 ? "null" : "\"${currentCommit[1].trim()}\""}),");
  }
  out("\t];");

  out("\n\tstatic final List<Tag> tags = [");
  for (var tag in run("git", ["tag", "-l"])
      .stdout
      .toString()
      .split("\n")
      .where((e) => e.isNotEmpty)) {
    out("\t\tTag(\"${run("git", [
          "rev-parse",
          tag
        ]).stdout.toString().trim()}\", \"$tag\"),");
  }
  out("\t];");

  out("}");
  output.close();

  print("Generated GitBaker file at: ${outputFile.path.replaceAll("\\", "/")}");
}
