.PHONY: build build-dds build-zenoh artifacts test test-dds test-zenoh clean

build: build-dds build-zenoh

build-dds:
	docker compose build base
	docker compose build dds-pqc

build-zenoh:
	docker compose build base
	docker compose build zenoh-pqc

artifacts:
	docker compose run --rm artifacts

test: test-dds test-zenoh

test-dds:
	./scripts/run_demo.sh dds

test-zenoh:
	./scripts/run_demo.sh zenoh

clean:
	docker compose down --volumes --remove-orphans
