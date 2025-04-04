REPOSITORY_NAME=yovanggaanandhika/postgresql
TAG_NAME=15-node

default:
	docker buildx build -t ${REPOSITORY_NAME}:${TAG_NAME} --load .

pull:
	docker pull ${REPOSITORY_NAME}:${TAG_NAME}

push:
	docker buildx build \
	--platform linux/amd64,linux/386,linux/arm64/v8,linux/arm/v7,linux/ppc64le,linux/s390x \
	-t ${REPOSITORY_NAME}:${TAG_NAME} --push .

rmi:
	docker rmi ${REPOSITORY_NAME}:${TAG_NAME}

up:
	docker compose up -d