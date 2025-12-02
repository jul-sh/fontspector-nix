{
  description = "Fontspector - Skrifa/Read-Fonts-based font QA tool (successor to fontbakery)";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, flake-utils }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = import nixpkgs {
          inherit system;
        };

        fontspector = pkgs.rustPlatform.buildRustPackage rec {
          pname = "fontspector";
          version = "1.5.1-git";

          src = pkgs.fetchFromGitHub {
            owner = "fonttools";
            repo = "fontspector";
            rev = "e4722fef242bc3554263a87e2b67599312e4dc14";
            hash = "sha256-s3w+uWvi+S0FP7yi6mCSDhCmJsJCTBK9eFm2NSU3SM0=";
          };

          cargoHash = "sha256-5C/u25SYNAdPjvJ8Lb2s6EBuHR593eYe5Bps5hwiC4s=";

          # Patch to make fontspector-checkapi offline-buildable for Nix sandboxed builds
          patches = [ ./patches/fontspector-offline.patch ];

          # Vendor the generated script_tags.rs and language_tags.rs files
          # to avoid network access during build
          postPatch = ''
            cp ${./patches/fontspector-checkapi-src/script_tags.rs} fontspector-checkapi/src/script_tags.rs
            cp ${./patches/fontspector-checkapi-src/language_tags.rs} fontspector-checkapi/src/language_tags.rs
          '';

          # Build only the CLI binary, not all workspace members
          cargoBuildFlags = [ "-p" "fontspector" ];
          cargoTestFlags = [ "-p" "fontspector" ];

          nativeBuildInputs = with pkgs; [
            pkg-config
          ];

          buildInputs = with pkgs; [
            openssl
            zlib
          ];

          meta = with pkgs.lib; {
            description = "Skrifa/Read-Fonts-based font QA tool (successor to fontbakery)";
            homepage = "https://github.com/fonttools/fontspector";
            license = licenses.asl20;
            maintainers = [ ];
            mainProgram = "fontspector";
            platforms = platforms.unix;
          };
        };
      in
      {
        packages = {
          default = fontspector;
          fontspector = fontspector;
        };

        # Development shell with fontspector
        devShells.default = pkgs.mkShell {
          buildInputs = [ fontspector ];
        };
      }
    );
}
