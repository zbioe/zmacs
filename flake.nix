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

      # everything zmacs builds for one system; shared by the packages, the
      # checks and the home-manager module
      zmacsFor =
        pkgs:
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
            "${emacsPkgs.jinx}/share/emacs/site-lisp/elpa"
          ];
          # jinx's enchant reads hunspell dictionaries from DICPATH
          dicts = pkgs.symlinkJoin {
            name = "zmacs-dicts";
            paths = with pkgs.hunspellDicts; [
              en_US
              pt_BR
            ];
          };

          # the environment that points Emacs at the natives; the launcher
          # exports it, the home-manager module puts it on the daemon
          env = {
            ZMACS_NIX_ELPA = nixElpa;
            ZMACS_TREESIT_PATH = "${grammars}/lib";
            ZMACS_MU_BINARY = "${pkgs.mu}/bin/mu";
            ZMACS_LSP_BOOSTER = "${pkgs.emacs-lsp-booster}/bin/emacs-lsp-booster";
            DICPATH = "${dicts}/share/hunspell";
          };

          # the init.el twist writes (initFiles concatenated), plus its
          # byte-compiled init.elc so startup doesn't macroexpand every
          # use-package form; early-init puts the natives on load-path so
          # their macros resolve while compiling
          mkInit =
            emacsEnv:
            pkgs.runCommandLocal "zmacs-init" { ZMACS_NIX_ELPA = nixElpa; } ''
              mkdir -p $out
              : > $out/init.el
              for f in ${builtins.concatStringsSep " " emacsEnv.initFiles}; do
                cat "$f" >> $out/init.el
                echo >> $out/init.el
              done
              cp ${./early-init.el} $out/early-init.el
              export HOME=$TMPDIR XDG_CONFIG_HOME=$TMPDIR XDG_STATE_HOME=$TMPDIR
              ${emacsEnv}/bin/emacs --batch -l $out/early-init.el \
                -f batch-byte-compile $out/init.el
            '';
          init = mkInit emacs;

          exportEnv = pkgs.lib.concatStrings (
            pkgs.lib.mapAttrsToList (k: v: "export ${k}=\"${v}\"\n") env
          );

          # standalone launcher: its own writable init dir, refreshed each run
          # so the config stays current; state (eln-cache, ...) persists
          launcher = pkgs.writeShellApplication {
            name = "zmacs";
            # mu and mbsync for mail; the rest (servers, rg, fd) come from the
            # ambient PATH (dotnix) when run there
            runtimeInputs = [
              pkgs.mu
              pkgs.isync
            ];
            text = ''
              ${exportEnv}
              dir="''${XDG_DATA_HOME:-$HOME/.local/share}/zmacs"
              mkdir -p "$dir"
              install -m600 ${init}/init.el "$dir/init.el"
              install -m600 ${init}/init.elc "$dir/init.elc"
              install -m600 ${init}/early-init.el "$dir/early-init.el"
              exec ${emacs}/bin/emacs --init-directory="$dir" "$@"
            '';
          };

          # boots the real config in batch (sandboxed: no network, empty home)
          # and runs test/smoke.el against it: bindings, loaded packages, natives,
          # no warnings/errors during startup, nothing fetched by package.el
          smoke = pkgs.runCommandLocal "zmacs-smoke" { } ''
            ${exportEnv}
            export HOME=$TMPDIR/home XDG_CONFIG_HOME=$TMPDIR/home/.config
            export XDG_STATE_HOME=$TMPDIR/home/.local/state XDG_DATA_HOME=$TMPDIR/home/.local/share
            mkdir -p $XDG_STATE_HOME/theme/current $XDG_CONFIG_HOME
            echo '@define-color window_bg_color #123456;' > $XDG_STATE_HOME/theme/current/gtk4.css
            dir=$TMPDIR/zmacs
            mkdir -p $dir
            cp ${init}/* $dir/
            ${emacs}/bin/emacs --batch --init-directory=$dir \
              -l ${./test/prelude.el} -l $dir/early-init.el -l $dir/init.elc \
              -l ${./test/smoke.el} -f ert-run-tests-batch-and-exit
            touch $out
          '';
        in
        {
          inherit
            emacs
            grammars
            env
            mkInit
            init
            launcher
            smoke
            nixElpa
            ;
        };
    in
    {
      packages = eachSystem (
        system: pkgs:
        let
          z = zmacsFor pkgs;
        in
        {
          inherit (z) emacs grammars init;
          default = z.launcher;
          # exposed so dotnix can set the same env for its wrapper/daemon
          nix-elpa = pkgs.writeText "zmacs-nix-elpa" z.nixElpa;
        }
      );

      checks = eachSystem (system: pkgs: { default = (zmacsFor pkgs).smoke; });

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

      # twist's module, plus what zmacs needs on top: the byte-compiled init
      # next to the init.el twist writes (Emacs loads the .elc), and the
      # natives' environment for the session and the daemon
      homeModules.default =
        {
          config,
          lib,
          pkgs,
          ...
        }:
        let
          cfg = config.programs.emacs-twist;
          z = zmacsFor nixpkgs.legacyPackages.${pkgs.stdenv.hostPlatform.system};
        in
        {
          imports = [ twist.homeModules.emacs-twist ];
          config = lib.mkIf cfg.enable (
            lib.mkMerge [
              (lib.mkIf cfg.createInitFile {
                home.file."${cfg.directory}/init.elc".source = "${z.mkInit cfg.config}/init.elc";
              })
              { home.sessionVariables = lib.mapAttrs (_: lib.mkDefault) z.env; }
              (lib.mkIf cfg.serviceIntegration.enable {
                systemd.user.services.emacs.Service.Environment = lib.mapAttrsToList (k: v: "${k}=${v}") z.env;
              })
            ]
          );
        };

      devShells = eachSystem (
        system: pkgs: {
          default = pkgs.mkShell { packages = [ pkgs.just ]; };
        }
      );
    };
}
