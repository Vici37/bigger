test:
	crystal spec --profile --error-trace -Ddev

test-prod:
	crystal spec --profile --error-trace


benchmark:
	crystal run --release bin/benchmark.cr
