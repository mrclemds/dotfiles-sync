# Public Release Checklist

Complete this checklist after the repository history has passed a full secret
scan and immediately before changing repository visibility.

## Repository Rules

Create one active branch ruleset for `main` and `release/**` with these rules:

- Require a pull request before merging.
- Require zero approving reviews until a trusted reviewer is added. Raise this
  to one approval and dismiss stale approvals on new commits at that point.
- Require all review conversations to be resolved.
- Require the `updater` and `workflows` checks from the `Test` workflow.
- Require linear history.
- Block force pushes and branch deletion.
- Do not grant a routine bypass.

Create a tag ruleset for `v*` that blocks deletion and updates. Release tags
must be pushed from commits already merged through a protected branch.

## Security Features

After making the repository public, enable:

- Secret Scanning and push protection.
- Dependabot alerts, security updates, and version updates.
- Private vulnerability reporting.
- The repository security advisory feature.

Review alerts after enabling each feature. Public GitHub repositories can use
these features without exposing report contents.

## Pre-Public Review

- Scan every reachable ref, tag, unreachable Git object, and GitHub release
  asset with current Gitleaks and TruffleHog versions.
- Revoke and rotate a discovered credential before rewriting history.
- If history changes, recreate affected tags and release assets, then repeat the
  scan against the rewritten repository.
- Confirm `SECURITY.md`, `CONTRIBUTING.md`, `CODE_OF_CONDUCT.md`, issue forms,
  pull-request template, and GPL-3.0 license are present.
- Confirm the Test workflow is green and its checks are selected in the branch
  ruleset.
- Open a no-op pull request to verify required checks and approval enforcement.
