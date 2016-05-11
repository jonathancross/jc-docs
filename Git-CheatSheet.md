Git Cheat Sheet
=======================

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
alias git-squash='git rebase -i origin/master'
```

### git aliases
```bash
# Opposit of git add, not to be confused with git rm
git config --global alias.unadd 'reset HEAD --'
git config --global alias.unstage 'reset HEAD --'
```

### git commands
```bash
git add --update # stages only the files which are already tracked and not new
git commit --amend     # Change previous commit message and / or add staged files.
git show --name-status # Show diff of previous commit
git log --stat # Show latest changes committed
git checkout [BRANCH NAME] # To switch to a particular branch
git remote set-url origin git@github.com:jonathancross/pics.jonathancross.com.git # Allow git push via ssh without password
```

### edit a commit message created on a branch after pull request initiated
```bash
# Assuming remote is jonathancross/Signal-Android.git and changes are on branch patch-1
git clone git@github.com:jonathancross/Signal-Android.git
cd Signal-Android
git checkout patch-1 # NOT git branch patch-1 with will CREATE patch-1!!!!!!!!!
git branch # Check that you are now on patch-1
git log --stat -1 # Look for your commit
# git pull  # DOES NOTHING SO COMMENTING OUT
git commit --amend
## Should be able to force push here, but not sure...
git push -f
# If not then try git merge --squash
# If not, then:
git pull # Makes a stupid merge commit
git rebase -i master ### Why master!? Doesn't work with patch-1
git push -f
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

### GitHub specific info
* To merge a branch back into master, use a pull request.  Will go from right (compare or "head" branch, what you did) to left ("base" where it should go)!
* To merge changes made in original to the fork, click on the green arrows, change the base, then create pull request, then merge the pull request.
