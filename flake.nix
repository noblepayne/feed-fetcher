{
  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
  outputs = inputs @ {nixpkgs, ...}: (
    let
      system = "x86_64-linux";
      pkgs = nixpkgs.legacyPackages.${system};

      toolsEnv = pkgs.buildEnv {
        name = "tools";
        paths = [
          pkgs.coreutils
          pkgs.findutils
          pkgs.gnused
          pkgs.gnugrep
          pkgs.gawk
          pkgs.curl
          pkgs.cacert
          pkgs.s5cmd
        ];
      };

      archiver = pkgs.writeShellApplication {
        name = "archiver";
        runtimeInputs = [toolsEnv];
        text = ''
          #!/usr/bin/env bash
          set -euo pipefail
          set -x

          export SSL_CERT_FILE="${pkgs.cacert}/etc/ssl/certs/ca-bundle.crt"

          send_podping() {
            local feed_url="$1"
            local reason="''${2:-update}"
            local retries=3
            local sleep_duration=10 # seconds

            echo "Sending podping for $feed_url with reason: $reason"

            for i in $(seq 1 $retries); do
                echo "  -> Attempt $i of $retries..."

                # Main Podping
                curl -sf -H "Authorization: $PODPING_AUTH" -H "User-Agent: JupiterBroadcasting" "https://podping.cloud/?url=$feed_url&reason=$reason"

                # Backup Podcast Index Ping
                curl -sf "https://api.podcastindex.org/api/1.0/hub/pubnotify?url=$feed_url"

                if [ "$i" -lt $retries ]; then
                    echo "  -> Sleeping for $sleep_duration seconds..."
                    sleep "$sleep_duration"
                fi
            done

            echo "Podping sequence complete for $feed_url."
          }

          ####################################################################
          # Main Execution Logic
          ####################################################################

          # Ensure the target directory exists
          mkdir -p rss

          # --- CONFIGURE YOUR SHOWS HERE ---
          # Format: "shortname,https://source.feed.url"
          SHOWS=(
            "twib,https://feeds.fountain.fm/40huHEEF6JMPGYctMuUI"
            # "another-show,https://example.com/another.xml"
          )

          for show_data in "''${SHOWS[@]}"; do
            IFS=',' read -r show_name source_url <<< "$show_data"
            echo "--- Processing: $show_name ---"

            # Define paths
            LOCAL_FEED_PATH="rss/$show_name.xml"
            S3_PATH="s3://feeds/rss/$show_name.xml"
            PROXY_URL="https://feeds.jupiterbroadcasting.com/$show_name" # Your public proxy URL
            TMP_FEED="/tmp/$show_name.xml"

            # 1. Fetch the new feed to a temporary file
            curl -sL "$source_url" > "$TMP_FEED"

            # 2. Check if the local file exists and needs to be updated.
            # `cmp -s` silently compares. Fails if files differ or first file doesn't exist.
            if ! [ -f "$LOCAL_FEED_PATH" ] || ! cmp -s "$LOCAL_FEED_PATH" "$TMP_FEED"; then
              echo "Change detected for $show_name. Updating local file, uploading to S3, and podping."

              # A. Overwrite the tracked file in the repo.
              mv "$TMP_FEED" "$LOCAL_FEED_PATH"

              # B. Upload the new version to S3.
              s5cmd cp "$LOCAL_FEED_PATH" "$S3_PATH"

              # C. Send the podping for your public proxy URL.
              send_podping "$PROXY_URL"

            else
              echo "$show_name is unchanged. Skipping."
              rm "$TMP_FEED" # Clean up temp file
            fi

            echo "--- Finished: $show_name ---"
          done
        '';
      };

      mkBundle = import ./bundle.nix;
      bundle = pkgs.callPackage mkBundle {};
      runScript = bundle archiver "${archiver}/bin/archiver";
    in {
      formatter.${system} = pkgs.alejandra;
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
