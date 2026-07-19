# ppf-schemas

CUE schemas for the ICPC/Kattis [problem package format](https://icpc.io/problem-package-format/spec/2025-09.html) (ppf) — `problem.yaml`, `submissions.yaml`, and per-testcase/test-group configuration.

This module does **not** cover BAPCtools' generators framework (`generators.yaml`); that stays BAPCtools-internal and will eventually import from here.

**Registry page:** [registry.cue.works/docs/github.com/thorehusfeldt/ppf-schemas/problempackageformat@v0.1.5](https://registry.cue.works/docs/github.com/thorehusfeldt/ppf-schemas/problempackageformat@v0.1.5)

## Layout

- `cue/` — the CUE module (`github.com/thorehusfeldt/ppf-schemas/problempackageformat`), published to the [CUE Central Registry](https://registry.cue.works/)
- `json/` — JSON Schema generated from the CUE, for editor/LSP `$schema` use (not yet populated)
- `test/` — fixture YAML files and `validate_yaml.sh`, a `cue vet` dispatcher

## Using this module

```cue
import ppf "github.com/thorehusfeldt/ppf-schemas/problempackageformat"
```

The module path has a `/problempackageformat` suffix (not just the bare repo) so that it matches
`package problempackageformat`, letting consumers import without an explicit `:problempackageformat`
qualifier.

## Examples

The quickest way to check a `problem.yaml`: put the version directly on the module path in the
`cue vet` invocation itself. This needs **no setup at all** — no `cue mod init`, no `cue.mod/`
directory, nothing written locally; `cue` resolves and caches the module from the registry on the
fly.

```bash
cue vet --schema '#Problem' github.com/thorehusfeldt/ppf-schemas/problempackageformat@v0.1.5 problem.yaml
```

If you're integrating this into a real project rather than doing a one-off check, the more usual
module-dependency workflow also works — `cue mod init your-module`, then
`cue mod get github.com/thorehusfeldt/ppf-schemas/problempackageformat@v0.1.5` once, after which
you can drop the `@v0.1.5` from the `cue vet` invocation and it resolves from the recorded
dependency instead.

All four examples below were run for real against the published `v0.1.5` module.

### Valid: 2025-09, using several optional features at once

```yaml
problem_format_version: 2025-09
uuid: acde070d-8c4c-4f0d-9d8a-162843c10333
name:
  en: Hello World!
  da: Hej verden!
type: [scoring, interactive]
credits:
  authors: Ada Lovelace <ada@example.com>
  testers:
    - Alan Turing
license: cc by-sa
source:
  name: NWERC 2024
  url: https://2024.nwerc.example/contest
limits:
  time_limit: 2.5
  memory: 1024
```

```
$ cue vet --schema '#Problem' github.com/thorehusfeldt/ppf-schemas/problempackageformat@v0.1.5 pos_2025-09.yaml
$
```
No output, exit `0` — `cue vet`'s way of saying everything's fine. Note there's no `rights_owner`:
`license: cc by-sa` would normally require one, but it's satisfied implicitly since `credits.authors`
is given.

### Valid: legacy, using several optional features at once

```yaml
name: Hello World!
author: Ada Lovelace
source: NWERC 2005
source_url: https://2005.nwerc.eu
type: scoring
grading:
  objective: max
  show_test_data_groups: true
license: cc0
limits:
  time_multiplier: 3
  memory: 512
```

```
$ cue vet --schema '#Problem' github.com/thorehusfeldt/ppf-schemas/problempackageformat@v0.1.5 pos_legacy.yaml
$
```
No `problem_format_version` key at all — a real legacy problem never has one. Also no `rights_owner`
despite `license: cc0`, satisfied implicitly this time by `author` instead of `credits.authors`.

### Invalid, instructively: dropping `problem_format_version` doesn't relax 2025-09 rules, it switches format entirely

```yaml
name: Hello World!
credits:
  authors: Ada Lovelace
```

```
$ cue vet --schema '#Problem' github.com/thorehusfeldt/ppf-schemas/problempackageformat@v0.1.5 neg_implicit_legacy.yaml
problem_format_version: field is required but not present:
    .../problem.cue:81:2
uuid: field is required but not present:
    .../problem.cue:84:2
```

This looks backwards at first — `problem_format_version` is optional, so why does removing it make it
*required*? Because `credits` isn't a legacy field (legacy only has `author`, a plain string), the
legacy branch this would otherwise resolve to is a genuine conflict, not just incomplete, and gets
eliminated from the disjunction entirely. That leaves only the 2025-09 branch as the surviving
explanation of what your document would need to be valid — which is exactly `problem_format_version`
and `uuid`.

### Invalid, instructively: a license that isn't `unknown`/`public domain` needs an attribution path

```yaml
problem_format_version: 2025-09
uuid: acde070d-8c4c-4f0d-9d8a-162843c10333
name: Hello World!
license: cc0
```

```
$ cue vet --schema '#Problem' github.com/thorehusfeldt/ppf-schemas/problempackageformat@v0.1.5 neg_missing_rights_owner.yaml
rights_owner: field is required but not present
```

`rights_owner` is only required when it *can't* be inferred from somewhere else. Adding `credits.authors`
or `source` (or switching to `license: unknown`) would each independently make this valid without
needing `rights_owner` explicitly.

## Schemas

| File | Schema |
|---|---|
| `problem.yaml` | `#Problem` (`#Problem_2025_09` \| `#Problem_legacy`, discriminated by `problem_format_version`) |
| `submissions.yaml` | `#Submissions` |
| `test_group.yaml` | `#test_group_configuration` (2025-09) |
| `testdata.yaml` | `#testdata_configuration` (legacy) |
| `data/**/*.yaml` (per-testcase config) | `#test_case_configuration` |

Building blocks used across the above, also available to import directly: `#name`, `#package_dirname`,
`#path` (rooted or not), `#relative_path`/`#absolute_path` (specialize `#path` to one or the other),
`#test_data_group`.

## Testing

```bash
cd test
./validate_yaml.sh       # -v for verbose, -e to fail fast, -s to silence "no schema" skips
```

## Development setup

One-time, per clone:

```bash
git config core.hooksPath .githooks
```

This enables a pre-commit hook (`.githooks/pre-commit`) that runs `cue fmt --check` and the full
test suite before each commit. Both are fast (formatting check is instant, the test suite is
~10 seconds) and silent on success.
