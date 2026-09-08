.PHONY: build build-base build-dds build-zenoh artifacts test test-dds test-zenoh test-openssl4-cms clean

build: build-dds build-zenoh

build-base:
	docker compose build base

build-dds: build-base
	docker compose build dds-pqc

build-zenoh: build-base
	docker compose build zenoh-pqc

artifacts: build-zenoh
	docker compose run --rm artifacts-zenoh

test: test-dds test-zenoh

test-dds:
	./scripts/run_demo.sh dds

test-zenoh:
	./scripts/run_demo.sh zenoh

test-openssl4-cms:
	docker compose build openssl4-cms
	docker compose run --rm openssl4-cms

clean:
	docker compose down --volumes --remove-orphans
