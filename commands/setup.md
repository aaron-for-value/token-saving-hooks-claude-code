# Setup token-saving-hooks

Run the following checks and actions to set up token-saving-hooks in the current project:

1. Check if `git` is installed by running `git --version`.
   - If the command fails, stop and tell the user: "Git is not installed. Please install Git first: https://git-scm.com/downloads"

2. Check if the current working directory is inside a Git repository by running `git rev-parse --show-toplevel`.
   - If it succeeds, tell the user: "Git repo detected at <path>. Setup complete — token-saving-hooks is ready."
   - If it fails (not a git repo), run `git init` in the current directory, then tell the user: "Initialized a new Git repository. token-saving-hooks is ready."
