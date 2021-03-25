# Contributing Guidelines

Contributions are welcome via GitHub Pull Requests. This document outlines the process to help get your contribution accepted.

Any type of contribution is welcome; from new features, bug fixes, or documentation.

## How to Contribute

1. Fork this repository, develop, and test your changes.
2. Submit a pull request.

### Technical Requirements

When submitting a PR make sure that it:

- Must pass CI jobs for linting and test the changes on top of different k8s platforms. (Automatically done by the CI/CD pipeline using GitHub actions).
- Must follow [Helm best practices](https://helm.sh/docs/chart_best_practices/).
- Any change to a chart requires a version bump following [semver](https://semver.org/) principles. Update the Pull Request with a new helm package version using the `helm package` command. For example:

```bash
helm package charts/illumidesk/ -d docs/ --version 1.2.3
```

### Documentation Requirements

- A chart's `README.md` must include configuration options.
- A chart's `NOTES.txt` must include relevant post-installation information.
- Comments to the `values.yaml` file to complement the `README.md` and the `NOTES.txt`.
- Add a reference to the GitHub issue in the PR's description.

**NOTE:** the comments within the `values.yaml` file should have the following convention:

- Primary key comments should have double hashes: `##`
- Primary key comments should have a comment to add a space
- All child key comments should have one hash: `#`
- If applicable add a reference with the link prependended with `ref: `.
- Keys that have empty values, such as `{}` should provide examples if possible.

For example:

```yaml
## Deployment pod host aliases
## https://kubernetes.io/docs/concepts/services-networking/add-entries-to-pod-etc-hosts-with-host-aliases/
## Example:
## hostAliases:
## - ip: "127.0.0.1"
##   hostnames:
##   - "foo.local"
##
hostAliases: []
```

### Locking dependencies

The IllumiDesk helm-chart depends on several sub charts. Use the following commands to ensure the sub charts are locked to specific versions:

```bash
cd charts/illumidesk
helm dependency build
```

### PR Approval and Release Process

1. Changes are automatically linted and tested using the [`ct` tool](https://github.com/helm/chart-testing) as a [GitHub action](https://github.com/helm/chart-testing-action). Those tests are based on `helm install`, `helm lint` and `helm test` commands and provide quick feedback about the changes in the PR. For those tests, the chart is installed on top of [kind](https://github.com/kubernetes-sigs/kind) and this step is not blocking (as opposed to 3rd step).
2. Changes are manually reviewed by IllumiDesk team members.
3. Once the changes are accepted, the PR is tested (if needed) into the IllumiDesk CI pipeline, the chart is installed and tested (verification and functional tests) on top of different k8s platforms.
4. When the PR passes all tests, the PR is merged by the reviewer(s) in the GitHub `main` branch.

### Run the linter locally (ct lint)

This setup uses the `ct` utility to lint the helm chart with GitHub Actions. You can use the `quay.io/helmpack/chart-testing:latest` image to run `ct` commands and lint the chart(s) before creating a Pull Request. To run the `ct lint ...` command from your local environment follow the steps below:

1. From the **root** of this repo start the container that includes all required dependencies:

```bash
docker run --rm -ti -v $(pwd):/workdir --workdir /workdir --network host --name ct quay.io/helmpack/chart-testing:latest sh
```

2. (Optional) Install the sub-charts that are included with this chart as dependencies:

```bash
ct install --config .github/ct.yaml
```

3. Run the linter with `ct`:

```bash
ct lint --config .github/ct.yaml
```

These steps help emulate the existing GitHub Action that runs the `ct lint` command. Specifically, these commands will:

- Run the `ct` container that includes all required dependencies.
- Mount the current location to a `/workdir` path within the container.
- Name the running container as `ct`.
- (Optional) Install all sub-chart dependencies with `ct`.
- Run the `ct lint` command as it runs with the GitHub action specification.

#### Commits and merges

When squashing and merging to the `main` branch, use the following format to provide consistent updates to the `CHANGELOG.md` file:

    <Commit Type>(scope): <Merge Description>

- `Merge Description` should initiate with a capital letter, as it provides the changelog with a standard sentence structure.

- `Commit Types` are listed below:

| Commit Type | Commit Format |
| --- | --- |
| Chores | `chore` |
| Documentation | `docs` |
| Features | `feat` |
| Fixes | `fix` |
| Refactoring | `refactor` |

Use the `BREAKING CHANGE` in the commit's footer if a release has a breaking change.

Examples:

- Commit a new feature:

    ```
    feat: Adds external database option
    ```

- Commit a bug fix:

    ```
    fix: Updates template to enable ingress resource when enabled
    ```

- Commit a version with a breaking change:

    ```
    feat: Deprecate network file system (NFS) options

    BREAKING CHANGE: `nfs.enabled` key is no longer valid
    ```
