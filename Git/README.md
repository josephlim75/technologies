Git environment variable escape characters
===
!   #   $    &   '   (   )   *   +   ,   /   :   ;   =   ?   @   [   ]
%21 %23 %24 %26 %27 %28 %29 %2A %2B %2C %2F %3A %3B %3D %3F %40 %5B %5D

Storing Git password without reentering
===
git config credential.helper store

Debug Git
===
GIT_CURL_VERBOSE=1
GIT_TRACE=1
GCM_TRACE=1

Run SETX GIT_TRACE %userprofile%\git.log
Run SETX GCM_TRACE %userprofile%\git.log

Disable certificate verification
=========
git config http.sslVerify false
git config http.sslcainfo C:/Users/JLim/Workspace/Admin/_Certificates/isae2016.pem

SSL
========
git config --system http.sslcainfo \\bin\\curl-ca-bundle.crt
git config --system http.sslcainfo C:/xxx/xxxx/xxx

git config --global http.proxy http://<login_internet>:<password_internet>@aproxy:aport
git config --global user.name <short_username>
git config --global user.email <email>
git config --global github.user <github_username>
git config --global github.token <github_token>

Git global config location
==============================
System wide = --system PROGRAMDATA\git
Global      = --global %Userprofile%\.gitconfig

git config --global core.longpaths true
git config --global core.symlinks true
git config --system core.longpaths true
git config --system core.symlinks true

Amending the Last Commit
==============================
To change the last commit, you can simply commit again, using the --amend flag:

$ git commit --amend -m "EDPD-289: Split Confluent schemaregistry and Landoop UI to separate container"
Simply put, this overwrites your last commit with a new one. This also means that you're not limited to 
just editing the commit's message: you could also add another couple of changes you forgot.

$ git add another/changed/file.txt
$ git commit --amend -m "message"

Get all symbolic files
==========================
git ls-files -s | awk '/120000/{print $4}'

Git changing file mode
============================

git update-index --chmod=+x foo.sh


Git is slow
=============
git config --global core.preloadindex true
git config --global core.fscache true
git config --global gc.auto 256


git log -n 1 --pretty=format:%h -- <PATH>
git name-rev --name-only HEAD
git symbolic-ref --short HEAD
sed '/^FROM/aI LABEL test=test \\\n test2=test2' jenkins.df > jenkins@build.df

git branch                                      - List the branch list
git pull                                        - Get latest to the current code
git branch <feature/EDP-xxx>                    - Create a branch
git checkout <branch name>                      - Checkout the code from <name> to local

git push --set-upstream origin feature/EDP-xxx  - Make master aware of a branch exists
git push -u origin <branch-name>

Changing Password
======================
To fix this, you can use

$ git config --global credential.helper osxkeychain
You'll then be prompted for your password again.

For Windows, it's the same command with a different argument:
$ git config --global credential.helper wincred

Debugging Git
===========================
GIT_CURL_VERBOSE=1

GIT_TRACE=2
If this variable is set to "1", "2" or "true" (comparison is case insensitive), git will print trace: messages on stderr 
telling about alias expansion, built-in command execution and external command execution. If this variable is set to an 
integer value greater than 1 and lower than 10 (strictly) then git will interpret this value as an open file descriptor 
and will try to write the trace messages into this file descriptor. Alternatively, if this variable is set to an absolute 
path (starting with a / character), git will interpret this as a file path and will try to write the trace messages into it. [1]

git gc --aggressive

git remote remove origin
git remote add origin http://jlim@git.qa.tpp.com:8080/scm/edp/tedp.git
git push --set-upstream origin master


Removing commit 
===========================

>>> Careful: git reset --hard WILL DELETE YOUR WORKING DIRECTORY CHANGES. Be sure to stash any local changes you want to keep before running this command. <<<

Assuming you are sitting on that commit, then this command will wack it...
  git reset --hard HEAD~1

The HEAD~1 means the commit before head.

Or, you could look at the output of 
  git log - find the commit id of the commit you want to back up to, and then do this:
  git reset --hard <sha1-commit-id>

If you already pushed it, you will need to do a force push to get rid of it...
  git push origin HEAD --force

However, if others may have pulled it, then you would be better off starting a new branch. Because when they pull, it will just merge it into their work, 
and you will get it pushed back up again.  If you already pushed, it may be better to use git revert, to create a "mirror image" commit that will undo the 
changes. However, both commits will be in the log.

----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
If you have not yet pushed the commit anywhere, you can use git rebase -i to remove that commit. First, find out how far back that commit is (approximately). 
Then do:

  git rebase -i HEAD~N
  
  The ~N means rebase the last N commits (N must be a number, for example HEAD~10). Then, you can edit the file that Git presents to you to delete the offending commit. 
  On saving that file, Git will then rewrite all the following commits as if the one you deleted didn't exist.

Rename committed message
===========================

git rebase -i HEAD~3   --> Get the last 3 commits

