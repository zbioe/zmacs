# refresh recipe inputs, then rewrite ./lock from them
update:
    nix run .#update
lock:
    nix run .#lock

# run the built Emacs
run:
    nix run .#emacs

# dry-build the Emacs closure
check:
    nix build .#emacs --dry-run
