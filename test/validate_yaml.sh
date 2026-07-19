#!/usr/bin/env bash
#set -euo pipefail

cd "$(dirname "$0")"

# ----------------------------
# Configuration
# ----------------------------

all_valid_yaml=(problem/valid_yaml test_group/valid_yaml submissions/valid_yaml testdata/valid_yaml)
all_invalid_yaml=(problem/invalid_yaml test_group/invalid_yaml submissions/invalid_yaml testdata/invalid_yaml)
schemadir="../cue"

# Temp directory for snippets
SNIPPETS_DIR=$(mktemp -d)
trap "rm -rf $SNIPPETS_DIR" EXIT

# Fail-fast mode if -e is passed
# Shut up about ignored .yaml
FAIL_FAST=0
SILENT=0
VERBOSE=0
for arg in "$@"; do
	case "$arg" in
		-e) FAIL_FAST=1 ;;
		-s) SILENT=1 ;;
		-v) VERBOSE=1 ;;
	esac
done

failed=0
succeeded=0
ignored=0

# ----------
# Dispatcher
# ----------

declare -A schema_map=(
["*problem.yaml"]="#Problem"
["*test_group.yaml"]="#test_group_configuration"
["*testdata.yaml"]="#testdata_configuration"
["*/data/**/*.yaml"]="#test_case_configuration"
["*submissions.yaml"]="#Submissions"
# add more schemas here
)

schema_for_file() {
	local file=$1
	for pattern in "${!schema_map[@]}"; do
		if [[ $file == $pattern ]]; then
			echo "${schema_map[$pattern]}"
			return 0
		fi
	done
	return 1
}

# --------------
# Cue vet helper
# --------------
run_cue_vet() {
	local snippet=$1
	local schema=$2
	local parent_file=${3:-$(basename "$snippet")}
	local expect_failure=${4:-0}

	echo -n "Validating $(basename "$snippet") (schema=$schema) "

	output_cue=$(cue vet "$schemadir" "$snippet" -d "$schema" 2>&1)
	exit_code=$?

	if [ $exit_code -eq 0 ]; then
		if [ "$expect_failure" -eq 1 ]; then
			echo -e "\033[0;31mIncorrectly accepted (should fail)\033[0m"
			sed 's/^/    /' <<< "$output_cue"
			((failed++))
			if [ "$VERBOSE" -eq 1 ]; then
				cat $snippet
			fi
			[ "$FAIL_FAST" -eq 1 ] && exit 1
		else
			echo -e "\033[0;32mOK\033[0m"
			((succeeded++))
		fi
	else
		if [ "$expect_failure" -eq 1 ]; then
			echo -e "\033[0;32mOK (correctly rejected)\033[0m"
			if [ "$VERBOSE" -eq 1 ]; then
				echo -e "$output_cue" | head -1
			fi
			((succeeded++))
		else
			echo -e "\033[0;31mError\033[0m"
			sed 's/^/    /' <<< "$output_cue"
			((failed++))
			[ "$FAIL_FAST" -eq 1 ] && exit $exit_code
		fi
	fi
}

# ------------------------
# Process single YAML file
# ------------------------
process_yaml_file() {
	local file=$1
	local expect_failure=${2:-0}  # default: 0 = normal
	local schema
	if ! schema=$(schema_for_file "$file"); then
		[ "$SILENT" -eq 0 ] && echo -e "\033[0;33mSkipping $(basename "$file") — no schema defined yet.\033[0m"
		((ignored++))
		return 0
	fi

	if grep -q '^---$' "$file"; then
		snippet_count=0
		awk -v snippets_dir="$SNIPPETS_DIR" -v file_base="$(basename "$file")" '
		BEGIN { snippet_count = 0 }
		/^---$/ { snippet_count++; next }
		{
			snippet_file = snippets_dir "/" file_base "_snippet_" snippet_count ".yaml"
			print > snippet_file
		}
		' "$file"

		for snippet in "$SNIPPETS_DIR"/"$(basename "$file")"_snippet_*.yaml; do
			run_cue_vet "$snippet" "$schema" "$file" "$expect_failure"
			rm -f "$snippet"
		done
	else
		run_cue_vet "$file" "$schema" "" "$expect_failure"
	fi
}

# -----------------------
# Validate all valid YAML
# -----------------------
for dir in "${all_valid_yaml[@]}"; do
	while read -r file; do
		process_yaml_file "$file"
	done < <(find "$dir" -type f -name '*.yaml')
done

# ------------------------------------------
# Invalidate invalid YAML (expect rejection)
# ------------------------------------------
for dir in "${all_invalid_yaml[@]}"; do
	while read -r file; do
		process_yaml_file "$file" 1
	done < <(find "$dir" -type f -name '*.yaml')
done

# ------------------------------------------------------
# Direct value checks for low-level, unwrapped defs that
# have no YAML file of their own to validate as a whole
# ------------------------------------------------------
check_value() {
	local def=$1 value=$2 expect_failure=$3
	local snippet="$SNIPPETS_DIR/value.yaml"
	printf '%s\n' "$value" > "$snippet"
	run_cue_vet "$snippet" "$def" "" "$expect_failure"
}

# #name
check_value '#name' 'huge' 0
check_value '#name' 'make_tree' 0
check_value '#name' '"3"' 0
check_value '#name' 'a' 0
check_value '#name' 'connected_graph-01' 0
check_value '#name' '-2' 1
check_value '#name' '.2' 1
check_value '#name' '..' 1
check_value '#name' '""' 1

# #path (general grammar: rooted or not)
check_value '#path' 'data/secret/huge' 0
check_value '#path' 'submissions/accepted/x.cpp' 0
check_value '#path' '/data/secret/huge' 0
check_value '#path' 'data//secret' 1
check_value '#path' 'data/secret/' 1

# #relative_path (specializes #path: never rooted)
check_value '#relative_path' 'data/secret/huge' 0
check_value '#relative_path' 'submissions/accepted/x.cpp' 0
check_value '#relative_path' '/data/secret/huge' 1

# #absolute_path (specializes #path: always rooted)
check_value '#absolute_path' '/data/secret/huge' 0
check_value '#absolute_path' '/submissions/accepted/x.cpp' 0
check_value '#absolute_path' 'data/secret/huge' 1

# #package_dirname
check_value '#package_dirname' 'hello123' 0
check_value '#package_dirname' 'a' 0
check_value '#package_dirname' '"0"' 0
check_value '#package_dirname' 'Hello' 1
check_value '#package_dirname' 'hello_world' 1
check_value '#package_dirname' 'hello-world' 1
check_value '#package_dirname' 'hello.world' 1

# #test_data_group
check_value '#test_data_group' 'secret/group1' 0
check_value '#test_data_group' 'secret/group1/sub' 0
check_value '#test_data_group' 'sample/group1' 1
check_value '#test_data_group' 'secret' 1
check_value '#test_data_group' 'public/secret/x' 1

# -------
# Summary
# -------
echo ""
echo -e "\033[1mSummary:\033[0m"
printf " %-15s %s\n" "Succeeded:" "$succeeded"
printf " %-15s %s\n" "Failed:" "$failed"
printf " %-15s %s\n" "Ignored:" "$ignored"
echo ""

if [ $failed -ne 0 ]; then
	echo -e "\nTotal failed: $failed"
	exit 1
else
	echo -e "\nAll validations passed."
fi
