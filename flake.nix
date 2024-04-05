{
  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
  outputs =
    inputs@{ nixpkgs, ... }:
    (
      let
        system = "x86_64-linux";
        pkgs = nixpkgs.legacyPackages.${system};
        toolsEnv = pkgs.buildEnv {
          name = "tools";
          paths = [
            pkgs.curl
            pkgs.s5cmd
	    pkgs.dua
          ];
        };
      in
      {
        packages.${system}.tools = toolsEnv;
      }
    );
}