Look something like this
 pick e499d89 Delete CNAME
 pick 0c39034 Better README
 pick f7fde4a Change the commit message but push the same commit.

# Rebase 9fdb3bd..f7fde4a onto 9fdb3bd
#
# Commands:
#  p, pick = use commit
#  r, reword = use commit, but edit the commit message
#  e, edit = use commit, but stop for amending
#  s, squash = use commit, but meld into previous commit
#  f, fixup = like "squash", but discard this commit's log message
#  x, exec = run command (the rest of the line) using shell
#
# These lines can be re-ordered; they are executed from top to bottom.
#
# If you remove a line here THAT COMMIT WILL BE LOST.
#
# However, if you remove everything, the rebase will be aborted.
#
# Note that empty commits are commented out
Replace pick with reword before each commit message you want to change.

 pick e499d89 Delete CNAME
 reword 0c39034 Better README
 reword f7fde4a Change the commit message but push the same commit.


In each resulting commit file, type the new commit message, save the file, and close it.
Force-push the amended commits.
 git push --force


Cloning
============
git clone -b <Branch_name> git@github.com:user/myproject.git

Clear or Revert
=================
git checkout . - Removes Unstaged Tracked files ONLY [Type 2]
git clean -f - Removes Unstaged UnTracked files ONLY [Type 3]
git reset --hard - Removes Staged Tracked and UnStaged Tracked files ONLY[Type 1, Type 2]
git stash -u - Removes all changes [Type 1, Type 2, Type 3]

Checkout branch
================
If branche created at remote server, local git will not see or have the remote branch 
when issuing `git branch -r or -a`

A git remote update needs to execute so that local git will fetch information remotely
  `git remote update`

Now you can `git branch -r` or `git checkout` the branch

Delete branch
=============
git push origin --delete <branch_name>  Delete remote branch
git branch -d <branch name>             Delete branch locally

git branch -a  (list all branch)
git branch -r  (list remote branch)

Pulling from other branch changes to local branches
====================================================
git fetch      (This will pull all changes into local git staging)
git merge origin/<branch name>    (Get the changes from remote changes)

Getting latest update from master
=================================
git pull origin master

push update
==============
git add --all && git commit -m "Your Message"
git add -A && git commit -m "Your Message"

Create Pull Request
======================
This is to commit and ask a person to pull and review your work


Switch Branch and start from new
===================================
git reset --hard   - When you don't want to keep your local changes at all.
git clean -fd      - Clean all untracked version folder and modified files

Git Stash Multiple times
============================
Stash
------
git stash -u  --- Put all your current working changes into a staging and start a new branch
git stash pop -- Retrieve all staging before

You can get a list of all stashes with

git stash list
which will show you something like

stash@{0}: WIP on dev: 1f6f8bb Commit message A
stash@{1}: WIP on master: 50cf63b Commit message B
If you made two stashes, then just call git stash pop twice. As opposed to git stash apply, pop applies and removes the latest stash.

You can also reference a specific stash, e.g.

git stash show stash@{1}
or
git stash apply stash@{1}

If you want to git stash pop twice because you want both stashes in the same commit but you encounter 
"error: Your local changes to the following files would be overwritten by merge:" on your 2nd git stash pop, then you can: 
1) git stash pop, 2) git add ., and 3) git stash pop. – gabe Mar 5 '15 at 16:37


-------------------------------------------------------------------------------------------------------------------------------------------------------------------

Reason for adding an answer at this moment: So far I was adding the conclusion and ‘answers’ to my initial question itself, making the question very lengthy, hence moving to separate answer, so that I can add more used git commands as well as add more commands that helps me on git, to help someone else too.

#check status

git status
#create a new local branch

git checkout -b "branchname" 
#commit local changes [two step process:- Add the file to the index, that means adding to the staging area. Then commit the files that are present in this staging area]

git add <path to file>

git commit -m "commit message"
#checkout some other local branch

git checkout "local branch name"
#remove all changes in local branch [Suppose you made some changes in local branch like adding new file or modifying existing file, or making a local commit, but no longer need that] git clean -d -f and git reset --hard [clean all local changes made to the local branch except if local commit]

git stash -u also removes all changes

Note: It's clear that we can use either (1) combination of git clean –d –f and git reset --hard OR (2) git stash -u to achieve the desired result.

Note 1: Stashing, as the word means 'Store (something) safely and secretly in a specified place.' This can always be retreived using git stash pop. So choosing between the above two options is developer's call.

Note 2: git reset --hard will delete working directory changes. Be sure to stash any local changes you want to keep before running this command.

# Switch to the master branch and make sure you are up to date.

git checkout master
git fetch [this may be necessary (depending on your git config) to receive updates on origin/master ]

git pull
# Merge the feature branch into the master branch.

git merge feature_branch
# Reset the master branch to origin's state.

git reset origin/master
#Accidentally deleted a file from local , how to retrieve it back? Do a git status to get the complete filepath of the deleted resource

git checkout branchname <file path name>
that's it!

#Merge master branch with someotherbranch

