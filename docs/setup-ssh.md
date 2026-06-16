# Connecting to a GPU box over SSH

autoresearch runs on a single NVIDIA GPU (an H100 is the reference target). Most
people rent one from a cloud provider and drive it from a laptop over SSH. This
note collects the bits that are easy to get wrong.

## 1. Generate a key (once)

```bash
ssh-keygen -t ed25519 -C "autoresearch" -f ~/.ssh/autoresearch
```

Add the public key (`~/.ssh/autoresearch.pub`) to your provider's dashboard.

## 2. Add a host alias

Put this in `~/.ssh/config` so you can type `ssh gpu` instead of the full
command:

```
Host gpu
    HostName <ip-of-your-box>
    User ubuntu
    IdentityFile ~/.ssh/autoresearch
    # Keep the connection alive during long compiles
    ServerAliveInterval 30
    ServerAliveCountMax 4
```

## 3. Keep training alive after you disconnect

A 5-minute run is short, but a full overnight sweep is not. Run the agent
inside `tmux` so the session survives a dropped connection:

```bash
ssh gpu
tmux new -s research
# ... start the agent ...
# detach with Ctrl-b d, reattach later with: tmux attach -t research
```

## 4. Forward the analysis notebook

To view `analysis.ipynb` locally while it reads results from the box, forward
the Jupyter port:

```bash
ssh -L 8888:localhost:8888 gpu
```

Then open the printed `http://localhost:8888/...` URL in your laptop browser.

## 5. Pull results back down

```bash
scp gpu:~/autoresearch/results.tsv ./results.tsv
```

See [troubleshooting.md](troubleshooting.md) if a run hangs on startup.
