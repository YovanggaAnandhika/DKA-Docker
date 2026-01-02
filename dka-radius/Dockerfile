# Build stage for NestJS
FROM node:20-alpine AS builder
WORKDIR /app
COPY app/package*.json ./
RUN npm install
COPY app/ ./
RUN npm run build

# Final stage
FROM alpine:3.21

# Install dependencies (Node.js, FreeRADIUS, utilities)
RUN apk add --no-cache \
    nodejs \
    npm \
    freeradius \
    freeradius-utils \
    freeradius-rest \
    curl \
    iputils \
    tzdata

WORKDIR /app

# Copy NestJS build and dependencies
COPY --from=builder /app/package*.json ./
COPY --from=builder /app/node_modules ./node_modules
COPY --from=builder /app/dist ./dist
COPY --from=builder /app/src ./src

# Copy FreeRADIUS configuration
# Note: we will use volumes in docker-compose for easy editing,
# but we can also bake in defaults here if desired.
# For now, we rely on the host configs via docker-compose.

# Copy entrypoint script
COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

# Expose ports
# NestJS
EXPOSE 3000
# RADIUS Auth, Acct, CoA
EXPOSE 1812/udp 1813/udp 3799/udp

ENTRYPOINT ["/entrypoint.sh"]
