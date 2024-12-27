# GitBaker

[![Pub Version](https://img.shields.io/pub/v/gitbaker)](https://pub.dev/packages/gitbaker) [![Pub Points](https://img.shields.io/pub/points/gitbaker)](https://pub.dev/packages/gitbaker/score)

An easy and simple to integrate info baker for git repositories into your Flutter or Dart project.

Did you ever wanted to show the latest commit number or the last commit message in your Flutter app, as a version number for example? GitBaker is here to help you with that. It bakes the information from your Git repository directly into your Flutter or Dart project.

## Usage

Firstly, add the GitBaker package to your project by running the following command:

```bash
dart pub add dev:gitbaker
```

You can then simply run the following command to bake the information from your Git repository into your project:

```bash
dart run gitbaker
```

GitBaker will then determine the current Git repository to use and bake the information. This should work in most cases, but in some cases might fail. If this happens, make sure the folder you're running the command in is either root of your Git repository or a subdirectory of it.

The command will create a new file called `gitbaker.g.dart` in the `lib/generated` directory of your project. You can change this by defining an output directory in your project's `pubspec.yaml` file:

```yaml
...
gitbaker:
    // Default is lib/generated
    output: lib/src/generated
...
```
