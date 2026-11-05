package problempackageformat

import "list"

#verdict: "AC" | "WA" | "RTE" | "TLE"

// Regular expressions for glob-like path matching
let letter = "[a-zA-Z0-9_.*-]"
let word_re = "[a-zA-Z0-9_. -]*"
let brace_atom_re = "\\{\(word_re)(,\(word_re))*\\}"
let component_re = "(\(letter)|\(brace_atom_re))+"
let glob_path = =~"^(\(component_re)/)*\(component_re)$" & !~"\\*\\*"

#Submissions: {
	[glob_path]: #submission
}

#submission: {
	language?: #ProgrammingLanguage

	// Path of the main file, relative to the submission's directory, such as "solve.py" or
	// "app/Main.java".
	main_file?: #relative_path

	// The author(s) of this submission.
	authors?: #Persons

	// A suggested model solution, suitable to be published.
	model_solution?: *false | true

	#expectation
	[=~"^(sample|secret|\\*)" & glob_path]: #expectation
}

#expectation: {
	// All test cases must have a verdict in this subset.
	permitted?: *["AC", "WA", "TLE", "RTE"] | [#verdict, ...#verdict]

	// At least one test case must have a verdict in this subset.
	required?: *["AC", "WA", "TLE", "RTE"] | [#verdict, ...#verdict]

	// The score of the submission equals the given number, or lies in the given inclusive
	// range. Only for scoring problems.
	score?: number | [number, number] & list.IsSorted(list.Ascending)

	// Must appear as a substring in at least one judgemessage.txt.
	judge_message?: *"" | string

	// Use this submission to lower or upper bound the time limit.
	use_for_time_limit?: "lower" | "upper"
}
