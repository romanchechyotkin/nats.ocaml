.PHONY: fmt
fmt: 
	dune fmt

.PHONY: build
build: fmt
	dune build


.PHONY: test
test: build
	dune exec _build/default/client/test/test_client.exe