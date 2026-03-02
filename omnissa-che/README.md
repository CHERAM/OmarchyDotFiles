Portable Omnissa Horizon helper configs.

Contents:
- `bcr/`: browser content redirection toggle files
- `html5mmr/`: HTML5 multimedia redirection toggle files
- `mmr/`: multimedia redirection toggle files
- `teamsopt/`: Teams optimization toggle files

Track these files when you want reproducible Horizon feature toggles across machines.

Do not track machine-specific state here. In particular:
- `~/.omnissa/horizon-brokers-prefs` contains broker history, selected desktops,
  monitor selections, and other account- and machine-specific preferences.
- That file should remain local and untracked.
