Git Cheat Sheet
=======================

Git can be challenging to learn and often _**makes the easy complicated**_ in its attempt to _**make the complicated easy**_. This is a collection of notes, aliases, shortcuts and explanations that help me to survive.

## Configuration

### Some useful bash aliases
```bash
# Show uncommitted changes:
# Usage: git-changes
alias git-changes='git commit -a --verbose --dry-run'

# Revert uncommitted changes in a file:
# Usage: git-revert <file.ext>
alias git-revert='git checkout'

# Revert ALL local changes to master. Can use git stash to save a copy.
# Usage: git-revert-everything
alias git-revert-everything='git fetch origin && git checkout master && git reset --hard origin/master'

# Totally reset local to what is on github with a final cleaning
# Usage: git-reset-to-github
alias git-reset-to-github='git fetch origin && git reset --hard origin/master && git clean -ffdx'

# Squash multiple commits into one for readability
# Usage: git-squash
alias git-squash='git rebase --interactive'

# Push up from a new (current) branch without having to remember:
# git push --set-upstream origin <branchname>
# Usage: git-push-branch
alias git-push-branch="git push --set-upstream origin $(git branch | awk '/^\* / { print $2 }') > /dev/null"

# Grab latest changes from the original project you forked on GitHub.
# Before doing this, you should have configured:
#    git remote add upstream https://github.com/ORIGINAL/ORIGINAL.git
# If you have a branch, you should go there and type `git merge master`.
# Usage: git-merge-from-upstream
alias git-merge-from-upstream='git fetch upstream && git checkout master && git merge upstream/master'

```

### Bash function used to automate a "fixup" of the previous commit
```bash
# Call git-fixup (from bash) to add your current changes to the last commit and force push.
function git-fixup () {
  local PREV_COMMIT=$(git log -1 | perl -n -e "/^commit (.+)/ && print \"\$1\n\"")
  echo "Last commit:"
  git log -1
  echo -e "Fixing up last commit: $PREV_COMMIT"
  # Commit the change without signing because the rebase later is signed.
  git commit -a --no-gpg-sign --fixup "$PREV_COMMIT" &&
    # Non-interactive rebase using `true` as EDITOR
    # http://stackoverflow.com/a/12395024/1117929
    GIT_SEQUENCE_EDITOR=true git rebase --interactive HEAD~2 &&
    git push --quiet --force
}
```

### git aliases
```bash
# Opposit of `git add`, not to be confused with `git rm`
git config --global alias.unadd 'reset HEAD --'
git config --global alias.unstage 'reset HEAD --'
```

### git global config
```bash
# Config git rebase -i to always autosquash.
# If you use `git commit --fixup [hash]`, then `git rebase -i HEAD~2` you will see that it marks the fixup items.
# So you just need to hit save from the editor.
# BTW: Why do I still need to go though this stupid interactive session when using "autosquash"!?
#      Seems the hack-job workaround is to set `GIT_SEQUENCE_EDITOR=true`... see `git-fixup` above.
git config --global rebase.autosquash true

# When pushing, always use the current branch.   Duh!
git config --global push.default current
```

### Configure git to sign all commits with my PGP key
```bash
git config --global user.email [EMAIL ADDRESS OF YOUR PGP IDENTITY]
git config --global user.signingkey [YOUR KEY HERE]
git config --global commit.gpgsign true  # Only works in git >= 2
```

