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
