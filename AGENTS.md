# Project Instructions

## Versioning

This project uses semantic versioning. The version is defined in `pubspec.yaml`, while the patch version is managed dynamically by CI.

### Version bump rules

A **minor version bump is required** when either of the following applies:

1. The PR fixes an issue labeled `enhancement`.
2. The PR introduces a large or substantial change, including but not limited to:
   - large dependency maintenance or dependency upgrades;
   - major framework or SDK-related updates;
   - substantial refactoring;
   - significant architectural changes;
   - other changes that materially affect a large part of the application.

For such PRs:

- Increment **only the minor version** in `pubspec.yaml`.
- Preserve the current major version.
- **Do not modify the patch version number.** The patch version is managed dynamically by CI.
- Do not increment the major version.

Examples:

- `1.2.x` → `1.3.x`
- `2.7.x` → `2.8.x`
- `1.9.x` → `1.10.x`

A version bump is **not** required for ordinary bug fixes, small improvements, documentation-only changes, or routine maintenance unless one of the conditions above applies.

### Pull request handling

Before finalizing a PR:

1. Inspect the associated GitHub issue labels when available.
2. Determine whether the PR fixes an issue labeled `enhancement`.
3. Determine whether the PR constitutes a large or substantial change.
4. If either condition applies, ensure that `pubspec.yaml` contains the required minor version bump.
5. Do not modify the patch version number.

If the required minor version bump is missing, update `pubspec.yaml` as part of the PR.

Do not independently change the project's versioning policy without an explicit instruction from the repository owner.
:::

## Dependencies

For every newly added dependency, always verify and use the latest available version unless it is incompatible with the app or conflicts with other dependencies. Do not update unrelated existing dependencies.