You should also [add your OpenPGP public key to GitHub](https://github.com/settings/keys) so that verification info is displayed to users.

NOTE: Both `git` and GitHub will show that code was signed with your signing **subkey** (rather than primary key).  This may be confusing for users because normally the primary key is used / publicly shared by devs and subkeys are selected quietly in the background as needed.  See [example here](https://github.com/jonathancross/j-renamer/commit/e93093aa5d87a33b0758b1614c31d70aae7999ed) and click on the green "Verified" button.

### Show commit signature info ([more info](https://git-scm.com/book/en/v2/Git-Tools-Signing-Your-Work))
```bash
git log --show-signature -1               # Details of last commit sig.
git log --pretty="format:%h %G? %aN  %s"  # Log of last commits. The "G" means good signature, "N" means no sig.
```

Troubleshooting, cookbook and examples
==============================

* http://ohshitgit.com - Solutions to common problems in plain English.

### Useful command reference
```bash
git add --update # stages only the files which are already tracked and not new
git commit --amend     # Change previous commit message and / or add staged files.
git show --name-status # Show diff of previous commit
git log --stat # Show latest changes committed
git checkout [BRANCH NAME] # To switch to a particular branch
git checkout -b [BRANCH NAME] # To CREATE a new branch
git remote set-url origin git@github.com:jonathancross/pics.jonathancross.com.git # Allow git push via ssh without password
git remote -v  # Show the remotes that are configured: https://help.github.com/articles/fork-a-repo/
```

### Move last commit from current branch to a new one
```bash
git branch newbranch    # Creates a new branch using your current state in master
git reset --hard HEAD~1 # Go back 1 commit. You *will* lose uncommitted work.
git checkout newbranch  # Switch to the new branch you made from master.
```

### Edit a commit message created on a branch after pull request initiated
```bash
# Assuming remote is jonathancross/Signal-Android.git and changes are on branch patch-1
git clone git@github.com:jonathancross/Signal-Android.git
cd Signal-Android
git checkout patch-1 # NOT `git branch patch-1` which will CREATE patch-1!!!!!!!!!
git branch # Check that you are now on patch-1
git log --stat -1 # Look for your commit
git commit --amend
git push -f
```


### To squash the last 3 commits (note the `~3`) into one after they were pushed:
```bash
git rebase -i HEAD~3
```

Then edit message like so:
```
pick  3074590 The message we want to keep.
fixup 917fdb0 Comment to discard 1
fixup b04757a Comment to discard 2
```

Normally, you can then simply force push the single "fixed" commit, replacing the two you had:
```bash
git push -f            # Force push the amended commit containing all 3 changes under one commit.
```

You might have to do some of this:
```bash
git add <file>         # Not clear why an existing file needs to be "added", but this is the way to mark resolution of conflicts.
git rebase --continue  # Continue a partial rebase if needed
git commit --amend     # Fix the commit message
git push -f            # Force push the amended commit & message
```

### Making a new branch after having already added changes in master
If you want to set your new branch to start at some time in the past, just add that commit hash to the end of your `git branch`
```bash
git log                # Get the commit hash of your starting point
git branch new-branch e673afd45c5246ac0f16f30472c677bcb9c0fd7b
git checkout new-branch
```

### Delete last commit after it was pushed:

* http://ncona.com/2011/07/how-to-delete-a-commit-in-git-local-and-remote/

### GitHub specific info
* To merge a branch back into master, use a pull request.  Will go from right (compare or "head" branch, what you did) to left ("base" where it should go)!
* To merge changes made in original to the fork, click on the green arrows, change the base, then create pull request, then merge the pull request.


### To checkout a pull request locally:
Eg: Pull this locally to test: https://github.com/monero-project/monero-core/pull/786 (branch name is `android_dockerfile`)

  cd monero-project
  git fetch upstream pull/786/head:android_dockerfile

Can probably then push to my fork, then submit a PR to them. Need to test.

#### Submitting multiple pull requests to same upstream repo
In many situations, I'd like to be able to submit a series of unrelated pull requests to a repo.
Unfortunately, if the first PR was from `master` branch (the default), future branches you create will include those changes unless you tell the branch to point to an earlier commit.

**Bottom line:** Always start with a new branch!  If you forgot, then see [Making a new branch after having already added changes in master](#making-a-new-branch-after-having-already-added-changes-in-master) above.

### License

WTFPL - See [LICENSE](https://github.com/jonathancross/jc-docs/blob/master/LICENSE) for more info.
