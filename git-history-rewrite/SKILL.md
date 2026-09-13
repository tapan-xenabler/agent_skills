---
name: git-history-rewrite
description: Instructions for rewriting Git commit author and email history on multiple branches and tags using git filter-branch.
---

# Git History Rewrite Skill

This skill provides a standard workflow for rewriting Git commit histories to correct author names and emails across all branches and tags.

## Workflow

1. **Check Working Directory**: Ensure there are no unstaged or uncommitted changes. If there are, temporarily stash them:
   ```bash
   git stash -u
   ```

2. **Run Git Filter-Branch**: Use `git filter-branch` with `--env-filter` to match the old names/emails and replace them with the correct ones.
   Example script:
   ```bash
   FILTER_BRANCH_SQUELCH_WARNING=1 git filter-branch -f --env-filter '
   OLD_EMAIL_1="old.email1@example.com"
   OLD_NAME_1="Old Name 1"
   OLD_EMAIL_2="old.email2@example.com"
   OLD_NAME_2="Old Name 2"

   CORRECT_NAME="Correct Name"
   CORRECT_EMAIL="correct.email@example.com"

   if [ "$GIT_COMMITTER_EMAIL" = "$OLD_EMAIL_1" ] || [ "$GIT_COMMITTER_NAME" = "$OLD_NAME_1" ] || \
      [ "$GIT_COMMITTER_EMAIL" = "$OLD_EMAIL_2" ] || [ "$GIT_COMMITTER_NAME" = "$OLD_NAME_2" ]
   then
       export GIT_COMMITTER_NAME="$CORRECT_NAME"
       export GIT_COMMITTER_EMAIL="$CORRECT_EMAIL"
   fi
   if [ "$GIT_AUTHOR_EMAIL" = "$OLD_EMAIL_1" ] || [ "$GIT_AUTHOR_NAME" = "$OLD_NAME_1" ] || \
      [ "$GIT_AUTHOR_EMAIL" = "$OLD_EMAIL_2" ] || [ "$GIT_AUTHOR_NAME" = "$OLD_NAME_2" ]
   then
       export GIT_AUTHOR_NAME="$CORRECT_NAME"
       export GIT_AUTHOR_EMAIL="$CORRECT_EMAIL"
   fi
   ' --tag-name-filter cat -- --branches --tags
   ```

3. **Force-Push**: Force push all branches and tags (requires remote branch permissions to temporarily allow force-pushing):
   ```bash
   git push --force --all && git push --force --tags
   ```

4. **Restore Stash**: If changes were stashed, restore them:
   ```bash
   git stash pop
   ```
