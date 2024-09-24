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
            curl -vL "https://feeds.jupiterbroadcasting.com/coder" > rss/jb_coder.xml
            curl -vL "https://coderqa.fireside.fm/rss" > rss/coderqa.xml
            curl -vL "https://selfhosted.fireside.fm/rss" > rss/ssh.xml
            curl -vL "https://sshsre.fireside.fm/rss" > rss/sshsre.xml 
	    # TODO: less hacky method that can support LUP and other shows
	    # don't overwrite coder if it has a pending or live liveItem
	    if grep liveItem rss/jb_coder.xml | grep -e 'status="pending"' -e 'status="pending"'; then
              echo 'coderqa ssh sshsre' | tr ' ' '\n' | xargs -I {} s5cmd cp rss/{}.xml s3://feeds/rss/{}.xml
	    else
              echo 'coder coderqa ssh sshsre' | tr ' ' '\n' | xargs -I {} s5cmd cp rss/{}.xml s3://feeds/rss/{}.xml
	    fi
          '';
        };
	mkBundle = import ./bundle.nix;
	bundle = pkgs.callPackage mkBundle {};
        runScript = bundle archiver "${archiver}/bin/archiver";
      in
      {
        packages.${system} = {
          inherit archiver;
          tools = toolsEnv;
          inherit runScript;
          default = runScript;
        };
	lib = {
	  inherit mkBundle;
	};
      }
    );
}
