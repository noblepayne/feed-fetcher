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
            pkgs.findutils # xargs
            pkgs.curl
            pkgs.cacert
	    pkgs.s5cmd
          ];
        };
        archiver = pkgs.writeShellApplication {
          name = "archiver";
          runtimeInputs = [ toolsEnv ];
          text = ''
            export SSL_CERT_FILE="${pkgs.cacert}/etc/ssl/certs/ca-bundle.crt"
            mkdir -p rss
            curl -vL "https://coder.fireside.fm/rss" > rss/coder.xml
            curl -vL "https://coderqa.fireside.fm/rss" > rss/coderqa.xml
            curl -vL "https://selfhosted.fireside.fm/rss" > rss/selfhosted.xml
            curl -vL "https://sshsre.fireside.fm/rss" > rss/sshsre.xml 
            echo 'coder coderqa ssh sshsre' | tr ' ' '\n' | xargs -I {} s5cmd cp rss/{}.xml s3://feeds/rss/{}_test.xml
          '';
        };
        baseRunScript = pkgs.writeTextFile {
          name = "base-run";
          text = ''
            #!/usr/bin/env sh
            set -e
            cat $0 | tail -n +6 | tar xzf - -P
            ${archiver}/bin/archiver
            exit $?
          '';
          executable = true;
        };
        toolsBundle = pkgs.stdenv.mkDerivation {
          name = "tools-bundle";
          dontUnpack = true;
          dontBuild = true;
          installPhase = ''
            tar czf $out -P -T ${pkgs.writeClosure archiver}
          '';
        };
	runScript = pkgs.stdenv.mkDerivation {
	  name = "run";
          dontUnpack = true;
          dontBuild = true;
	  dontPatchShebangs = true;
	  installPhase = ''
	    cat ${baseRunScript} ${toolsBundle} >> $out
	    chmod +x $out
	  '';
	  postInstall="";
	};
      in
      {
        packages.${system} = {
          inherit archiver;
          tools = toolsEnv;
          inherit baseRunScript;
          inherit toolsBundle;
          inherit runScript;
	  default = runScript;
        };
      }
    );
}
