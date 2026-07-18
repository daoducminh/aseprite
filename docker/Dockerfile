# syntax=docker/dockerfile:1
# Builds Aseprite for Linux x64 inside a container.
# Usage: see docker/build.sh (handles image build, container run, and
# copying the resulting binary out to ./output on the host). Build context
# must be the repository root, e.g.: docker build -f docker/Dockerfile .
#
# Multi-stage: the "build" stage does the heavy lifting (compiler, headers,
# Skia, object files); only the final binaries are copied into a tiny
# "export" stage, so the image you actually keep around is small.

FROM debian:bookworm-slim AS build

RUN --mount=type=cache,target=/var/cache/apt,sharing=locked \
    --mount=type=cache,target=/var/lib/apt,sharing=locked \
    apt-get update && apt-get install -y --no-install-recommends \
      g++ clang cmake ninja-build \
      libx11-dev libxcursor-dev libxi-dev libxrandr-dev \
      libgl1-mesa-dev libfontconfig1-dev \
      ca-certificates curl unzip git

ARG SKIA_URL=https://github.com/aseprite/skia/releases/download/m124-08a5439a6b/Skia-Linux-Release-x64.zip

RUN mkdir -p /deps/skia \
    && curl -fsSL "$SKIA_URL" -o /tmp/skia.zip \
    && unzip -q /tmp/skia.zip -d /deps/skia \
    && rm /tmp/skia.zip

WORKDIR /src
COPY . .

ARG VERSION=""
RUN if [ -n "$VERSION" ]; then \
      echo "==> Checking out $VERSION" \
      && (git rev-parse --verify --quiet "refs/tags/${VERSION}" >/dev/null \
          || git fetch --tags --depth 1 origin "refs/tags/${VERSION}:refs/tags/${VERSION}" \
          || git fetch --tags) \
      && git checkout "$VERSION"; \
    fi

RUN git submodule update --init --recursive --depth 1

RUN --mount=type=cache,target=/src/build \
    mkdir -p build && cd build \
    && cmake \
      -DCMAKE_BUILD_TYPE=RelWithDebInfo \
      -DLAF_BACKEND=skia \
      -DSKIA_DIR=/deps/skia \
      -DSKIA_LIBRARY_DIR=/deps/skia/out/Release-x64 \
      -DSKIA_LIBRARY=/deps/skia/out/Release-x64/libskia.a \
      -G Ninja \
      .. \
    && ninja aseprite \
    && mkdir -p /output && cp -a bin/. /output/

FROM scratch AS export
COPY --from=build /output /out/
