REPOSITORY_NAME=yovanggaanandhika/mongo
TAG_NAME=12-slim-mongo-node-8.0.5

default:
	docker buildx build -t ${REPOSITORY_NAME}:${TAG_NAME} --load .

pull:
	docker pull ${REPOSITORY_NAME}:${TAG_NAME}

push:
	docker buildx build \
	--platform linux/amd64 \
	-t ${REPOSITORY_NAME}:${TAG_NAME} --push .