{
  description = "A Web UI for Taskwarrior";
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-24.11";
  };
  outputs =
    { self, nixpkgs, ... }:
    let
      lib = nixpkgs.lib;
      supportedSystems = [
        "x86_64-linux"
        "i686-linux"
        "aarch64-linux"
        "riscv64-linux"
      ];
      forAllSystems = lib.genAttrs supportedSystems;
    in
    {
      packages = forAllSystems (
        system:
        let
          pkgs = import nixpkgs { inherit system; };
        in
        pkgs.buildNpmPackage {
          pname = "taskwarrior-webui-api";
          version = "1.0.0";
          npmDepsHash = "sha256-KJzNuIcYF/3ZmpXymaPer1luJLgsMemtJ4eqYdh+HFA=";
          src = ./backend;
          npmFlags = [ "--legacy-peer-deps" ];
          installPhase = ''
            mkdir -p $out
            cp -rv . $out

          '';
          meta = with pkgs.lib; {
            description = "A Web UI for Taskwarrior";
            license = licenses.mit;
            maintainers = [ "justinmartin" ];
          };
        }
      );

      defaultPackage = forAllSystems (system: self.packages.${system});

    };
}
