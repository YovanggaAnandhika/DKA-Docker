FROM alpine:3.21.0
# Maintainer
LABEL maintainer="Yovangga Anandhika <dka.tech.dev@gmail.com>"
# Install Require Apt
RUN apk update && apk add --no-cache openjdk21 bash git curl unzip openjdk21
# Install Gradle by downloading the distribution
RUN curl -L https://services.gradle.org/distributions/gradle-8.5-bin.zip -o gradle.zip && unzip gradle.zip &&  \
    mv gradle-8.5 /opt/gradle && ln -s /opt/gradle/bin/gradle /usr/local/bin/gradle && rm gradle.zip
# Configure entrypoint script
COPY entrypoint.sh /usr/local/bin/entrypoint.sh
# set Execution bin dir
RUN chmod +x /usr/local/bin/*
# Set Working Dir
WORKDIR /app
# Set the entrypoint to the script
ENTRYPOINT ["entrypoint.sh"]