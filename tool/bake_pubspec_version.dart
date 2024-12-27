import 'dart:io';
import 'package:yaml/yaml.dart';

void main() {
  Directory.current = Platform.script.resolve('../').toFilePath();
  File("bin/generated/pubspec.g.dart")
    ..createSync(recursive: true)
    ..writeAsStringSync(
        "// automatically generated file, do not modify!\n// run 'dart tool/bake_pubspec_version.dart' to update\n\nconst String version = \"${loadYaml(File("pubspec.yaml").readAsStringSync())["version"]}\";\n");
}
