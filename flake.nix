{
  inputs = {
    nixpkgs.url = "nixpkgs";
    flake-utils.url = "github:numtide/flake-utils";
    fenix = {
      inputs.nixpkgs.follows = "nixpkgs";
      url = github:nix-community/fenix;
    };
    rust-manifest = {
      flake = false;
      url = "https://static.rust-lang.org/dist/2024-05-08/channel-rust-nightly.toml";
    };
  };

  outputs = { self, nixpkgs, flake-utils, fenix, ... } @ inputs:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = nixpkgs.legacyPackages.${system};
        fenix' = pkgs.callPackage "${fenix}/." {};
        rust-toolchain = fenix'.fromManifestFile inputs.rust-manifest;
        rust = fenix'.combine (with rust-toolchain; [
          rustc cargo rust-src rustfmt clippy
        ]);
        rustPlatform = (pkgs.makeRustPlatform {
          cargo = rust-toolchain.cargo;
          rustc = rust-toolchain.rustc;
        });
        wlx-overlay-s = (pkgs.wlx-overlay-s.override {
          inherit rustPlatform;
        }).overrideAttrs {
          src = ./.;
          cargoLock.lockFile = ./Cargo.lock;
        };
      in
      {
        devShell = wlx-overlay-s;
        packages.default = wlx-overlay-s;
      });
}
