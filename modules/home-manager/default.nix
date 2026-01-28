{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfgHello = config.programs.my-hello;
  cfgPiAgent = config.programs.pi-coding-agent;
in
{
  imports = [
    ./pi.nix
  ];

  options.programs.my-hello = {
    enable = lib.mkEnableOption "my-hello custom package";
  };

  options.programs.pi-coding-agent = {
    enable = lib.mkEnableOption "pi-coding-agent custom package";
  };

  config = lib.mkMerge [
    (lib.mkIf cfgHello.enable {
      home.packages = [ pkgs.hello ];
    })
    (lib.mkIf cfgPiAgent.enable {
      home.packages = [ pkgs.pi-coding-agent ];
    })
  ];
}
