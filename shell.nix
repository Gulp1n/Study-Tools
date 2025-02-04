{ pkgs ? import <nixpkgs> {} }:

pkgs.mkShell {
  buildInputs = [
    pkgs.chromium
    pkgs.nodejs_23
  ];
}
