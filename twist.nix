{
  pkgs,
  emacsPackage,
  inputs,
}:
{
  inherit pkgs emacsPackage;
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
  inputOverrides = {
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
}
