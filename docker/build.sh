#!/usr/bin/env bash
# Builds Aseprite inside a Docker container and copies the resulting
# binary + data files out to ./output on the host.
#
# Usage: ./docker/build.sh [git-tag]
#   e.g. ./docker/build.sh v1.3.9.1
# With no argument, builds whatever is currently checked out.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
cd "$REPO_ROOT"

VERSION="${1:-}"
IMAGE_TAG=aseprite-build
CONTAINER_NAME=aseprite-build-tmp
OUTPUT_DIR=output

echo "==> Building Docker image ($IMAGE_TAG)${VERSION:+ for $VERSION}"
DOCKER_BUILDKIT=1 docker build -f docker/Dockerfile --target export --build-arg VERSION="$VERSION" -t "$IMAGE_TAG" .

echo "==> Creating temporary container"
docker rm -f "$CONTAINER_NAME" >/dev/null 2>&1 || true
# scratch image has no CMD/entrypoint; a dummy command is required to
# create the container, but it's never executed since we only `docker cp`.
docker create --name "$CONTAINER_NAME" "$IMAGE_TAG" nonexistent >/dev/null

echo "==> Copying build output to ./$OUTPUT_DIR"
rm -rf "$OUTPUT_DIR"
mkdir -p "$OUTPUT_DIR"
docker cp "$CONTAINER_NAME:/out/." "$OUTPUT_DIR/"

echo "==> Cleaning up temporary container"
docker rm -f "$CONTAINER_NAME" >/dev/null

echo "==> Done. Aseprite binary at: $OUTPUT_DIR/aseprite"
