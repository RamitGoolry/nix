{
  description = "Ramit's Darwin system flake";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    nix-darwin.url = "github:LnL7/nix-darwin";
    nix-darwin.inputs.nixpkgs.follows = "nixpkgs";
    nix-homebrew.url = "github:zhaofengli-wip/nix-homebrew";
  };

  outputs = inputs@{ self, nix-darwin, nixpkgs, nix-homebrew }:
  let
    configuration = { pkgs, config, ... }: {
      nixpkgs.config.allowUnfree = true;

      # Installed packages
      environment.systemPackages = [
        pkgs.alacritty
        pkgs.discord
        pkgs.gimp
        pkgs.google-chrome
        pkgs.iterm2
        pkgs.obsidian
        pkgs.vscode
        pkgs.rectangle
        pkgs.zoom-us
        pkgs.slack
        pkgs.stats

        pkgs.antigen
        pkgs.coreutils
        pkgs.neovim
        pkgs.mkalias
        pkgs.tmux
        pkgs.htop
        pkgs.jq
        pkgs.ffmpeg
        pkgs.fzf
        pkgs.btop
        pkgs.docker
        pkgs.docker-compose
        pkgs.gh
        pkgs.bettercap
        pkgs.git
        pkgs.cloudflared
        pkgs.nmap
        pkgs.wget
        pkgs.doxygen
        pkgs.httpie
        pkgs.kubernetes-helm
        pkgs.helm-ls
        pkgs.kubectl
        pkgs.taskwarrior3
        pkgs.taskwarrior-tui
        pkgs.lazygit
        pkgs.ntfy-sh
        pkgs.neofetch
        pkgs.ollama
        pkgs.llvm
        pkgs.unixtools.watch
        pkgs.lua-language-server
        pkgs.speedtest-cli
        pkgs.terraform-ls
        pkgs.tree
        pkgs.tree-sitter
        pkgs.mysql-shell
        pkgs.redis
        pkgs.turso-cli
        pkgs.openssl_3_3
        pkgs.pgadmin4
        pkgs.tshark

        pkgs.awscli
        pkgs.graphviz
        pkgs.gd
        pkgs.guile
        pkgs.netpbm
        pkgs.pango
        pkgs.tesseract
        pkgs.gobject-introspection
        pkgs.harfbuzz
        pkgs.gnutls
        pkgs.gdk-pixbuf
        pkgs.unbound
        pkgs.fira-code
        pkgs.fira-code-nerdfont

        pkgs.glib    # TODO: Needed?
        pkgs.librist # TODO: Needed?
        pkgs.libidn2 # TODO: Needed?

        pkgs.go
        pkgs.gleam
        pkgs.nodejs_18 # TODO: Prefer n over nodejs
        pkgs.lua
        pkgs.python312
        pkgs.terraform
        pkgs.ruby
      ];

      homebrew = {
          enable = true;
          brews = [
            "antigen"
            "mas"
          ];

          casks = [
            "anydesk"
            "insomnia"
            "notion"
            "firefox"
            "numi"
            "balenaetcher"
            "tor-browser"
            "whatsapp"
          ];

          masApps = {
            "Petrify" = 1451177988;
            "Patterns" = 429449079;
            "OneNote" = 784801555;
            "Notability" = 360593530;
            "Goodnotes" = 1444383602;
            "Amphetamine" = 937984704;
          };

          onActivation.cleanup = "zap";
          onActivation.autoUpdate = true;
          onActivation.upgrade = true;
      };

      fonts.packages = [];

      system.activationScripts.applications.text = let
        env = pkgs.buildEnv {
          name = "system-applications";
          paths = config.environment.systemPackages;
          pathsToLink = "/Applications";
        };
      in
        pkgs.lib.mkForce ''
          # Set up applications.
          echo "setting up /Applications" >&2
          rm -rf /Applications/Nix\ Apps
          mkdir -p /Applications/Nix\ Apps
          find ${env}/Applications -maxdepth 1 -type l -exec readlink '{}' + | while read src; do
            app_name=$(basename "$src")
            echo "aliasing $app_name" >&2
            ${pkgs.mkalias}/bin/mkalias "$src" "/Applications/Nix Apps/$app_name"
          done
        '';

      services.nix-daemon.enable = true;
      # nix.package = pkgs.nix;

      nix.settings.experimental-features = "nix-command flakes";

      programs.zsh.enable = true;  # default shell on catalina
      # programs.fish.enable = true;

      system.configurationRevision = self.rev or self.dirtyRev or null;
      system.stateVersion = 5;

      nixpkgs.hostPlatform = "aarch64-darwin";
    };
  in
  {
    # Build darwin flake using:
    # $ darwin-rebuild build --flake .#personal
    darwinConfigurations."personal" = nix-darwin.lib.darwinSystem {
      modules = [
        configuration
        nix-homebrew.darwinModules.nix-homebrew {
          nix-homebrew = {
            enable = true;
            enableRosetta = true;
            user = "ramit";
          };
        }
      ];
    };

    darwinPackages = self.darwinConfigurations."personal".pkgs;
  };
}
