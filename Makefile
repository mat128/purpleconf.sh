.PHONY: test

test:
	bats --formatter tap test/

test_over_docker:
	docker build -t purpleconf-testing .
	docker run -v "${PWD}:/code" purpleconf-testing test