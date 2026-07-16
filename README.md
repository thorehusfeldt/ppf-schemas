# ppf-schemas

CUE schemas for the ICPC/Kattis [problem package format](https://icpc.io/problem-package-format/spec/2025-09.html) (ppf) — `problem.yaml`, `submissions.yaml`, and per-testcase/test-group configuration.

This module does **not** cover BAPCtools' generators framework (`generators.yaml`); that stays BAPCtools-internal and will eventually import from here.

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

After the one-time setup (`cue mod init your-module; cue mod get github.com/thorehusfeldt/ppf-schemas/problempackageformat@v0.1.1`),
you can `cue vet` a `problem.yaml` in one line — no local `.cue` file needed. Pass the module's
import path as an instance argument, the same way you'd pass a local schema directory:

```bash
cue vet github.com/thorehusfeldt/ppf-schemas/problempackageformat problem.yaml --schema '#Problem'
```

All four examples below were run for real against the published `v0.1.1` module.

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
$ cue vet github.com/thorehusfeldt/ppf-schemas/problempackageformat pos_2025-09.yaml --schema '#Problem'
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
$ cue vet github.com/thorehusfeldt/ppf-schemas/problempackageformat pos_legacy.yaml --schema '#Problem'
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
$ cue vet github.com/thorehusfeldt/ppf-schemas/problempackageformat neg_implicit_legacy.yaml --schema '#Problem'
credits: field not allowed:
    ./neg_implicit_legacy.yaml:2:1
```

`credits` is a 2025-09-only field (legacy has `author`, a plain string, instead) — and since
`problem_format_version` is absent here, this is unambiguously a legacy problem, which flatly doesn't
have a `credits` key to allow.

### Invalid, instructively: a license that isn't `unknown`/`public domain` needs an attribution path

```yaml
problem_format_version: 2025-09
uuid: acde070d-8c4c-4f0d-9d8a-162843c10333
name: Hello World!
license: cc0
```

```
$ cue vet github.com/thorehusfeldt/ppf-schemas/problempackageformat neg_missing_rights_owner.yaml --schema '#Problem'
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

## Testing

```bash
cd test
./validate_yaml.sh       # -v for verbose, -e to fail fast, -s to silence "no schema" skips
```
