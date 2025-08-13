## 0.0.7

- Improved escaping of strings in generated code
- Added support for global `gitbaker` command
- Commit's `date` property is now correctly set
- New `remote` getter returns primary remote from `remotes`

## 0.0.6

- Better error handling
- Better encoding handling
- Classes are now marked as `final`
- Dart SDK version is now 3.7.0 or higher
- No more dependency on `intl` package
  - Better DX when used with Flutter

## 0.0.5

- `Remote.url` now is an `Uri` object instead of a string
- All helper classes now have a private constructor
- Generated file now declares itself as library
- Code is formatted before being written to the file
- Strings are now raw strings making it safer
- Nicer CLI output

## 0.0.4

- Everything is now a Set
- New User object whenever username was returned before
- Contributors list added
- Commits now have a `signed` field

## 0.0.3

- Support git encoding

## 0.0.2

- Various bug fixes and improvements

## 0.0.1

- Initial version
