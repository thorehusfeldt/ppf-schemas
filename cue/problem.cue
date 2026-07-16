package problempackageformat

import "list"

import "time"

import uuidpkg "uuid"

// The category of a problem and how it is judged:
// "pass-fail" (the default) - accepted or rejected with a specific verdict, incompatible with scoring;
// "scoring" - submissions receive a non-negative numeric score, incompatible with pass-fail;
// "multi-pass" - the submission is run multiple times against generated inputs, incompatible with submit-answer;
// "interactive" - the output validator runs interactively with the submission, incompatible with submit-answer;
// "submit-answer" - the submission contains answers rather than source code, incompatible with multi-pass and interactive.
#Type: "pass-fail" | "scoring" | "multi-pass" | "interactive" | "submit-answer"

// A single source of this problem, given either as a string with just the name, or as a map
// with the mandatory name and the optional url of the event's webpage.
#Source: string | {
	// The name of the problem set, typically including the year, such as `NWERC 2024`.
	name!: string

	// A link to the event's webpage.
	url?: string
}

// A person, given either as a string with the full name, optionally followed by an email
// wrapped in <>, such as `Josiah Carberry` or `Josiah Carberry <jcarberry@brown.edu>`, or as a
// map with the mandatory name and the optional email, orcid, and kattis fields below.
#Person: string | {
	// The person's name, such as `Josiah Carberry`
	name!: string

	// The person's email address, such as `jcarberry@brown.edu`
	email?: string

	// The person's ID in the Open Researcher and Contributor ID system (ORCID), such as `0000-0002-1825-0097`.
	orcid?: string

	// The person's username on Kattis, such as `jcarberry01`
	kattis?: string
}

#Persons: #Person | [#Person, ...#Person]

// Resource limits common to both format versions. Explicitly specifying a limit is a hard
// requirement that the system must honor exactly; omitting it means any reasonable system
// default is acceptable. (Unlike #Problem_2025_09's time_multipliers, time_resolution, and
// validation_passes, none of these have a format-mandated default value.)
#ResourceLimits: {
	// The maximum memory a submission may use, in MiB.
	memory?: int & >0

	// The maximum total size of output a submission may produce, in MiB: the sum of standard
	// output, standard error, and (when file writing is allowed) all files it created or modified.
	output?: int & >0

	// The maximum total size of the submitted files of a submission, in KiB.
	code?: int & >0

	// The maximum time allowed to compile a submission, in seconds.
	compilation_time?: int & >0

	// The maximum memory allowed to compile a submission, in MiB.
	compilation_memory?: int & >0

	// The maximum time an output validator may run, in seconds.
	validation_time?: int & >0

	// The maximum memory an output validator may use, in MiB.
	validation_memory?: int & >0

	// The maximum total size of output an output validator may produce, in MiB.
	validation_output?: int & >0
}

// The version of the problem format package used for this problem. Absence means legacy.
#Problem: *#Problem_legacy | #Problem_2025_09