git checkout master
git merge someotherbranchname
#rename local branch

git branch -m old-branch-name new-branch-name
#delete local branch

git branch -D branch-name
#delete remote branch

git push origin :branch-name
#revert a commit already pushed to a remote repository

git revert hgytyz4567
#branch from a previous commit using GIT

git branch branchname <sha1-of-commit>
#Change commit message of the most recent commit that's already been pushed to remote

git commit --amend -m "new commit message"
git push --force origin <branch-name>
# Discarding all local commits on this branch [Removing local commits]

In order to discard all local commits on this branch, to make the local branch identical to the "upstream" of this branch, simply run

git reset --hard @{u}
Reference: http://sethrobertson.github.io/GitFixUm/fixup.html or do git reset --hard origin/master [if local branch is master]

# Revert a commit already pushed to a remote repository?

$ git revert ab12cd15
#Delete a previous commit from local branch and remote branch Case: You just commited a change to your local branch and immediately pushed to the remote branch, Suddenly realized , Oh no! I dont need this change. Now do what? git reset --hard HEAD~1 [for deleting that commit from local branch. 1 denotes the ONE commit you made]

git push origin HEAD --force [both the commands must be executed. For deleting from remote branch]. branch means the currently checked out branch.

# Remove local git merge: Case: I am on master branch and merged master branch with a newly working branch phase2

$ git status
On branch master

$ git merge phase2  $ git status

On branch master

Your branch is ahead of 'origin/master' by 8 commits.

Q: How to get rid of this local git merge? Tried git reset --hard and git clean -d -f Both didn't work. The only thing that worked are any of the below ones:

$ git reset --hard origin/master

or

$ git reset --hard HEAD~8

or

$ git reset --hard 9a88396f51e2a068bb7 [sha commit code - this is the one that was present before all your merge commits happened]

shareimprove this answer
answered Sep 18 '15 at 21:18

spiderman
3,34932552
  	 	
Your command for Deleting Remote Branch might be not best. You are using git push origin :branch-name however I recommend using git push origin --delete branchname – vibs2006 May 4 at 6:18 
add a comment
up vote
3
down vote
1. When you don't want to keep your local changes at all.

git reset --hard
This command will completely remove all the local changes from your local repository. This is the best way to avoid conflicts during pull command, only if you don't want to keep your local changes at all.

2. When you want to keep your local changes

If you want to pull the new changes from remote and want to ignore the local changes during this pull then,

git stash
It will stash all the local changes, now you can pull the remote changes,

git pull
Now, you can bring back your local changes by,

git stash pop
shareimprove this answer


https://help.github.com/articles/fork-a-repo/
https://www.atlassian.com/blog/git/git-branching-and-forking-in-the-enterprise-why-fork
https://gist.github.com/Chaser324/ce0505fbed06b947d962


There is no tracking information for the current branch.
Please specify which branch you want to merge with.
See git-pull(1) for details.

    git pull <remote> <branch>

If you wish to set tracking information for this branch you can do so with:

    git branch --set-upstream-to=origin/<branch> master


JLim@PC0B9KEF MINGW64 /c/Workspace/App.Java/tedp.master (master)
$ git checkout master
Already on 'master'

JLim@PC0B9KEF MINGW64 /c/Workspace/App.Java/tedp.master (master)
$ git branch feature/EDP-90

JLim@PC0B9KEF MINGW64 /c/Workspace/App.Java/tedp.master (master)
$ git branch
  feature/EDP-90
* master

JLim@PC0B9KEF MINGW64 /c/Workspace/App.Java/tedp.master (master)
$ git checkout feature/EDP-90
Switched to branch 'feature/EDP-90'

JLim@PC0B9KEF MINGW64 /c/Workspace/App.Java/tedp.master (feature/EDP-90)
$ git push --set-upstream origin feature/EDP-90
Total 0 (delta 0), reused 0 (delta 0)
remote:
remote: Create pull request for feature/EDP-90:
remote:   http://git.qa.tpp.com:8080/projects/EDP/repos/tedp/compare/commits?sourceBranch=refs/heads/feature/EDP-90
remote:
To http://git.qa.tpp.com:8080/scm/edp/tedp.git
 * [new branch]      feature/EDP-90 -> feature/EDP-90
Branch feature/EDP-90 set up to track remote branch feature/EDP-90 from origin.

JLim@PC0B9KEF MINGW64 /c/Workspace/App.Java/tedp.master (feature/EDP-90)
$ ^C

JLim@PC0B9KEF MINGW64 /c/Workspace/App.Java/tedp.master (feature/EDP-90)
$ ^C

JLim@PC0B9KEF MINGW64 /c/Workspace/App.Java/tedp.master (feature/EDP-90)
$ git checkout feature/EDP-90
Already on 'feature/EDP-90'
Your branch is up-to-date with 'origin/feature/EDP-90'.

JLim@PC0B9KEF MINGW64 /c/Workspace/App.Java/tedp.master (feature/EDP-90)
$
