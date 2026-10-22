{
  description = "zmacs: a reproducible Emacs built from source with twist.nix";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    systems.url = "github:nix-systems/default";
    twist.url = "github:emacs-twist/twist.nix";

    # package recipe sources, locked into ./lock
    melpa = {
      url = "github:melpa/melpa";
      flake = false;
    };
    gnu-elpa = {
      url = "github:elpa-mirrors/elpa";
      flake = false;
    };
    nongnu = {
      url = "github:elpa-mirrors/nongnu";
      flake = false;
    };
    epkgs = {
      url = "github:emacsmirror/epkgs";
      flake = false;
    };
    gnu-elpa-archive = {
      url = "file+https://raw.githubusercontent.com/d12frosted/elpa-mirror/master/gnu/archive-contents";
      flake = false;
    };
  };

  outputs =
    {
      nixpkgs,
      systems,
      twist,
      self,
      ...
    }@inputs:
    let
      eachSystem =
        f:
        nixpkgs.lib.genAttrs (import systems) (
          system: f system nixpkgs.legacyPackages.${system}
        );
    in
    {
      packages = eachSystem (
        system: pkgs:
        let
          emacsPackage = pkgs.emacs-pgtk;
          twistConfig = import ./twist.nix { inherit inputs pkgs emacsPackage; };
          emacs = twist.lib.makeEnv twistConfig;

          # natives twist doesn't build well (compiled modules, grammars) come
          # from nixpkgs and are put on the load-path by early-init.el
          emacsPkgs = pkgs.emacsPackagesFor emacsPackage;
          grammars = emacsPkgs.treesit-grammars.with-all-grammars;
          nixElpa = pkgs.lib.concatStringsSep ":" [
            "${emacsPkgs.vterm}/share/emacs/site-lisp/elpa"
            "${emacsPkgs.pdf-tools}/share/emacs/site-lisp/elpa"
            "${emacsPkgs.mu4e}/share/emacs/site-lisp/elpa"
          ];

          # the init.el twist would write, concatenated from initFiles
          initFile = pkgs.runCommandLocal "zmacs-init" { } ''
            mkdir -p $out
            : > $out/init.el
            for f in ${builtins.concatStringsSep " " twistConfig.initFiles}; do
              cat "$f" >> $out/init.el
              echo >> $out/init.el
            done
            cp ${./early-init.el} $out/early-init.el
          '';

          # the environment variables that point Emacs at the natives; shared
          # by the standalone launcher and (later) the dotnix home-manager module
          envVars = ''
            export ZMACS_NIX_ELPA="${nixElpa}"
            export ZMACS_TREESIT_PATH="${grammars}/lib"
            export ZMACS_MU_BINARY="${pkgs.mu}/bin/mu"
          '';

          # standalone launcher: its own writable init dir, refreshed each run
          # so the config stays current; state (eln-cache, ...) persists
          zmacs = pkgs.writeShellApplication {
            name = "zmacs";
            # mu and mbsync for mail; the rest (servers, rg, fd) come from the
            # ambient PATH (dotnix) when run there
            runtimeInputs = [
              pkgs.mu
              pkgs.isync
            ];
            text = ''
              ${envVars}
              dir="''${XDG_DATA_HOME:-$HOME/.local/share}/zmacs"
              mkdir -p "$dir"
              install -m600 ${initFile}/init.el "$dir/init.el"
              install -m600 ${initFile}/early-init.el "$dir/early-init.el"
              exec ${emacs}/bin/emacs --init-directory="$dir" "$@"
            '';
          };
        in
        {
          inherit emacs grammars;
          default = zmacs;
          # exposed so dotnix can set the same env for its wrapper/daemon
          nix-elpa = pkgs.writeText "zmacs-nix-elpa" nixElpa;
        }
      );

      # `nix run .#update` refreshes recipe inputs, `.#lock` rewrites ./lock,
      # `.#default` runs the editor
      apps = eachSystem (
        system: _pkgs:
        (self.packages.${system}.emacs.makeApps { lockDirName = "lock"; })
        // {
          default = {
            type = "app";
            program = "${self.packages.${system}.default}/bin/zmacs";
          };
        }
      );

      homeModules.default = twist.homeModules.emacs-twist;

      devShells = eachSystem (
        system: pkgs: {
          default = pkgs.mkShell { packages = [ pkgs.just ]; };
        }
      );
    };
}
