{
  pkgs,
  emacsPackage,
  inputs,
  # elisp appended to site-start.el (flake.nix: defaults for the natives' env)
  extraSiteStartElisp ? "",
}:
let
  inherit (pkgs) lib;

  # twist fetches the locked sources with builtins.fetchTree, which always
  # asks the network: as fixed-output derivations they're the same store
  # paths, and a store that has them is enough (an offline install)
  lock = lib.importJSON ./lock/flake.lock;
  fetchLocked =
    l:
    let
      hash = l.narHash;
    in
    if l.type == "github" then
      pkgs.fetchzip {
        url = "https://github.com/${l.owner}/${l.repo}/archive/${l.rev}.tar.gz";
        inherit hash;
      }
    else if l.type == "gitlab" then
      pkgs.fetchzip {
        url = "https://gitlab.com/api/v4/projects/${l.owner}%2F${l.repo}/repository/archive.tar.gz?sha=${l.rev}";
        inherit hash;
      }
    else if l.type == "tarball" then
      pkgs.fetchzip {
        inherit (l) url;
        inherit hash;
      }
    else if l.type == "git" then
      pkgs.fetchgit {
        name = "source";
        inherit (l) url rev;
        inherit hash;
        fetchSubmodules = false;
      }
    else
      throw "zmacs: no fetcher for ${l.type} inputs";
  sources = lib.mapAttrs (_: node: {
    src = fetchLocked lock.nodes.${node}.locked;
  }) lock.nodes.${lock.root}.inputs;

  overrides = {
    # its autoloads run (treesit-ready-p 'astro) from site-start, before
    # treesit is loaded: void-function, and startup dies. lang.el maps .astro
    astro-ts-mode = _: _: {
      preBuild = ''
        sed -i '/^;;;###autoload$/{N;s/^;;;###autoload\n\((if (treesit-ready-p\)/\1/}' astro-ts-mode.el
      '';
    };
    # 2449 snippet files, read one by one (each asking editorconfig for its
    # coding system) the first time yasnippet loads a mode: ~0.2s. Compile them
    # here into one .yas-compiled-snippets.el per mode, which yasnippet prefers
    yasnippet-snippets = _: _: {
      preBuild = ''
        HOME=$TMPDIR emacs --batch -l yasnippet --eval '(yas-compile-directory "snippets")'
      '';
    };
    # combobulate.el marks its own (require ...) forms ;;;###autoload, so its
    # autoloads file loads all 19 modules at every startup (~0.2s); drop those
    # cookies, the package still loads in full when combobulate-mode runs
    combobulate = _: _: {
      preBuild = ''
        sed -i '/^;;;###autoload$/{N;s/^;;;###autoload\n\((require \)/\1/}' combobulate.el
      '';
    };
    # its -pkg.el has keywords after the requires, which twist can't parse
    base16-theme = _: _: { packageRequires = { }; };
    # savannah.gnu.org is often down; pull tramp from a mirror
    tramp = _: _: {
      origin = {
        type = "github";
        owner = "emacs-straight";
        repo = "tramp";
        ref = "master";
      };
    };
  };
in
{
  inherit pkgs emacsPackage extraSiteStartElisp;
  initFiles = [
    ./init.el
    ./lisp/ui.el
    ./lisp/evil.el
    ./lisp/completion.el
    ./lisp/editor.el
    ./lisp/lsp.el
    ./lisp/checkers.el
    ./lisp/lang.el
    ./lisp/org.el
    ./lisp/vterm.el
    ./lisp/pdf.el
    ./lisp/mail.el
    ./lisp/search.el
    ./lisp/tools.el
    ./lisp/spell.el
    ./lisp/help.el
    ./lisp/debug.el
    ./lisp/keys.el
    ./lisp/activity.el
  ];
  lockDir = ./lock;
  registries = [
    {
      type = "elpa";
      path = inputs.gnu-elpa.outPath + "/elpa-packages";
      core-src = emacsPackage.src;
      auto-sync-only = true;
    }
    {
      name = "melpa";
      type = "melpa";
      path = inputs.melpa.outPath + "/recipes";
    }
    {
      type = "elpa";
      path = inputs.nongnu.outPath + "/elpa-packages";
    }
    {
      name = "gnu";
      type = "archive-contents";
      path = inputs.gnu-elpa-archive.outPath;
      base-url = "https://raw.githubusercontent.com/d12frosted/elpa-mirror/master/gnu/";
    }
    {
      name = "emacsmirror";
      type = "gitmodules";
      path = inputs.epkgs.outPath + "/.gitmodules";
    }
  ];
  # each locked source, plus the overrides above on top
  inputOverrides =
    lib.mapAttrs (
      ename: s: final: prev:
      s // (overrides.${ename} or (_: _: { })) final prev
    ) sources
    // removeAttrs overrides (lib.attrNames sources);
}
