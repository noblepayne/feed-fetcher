# 🛰️ feed-fetcher

A simple, reliable RSS feed archiver and proxy, built with a little help from Nix and GitHub Actions. It fetches podcast feeds, archives them, and tells the world they're updated.

## ✨ What's it do?

This little project is designed to be a robust, self-contained feed utility. At its heart, it:

*   **Fetches** RSS feeds from their original sources on a schedule.
*   **Archives** the latest version of each feed to an S3-compatible object store.
*   **Caches** a copy of the feed directly in this Git repository (in the `rss/` directory).
*   **Notifies** podcasting services like Podping and Podcast Index that an update has occurred, ensuring listeners get new episodes ASAP.

The whole process is automated to run every few minutes via a GitHub Action.

## ⚙️ How it Works

The magic is in its simplicity and portability!

1.  **The Logic**: A core shell script (`flake.nix`'s `archiver`) contains all the logic for fetching, uploading, and pinging services.
2.  **The Environment**: We use [Nix](https://nixos.org/) to define all the tools the script needs (`curl`, `s5cmd`, etc.) in a `flake.nix` file. This ensures it works the same way every time.
3.  **The Bundle**: A clever Nix function (`bundle.nix`) takes the script and all its Nix dependencies and packs them into a single, portable executable file named `run`.
4.  **The Automation**: A GitHub Actions workflow runs on a schedule, executes the `./run` file, and commits any updated feeds back to the repository.

This means the runner doesn't need Nix installed—just a standard Linux environment.

## 🚀 Getting Started

You can get your own copy of feed-fetcher running in a few steps.

### 1. Fork the Repository

First, fork this repository to your own GitHub account.

### 2. Configure Secrets

This project relies on a few secrets to function. Add the following to your repository's secrets (`Settings` > `Secrets and variables` > `Actions`):

*   `S3_ENDPOINT_URL`: The full URL to your S3-compatible object storage endpoint.
*   `AWS_ACCESS_KEY_ID`: Your S3 access key.
*   `AWS_SECRET_ACCESS_KEY`: Your S3 secret key.
*   `PODPING_AUTH`: Your authorization key for the [Podping.cloud](https://podping.cloud/) service.

### 3. Add Your Feeds

To add a podcast feed you want to track, edit the `flake.nix` file. Find the `SHOWS` array and add a new line with the format `"shortname,https://source.feed.url"`.

```nix
# --- CONFIGURE YOUR SHOWS HERE ---
# Format: "shortname,https://source.feed.url"
SHOWS=(
  "twib,https://feeds.fountain.fm/40huHEEF6JMPGYctMuUI"
  "my-new-show,https://example.com/podcast.xml" # <-- Add your show here!
)
```

### 4. Build and Commit

After adding your shows, you need to rebuild the `run` executable. This step requires you to have Nix installed on your local machine.

```sh
# 1. Run the build script
./build.sh

# 2. Add and commit the updated `run` file
git add run
git commit -m "build: Update run executable with new feeds"
git push
```

That's it! The GitHub Action will now pick up your new configuration and start fetching your feeds.
