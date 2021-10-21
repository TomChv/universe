package trivy

import (
	"strconv"

	"alpha.dagger.io/alpine"
	"alpha.dagger.io/aws"
	"alpha.dagger.io/dagger"
	"alpha.dagger.io/dagger/op"
)

// Set Trivy download source
// - AWS
// - GCP
// - Docker Hub
// - Self Hosted

// Trivy Configuration
#Config: {
	// Docker Hub / Self hosted registry auth
	basicAuth: {
		// Username
		username: dagger.#Input & {string}

		// Password
		password: dagger.#Input & {dagger.#Secret}

		// No SSL connection
		noSSL: *false | bool
	} | *null

	// AWS ECR auth
	awsAuth: aws.#Config | *null

	// GCR auth (credential.json as string)
	gcpAuth: dagger.#Input & {dagger.#Secret | *null}
}

// Re-usable CLI component
#CLI: {
	config: #Config

	#up: [
		if config.awsAuth == null {
			op.#Load & {
				from: alpine.#Image & {
					package: bash: "=~5.1"
					package: curl: true
				}
			}
		},
		if config.awsAuth != null {
			op.#Load & {
				from: aws.#CLI & {
					"config": config
				}
			}
		},
		op.#Exec & {
			args: ["sh", "-c",
				#"""
					curl -sfL https://raw.githubusercontent.com/aquasecurity/trivy/main/contrib/install.sh &&
					chmod +x /usr/local/bin/trivy
					"""#,
			]
		},
		// config.basicAuth case
		if config.basicAuth != null && config.awsAuth == null && config.gcpAuth == null {
			op.#Exec & {
				args: ["/bin/bash", "-c",
					#"""
						# Rename
						mv /usr/local/bin/trivy /usr/local/bin/trivy-dagger

						# Build root of executable script
						echo '#!/bin/bash'$'\n' > /usr/local/bin/trivy

						# Construct env string from env vars
						envs=()
						[ -n "$TRIVY_USERNAME" ] && envs+=("TRIVY_USERNAME={$TRIVY_USERNAME}")
						[ -n "$TRIVY_NON_SSL" ] && envs+=("TRIVY_NON_SSL=$TRIVY_NON_SSL")

						# Append secret to env string
						[ -n "$(cat /password)" ] && envs+=("TRIVY_PASSWORD={$(cat /password)}")

						# Append full command
						echo "${envs[@]}" '/usr/local/bin/trivy-dagger "$@"' >> /usr/local/bin/trivy

						# Make it executable
						chmod +x /usr/local/bin/trivy
						"""#,
				]
				env: TRIVY_USERNAME: config.basicAuth.username
				env: TRIVY_NON_SSL:  strconv.FormatBool(config.basicAuth.noSSL)
				mount: "/password": secret: config.basicAuth.password
			}
		},
		// config.gcpAuth case
		if config.basicAuth == null && config.awsAuth == null && config.gcpAuth != null {
			op.#WriteFile & {
				dest:    "/credentials.json"
				content: config.gcpAuth
			}
			op.#Exec & {
				args: ["/bin/bash", "-c",
					#"""
						# Rename
						mv /usr/local/bin/trivy /usr/local/bin/trivy-dagger

						# Build root of executable script
						echo '#!/bin/bash'$'\n' > /usr/local/bin/trivy

						# Append full command
						echo "TRIVY_USERNAME=" "GOOGLE_APPLICATION_CREDENTIALS=/credentials.json" '/usr/local/bin/trivy-dagger "$@"' >> /usr/local/bin/trivy

						# Make it executable
						chmod +x /usr/local/bin/trivy
						"""#,
				]
			}
		},
	]
}
