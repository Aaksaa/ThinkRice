{
  description = "ThinkRice: A collection of Linux ricing configurations and assets with ThinkPad/Lenovo themes";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, nixpkgs, home-manager, ... }:
    let
      forAllSystems = nixpkgs.lib.genAttrs [ "x86_64-linux" "aarch64-linux" "x86_64-darwin" "aarch64-darwin" ];
      
      thinkricePackage = pkgs: pkgs.stdenv.mkDerivation {
        pname = "thinkrice";
        version = "1.0.0";
        src = pkgs.lib.cleanSource self.outPath;
        
        installPhase = ''
          mkdir -p $out/share/thinkrice
          cp -r assets fastfetch grub neofetch wallpapers $out/share/thinkrice/
        '';
      };
    in
    {
      packages = forAllSystems (system: {
        default = thinkricePackage nixpkgs.legacyPackages.${system};
      });

      homeManagerModules.default = { config, pkgs, ... }:
        let
          cfg = config.programs.thinkrice;
          thinkrice = self.packages.${pkgs.system}.default;
        in
        {
          options.programs.thinkrice = {
            enable = pkgs.lib.mkEnableOption "Enable ThinkRice configuration";
            
            configName = pkgs.lib.mkOption {
              type = pkgs.lib.types.str;
              default = "thinkpad-vertical.jsonc";
              description = "The name of the fastfetch configuration file to use.";
            };
            
            enableNeofetch = pkgs.lib.mkOption {
              type = pkgs.lib.types.bool;
              default = false;
              description = "Also enable ASCII support for Neofetch (legacy).";
            };
          };

          config = pkgs.lib.mkIf cfg.enable {
            programs.fastfetch.enable = pkgs.lib.mkDefault true;

            xdg.configFile."fastfetch/config.jsonc".source = 
              "${thinkrice}/share/thinkrice/fastfetch/configs/${cfg.configName}";
            
            xdg.configFile."fastfetch/ascii".source = 
              "${thinkrice}/share/thinkrice/fastfetch/ascii";

            xdg.configFile."neofetch/ascii".source = pkgs.lib.mkIf cfg.enableNeofetch
              "${thinkrice}/share/thinkrice/neofetch/ascii";

            xdg.dataFile."wallpapers/thinkrice".source = 
              "${thinkrice}/share/thinkrice/wallpapers";
            
            xdg.dataFile."grub/themes/thinkpad".source = 
              "${thinkrice}/share/thinkrice/grub/thinkpad";
          };
        };
    };
}