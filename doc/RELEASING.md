# Releasing

## Delivery flow

A maintainer's protected `v<pubspec.version>` tag triggers Release. The tag must match a valid package version and CHANGELOG entry and point to a commit in main history. Pre-release versions are supported. Release invokes full CI for that commit, publishes the verified Pub archive, then creates GitHub Release and deploys the verified Pages artifact.

Manual **CI** is the non-publishing rehearsal. Release has no manual trigger. CI has read-only repository permissions and no publication identity; publication and deployment grant only the permissions required by their jobs.

## Repository setup

Install CI and observe a successful run before configuring main to require `CI / required`. Require PRs, prevent force pushes/deletion, and keep the default workflow token read-only. Version tag creation is restricted to release maintainers; updates and deletion are prohibited.

Use tag-only Environments `pub.dev` and `github-pages`, without an extra reviewer gate. Configure Pages to use GitHub Actions. On pub.dev, enable automated publishing for `MasterHiei/timetable_next`, tag pattern `v{{version}}`, requiring Environment `pub.dev`. Do not store a long-lived Pub credential.

These settings must be checked in the services themselves; workflow files do not establish them.

## Rehearsal and first publication

After CI exists on main:

```sh
gh workflow run ci.yml --ref main
```

Inspect `CI / required` and the candidate/Pages artifacts. This event cannot publish or deploy. An uploaded artifact alone does not prove the complete run passed.

If the package does not exist on pub.dev, an authorized maintainer must publish its first version manually:

1. Complete full CI for the intended main commit and download `candidate-package`.
2. At that source revision, verify it with `python3 tool/ci.py verify-archive <package.tar.gz> <manifest.json>` and check the CI-reported SHA-256.
3. Use the recorded Dart SDK to run `dart pub publish --from-archive=<package.tar.gz>`. Publish the verified archive, not a new package assembled locally.
4. Configure pub.dev automation, then push the matching version tag on the same source commit. Tag CI verifies the existing publication's contents before completing GitHub Release and Pages.

## Subsequent releases

Update version and CHANGELOG through a PR, then create and push its matching tag. Full tag CI must succeed; another run or commit's artifacts are not reused.

CI runs `dart pub publish --dry-run`, creates the candidate once with `--to-archive`, and tests its contents with both SDK consumers. Publication checks its revision/version/SHA-256 and uses `--from-archive` with OIDC. Archive publishing skips some client checks, so dry-run and consumer checks are mandatory.

GitHub Release attaches that candidate and its small identity manifest. Pre-releases are marked accordingly. There is no example-application binary distribution or signing step.

## GitHub Pages

Build JavaScript Release with `--base-href /timetable_next/ --no-web-resources-cdn`. Write version/revision to `release.json`, smoke-test the actual bundle at that subpath, then upload it with the official Pages action. Deployment uses that same run's Pages artifact and never rebuilds. After deployment, check availability and version/revision over HTTP; do not repeat browser integration testing.

The Demo follows successful publications, including pre-releases. Compare versions by SemVer precedence; an older rerun leaves a newer Demo untouched. The same version with another revision fails.

The intended URL is `https://masterhiei.github.io/timetable_next/`. Add the README Demo link only after the first successful deployment and live check.

## Recovery

- Verification failure stops distribution. Diagnose and fix it; do not retry away test failures.
- Upload failure stops publication. Read polling is bounded to 120 seconds and never repeats uploads.
- An existing Pub version is accepted only if all file contents match the candidate; gzip timestamps need not match.
- If Pub succeeded and Release or Pages failed, rerun the unfinished job using retained artifacts.
- If artifacts expired, repeat full CI for that source and compare with any existing publication.
- Fix product regressions with a new version. Never replace published contents or move an old tag. Demo rollback is a separate explicit maintenance operation.

## Official references

- [Dart automated publishing and first publication](https://dart.dev/tools/pub/automated-publishing)
- [Official archive-based publishing workflow](https://github.com/dart-lang/setup-dart/blob/main/.github/workflows/publish.yml)
- [GitHub Pages artifact deployment](https://docs.github.com/en/pages/getting-started-with-github-pages/using-custom-workflows-with-github-pages)
