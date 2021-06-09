package main

import (
	"dagger.io/docker"
	"dagger.io/dagger"
	"dagger.io/random"
)

TestConfig: {
	host:       string         @dagger(input)
	user:       string         @dagger(input)
	key:        dagger.#Secret @dagger(input)
	passphrase: dagger.#Secret @dagger(input)
}

TestRun: {
	suffix: random.#String & {
		seed: ""
	}

	run: docker.#Run & {
		name: "daggerci-test-ssh-wrong-passphrase-\(suffix.out)"
		ref:  "hello-world"

		ssh: {
			host:          TestConfig.host
			user:          TestConfig.user
			key:           TestConfig.key
			keyPassphrase: TestConfig.passphrase
		}
	}
}
