.PHONY: test clean format

test:
	bazel test //tests:all_tests

clean:
	bazel clean

format:
	bazel run //.github/workflows:buildifier.check
