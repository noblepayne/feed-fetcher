# feed-fetcher

A self-contained RSS feed archiver and proxy. Fetches podcast feeds on a schedule, archives them to S3, caches them locally, and notifies Podping and Podcast Index of updates.

## Overview

The system fetches RSS feeds from their sources, stores copies in both a Git repository and S3, then notifies third-party services of changes. GitHub Actions triggers the process automatically at regular intervals.

## How It Works

The archiver is a shell script that runs in a Nix-defined environment. The key components are:

**archiver**: A shell script that handles feed fetching, S3 uploads, and service notifications.

**flake.nix**: Defines the complete dependency environment (curl, s5cmd, coreutils, etc.) so the script runs consistently across different systems.

**bundle.nix**: Packs the script and all dependencies into a single self-extracting executable named `run`. This binary contains everything needed; the runner doesn't require Nix to be installed.

**build.sh**: Builds the bundled executable for deployment.

The bundled `run` file is committed to the repository so GitHub Actions can execute it without additional setup.

## Setup

### 1. Fork and Configure Secrets

Fork this repository and add the following to repository secrets (Settings > Secrets and variables > Actions):

- `S3_ENDPOINT_URL`: Full URL to S3-compatible storage endpoint
- `AWS_ACCESS_KEY_ID`: S3 access key
- `AWS_SECRET_ACCESS_KEY`: S3 secret key
- `PODPING_AUTH`: Authorization token for Podping.cloud

### 2. Add Feeds

Edit `flake.nix` and add entries to the `SHOWS` array in the format `"shortname,https://feed.url"`:

```nix
SHOWS=(
  "twib,https://feeds.fountain.fm/40huHEEF6JMPGYctMuUI"
  "my-show,https://example.com/podcast.xml"
)
```

### 3. Rebuild and Commit

With Nix installed locally, run:

```sh
./build.sh
git add run
git commit -m "build: Update run executable"
git push
```

GitHub Actions will execute the updated bundled script on its next scheduled run.

## Configuration

Feeds are configured as a simple array in `flake.nix`. The script:

1. Fetches each feed from its source URL
2. Compares it with the local cached version
3. If changed, writes the new version locally, uploads to S3, and sends notifications
4. If unchanged, skips the update

S3 path: `s3://feeds/rss/{shortname}.xml`

Local path: `rss/{shortname}.xml`

Proxy URL for notifications: `https://feeds.jupiterbroadcasting.com/{shortname}`

## Dependencies

The bundled executable includes: coreutils, findutils, sed, grep, awk, curl, s5cmd, and CA certificates. The runner must provide: sh, tail, and tar. These are present on any standard Unix environment.
