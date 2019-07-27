#!/bin/sh
export GOPROXY=https://proxy.golang.org/
export GO111MODULE=on

go run github.com/kudobuilder/kudo/cmd/kubectl-kudo test --artifacts-dir "$ARTIFACTS" $@
