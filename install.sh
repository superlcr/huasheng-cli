#!/usr/bin/env sh
# hs 安装器。用法:
#   curl -fsSL https://raw.githubusercontent.com/superlcr/huasheng-cli/main/install.sh | sh
#
# 覆盖点(内网镜像 / 测试用):
#   HS_BASE_URL     下载地址前缀,默认 GitHub 最新 release
#   HS_INSTALL_DIR  安装目录,默认 ~/.local/bin
#
# ★ 用 sh 不用 bash:某些精简 Linux 镜像没有 bash,而这是用户见到 hs 的第一步,
#   在这里挑食等于把人挡在门外。
set -eu

REPO="${HS_REPO:-superlcr/huasheng-cli}"
BASE_URL="${HS_BASE_URL:-https://github.com/$REPO/releases/latest/download}"
INSTALL_DIR="${HS_INSTALL_DIR:-$HOME/.local/bin}"

die() { echo "错误: $*" >&2; exit 1; }

# ---- 1. 认平台 ----
OS="$(uname -s)"; ARCH="$(uname -m)"
case "$OS-$ARCH" in
  Darwin-arm64)  PLATFORM="darwin-arm64" ;;
  Darwin-x86_64) PLATFORM="darwin-x64" ;;
  Linux-x86_64)  PLATFORM="linux-x64" ;;
  *) die "还没有 $OS-$ARCH 的版本。手动下载: https://github.com/$REPO/releases/latest" ;;
esac
ASSET="hs-$PLATFORM.tar.gz"

# ---- 2. 下载 ----
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT
echo "下载 $ASSET …"
curl -fsSL "$BASE_URL/$ASSET"      -o "$TMP/$ASSET"   || die "下载失败: $BASE_URL/$ASSET"
curl -fsSL "$BASE_URL/SHA256SUMS"  -o "$TMP/SHA256SUMS" || die "下载校验和失败"

# ---- 3. 校验(失败必须中止)----
# ★ 不用 `shasum -c`:mac 是 shasum、Linux 多是 sha256sum,名字不统一;
#   而且 -c 对「文件不在清单里」的处理各家不同。自己比对最踏实。
if command -v shasum >/dev/null 2>&1; then
  ACTUAL="$(shasum -a 256 "$TMP/$ASSET" | cut -d' ' -f1)"
elif command -v sha256sum >/dev/null 2>&1; then
  ACTUAL="$(sha256sum "$TMP/$ASSET" | cut -d' ' -f1)"
else
  die "这台机器上没有 shasum 也没有 sha256sum,无法校验下载内容,已中止"
fi
# ★ 哈希工具静默失败(权限/损坏文件之类)时 ACTUAL 会是空字符串,不加这条
#   guard 会走进下面「校验不通过」分支,打印「期望 X / 实际 (空)」——看着
#   像被人动过手脚,其实只是本地算不出哈希(review Minor,与 #7 一起改)。
[ -n "$ACTUAL" ] || die "算不出下载文件的哈希(shasum/sha256sum 跑完没有输出),无法校验,已中止"
EXPECTED="$(grep " $ASSET\$" "$TMP/SHA256SUMS" | cut -d' ' -f1)"
[ -n "$EXPECTED" ] || die "校验和清单里没有 $ASSET"
if [ "$ACTUAL" != "$EXPECTED" ]; then
  die "校验不通过 —— 下载到的内容和官方发布的不一致。
  期望 $EXPECTED
  实际 $ACTUAL
这通常是下载没完整拿到,或者这个下载源不是官方的。已中止,什么都没有安装。"
fi

# ---- 4. 安装 ----
# ★ 不直接 `mv "$TMP/hs" "$INSTALL_DIR/hs"`(review Important #4):$TMP 来自
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
echo "✅ 装好了: $INSTALL_DIR/hs"
"$INSTALL_DIR/hs" --version

# ---- 5. PATH 提示 ----
case ":$PATH:" in
  *":$INSTALL_DIR:"*) ;;
  *) echo ""
     echo "⚠ $INSTALL_DIR 不在 PATH 里。把下面这行加进 ~/.zshrc 或 ~/.bashrc:"
     echo "    export PATH=\"$INSTALL_DIR:\$PATH\"" ;;
esac
echo ""
echo "下一步:  hs auth login"