#Problem_2025_09: {
	problem_format_version!: "2025-09"

	// A universally unique identifier for this problem, such as `acde070d-8c4c-4f0d-9d8a-162843c10333`.
	uuid!: uuidpkg.Valid

	// The name of the problem, such as "Hello World!". For problems with statements in multiple
	// languages, a map from each language code to the problem's name in that language, such as
	// {en: "Hello World!", da: "Hej verden!"}.
	name!: string | {[#LanguageCode]: string}

	// The type of this problem, such as "pass-fail" or ["scoring", "interactive"]
	type?: *"pass-fail" | #Type | [#Type, ...#Type]
	// Two values listed as incompatible in #Type must not both appear.
	if (type & [...]) != _|_ {
		_policy: true &
			!(list.Contains(type, "scoring") && list.Contains(type, "pass-fail")) &&
			!(list.Contains(type, "multi-pass") && list.Contains(type, "submit-answer")) &&
			!(list.Contains(type, "interactive") && list.Contains(type, "submit-answer"))
	}

	// The version of this problem, as it undergoes (slight) changes possibly during development or deployment.
	// This can be used to check whether a problem uploaded to a contest system needs to be updated since it does not contain the latest fixes.
	version?: string

	// Keywords describing this problem, such as ["graph", "dynamic programming", "greedy"].
	// These are not standardized and are only for informational purposes.
	keywords?: [...string]

	// The persons who should get credit for this problem.
	credits?: string | {

		// The people who conceptualized the problem.
		authors!: #Persons

		// The people who developed the problem package, such as the statement, validators, and test data.
		contributors?: #Persons

		// The people who tested the problem package, for example, by providing a solution and reviewing the statement.
		testers?: #Persons

		// The people who translated the statement to other languages. Each key must be a language code.
		translators?: [#LanguageCode]: #Persons

		// The people who created the problem package out of an existing problem.
		packagers?: #Persons

		// Extra acknowledgements or special thanks in addition to the previously mentioned.
		acknowledgements?: #Persons
	}

	// The license under which this problem may be used.
	license: *"unknown" | "public domain" | "cc0" | "cc by" | "cc by-sa" | "educational" | "permission"
	if license != "public domain" {
		// The person(s) owning the rights to this problem.
		rights_owner?: #Persons
		if license != "unknown" && (credits & string) == _|_ && credits.authors == _|_ && source == _|_ {
			rights_owner!: _
		}
	}


	// The source(s) of this problem, such as `Northwestern Europe Regional Contest (NWERC) 2005`.
	// Multiple sources can be given as a list, mixing string and map form freely.
	source?: #Source | [#Source, ...#Source]

	limits?: {
		#ResourceLimits

		time_multipliers?: {
			ac_to_time_limit?:  number & >=1 | *2.0
			time_limit_to_tle?: number & >=1 | *1.5
		}
		time_limit?:      (float | int ) & >0
		time_resolution?: float & >0 | *1.0

		if (type & [...]) != _|_ if (list.Contains(type, "multi-pass")) {
			validation_passes?: int & >=2 | *2
		}
	}


	// The problem package should not be publicly available until this date (or date-time, in UTC).
	// If only a date is given, the time defaults to the start of that day in UTC.
	embargo_until?: time.Format("2006-01-02") | time.Format("2006-01-02T15:04:05Z")

	// The programming languages that may be used to solve this problem, restricted to the values
	// from the languages table, or "all" (the default) to allow any supported language.
	languages?: *"all" | [#ProgrammingLanguage, ...#ProgrammingLanguage]

	// Whether submissions may create, edit, and delete files in their working directory.
	// If false (the default), submissions may only read files.
	allow_file_writing?: *false | true

	// Named constant values, substituted via {{name}} (or {{name.variant}} for a variant) tokens
	// in statements, validators, included files, and example submissions -- but not in test data
	// or in problem.yaml itself. A constant is either a scalar (int, float, or string), equivalent
	// to {value: scalar}, or a map with the mandatory value and optional named variants giving
	// alternative representations, such as {value: 5000000, tex: "5,000,000"}.
	constants?: [=~"^[a-zA-Z_][a-zA-Z0-9_]*$"]: int | float | string | {
		value!:               int | float | string
		[string & !="value"]: string
	}
}

#Problem_legacy: {
	problem_format_version?: "legacy"

	// A universally unique identifier for this problem, such as `acde070d-8c4c-4f0d-9d8a-162843c10333`.
	uuid?: uuidpkg.Valid

	// The name of the problem.
	name!: string

	// The type of this problem.
	type?: "pass-fail" | "scoring"

	// The person or persons credited as author(s) of this problem.  Given as a string
	// separated by "," or "and ". This would typically be the people that came up with
	// the idea, wrote the problem specification and created the test data. This is sometimes
	// omitted when authors choose to instead only give source credit, but both may be specified.
	author?: string

	// The source that this problem originates from. This should typically contain the name
	// (and year) of the problem set (such as a contest or a course) where the problem was
	// first used or for which it was created.
	source?: string
	if source != _|_ {
		// A link to the event's page. Must not be given if source is not.
		source_url?: string
	}

	// The license under which this problem may be used.
	license: *"unknown" | "public domain" | "cc0" | "cc by" | "cc by-sa" | "educational" | "permission"
	if license != "public domain" {
		// The person(s) owning the rights to this problem. Defaults to `author` if present,
		// otherwise `source`; if neither is present, this remains unset.
		rights_owner?: string
		if license != "unknown" && author == _|_ && source == _|_ {
			rights_owner!: _
		}
	}

	limits?: {
		#ResourceLimits

		time_multiplier?:    number & >0 | *5
		time_safety_margin?: number & >0 | *2
	}

	// A space separated list of strings describing how validation is done. Must begin with one
	// of "default" or "custom"; if "custom", may be followed by some subset of "score" and
	// "interactive". Defaults to "default".
	validation?: *"default" | string

	// Arguments passed to each of the output validators.
	validator_flags?: string

	// Must only be used on scoring problems.
	if type != _|_ if type == "scoring" {
		grading?: {
			// Whether this is a minimization or a maximization problem.
			objective?: *"max" | "min"

			// Whether test group results should be shown to the end user.
			show_test_data_groups?: *false | true
		}
	}

	// A space-separated list of keywords describing this problem; keywords themselves must not
	// contain spaces. These are not standardized and are only for informational purposes.
	keywords?: string
}
