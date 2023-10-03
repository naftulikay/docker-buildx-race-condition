# to share default build arg values _across all build stages_, you must declare them _before_ any FROM statement, ie at
# the very beginning of your Dockerfile
ARG CACHE_VERSION=v1
ARG NODE_MODULE_CACHE_ID=com.github.naftulikay.my-repo.node-modules.${CACHE_VERSION}

# --- build stage
FROM node:18-alpine as builder

# declaring the build arg within the stage "imports" the build arg's default value to this build stage
ARG NODE_MODULE_CACHE_ID

# create the workdir
RUN install -d -m 0755 /usr/src/app /usr/src/app/dist
WORKDIR /usr/src/app

# bring in dependencies
COPY ./package.json ./package-lock.json ./

# install dependencies into the cache
RUN --mount=type=cache,id=${NODE_MODULE_CACHE_ID},target=/usr/src/app/node_modules \
    npm install && \
    touch .cookie

# copy source code files
COPY ./index.js ./

# --- runtime stage
FROM node:18-alpine

# declaring the build arg within the stage "imports" the build arg's default value to this build stage
ARG NODE_MODULE_CACHE_ID

# create the workdir
RUN install -d -m 0755 /usr/src/app
WORKDIR /usr/src/app

# copy in the empty file, forcing a dependency between stages
COPY --from=builder /usr/src/app/.cookie ./

# copy dependencies from builder stage into this stage (runtime stage)
# NOTE you absolutely do NOT want the `from` argument, it absolutely does not do what you think it does
RUN --mount=type=cache,sharing=locked,id=${NODE_MODULE_CACHE_ID},target=/builder/node_modules cp -r /builder/node_modules ./

# copy source code from builder stage into this stage (runtime stage)
COPY --from=builder /usr/src/app/index.js ./

# sanity test
COPY utils/sanity.sh ./
RUN ./sanity.sh --clean

CMD ["index"]