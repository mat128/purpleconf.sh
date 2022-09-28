.PHONY: test_native test

test_native:
	bats --formatter tap test/

test:
	docker build -t purpleconf-testing .
	docker run -v "${PWD}:/code" purpleconf-testing test