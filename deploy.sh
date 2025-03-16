#!/usr/bin/env bash
export NIX_SSHOPTS="-A"

build_remote=false

hosts="$1"
shift

if [ -z "$hosts" ]; then
    echo "No hosts to deploy"
    exit 2
fi

for host in ${hosts//,/ }; do
    nixos-rebuild --fast --flake .\#$host switch --target-host 10.1.0.81 --build-host 10.1.0.81 --use-remote-sudo --use-substitutes
done