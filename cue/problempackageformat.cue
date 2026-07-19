package problempackageformat

// Directory and file names, as well as names of test cases are
// alphanumerical with internal underscores and hyphens; such as
// "huge", "make_tree", "3", "a", or "connected_graph-01";
// but not "-2" or ".2" or ".." or "".
// Exported as plain data (not a #definition) so tools built on this module can compose their
// own path variants without duplicating the pattern.
name_pattern: "[a-zA-Z0-9_][a-zA-Z0-9_.-]{0,254}"

#name: =~"^\(name_pattern)$"

// The top-level directory name of a problem package (or its .zip's base name) -- more
// restrictive than #name: lowercase letters and digits only. Shared between both format
// versions; unlike most naming rules, this one was never forked.
#package_dirname: #name & =~"^[a-z0-9]+$"

// Paths are /-separated sequences of names, optionally rooted at the package root (a leading
// /). #path is the general grammar; #relative_path and #absolute_path specialize it to one or
// the other for contexts where only one is legal.
#path: =~"^/?(\(name_pattern)/)*\(name_pattern)$"

// A path relative to the package root, such as "data/secret/huge" or "submissions/accepted/x.cpp".
#relative_path: #path & !~"^/"

// A path rooted at the package root, such as "/data/secret/huge" or "/submissions/accepted/x.cpp".
#absolute_path: #path & =~"^/"

// A named subdivision of `secret`, nested to any depth, such as "secret/group1" or
// "secret/group1/sub". Never bare "secret" itself -- secret may only depend on sample
// (via the separate "sample" literal in require_pass below), never on itself.
#test_data_group: =~"^secret(/\(name_pattern))+$"

#ProgrammingLanguage: "ada" | "algol68" | "apl" | "bash" | "c" | "cgmp" | "cobol" | "cpp" | "cppgmp" | "crystal" | "csharp" | "d" | "dart" | "elixir" | "erlang" | "forth" | "fortran" | "fsharp" | "gerbil" | "go" | "haskell" | "java" | "javaalgs4" | "javascript" | "julia" | "kotlin" | "lisp" | "lua" | "modula2" | "nim" | "objectivec" | "ocaml" | "octave" | "odin" | "pascal" | "perl" | "php" | "prolog" | "python2" | "python3" | "python3numpy" | "racket" | "ruby" | "rust" | "scala" | "simula" | "smalltalk" | "snobol" | "swift" | "typescript" | "visualbasic" | "zig"
#LanguageCode:        =~"^[a-z]{2,3}(-[A-Z]{2})?$"

// Test data configuration
#test_case_or_group_configuration: {
	args?: [...string]
	answer_validator_args?: [...string] | {[string]: [...string]}
	input_validator_args?: [...string] | {[string]: [...string]}
	output_validator_args?: [...string]
	input_visualizer_args?: [...string]
	output_visualizer_args?: [...string]
	full_feedback?: bool
}

#test_case_configuration: {
	#test_case_or_group_configuration
	hint?:        string
	description?: string
}

// Configuration for test_group.yaml (2025-09 format only -- legacy uses testdata.yaml,
// #testdata_configuration, with an unrelated set of keys).
#test_group_configuration: {
	#test_case_or_group_configuration
	max_score?:               int & >=0 | "unbounded"
	score_aggregation?:       "pass-fail" | "sum" | "min"
	static_validation_score?: int & >=0 | "pass-fail"
	if static_validation_score != _|_ {
		static_validator_args?: [...string]
	}
	require_pass?: "sample" | #test_data_group | [...("sample" | #test_data_group)]

}

let inf_or_number = "([-+]?[0-9]+(\\.[0-9]+)?|-inf|\\+inf|inf)"

// Configuration for testdata.yaml (legacy format only -- 2025-09 uses test_group.yaml,
// #test_group_configuration, with an unrelated set of keys, plus a separate per-testcase
// #test_case_configuration file that legacy has no equivalent of). May be placed in any test
// data group; properties are inherited transitively by descendant groups that don't override
// them.
#testdata_configuration: {
	// How judging proceeds after a non-Accept judgement on an individual test case or subgroup.
	// "break": proceed immediately to grading. "continue": keep judging the rest of the group.
	on_reject?: *"break" | "continue"

	grading?: *"default" | "custom"

	// Arguments passed to the grader for this test data group.
	grader_flags?: *"" | string

	// Arguments passed to the input validator for this test data group. If a string, those are
	// the arguments passed to each input validator. If a map, name is the input validator to use
	// and flags are its arguments. (The spec's prose also describes this map as if it could be
	// dynamically keyed by validator name, with "validators not present in the map run without
	// arguments" -- that's inconsistent with its own type column, "map with the keys name and
	// flags", which is what's encoded here.)
	input_validator_flags?: *"" | string | {name?: string, flags?: string}

	// Arguments passed to the output validator for this test data group. If a string, this is
	// the name of the output validator to use (not its arguments -- asymmetric with
	// input_validator_flags, but that's what the spec states). If a map, name is the output
	// validator to use and flags are its arguments.
	output_validator_flags?: *"" | string | {name?: string, flags?: string}

	// Default score for accepted input files. Only for scoring problems.
	accept_score?: *1 | number

	// Default score for rejected input files. Only for scoring problems.
	reject_score?: *0 | number

	// The range of possible scores: two space-separated numbers A and B, where "inf", "-inf",
	// and "+inf" are allowed for infinity. Only for scoring problems.
	range?: *"-inf +inf" | =~"^\(inf_or_number) \(inf_or_number)$"
}
