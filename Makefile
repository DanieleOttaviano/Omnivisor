IMAGE = omnv_env_builder

build:
	docker build -t $(IMAGE) .

run:
	docker run -it --rm \
		--user $(shell id -u):$(shell id -g) \
		-v /etc/passwd:/etc/passwd:ro \
		--net=host \
		--name $(IMAGE) \
		-v $(PWD):/home \
		-w /home \
		$(IMAGE)

connect:
	docker exec -it $(IMAGE) /bin/bash