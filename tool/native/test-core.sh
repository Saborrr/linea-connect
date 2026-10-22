#!/usr/bin/env bash
set -euo pipefail
core_dir=${1:?Pass the prepared core source directory}
cd "$core_dir"
go test -mod=mod -ldflags=-checklinkname=0 -v -count=1 -timeout=3m -tags with_awg,with_gvisor,with_wireguard \
  github.com/sagernet/sing-box/protocol/awg \
  github.com/sagernet/sing-box/transport/awg

go test -mod=mod -ldflags=-checklinkname=0 -v -count=1 -timeout=3m -tags with_awg,with_gvisor,with_wireguard \
  -run TestLinea_Awg31Import github.com/hiddify/ray2sing/ray2sing
