# Setup token-saving-hooks

Run the following checks and actions to set up token-saving-hooks in the current project:

1. Check if `git` is installed by running `git --version`.
   - If the command fails, stop and tell the user: "Git is not installed. Please install Git first: https://git-scm.com/downloads"

2. Check if the current working directory is inside a Git repository by running `git rev-parse --show-toplevel`.
   - If it succeeds, the repo already exists. Jump to step 3.
   - If it fails (not a git repo), run `git init` in the current directory.

3. Stage non-hidden files so `git diff` has a baseline:
   - Run: `find . -maxdepth 5 -type f -not -path './.git/*' -not -name '.*' -not -path '*/.*' 2>/dev/null | head -200 | xargs git add -- 2>/dev/null; true`
   - If there are no files to stage, skip silently.
   - Files already tracked by git are unaffected.

4. Tell the user the outcome:
   - If git init was run in step 2: "Initialized a new Git repository and staged existing files. token-saving-hooks is ready."
   - Otherwise: "Git repo detected. Staged any untracked non-hidden files. token-saving-hooks is ready."
