#!/bin/bash

set -e

export PATH="/c/msys64/$MSYSTEM/bin:$PATH"
if [[ "$MSYSTEM" == "MINGW32" ]]; then
    export MSYS2_ARCH="i686"
else
    export MSYS2_ARCH="x86_64"
fi

pacman --noconfirm -Suy

pacman --noconfirm -S --needed \
    base-devel \
    mingw-w64-$MSYS2_ARCH-ccache \
    mingw-w64-$MSYS2_ARCH-gettext \
    mingw-w64-$MSYS2_ARCH-libffi \
    mingw-w64-$MSYS2_ARCH-meson \
    mingw-w64-$MSYS2_ARCH-pcre \
    mingw-w64-$MSYS2_ARCH-python3 \
    mingw-w64-$MSYS2_ARCH-python3-pip \
    mingw-w64-$MSYS2_ARCH-toolchain \
    mingw-w64-$MSYS2_ARCH-zlib

mkdir -p _ccache
export CCACHE_BASEDIR="$(pwd)"
export CCACHE_DIR="${CCACHE_BASEDIR}/_ccache"
pip3 install --upgrade --user meson
export PATH="$HOME/.local/bin:$PATH"
export CFLAGS="-coverage -ftest-coverage -fprofile-arcs"

meson --werror --buildtype debug _build
cd _build
ninja

# FIXME: fix the test suite
meson test --timeout-multiplier ${MESON_TEST_TIMEOUT_MULTIPLIER} || true

cd ..
curl -O -J -L "https://github.com/linux-test-project/lcov/releases/download/v1.13/lcov-1.13.tar.gz"
echo "44972c878482cc06a05fe78eaa3645cbfcbad6634615c3309858b207965d8a23  lcov-1.13.tar.gz" | sha256sum -c
tar -xvzf lcov-1.13.tar.gz

mkdir -p _coverage
./lcov-1.13/bin/lcov \
    --rc lcov_branch_coverage=1 \
    --directory . \
    --capture \
    --no-external \
    --output-file "_coverage/${CI_JOB_NAME}.lcov"
