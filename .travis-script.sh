#!/usr/bin/env bash
set -e
set -o pipefail
set -x

source .travis-common.sh

MAKEFLAGS+=("CFLAGS=-g -O0 -Werror -Wall")

clang-tidy() {
  clang-tidy${CC:5} "$@" >tmp-tidy-results || true
  set +x
  if grep -q ' \(warning\|error\):' tmp-tidy-results; then
    echo "########## $1 ##########" >> tidy-results
    cat tmp-tidy-results >> tidy-results
  fi
  set -x
}

if [ "$LINT" = "1" ]; then
  make "${MAKEFLAGS[@]}" all
  touch tidy-results
  for file in $(find include src -name \*.c -or -name \*.h); do
    clang-tidy "$file" -- -std=gnu11 -I.pblog/include -I"$LOCAL_PREFIX"/include
  done
  for file in $(find test -name \*.cc -or -name \*.hh); do
    clang-tidy "$file" -- -std=gnu++11 -I.pblog/include -I"$LOCAL_PREFIX"/include
  done
  set +x
  if [ -s "tidy-results" ]; then
    cat tidy-results
    exit 1
  fi
  set -x
else
  # Make sure we can build against installed nanopb
  make "${MAKEFLAGS[@]}" all
  make "${MAKEFLAGS[@]}" GTEST_DIR="$LOCAL_PREFIX" check
  make "${MAKEFLAGs[@]}" PREFIX="$LOCAL_PREFIX" install

  test -f "$LOCAL_PREFIX"/lib/libpblog.so
  test -f "$LOCAL_PREFIX"/lib/libpblog.a
  test -d "$LOCAL_PREFIX"/include/pblog

  # Make sure we can build against nanopb src
  rm -rf "$LOCAL_PREFIX"/{include/pblog,lib/libpblog.{so,a}}
  make "${MAKEFLAGS[@]}" clean
  make "${MAKEFLAGS[@]}" NANOPB_SRC_DIR=../nanopb all
  make "${MAKEFLAGS[@]}" NANOPB_SRC_DIR=../nanopb GTEST_DIR="$LOCAL_PREFIX" check
  make "${MAKEFLAGs[@]}" NANOPB_SRC_DIR=../nanopb PREFIX="$LOCAL_PREFIX" install

  test -f "$LOCAL_PREFIX"/lib/libpblog.so
  test -f "$LOCAL_PREFIX"/lib/libpblog.a
  test -d "$LOCAL_PREFIX"/include/pblog
fi
