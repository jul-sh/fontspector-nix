# fontspector-nix

Nix flake for [fontspector](https://github.com/fonttools/fontspector), a Skrifa/Read-Fonts-based font QA tool and successor to fontbakery.

## What is fontspector?

Fontspector is a modern font quality assurance tool built on the Rust-based `skrifa` library. It performs comprehensive checks on font files to ensure they meet quality standards and specifications, particularly for Google Fonts.

## Why this flake exists

This flake packages fontspector for Nix with modifications to make it work in sandboxed Nix builds:

- **Offline build support**: The original fontspector build script downloads OpenType script and language tags from Microsoft's documentation at build time. This doesn't work in Nix's sandboxed builds.
- **Vendored resources**: This flake vendors the pre-generated `script_tags.rs` and `language_tags.rs` files and patches the build script to use them instead of downloading.

## Usage

### Using with Nix flakes

Try it without installing:
```bash
nix run github:yourusername/fontspector-nix -- --help
```

Build and install:
```bash
nix build github:yourusername/fontspector-nix
./result/bin/fontspector --help
```

Add to your `flake.nix`:
```nix
{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    fontspector.url = "github:yourusername/fontspector-nix";
  };

  outputs = { self, nixpkgs, fontspector }: {
    # Use fontspector in your outputs
  };
}
```

### Using in development shells

Add to your `devShell`:
```nix
devShells.default = pkgs.mkShell {
  buildInputs = [
    fontspector.packages.${system}.default
  ];
};
```

## Running fontspector

Example usage:
```bash
# Basic check
fontspector font.ttf

# Check with Google Fonts profile
fontspector --profile googlefonts font.ttf

# Generate HTML and markdown reports
fontspector --profile googlefonts \
  --html report.html \
  --ghmarkdown report.md \
  font.ttf
```

## Contributing to nixpkgs

To submit this package to nixpkgs:

1. Fork the [nixpkgs repository](https://github.com/NixOS/nixpkgs)

2. Create a package directory:
   ```bash
   mkdir -p pkgs/by-name/fo/fontspector
   ```

3. Create `pkgs/by-name/fo/fontspector/package.nix`:
   ```nix
   { lib
   , rustPlatform
   , fetchFromGitHub
   , pkg-config
   , openssl
   , zlib
   }:

   rustPlatform.buildRustPackage rec {
     pname = "fontspector";
     version = "1.5.1-git";

     src = fetchFromGitHub {
       owner = "fonttools";
       repo = "fontspector";
       rev = "e4722fef242bc3554263a87e2b67599312e4dc14";
       hash = "sha256-s3w+uWvi+S0FP7yi6mCSDhCmJsJCTBK9eFm2NSU3SM0=";
     };

     cargoHash = "sha256-5C/u25SYNAdPjvJ8Lb2s6EBuHR593eYe5Bps5hwiC4s=";

     patches = [ ./fontspector-offline.patch ];

     postPatch = ''
       cp ${./fontspector-checkapi-src/script_tags.rs} fontspector-checkapi/src/script_tags.rs
       cp ${./fontspector-checkapi-src/language_tags.rs} fontspector-checkapi/src/language_tags.rs
     '';

     cargoBuildFlags = [ "-p" "fontspector" ];
     cargoTestFlags = [ "-p" "fontspector" ];

     nativeBuildInputs = [
       pkg-config
     ];

     buildInputs = [
       openssl
       zlib
     ];

     meta = with lib; {
       description = "Skrifa/Read-Fonts-based font QA tool (successor to fontbakery)";
       homepage = "https://github.com/fonttools/fontspector";
       license = licenses.asl20;
       maintainers = with maintainers; [ ]; # Add your maintainer entry
       mainProgram = "fontspector";
       platforms = platforms.unix;
     };
   }
   ```

4. Copy the patch files:
   ```bash
   cp patches/fontspector-offline.patch pkgs/by-name/fo/fontspector/
   cp -r patches/fontspector-checkapi-src pkgs/by-name/fo/fontspector/
   ```

5. Test the package:
   ```bash
   nix build .#fontspector
   ```

6. Create a pull request to nixpkgs with:
   - The package definition
   - A clear description of what fontspector does
   - Explanation of why the patches are needed (sandboxed builds)
   - Your maintainer information

## Patches

### fontspector-offline.patch

This patch modifies the `fontspector-checkapi/build.rs` build script to:
- Remove network requests to Microsoft's OpenType documentation
- Use vendored `script_tags.rs` and `language_tags.rs` files instead
- Make the build fully offline-compatible for Nix's sandboxed builds

The vendored files were generated from the original build script and contain OpenType script and language tag definitions from Microsoft's specification.

## License

This Nix flake packaging is provided as-is. Fontspector itself is licensed under the Apache License 2.0.

## Upstream

Fontspector upstream: https://github.com/fonttools/fontspector
