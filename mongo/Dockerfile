# Gunakan base image Alpine
FROM alpine:3.18

# Update repositori
RUN apk update

# Install dependencies yang diperlukan untuk build MongoDB
RUN apk add --no-cache build-base
RUN apk add --no-cache curl
RUN apk add --no-cache git
RUN apk add --no-cache openssl-dev
RUN apk add --no-cache zlib-dev
RUN apk add --no-cache python3
RUN apk add --no-cache py3-setuptools
RUN apk add --no-cache py3-pip
RUN apk add --no-cache scons
RUN apk add --no-cache python3-dev
RUN apk add --no-cache musl-dev
RUN apk add --no-cache linux-headers

# Install mongo-tooling-metrics
RUN pip install mongo-tooling-metrics
RUN pip install psutil
RUN pip install jsonschema
RUN pip install memory-profiler
RUN pip install puremagic
RUN pip install networkx
RUN pip install cxxfilt

# Tentukan variabel lingkungan
ENV MONGO_MAJOR=8.0
# Tentukan variabel lingkungan
ARG MONGO_VERSION=8.0.0

# Clone MongoDB source code dari GitHub
RUN git clone --branch r${MONGO_VERSION} --depth 1 https://github.com/mongodb/mongo.git /mongo

# Masuk ke direktori source MongoDB
WORKDIR /mongo

# Compile MongoDB
RUN scons --ssl --release --use-system-zlib --prefix=/usr install -j $(nproc)

# Hapus file yang tidak diperlukan setelah kompilasi
RUN rm -rf /mongo

# Hapus paket-paket build dependencies untuk mengurangi ukuran image
RUN apk del git
RUN apk del build-base

# Tentukan entrypoint
ENTRYPOINT ["/usr/bin/mongod"]
