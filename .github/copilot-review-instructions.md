# Pull Request Review Instructions

## Versioning

When reviewing a pull request, verify that the version in `pubspec.yaml` has been updated when required by the project's versioning policy.

A minor version bump is required when either:

1. The PR fixes an issue labeled `enhancement`.
2. The PR introduces a large or substantial change, including large dependency maintenance or dependency upgrades, major framework or SDK-related updates, substantial refactoring, significant architectural changes, or other changes that materially affect a large part of the application.

For these changes:

- The minor version must be incremented in `pubspec.yaml`.
- The major version must remain unchanged.
- The patch version number must not be modified. It is managed dynamically by CI.

Examples:

- `1.2.x` → `1.3.x`
- `2.7.x` → `2.8.x`

If a required minor version bump is missing, report it as a review finding.

Do not report a version bump as missing for ordinary bug fixes, small improvements, documentation-only changes, or routine maintenance unless the change otherwise qualifies as a large or substantial change.

Do not request changes to the patch version number.