# zmacs

A reproducible Emacs, built from source with [twist.nix](https://github.com/emacs-twist/twist.nix).
Every package is locked in `lock/`, so the whole editor is pinned by the flake —
nothing is fetched at startup.

## Use it

```sh
nix run github:zbioe/zmacs        # try it
```

As a flake input (what [dotnix](https://github.com/zbioe/dotnix) does):

```nix
inputs.zmacs.url = "github:zbioe/zmacs";

# in a home-manager module
imports = [ inputs.zmacs.homeModules.default ];
programs.emacs-twist = {
  enable = true;
  name = "zmacs";
  config = inputs.zmacs.packages.${pkgs.system}.emacs;
  earlyInitFile = ... ;             # or let dotnix point at this repo's
  serviceIntegration.enable = true; # the daemon
  emacsclient.enable = true;
};
```

## Develop

The config is plain Emacs Lisp:

- `init.el` — `use-package` declarations; twist reads `:ensure t` to know the
  package set.
- `early-init.el` — pre-UI setup.

After changing which packages are used, rewrite the lock:

```sh
nix run .#update   # refresh the recipe inputs (melpa, elpa, ...)
nix run .#lock     # rewrite ./lock from them
nix run .#emacs    # run the result
```

Colours follow dotnix's `theme` when its state file is present, otherwise a
built-in fallback.

## Layout

```
flake.nix     inputs and outputs (packages.emacs, apps lock/update, homeModule)
twist.nix     the twist config: init files, lock dir, package registries
init.el       the editor
early-init.el pre-UI
lock/         the package lockfiles (generated)
```
