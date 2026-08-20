#!/usr/bin/env sh
# The hs installer. Usage:
#   curl -fsSL https://raw.githubusercontent.com/superlcr/huasheng-cli/main/install.sh | sh
#
# Overrides (private mirror / testing):
#   HS_BASE_URL     where to download from, default the latest GitHub release
#   HS_INSTALL_DIR  where to install, default ~/.local/bin
#
# ★ sh, not bash: some minimal Linux images have no bash, and this is the very
#   first thing anyone runs. Being fussy here just turns people away.
set -eu

REPO="${HS_REPO:-superlcr/huasheng-cli}"
BASE_URL="${HS_BASE_URL:-https://github.com/$REPO/releases/latest/download}"
INSTALL_DIR="${HS_INSTALL_DIR:-$HOME/.local/bin}"

die() { echo "Error: $*" >&2; exit 1; }

# ---- 1. 认平台 ----
OS="$(uname -s)"; ARCH="$(uname -m)"
case "$OS-$ARCH" in
  Darwin-arm64)  PLATFORM="darwin-arm64" ;;
  Darwin-x86_64) PLATFORM="darwin-x64" ;;
  Linux-x86_64)  PLATFORM="linux-x64" ;;
  *) die "There is no build for $OS-$ARCH yet. Download one manually: https://github.com/$REPO/releases/latest" ;;
esac
ASSET="hs-$PLATFORM.tar.gz"

# ---- 2. 下载 ----
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT
echo "Downloading $ASSET ..."
curl -fsSL "$BASE_URL/$ASSET"      -o "$TMP/$ASSET"   || die "Download failed: $BASE_URL/$ASSET"
curl -fsSL "$BASE_URL/SHA256SUMS"  -o "$TMP/SHA256SUMS" || die "Could not download the checksum file"

# ---- 3. 校验(失败必须中止)----
# ★ 不用 `shasum -c`:mac 是 shasum、Linux 多是 sha256sum,名字不统一;
#   而且 -c 对「文件不在清单里」的处理各家不同。自己比对最踏实。
if command -v shasum >/dev/null 2>&1; then
  ACTUAL="$(shasum -a 256 "$TMP/$ASSET" | cut -d' ' -f1)"
elif command -v sha256sum >/dev/null 2>&1; then
  ACTUAL="$(sha256sum "$TMP/$ASSET" | cut -d' ' -f1)"
else
  die "Neither shasum nor sha256sum is available, so the download cannot be verified. Stopping."
fi
# ★ 哈希工具静默失败(权限/损坏文件之类)时 ACTUAL 会是空字符串,不加这条
#   guard 会走进下面「校验不通过」分支,打印「期望 X / 实际 (空)」——看着
#   像被人动过手脚,其实只是本地算不出哈希。
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

# ---- 4. 安装 ----
# ★ 不直接 `mv "$TMP/hs" "$INSTALL_DIR/hs"`:$TMP 来自
#   `mktemp -d`,多数 Linux 发行版 /tmp 是 tmpfs,而 $INSTALL_DIR 在 $HOME ——
#   跨文件系统时 `mv` 会退化成"拷贝再删源文件",不是原子操作。拷贝中途被打断
#   (Ctrl-C/磁盘满)会在 PATH 上留下一个半截的可执行文件,比装失败更糟,
#   而且 `hs upgrade` 时目标文件正在被执行,自我覆盖更容易撞上这条路径。
#   改法:先拷进目标目录里的一个临时名,再在**同一个目录内** rename ——
#   同目录 rename 在任何文件系统上都是原子的,拷贝失败也不会碰到 `hs` 这个名字。
mkdir -p "$INSTALL_DIR"
tar -xzf "$TMP/$ASSET" -C "$TMP"
chmod +x "$TMP/hs"
STAGE_FILE="$INSTALL_DIR/.hs.new.$$"
trap 'rm -rf "$TMP"; rm -f "$STAGE_FILE"' EXIT
cp "$TMP/hs" "$STAGE_FILE"
mv "$STAGE_FILE" "$INSTALL_DIR/hs"
echo "Installed: $INSTALL_DIR/hs"
"$INSTALL_DIR/hs" --version

# ---- 5. PATH 提示 ----
case ":$PATH:" in
  *":$INSTALL_DIR:"*) ;;
  *) echo ""
     echo "Note: $INSTALL_DIR is not on your PATH. Add this line to ~/.zshrc or ~/.bashrc:"
     echo "    export PATH=\"$INSTALL_DIR:\$PATH\"" ;;
esac
echo ""
echo "Next:  hs auth login"
