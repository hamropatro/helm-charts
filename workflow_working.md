# Release Workflow Working

## Concept/Reason

The release workflow publishes Helm charts from the `release` branch. It lints every chart, then uses `helm/chart-releaser-action` to publish chart releases and update the root `index.yaml`.

The published Helm repository path is `https://hamropatro.github.io/helm-charts/build`.

The workflow keeps that `/build` URL working by copying the generated root `index.yaml` to `build/index.yaml` and copying `README.md` into `build/` after chart-releaser finishes.

## Trigger

The workflow runs on pushes to the `release` branch.

It does not run for changes that only touch:

- `build/**`
- `**/*.md`
- `.github/workflows/release.yaml`

This prevents release loops from `build/` commits and avoids chart release runs for documentation-only or workflow-only changes. Changes to root `index.yaml` are not ignored.

## What `release.yaml` Does

1. Runs the `lint` job.

   It checks out the pushed ref with full Git history, installs Helm `v3.14.4`, and runs `helm lint` for every directory under `charts/*`.

2. Runs the `release` job after lint passes.

   It checks out the `release` branch with full Git history and grants `contents: write` so generated release files can be pushed.

3. Configures Git.

   Commits are authored as `github-actions[bot]`.

4. Installs Helm.

   The workflow installs Helm `v3.14.4`.

5. Runs chart-releaser.

   The workflow uses `helm/chart-releaser-action@v1.6.0` with:

   - `charts_dir: charts`
   - `pages_branch: release`
   - `skip_existing: true`

   Chart-releaser packages chart versions that do not already exist, creates or updates chart releases, and updates root `index.yaml` on the `release` branch.

6. Refreshes the workspace.

   After chart-releaser may have committed changes, the workflow fetches `origin/release` and resets the workspace to `origin/release` so the next step sees the latest root `index.yaml`.

7. Syncs public build files.

   It creates `build/`, copies root `index.yaml` to `build/index.yaml`, and copies `README.md` to `build/`.

8. Commits build output.

   If `build/` changed, the workflow commits it with `Sync Helm index to build/` and pushes back to `release`.

## Normal Release Flow

1. Change a chart under `charts/<chart-name>/`.
2. Bump `version:` in that chart's `Chart.yaml`.
3. Push to the `release` branch.
4. GitHub Actions lints all charts.
5. Chart-releaser publishes any chart versions that do not already exist and updates root `index.yaml`.
6. GitHub Actions copies root `index.yaml` to `build/index.yaml` and commits changed `build/` files.
7. Consumers use `https://hamropatro.github.io/helm-charts/build` and run `helm repo update` to get the new chart version.

## Validation

Before pushing chart changes, run:

```sh
helm lint charts/<chart-name>
helm package charts/<chart-name> -d /tmp/helm-chart-test
```

For all charts, run:

```sh
mkdir -p build
for chart in charts/*; do
  [ -d "$chart" ] || continue
  helm lint "$chart"
  helm package "$chart" -d build
done
helm repo index build/
```

This validates chart packaging locally. It does not create GitHub releases or exactly reproduce chart-releaser metadata.

## Rollback

If a workflow change breaks release, revert the workflow file and rerun the failed GitHub Action.

If `build/index.yaml` points to bad content, revert the bad `build/` sync commit or rerun the workflow after fixing root `index.yaml`.

If a chart release was published with the wrong content, bump the chart version again and publish a corrected chart version. Do not overwrite an existing published chart version unless consumers are known safe.
