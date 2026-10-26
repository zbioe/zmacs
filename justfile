# refresh recipe inputs and the GNU ELPA mirror's commit, then rewrite ./lock
update:
    #!/usr/bin/env bash
    set -euo pipefail
    rev=$(git ls-remote https://github.com/d12frosted/elpa-mirror refs/heads/master | cut -f1)
    sed -i "s|elpa-mirror/[0-9a-f]\{40\}/|elpa-mirror/$rev/|" flake.nix twist.nix
    nix run .#update
lock:
    nix run .#lock

# run the built Emacs
run:
    nix run .#emacs

# dry-build the Emacs closure
check:
    nix build .#emacs --dry-run
