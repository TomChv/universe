package main

import (
	"alpha.dagger.io/dagger"
	"alpha.dagger.io/dagger/op"
	"alpha.dagger.io/alpine"
)

dockersocket: dagger.#Socket & dagger.#Input

TestDockerSocket: #up: [
	op.#Load & {
		from: alpine.#Image & {
			package: "docker-cli": true
		}
	},

	op.#Exec & {
		always: true
		mount: "/var/run/docker.sock": socket: dockersocket
		args: ["docker", "info"]
	},
]
