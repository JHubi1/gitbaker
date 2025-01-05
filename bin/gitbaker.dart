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
  out("\nclass User {\n\tfinal String name;\n\tfinal String email;\n\n\tUser(this.name, this.email);\n}");
  out("\nclass Commit {\n\tfinal String hash;\n\tfinal String message;\n\tfinal DateTime date;\n\n\t/// Whether the commit has been signed.\n\t/// Careful: not whether the signature is valid!\n\tfinal bool signed;\n\n\tfinal String _branch;\n\tBranch get branch => GitBaker.branches.where((e) => e.name == _branch).first;\n\n\tfinal String _author;\n\tUser get author => GitBaker.contributors.where((e) => e.name == _author).first;\n\n\tCommit(this.hash, this.message, this.date, this.signed, this._branch, this._author);\n}");
  out("\nclass Branch {\n\tfinal String hash;\n\tfinal String name;\n\tfinal List<Commit> commits;\n\n\tbool get isCurrent => this == GitBaker.currentBranch;\n\tbool get isDefault => this == GitBaker.defaultBranch;\n\n\tBranch(this.hash, this.name, this.commits);\n}");
  out("\nclass Tag {\n\tfinal String hash;\n\tfinal String name;\n\tfinal String description;\n\n\tTag(this.hash, this.name, this.description);\n}");

  out("\nclass GitBaker {");

  var descriptionFile = File("${gitRoot.path}/.git/description");
  var description = descriptionFile.existsSync()
      ? descriptionFile.readAsStringSync().trim().replaceAll('"', '\\"')
      : null;
  if (description ==
      "Unnamed repository; edit this file 'description' to name the repository.") {
    description = null;
  }
  out("\tstatic final String? description = ${description == null ? "null" : "\"$description\""};");

  out("\n\tstatic final Set<Remote> remotes = {");
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
  out("\t};");

  out("\n\tstatic final Set<User> contributors = {");
  for (var commit in run("git", ["log", "--pretty=format:%an|%ae", "--all"])
      .stdout
      .toString()
      .split("\n")
      .where((e) => e.isNotEmpty)
      .toSet()
      .toList()) {
    var parts = commit.split("|").map((e) => e.trim()).toList();
    out("\t\tUser(\"${parts[0]}\", \"${parts[1]}\"),");
  }
  out("\t};");

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

  out("\n\tstatic final Set<Branch> branches = {");
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

      out("\t\t\tCommit(\"${parts[0]}\", \"${parts[1]}\", DateTime.fromMillisecondsSinceEpoch(${date.copyWith(hour: date.hour + int.parse(sign + calc.substring(0, 2)), minute: date.minute + int.parse(sign + calc.substring(2))).millisecondsSinceEpoch}), ${Process.runSync("git", [
            "verify-commit",
            parts[0]
          ]).stderr.toString().trim().isEmpty ? "false" : "true"}, \"${branchName.replaceAll('"', '\\"')}\", \"${parts[2]}\"),");
    }
    out("\t\t]),");
  }
  out("\t};");

  out("\n\tstatic final Set<Tag> tags = {");
  for (var tag in run("git", ["tag", "-ln9"])
      .stdout
      .toString()
      .split("\n")
      .where((e) => e.isNotEmpty)) {
    var parts = tag.split(" ")..removeWhere((e) => e.trim().isEmpty);
    out("\t\tTag(\"${run("git", [
          "rev-parse",
          parts[0]
        ]).stdout.toString().trim()}\", \"${parts[0]}\", \"${(parts..removeAt(0)).join(" ")}\"),");
  }
  out("\t};");

  out("}");
  output.close();

  print("Generated GitBaker file at: ${outputFile.path.replaceAll("\\", "/")}");
}
