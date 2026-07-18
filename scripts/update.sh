#!/usr/bin/env bash
# Synchronizes the fork with upstream Aseprite (old-origin):
# 1. Checks out main branch
# 2. Pulls latest changes in main and new tags from old-origin
# 3. Pushes updated main to origin
# 4. Checks out release branch and rebases onto main
# 5. Force pushes release branch and pushes all tags to origin
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
cd "$REPO_ROOT"

if [ -n "$(git status --porcelain)" ]; then
  echo "Error: Working tree is not clean. Please commit or stash changes before running update.sh." >&2
  exit 1
fi

echo "==> Checking out main branch"
git checkout main

echo "==> Pulling changes in main from old-origin remote"
git pull old-origin main

echo "==> Fetching new tags from old-origin remote"
git fetch --tags old-origin

echo "==> Pushing main branch to origin"
git push origin main

echo "==> Checking out release branch"
git checkout release

echo "==> Rebasing release from main"
git rebase main

echo "==> Force pushing release branch to origin"
git push --force origin release

echo "==> Pushing all tags to origin"
git push origin --tags

echo "==> Update complete! Successfully rebased and pushed release and tags."
