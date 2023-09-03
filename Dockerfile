# WARNING:
#
# For development and debugging only. Use Dockerfile.release for production.
#
# This image bundles rTorrent for easier debugging. It is not started by default.
# Use --rtorrent argument if you wish to start the bundled rTorrent.
# For production, use rtorrent-flood instead.
#
# This Dockerfile uses contents of current folder which might contain
# secrets, uncommitted changes or other sensitive information. DO NOT
# publish the result image unless it was composed in a clean environment.

ARG BUILDPLATFORM=amd64
ARG NODE_IMAGE=docker.io/node:alpine

FROM --platform=$BUILDPLATFORM ${NODE_IMAGE} AS nodebuild

WORKDIR /usr/src/app/

# Copy project files
COPY . ./

RUN corepack enable && corepack install

# Fetch dependencies from npm
RUN pnpm install --frozen-lockfile

# Build assets
RUN npm run build

# Now get the clean Node.js image
FROM ${NODE_IMAGE} AS flood

WORKDIR /usr/src/app/

# Copy sources
COPY --from=nodebuild /usr/src/app ./

# Install runtime dependencies
RUN apk --no-cache add \
    mediainfo \
    tini

# Create "download" user
RUN adduser -h /home/download -s /sbin/nologin --disabled-password download

# Run as "download" user
USER download

# Expose port 3000 and 4200
EXPOSE 3000

ENV FLOOD_OPTION_HOST="0.0.0.0"
ENTRYPOINT ["/sbin/tini", "--", "npm", "start"]
