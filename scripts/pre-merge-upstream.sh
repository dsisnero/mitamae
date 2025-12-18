#!/bin/bash
set -e

# pre-merge-upstream hook: updates from upstream before merging
#
# This hook fetches upstream and fast-forwards the current branch if it's
# the main branch and behind upstream. If fast-forward fails, the merge
# is aborted to prevent conflicts.
#
# Environment variables:
#   UPSTREAM_REMOTE: name of upstream remote (default: upstream)
#   MAIN_BRANCH: name of main branch (default: master)
#   SKIP_PRE_MERGE_UPSTREAM: set to 1 to skip this hook

UPSTREAM_REMOTE="${UPSTREAM_REMOTE:-upstream}"
MAIN_BRANCH="${MAIN_BRANCH:-master}"

# Allow skipping
if [ -n "$SKIP_PRE_MERGE_UPSTREAM" ]; then
    echo "Skipping pre-merge-upstream hook (SKIP_PRE_MERGE_UPSTREAM is set)."
    exit 0
fi

# Ensure upstream remote exists
if ! git remote | grep -q "^$UPSTREAM_REMOTE$"; then
    echo "Warning: upstream remote '$UPSTREAM_REMOTE' not found. Skipping update."
    exit 0
fi

# Fetch upstream
echo "Fetching upstream from $UPSTREAM_REMOTE..."
git fetch "$UPSTREAM_REMOTE"

CURRENT_BRANCH="$(git rev-parse --abbrev-ref HEAD)"

# Only update if we're on the main branch
if [ "$CURRENT_BRANCH" = "$MAIN_BRANCH" ]; then
    UPSTREAM_BRANCH="$UPSTREAM_REMOTE/$MAIN_BRANCH"

    # Check if we're already up-to-date
    if git merge-base --is-ancestor "$UPSTREAM_BRANCH" HEAD; then
        echo "Already up-to-date with $UPSTREAM_BRANCH."
    else
        echo "Merging $UPSTREAM_BRANCH into $CURRENT_BRANCH..."
        if git merge --ff-only "$UPSTREAM_BRANCH"; then
            echo "Successfully fast-forwarded $CURRENT_BRANCH to $UPSTREAM_BRANCH."
        else
            echo "Error: Cannot fast-forward merge. Please update manually with:"
            echo "  git merge $UPSTREAM_BRANCH"
            echo "or rebase with:"
            echo "  git rebase $UPSTREAM_BRANCH"
            echo ""
            echo "To skip this hook, set SKIP_PRE_MERGE_UPSTREAM=1"
            exit 1
        fi
    fi
else
    echo "Not on $MAIN_BRANCH ($CURRENT_BRANCH), skipping upstream update."
fi