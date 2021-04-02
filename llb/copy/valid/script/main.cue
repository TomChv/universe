package testing

test: {
	string

	#up: [
		{
			do:  "fetch-container"
			ref: "busybox"
		},
		{
			do: "copy"
			from: [{do: "fetch-container", ref: "alpine"}]
			src:  "/etc/issue"
			dest: "/"
		},
		{
			do:     "export"
			source: "/issue"
			format: "string"
		},
	]
}
