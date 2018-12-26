One of my projects starting getting some PRs recently - I learned how to add their branches as remotely, and add and push commits to them.

## The PR

I am working on a project called Vue Testing Handbook. You can view it at [here](https://lmiller1990.github.io/vue-testing-handbook/). Recently [this](https://github.com/lmiller1990/vue-testing-handbook/pull/59) PR was made. Sometimes I like to do some minor formatting before merging.

## Adding as a Remote

The first thing I need to do if I want to add some commits to this PR is add the other user's repository as a remote. His repository url is https://github.com/superyusuke/vue-testing-handbook.git. I can add it under any name I like. I'll use `yusuke`. So, to add the repo I can run

```sh
git remote add yusuke https://github.com/superyusuke/vue-testing-handbook.git
```

I can view a list of my remote repositories by running `git remote`. I get the following: 

```
alex
fork
origin
yusuke
```

Looks like it's working. I can actually fetch all his branches using `git fetch yusuke`.

## Checking Out the Branch

Next I want to check his branch out. I will make a new branch, forked from his. I can do this by running `git checkout -b yusuke-vuex-update yusuke/japanese/testing-vuex`. The output is `Branch 'yusuke-vuex-update' set up to track remote branch 'japanese/testing-vuex' from 'yusuke'`. This new branch is __tracking__ the remote. [This](https://stackoverflow.com/questions/4693588/git-what-is-a-tracking-branch) Stack Overflow explains it well. Simply put:

> A 'tracking branch' in Git is a local branch that is connected to a remote branch. When you push and pull on that branch, it automatically pushes and pulls to the remote branch that it is connected with.

That means if I commit and push anything to my local `yusuke-vuex-update`, git knows which remote repo and branch to push to. In this case, that will be the branch that is making the PR against my repo.

## Pushing to the Remote

After I made my changes locally on `yusuke-vuex-update`, I committed them and ran `git push`. I got the following message:

```sh
fatal: The upstream branch of your current branch does not match
the name of your current branch.  To push to the upstream branch
on the remote, use

    git push yusuke HEAD:japanese/testing-vuex

To push to the branch of the same name on the remote, use

    git push yusuke yusuke-vuex-update

To choose either option permanently, see push.default in 'git help config'.
```

I want my new commits to be on the same branch - that is, I want them to become the new `HEAD`. The second option would create a new branch, which is not what I want. So I run `git push yusuke HEAD:japanese/testing-vuex`. It works.

## Conclusion

- You add a remote repo by typing `git remote add [remote-name-to-use-locally] [remote-url]`
- A full example is `git remote add yusuke https://github.com/superyusuke/vue-testing-handbook.git`

- Checkout a remote branch with `git checkout -b [new-local-branch-name] [remote-name-to-use-locally]/[remote-branch]`
- A full example is `git checkout -b update-yusuke-testing-vuex yusuke/japanese/testing-vuex`.
- This sets up a local branch which is __tracking__ the remote
- When a local branch his tracking a remote branch, git knows which remote repoistory and branch to push any commits to

- To push to a remote from a tracking branch, you can run `git push [remote-name-to-use-locally] HEAD:[remote-branch]`
- Aa full example is `git push yusuke HEAD:japanese/testing-vuex`
