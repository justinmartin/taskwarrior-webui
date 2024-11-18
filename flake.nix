{
  description = "A Web UI for Taskwarrior";
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-24.11";
    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
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
        {
          backend = pkgs.buildNpmPackage {
            pname = "taskwarrior-webui-api";
            version = "1.0.0";
            npmDepsHash = "sha256-KJzNuIcYF/3ZmpXymaPer1luJLgsMemtJ4eqYdh+HFA=";
            src = ./backend;
            npmFlags = [ "--legacy-peer-deps" ];
            installPhase = ''
              mkdir -p "$out"
              cp -rv . "$out"
            '';
          };
          meta = with pkgs.lib; {
            description = "A Web UI for Taskwarrior";
            license = licenses.mit;
            maintainers = [ "justinmartin" ];
          };

          frontend = pkgs.buildNpmPackage {
            pname = "taskwarrior-webui-frontend";
            version = "1.0.0";
            src = ./frontend;
            npmDepsHash = "sha256-wrEfYd8EXr5T4gV+plzBl184M8VAT0KzHtrkASjjGlA=";
            npmFlags = [ "--legacy-peer-deps" ];
            buildPhase = ''
              runHook preBuild

              echo "Building frontend..."
              npm run build
              export NUXT_TELEMETRY_DISABLED=1
              npm run export
              cp -rv dist/* static/
              runHook postBuild
            '';
            installPhase = ''
              mkdir -p "$out"
              cp -rv . "$out"
            '';
            meta = with pkgs.lib; {
              description = "A Web UI for Taskwarrior Frontend";
              license = licenses.mit;
              maintainers = [ "justinmartin" ];
            };
          };
          combined = pkgs.stdenv.mkDerivation {
            pname = "taskwarrior-webui";
            version = "1.0.0";
            src = ./.;
            buildInputs = [
              self.packages.${system}.backend
              self.packages.${system}.frontend
              self.packages.${system}.startBackendScript
            ];
            installPhase = ''
              mkdir -p "$out/backend"
              mkdir -p "$out/frontend"
              cp -rv ${self.packages.${system}.backend}/. $out/backend
              cp -rv ${self.packages.${system}.frontend}/. $out/frontend
              # Copy the startup script to the output bin directory
              mkdir -p "$out/bin"
              cp ${self.startBackendScript}/bin/start-backend-server "$out/bin/"
            '';
            meta = with pkgs.lib; {
              description = "A Web UI for Taskwarrior (Combined)";
              license = licenses.mit;
              maintainers = [ "justinmartin" ];
            };
          };

          startBackendScript = pkgs.writeShellScriptBin "start-backend-server" ''
            #!/usr/bin/env bash
            ${pkgs.nodejs}/bin/npm start --prefix ${self.packages.${system}.backend}
          '';

        }
      );

      defaultPackage = forAllSystems (system: self.packages.${system}.backend);
      defaultApp = forAllSystems (system: {
        type = "app";
        program = "${self.packages.${system}.startBackendScript}/bin/start-backend-server";
      });

    };
}
