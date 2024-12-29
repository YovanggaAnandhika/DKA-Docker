# syntax=docker/dockerfile:1.4
FROM alpine:3.21.0
# Set Go version
ARG GO_VERSION=1.22.10
# Use TARGETOS and TARGETARCH to construct the download URL
ARG TARGETOS
ARG TARGETARCH
# Declare User Use
USER root
# Install required tools
RUN apk add --no-cache bash curl tar make protobuf-dev gcompat
# Construct download URL
ENV DOWNLOAD_URL="https://go.dev/dl/go${GO_VERSION}.${TARGETOS}-${TARGETARCH}.tar.gz"
# Check if the file exists on the host before downloading it
RUN curl --head --silent --fail "$DOWNLOAD_URL" || { echo "arch not supported: $DOWNLOAD_URL"; exit 1; }
# Download Go binary if the file exists
RUN curl -LO "$DOWNLOAD_URL"
# Extract Tar.gz to /use/local
RUN tar -C /usr/local -xvzf "go${GO_VERSION}.${TARGETOS}-${TARGETARCH}.tar.gz"
# Remove Binary
RUN rm -rf "go${GO_VERSION}.${TARGETOS}-${TARGETARCH}.tar.gz"
# Set Go environment variables
ENV GOPATH=/root/go
ENV PATH="$PATH:/usr/local/go/bin"
ENV PATH="$PATH:$GOPATH/bin"
# Verify Go installation
CMD ["go version"]
