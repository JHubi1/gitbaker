import 'dart:io';

import 'package:yaml/yaml.dart';
import 'generated/pubspec.g.dart' as info;
import 'package:intl/intl.dart';

Map<String, dynamic> config = {"output": "lib/generated"};

void main(List<String> arguments) {
  try {
    Process.runSync("git", ["--version"]);
  } catch (e) {
    print(
        "Git check failed, it may not be installed. Please install Git and try again.");
    exit(1);
  }

  try {
    if (Process.runSync("git", ["rev-parse", "--is-inside-work-tree"])
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
      Process.runSync("git", ["rev-parse", "--show-toplevel"])
          .stdout
          .toString()
          .trim());
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

  output.writeln(
      "// GitBaker v${info.version} <https://pub.dev/packages/gitbaker>\n");

  output.writeln(
      "// This is an automatically generated file by GitBaker. Do not modify manually.");
  output.writeln(
      "// To regenerate this file, please rerun the command 'dart pub run gitbaker'");

  output.writeln(
      "\nenum RemoteType { fetch, push }\nclass Remote {\n\tfinal String name;\n\tfinal String url;\n\tfinal RemoteType type;\n\n\tRemote(this.name, this.url, this.type);\n}");
  output.writeln(
      "\nclass Commit {\n\tfinal String hash;\n\tfinal String message;\n\tfinal String author;\n\tfinal DateTime date;\n\n\tfinal String _branch;\n\tBranch get branch => GitBaker.branches.where((e) => e.name == _branch).toList().first;\n\n\tCommit(this.hash, this.message, this.author, this.date, this._branch);\n}");
  output.writeln(
      "\nclass Branch {\n\tfinal String hash;\n\tfinal String name;\n\tfinal List<Commit> commits;\n\n\tfinal String _latestCommit;\n\tCommit get latestCommit => commits.where((e) => e.hash == _latestCommit).toList().first;\n\n\tBranch(this.hash, this.name, this.commits, this._latestCommit);\n}");
  output.writeln(
      "\nclass Tag {\n\tfinal String hash;\n\tfinal String name;\n\n\tTag(this.hash, this.name);\n}");

  output.writeln("\nclass GitBaker {");

  var descriptionFile = File("${gitRoot.path}/.git/description");
  output.writeln(
      "\tstatic final String? description = ${descriptionFile.existsSync() ? "\"${descriptionFile.readAsStringSync().trim().replaceAll('"', '\\"')}\"" : "null"};");
  output.writeln(
      "\tstatic final String defaultBranch = \"${(Process.runSync("git", [
        "rev-parse",
        "--abbrev-ref",
        "origin/HEAD"
      ]).stdout.toString().trim().split("/")..removeWhere((e) => e == "origin")).join("/")}\";");

  output.writeln("\n\tstatic final List<Remote> remotes = [");
  for (var remote in Process.runSync("git", ["remote", "-v"])
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
  output.writeln("\t];");

  output.writeln("\n\tstatic final List<Branch> branches = [");
  for (var branch in Process.runSync("git", ["branch", "--list"])
      .stdout
      .toString()
      .split("\n")
      .where((e) => e.isNotEmpty)) {
    var branchName = branch.substring(2);
    output.writeln("\t\tBranch(\"${Process.runSync("git", [
          "rev-parse",
          branchName
        ]).stdout.toString().trim()}\", \"$branchName\", [");
    for (var commit in Process.runSync(
            "git", ["log", "--pretty=format:%H|%s|%an|%ad", branchName])
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

      output.writeln(
          "\t\t\tCommit(\"${parts[0]}\", \"${parts[1]}\", \"${parts[2]}\", DateTime.fromMillisecondsSinceEpoch(${date.copyWith(hour: date.hour + int.parse(sign + calc.substring(0, 2)), minute: date.minute + int.parse(sign + calc.substring(2))).millisecondsSinceEpoch}), \"${branchName.replaceAll('"', '\\"')}\"),");
    }
    output.writeln("\t\t], \"${Process.runSync("git", [
          "log",
          "-n",
          "1",
          branchName
        ]).stdout.toString().split("\n").first.split(" ")[1].trim()}\"),");
  }
  output.writeln("\t];");

  output.writeln("\n\tstatic final List<Tag> tags = [");
  for (var tag in Process.runSync("git", ["tag", "-l"])
      .stdout
      .toString()
      .split("\n")
      .where((e) => e.isNotEmpty)) {
    output.writeln("\t\tTag(\"${Process.runSync("git", [
          "rev-parse",
          tag
        ]).stdout.toString().trim()}\", \"$tag\"),");
  }
  output.writeln("\t];");

  output.writeln("}");
  output.close();

  print("Generated GitBaker file at ${outputFile.path.replaceAll("\\", "/")}.");
}
