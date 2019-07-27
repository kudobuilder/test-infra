#!/bin/sh
set -e

# We can replace this installation with fetching a pre-built binary once a release happens.

apk update && apk add go git musl-dev

./test.sh
