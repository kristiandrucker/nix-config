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
    nixos-rebuild --flake .\#$host switch --build-host kristian@10.1.0.97 --target-host kristian@10.1.0.97 --use-remote-sudo --use-substitutes $@
done