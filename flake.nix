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
          emacs = twist.lib.makeEnv (import ./twist.nix {
            inherit inputs pkgs;
            emacsPackage = pkgs.emacs-pgtk;
          });
        in
        {
          inherit emacs;
          default = emacs;
        }
      );

      # `nix run .#update` refreshes the recipe inputs, `nix run .#lock`
      # (re)writes ./lock from them
      apps = eachSystem (
        system: _pkgs: self.packages.${system}.emacs.makeApps { lockDirName = "lock"; }
      );

      # consumed by dotnix: set programs.emacs-twist.config to packages.<sys>.emacs
      homeModules.default = twist.homeModules.emacs-twist;

      devShells = eachSystem (
        system: pkgs: {
          default = pkgs.mkShell { packages = [ pkgs.just ]; };
        }
      );
    };
}
