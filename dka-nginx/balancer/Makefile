REPOSITORY_NAME=yovanggaanandhika/nginx
TAG_NAME=loadbalancer

default:
	docker buildx build \
	--platform linux/amd64,linux/386,linux/arm64/v8,linux/ppc64le,linux/riscv64 \
	-t ${REPOSITORY_NAME}:${TAG_NAME} --push .