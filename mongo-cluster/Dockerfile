FROM debian:12

RUN apt-get update
RUN apt-get install -y gnupg curl

RUN curl -fsSL https://www.mongodb.org/static/pgp/server-8.0.asc | gpg -o /usr/share/keyrings/mongodb-server-8.0.gpg --dearmor
RUN echo "deb [ signed-by=/usr/share/keyrings/mongodb-server-8.0.gpg ] http://repo.mongodb.org/apt/debian bookworm/mongodb-org/8.0 main" | tee /etc/apt/sources.list.d/mongodb-org-8.0.list

RUN apt-get update
RUN apt-get install -y mongodb-org

EXPOSE 27017

CMD ["mongod"]
