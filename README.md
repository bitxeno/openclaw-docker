# openclaw-docker

Minimal Docker image providing a development workspace with common tools.

Key points
- Base: `ubuntu:24.04`
- Runs as non-root user `openclaw` (passwordless sudo)
- Workspace: `/home/openclaw/workspace`
- ENTRYPOINT: s6-overlay (`/init`) — services under `/etc/services.d`

Included tools (installed in image)
- Python 3, `python` -> `python3`
- Node.js (LTS) and `npm`
- Bun
- `uv` (Python package manager)
- Go 1.26.1
- Rust (installed via `rustup`)
- `opencode` CLI
- `jj` (versioned install)
- `rclone`, `jq`, common build tools
- `openclaw` (installed via `npm -g openclaw@latest`)

Quick start

Build the image locally:

```bash
docker build -t openclaw-docker:latest .
```

Run (mount workspace from host):

```bash
docker run -d --name openclaw \
  -v $(pwd)/workspace:/home/openclaw/workspace \
  openclaw-docker:latest
```

Interactive shell (useful for debugging):

```bash
docker run -it --rm \
  -v $(pwd)/workspace:/home/openclaw/workspace \
  openclaw-docker:latest bash
```

Check installed versions quickly:

```bash
docker run --rm openclaw-docker:latest bash -lc "python --version && node --version && bun --version && go version && rustc --version && opencode --version"
```

Notes
- `opencode.json` from the repo is copied to `/home/openclaw/.config/opencode/opencode.json` inside the image.
- Services scripts are provided under `services.d` and copied to `/etc/services.d`.
- The image does not publish any ports by default — expose or map ports when running if your app requires it.

If you want, I can also add a short `docker-compose.yml` example. 
