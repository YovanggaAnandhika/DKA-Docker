REPOSITORY_NAME=yovanggaanandhika/mariadb
TAG_NAME=latest

default:
	docker buildx build -t ${REPOSITORY_NAME}:${TAG_NAME} --load .

pull:
	docker pull ${REPOSITORY_NAME}:${TAG_NAME}

push:
	docker buildx build \
	--platform linux/amd64,linux/386,linux/arm64/v8,linux/arm/v7,linux/ppc64le,linux/s390x,linux/riscv64 \
	-t ${REPOSITORY_NAME}:${TAG_NAME} --push .