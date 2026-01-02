REPOSITORY_NAME=yovanggaanandhika/rust
TAG_NAME=latest

default:
	docker buildx build -t ${REPOSITORY_NAME}:${TAG_NAME} --load .

pull:
	docker pull ${REPOSITORY_NAME}:${TAG_NAME}

push:
	docker buildx build \
	--platform linux/amd64,linux/arm64/v8,linux/ppc64le \
	-t ${REPOSITORY_NAME}:${TAG_NAME} --push .

rmi:
	docker rmi ${REPOSITORY_NAME}:${TAG_NAME}

up:
	docker compose up -d