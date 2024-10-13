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
    system = "aarch64-darwin";
    pkgs = import nixpkgs {
        inherit system;
        config.allowUnfree = true;
    };

    # NOTE: We are using the system `hdiutil` and `codesign` tools to mount the DMG.
    # If we can, we should use the `nixpkgs` version of these tools.
    buildDmgApp = { name, version, url, sha256, appName }:
      pkgs.stdenv.mkDerivation {
        pname = name;
        inherit version;

        src = pkgs.fetchurl {
          inherit url sha256;
        };

        nativeBuildInputs = [ pkgs.coreutils pkgs.findutils ];

        unpackPhase = ''
          runHook preUnpack

          TMPMOUNT=$(mktemp -d)
          echo "Mounting $src to $TMPMOUNT"
          /usr/bin/hdiutil attach -nobrowse -readonly -mountpoint "$TMPMOUNT" "$src"

          runHook postUnpack
        '';

        installPhase = ''
          runHook preInstall

          if [ -e "$TMPMOUNT/${appName}" ]; then
            mkdir -p "$out/Applications"
            cp -pR "$TMPMOUNT/${appName}" "$out/Applications/"
          else
            echo "ERROR: ${appName} not found in DMG"
            ls -R "$TMPMOUNT"
            exit 1
          fi

          runHook postInstall
        '';

        postInstall = ''
          /usr/bin/hdiutil detach "$TMPMOUNT"
          rm -rf "$TMPMOUNT"
        '';

         postFixup = ''
            app="$out/Applications/${appName}"
            /usr/bin/codesign --sign - --force --deep "$app"
        '';

        meta = {
          description = "Package ${name} version ${version} from DMG";
          homepage = "unavailable";
          license = pkgs.lib.licenses.unfree;
          platforms = pkgs.lib.platforms.darwin;
        };
      };

    dmgApps = [
      {
        name = "Immersed";
        version = "21.4.0";
        url = "https://static.immersed.com/dl/Immersed.dmg";
        sha256 = "sha256-/g/qj5EuwWq8+plSArD6zynuWY41wYBaMrNK/nVBVPE=";
        appName = "Immersed.app";
      }
      {
        name = "Raspberry Pi Imager";
        version = "1.9.0";
        url = "https://github.com/raspberrypi/rpi-imager/releases/download/v1.9.0/Raspberry.Pi.Imager-1.9.0.dmg";
        sha256 = "sha256-w5eCOGTyLqtpTyFgqekt68G0OaK+znRFRcqNr9o56q4=";
        appName = "Raspberry Pi Imager.app";
      }
    ];
    dmgAppPackages = map (appAttrs: buildDmgApp appAttrs) dmgApps;


    # NOTE: We are using the system `pkgutil` tool to mount the PKG.
    # If we can, we should use the `nixpkgs` version of this tool.
    buildPkgApp = { name, version, url, sha256, appName }:
      pkgs.stdenv.mkDerivation {
        pname = name;
        inherit version;
        
        src = pkgs.fetchurl {
          inherit url sha256;
        };

        unpackPhase = ''
          runHook preUnpack

          # Generate a temporary mount point path
          TMPMOUNT="/tmp/pkg-mount-$(date +%s)"
          echo "Mounting $src to $TMPMOUNT"
          /usr/sbin/pkgutil --expand "$src" "$TMPMOUNT"

          runHook postUnpack
        '';

        installPhase = ''
          runHook preInstall

          if [ -e "$TMPMOUNT/${appName}" ]; then
            mkdir -p "$out/Applications"
            cp -pR "$TMPMOUNT/${appName}" "$out/Applications/"
          else
            echo "ERROR: ${appName} not found in PKG"
            ls -R "$TMPMOUNT"
            exit 1
          fi

          runHook postInstall
        '';

        postInstall = ''
          /usr/sbin/pkgutil --forget "$TMPMOUNT"
          rm -rf "$TMPMOUNT"
        '';

         postFixup = ''
            app="$out/Applications/${appName}"
            /usr/bin/codesign --sign - --force --deep "$app"
        '';

        meta = {
          description = "Package ${name} version ${version} from PKG";
          homepage = "unavailable";
          license = pkgs.lib.licenses.unfree;
          platforms = pkgs.lib.platforms.darwin;
        };
      };

    pkgApps = [
      {
        name = "Elgato Stream Deck";
        version = "6.7.3.21005";
        url = "https://edge.elgato.com/egc/macos/sd/Stream_Deck_6.7.3.21005.pkg";
        sha256 = "sha256-3xMXa1vQbDc9v41Znlmefo0W2n4yZHN/tHuy8DMgFhA=";
        appName = "Elgato Stream Deck.app";
      }
    ];

    pkgAppPackages = map (appAttrs: buildPkgApp appAttrs) pkgApps;

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
        pkgs.arc-browser

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
        pkgs.eza
        pkgs.ripgrep

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

        pkgs.go
        pkgs.gleam
        pkgs.nodejs_18 # TODO: Prefer n over nodejs
        pkgs.lua
        pkgs.python312
        pkgs.terraform
        pkgs.ruby
        pkgs.cargo
        pkgs.bun
      ] ++ dmgAppPackages;
        # ++ pkgAppPackages;

      homebrew = {
          enable = true;
          taps = [
            "codecrafters-io/tap"
          ];

          brews = [
            "antigen"
            "mas"
            "codecrafters-io/tap/codecrafters"
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
            "font-fira-code"
            "font-fira-code-nerd-font"
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
