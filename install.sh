#!/usr/bin/env sh
# The hs installer. Usage:
#   curl -fsSL https://raw.githubusercontent.com/superlcr/huasheng-cli/main/install.sh | sh
#
# Overrides (private mirror / testing):
#   HS_BASE_URL     where to download from, default the latest GitHub release
#   HS_INSTALL_DIR  where to install, default ~/.local/bin
#
# sh, not bash: some minimal Linux images have no bash, and this is the very first
# thing anyone runs. Being fussy here just turns people away.
set -eu

REPO="${HS_REPO:-superlcr/huasheng-cli}"
BASE_URL="${HS_BASE_URL:-https://github.com/$REPO/releases/latest/download}"
INSTALL_DIR="${HS_INSTALL_DIR:-$HOME/.local/bin}"

die() { echo "Error: $*" >&2; exit 1; }

# ---- 1. Identify the platform ----
OS="$(uname -s)"; ARCH="$(uname -m)"
case "$OS-$ARCH" in
  Darwin-arm64)  PLATFORM="darwin-arm64" ;;
  Darwin-x86_64) PLATFORM="darwin-x64" ;;
  Linux-x86_64)  PLATFORM="linux-x64" ;;
  *) die "There is no build for $OS-$ARCH yet. Download one manually: https://github.com/$REPO/releases/latest" ;;
esac
ASSET="hs-$PLATFORM.tar.gz"

# ---- 2. Download ----
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT
echo "Downloading $ASSET ..."
curl -fsSL "$BASE_URL/$ASSET"      -o "$TMP/$ASSET"   || die "Download failed: $BASE_URL/$ASSET"
curl -fsSL "$BASE_URL/SHA256SUMS"  -o "$TMP/SHA256SUMS" || die "Could not download the checksum file"

# ---- 3. Verify (a failure must stop the install) ----
# Not `shasum -c`: the tool is called shasum on macOS and usually sha256sum on Linux, and
# the two disagree about what -c does when a file is missing from the list. Comparing the
# digests ourselves is the one thing that behaves the same everywhere.
if command -v shasum >/dev/null 2>&1; then
  ACTUAL="$(shasum -a 256 "$TMP/$ASSET" | cut -d' ' -f1)"
elif command -v sha256sum >/dev/null 2>&1; then
  ACTUAL="$(sha256sum "$TMP/$ASSET" | cut -d' ' -f1)"
else
  die "Neither shasum nor sha256sum is available, so the download cannot be verified. Stopping."
fi
# If the hashing tool fails quietly (a permissions problem, a truncated file), ACTUAL ends
# up empty. Without this guard we would fall into the mismatch branch below and print
# "expected X / actual (nothing)" — which reads like the download was tampered with, when
# in fact the digest simply could not be computed locally.
[ -n "$ACTUAL" ] || die "The checksum tool produced no output, so the download cannot be verified. Stopping."
EXPECTED="$(grep " $ASSET\$" "$TMP/SHA256SUMS" | cut -d' ' -f1)"
[ -n "$EXPECTED" ] || die "$ASSET is not listed in SHA256SUMS"
if [ "$ACTUAL" != "$EXPECTED" ]; then
  die "Checksum mismatch: what was downloaded is not what was published.
  expected $EXPECTED
  actual   $ACTUAL
Usually the download was incomplete, or this is not the official source.
Stopping. Nothing has been installed."
fi

# ---- 4. Install ----
# Not a plain `mv "$TMP/hs" "$INSTALL_DIR/hs"`: $TMP comes from `mktemp -d`, /tmp is tmpfs
# on most Linux distributions, and $INSTALL_DIR lives under $HOME. Across filesystems `mv`
# degrades into "copy, then unlink the source", which is not atomic. Interrupt that copy
# (Ctrl-C, a full disk) and you are left with a half-written executable sitting on the PATH
# — worse than a failed install. `hs upgrade` makes it likelier still, because the target
# file is being executed while it is overwritten.
# So: copy to a temporary name *inside the destination directory*, then rename within that
# same directory. A same-directory rename is atomic on every filesystem, and a failed copy
# never touches the name `hs`.
mkdir -p "$INSTALL_DIR"
tar -xzf "$TMP/$ASSET" -C "$TMP"
chmod +x "$TMP/hs"
STAGE_FILE="$INSTALL_DIR/.hs.new.$$"
trap 'rm -rf "$TMP"; rm -f "$STAGE_FILE"' EXIT
cp "$TMP/hs" "$STAGE_FILE"
mv "$STAGE_FILE" "$INSTALL_DIR/hs"
echo "Installed: $INSTALL_DIR/hs"
"$INSTALL_DIR/hs" --version

# ---- 5. PATH hint ----
case ":$PATH:" in
  *":$INSTALL_DIR:"*) ;;
  *) echo ""
     echo "Note: $INSTALL_DIR is not on your PATH. Add this line to ~/.zshrc or ~/.bashrc:"
     echo "    export PATH=\"$INSTALL_DIR:\$PATH\"" ;;
esac
echo ""
echo "Next:  hs auth login"
