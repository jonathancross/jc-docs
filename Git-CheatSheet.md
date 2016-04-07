Git & GitHub Cheat Sheet
=======================

    git-changes # Show uncommitted changes
    git-remove file.ext # remove files from the index (opposite of git add): git reset HEAD 
    git-revert file.ext # revert uncommitted changes in a file 
    git add --update # stages only the files which are already tracked and not new
    git commit --amend     # Change previous commit message and / or add staged files.
    git show --name-status # Show diff of previous commit
    git fetch origin && git checkout master && git reset --hard origin/master # Revert all changes to master.
                                                                              # Can use git stash to save a copy.
    git log --stat # Show latest changes committed
    git remote set-url origin git@github.com:jonathancross/pics.jonathancross.com.git # Allow git push via ssh without password


## Sign all commits with PGP key
    git config --global user.email [EMAIL ADDRESS OF YOUR PGP IDENTITY]
    git config --global user.signkey [YOUR KEY HERE]
    git config --global commit.gpgsign true
    
## GitHub specific

* To merge a branch back into master, use a pull request.  Will go from right (compare or "head" branch, what you did) to left ("base" where it should go)!
* To merge changes made in original to the fork, click on the green arrows, change the base, then create pull request, then merge the pull request.
