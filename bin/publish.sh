#!/bin/bash
# Publish every workspace package at the root package.json version.
# Adapted from tilia's bin/publish.sh: same clean-tree check and local
# registry handling; no build step, no beta/canary, no GitHub release.
#
#   ./bin/publish.sh             publish and tag v<version>
#   ./bin/publish.sh --dry-run   pack and list, publish nothing

set -e
cd "$(dirname "$0")/.."

PACKAGES=(db radifdb)

DRY_RUN=()
[[ $1 == "--dry-run" ]] && DRY_RUN=(--dry-run)

if ! command -v pnpm &>/dev/null; then
  echo "pnpm is not installed. Please install it first."
  exit 1
fi

if [[ -z ${DRY_RUN[*]} && -n "$(git status --porcelain)" ]]; then
  echo "Error: There are uncommitted changes in the repository."
  echo "Please commit or stash your changes before proceeding."
  exit 1
fi

VERSION=$(npm pkg get version | sed 's/"//g')
if ! [[ "$VERSION" =~ ^[0-9]+\.[0-9]+\.[0-9]+(-[a-zA-Z0-9.]+)?$ ]]; then
  echo "Invalid SemVer: $VERSION"
  exit 1
fi

# Same as tilia: a local registry (verdaccio) admits anonymous publish,
# but npm refuses to send one without a credential for the host. Give it
# a throwaway token for the run. npmjs keeps the real ~/.npmrc token.
REGISTRY=$(npm config get registry)
REGISTRY=${REGISTRY%/}
PUBLISH_ARGS=()
case "$REGISTRY" in
"" | *registry.npmjs.org*) ;;
*)
  NPMRC=$(mktemp)
  trap 'rm -f "$NPMRC"' EXIT
  printf '//%s/:_authToken="local"\n' "${REGISTRY#*://}" >"$NPMRC"
  export NPM_CONFIG_USERCONFIG=$NPMRC
  PUBLISH_ARGS=(--registry "$REGISTRY")
  ;;
esac
echo "Publishing $VERSION to ${REGISTRY:-https://registry.npmjs.org} ${DRY_RUN[*]}"

for pkg in "${PACKAGES[@]}"; do
  (
    cd "$pkg"
    npm --no-git-tag-version --allow-same-version version "$VERSION" >/dev/null
    pnpm publish --access public --no-git-checks "${PUBLISH_ARGS[@]}" "${DRY_RUN[@]}"
  )
done

# The version bump in each package must not linger.
git rev-parse -q --verify HEAD >/dev/null && git checkout -- "${PACKAGES[@]/%//package.json}"

if [[ -z ${DRY_RUN[*]} ]]; then
  git tag "v$VERSION"
  echo "Published $VERSION and tagged v$VERSION."
else
  echo "Dry run done. Nothing published."
fi
