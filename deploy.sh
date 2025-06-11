#!/usr/bin/env bash
export NIX_SSHOPTS="-A"

build_remote=false

hosts="$1"
shift

if [ -z "$hosts" ]; then
    echo "No hosts to deploy"
    exit 2
fi

# Add --impure to allow access to untracked files
for host in ${hosts//,/ }; do
#    nixos-rebuild --fast --flake .\#$host switch --target-host 10.1.0.72 --build-host 10.1.0.72 --use-remote-sudo --use-substitutes --impure
    nixos-rebuild --fast --flake .\#$host switch --target-host $host.ts.drkr.io --build-host $host.ts.drkr.io --use-remote-sudo --use-substitutes
#    nixos-rebuild --fast --flake .\#$host switch --target-host 10.1.0.206 --build-host cache.drkr.io --use-remote-sudo --use-substitutes
done
