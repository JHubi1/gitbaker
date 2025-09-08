## 0.1.1

- Improved documentation
- Added `hashAbbreviated` property to `Commit`
- Added (non-static) `toJson` methods to all generated classes for easier serialization

## 0.1.0

- Documentation of generated classes
- New `presentIn` property on `Commit` returning all branches the commit is present in
- Removed `branch` property on `Commit`, use `presentIn` instead
- `GitBaker` now has a new `commits` property returning all commits in the repository
  - Including those not present in any branch
- `Branch`'s `commits` property now doesn't store the `Commit` objects directly anymore, but only their hashes. It then resolves the hashes to `Commit` objects on access.
  - This way, `Commit` objects are only created once and reused, making comparisons and lookups easier and faster
- `Branch` has a new `revision` property returning the number of commits in the branch
  - This only takes commits that are a direct ancestor of the branch's HEAD into account
  - So if a branch merges another branch, the commits from the merged branch are not counted, only the merge commit itself
- `Remote`'s `url` property is now named `uri`
- `contributors` property is now called `members`

## 0.0.8

- Removed Branch's `hash` property, use `commits.last.hash` instead
- Removed Tag's `hash` property, use `commit.hash` instead
- Removed Tag's `description` property, use `commit.message` instead

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
