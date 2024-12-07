FROM mongo:latest

RUN openssl rand -base64 756 > /etc/mongo-keyfile
RUN chmod 400 /etc/mongo-keyfile
RUN chown mongodb:mongodb /etc/mongo-keyfile

COPY ./etc/mongod.conf /etc/mongod.conf

COPY docker-entrypoint-initdb.d/* ./docker-entrypoint-initdb.d/

# Expose default port
EXPOSE 27017

CMD ["mongod","--config","/etc/mongod.conf"]