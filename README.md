# docker-buildx-race-condition

Repository demonstrating a race condition in Docker's build/buildx system.

## Background

When trying to create a demonstration of using a shared build cache across multi-stage images, I encountered a very
strange problem: for some reason, `docker buildx build` _seems_ to be building the first-stage (`builder`)
**simultaneously** with the second/final stage, even though the second stage declares a `COPY --from=builder`,
indicating the dependency.

The issue seems to arise out of the ordering of two statements in the second stage:

```dockerfile
RUN --mount=type=cache,... command
COPY --from=builder /usr/src/index.js ./
```

For some reason, if the `RUN --mount` statement comes before the `COPY --from=builder` statement, buildx does not see
the dependency between the stages and simply **attempts to run both stages simultaneously**, which could not ever
possibly work. Even specifying `sharing=locked` on the `RUN --mount` cache does not seem to fix the issue.

## Reproducing

Two `Dockerfile`s are provided in this repository, `Dockerfile`, and `Dockerfile.workaround`. Here is the difference
between these two versions:

<details>
<summary>Dockerfile Diff</summary>

```diff
diff --git a/Dockerfile b/Dockerfile.workaround
index e71c957..735f12d 100644
--- a/Dockerfile
+++ b/Dockerfile.workaround
@@ -20,7 +20,8 @@ COPY ./package.json ./package-lock.json ./
 RUN echo "*** cache id: ${NODE_MODULE_CACHE_ID}"
 RUN --mount=type=cache,sharing=locked,id=${NODE_MODULE_CACHE_ID},target=/usr/src/app/node_modules \
     rm -fr node_modules/* && \
-    npm install
+    npm install && \
+    touch .cookie
 
 # copy source code files
 COPY ./index.js ./
@@ -35,6 +36,10 @@ ARG NODE_MODULE_CACHE_ID
 RUN install -d -m 0755 /usr/src/app
 WORKDIR /usr/src/app
 
+# FIXME here comes the workaround: we create .cookie in the first stage and copy it _before_ calling `RUN --mount`.
+#       placing a COPY --from before the RUN --mount seems to fix the ordering bug
+COPY --from=builder /usr/src/app/.cookie ./
+
 # copy dependencies from builder stage into this stage (runtime stage)
 # NOTE you absolutely do NOT want the `from` argument, it absolutely does not do what you think it does
 RUN echo "*** cache id: ${NODE_MODULE_CACHE_ID}"
```

</details>

A `Makefile` is present, with a few useful targets:

 - `clean`: runs `docker buildx purge -f`
 - `version`: outputs the version of Docker and the buildx plugin
 - `demo`: demonstrates the race condition with in `Dockerfile`
 - `workaround`: demonstrates the workaround in `Dockerfile.workaround`

My local versions of Docker and the buildx plugin are:

```text
docker --version
Docker version 24.0.6, build ed223bc
docker buildx version
github.com/docker/buildx v0.11.2 9872040
```

I have included logs for the invocation of both the bug and the workaround:

 - `make clean demo`: [`logs/bug.log`](./logs/bug.log)
 - `make clean workaround`: [`logs/workaround.log`](./logs/workaround.log)

## License

Licensed at your discretion under either:

 - [Apache Software License, Version 2.0](./LICENSE-APACHE)
 - [MIT License](./LICENSE-MIT)