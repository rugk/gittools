#!/bin/bash
# Cleans up unused/legacy branches that once were feature branches or have already been deleted at the remote, both on your local and remote site.
# See https://stackoverflow.com/questions/3184555/cleaning-up-old-remote-git-branches
#
# LICENSE: CC0/Public Domain - To the extent possible under law, rugk has waived all copyright and related or neighboring rights to this work. This work is published from: Deutschland.
#

# safe run

git remote prune origin --dry-run
git fetch --prune --dry-run
git branch -r --merged | grep origin | grep -v '>' | grep -v master | perl -lpe '($junk, $_) = split(/\//, $_,2)' | xargs git push origin --delete --dry-run

echo
read -rp "Continue? [y/N] " cont
if [ "${cont}" != "y" ] && [ "${cont}" != "Y" ]; then
    exit 1
fi

git remote prune origin --dry-run
git fetch --prune --dry-run
git branch -r --merged | grep origin | grep -v '>' | grep -v master | perl -lpe '($junk, $_) = split(/\//, $_,2)' | xargs git push origin --delete

# more local merged branches
git branch --merged | grep -E -v "(^\*|master|dev)"

echo
read -rp "Continue? [y/N] " cont
if [ "${cont}" != "y" ] && [ "${cont}" != "Y" ]; then
    exit 1
fi

git branch --merged | grep -E -v "(^\*|master|dev)" | xargs git branch -d

# possibly dangerous commands

echo "Deleting more merged branches?"
echo "[1]"
git branch -r --merged | grep -Ev 'HEAD|master|develop'

echo "[2]"
git branch -r | grep -Ev 'HEAD|master|develop|origin'

echo "[3] (MAY BE DANGEROUS!)"
git branch -r | grep -Ev 'HEAD|master|develop'

echo
read -rp "Delete 1, 2 or 3? [1/2/3] " cont
if [ "${cont}" != "1" ] && [ "${cont}" != "2" ] && [ "${cont}" != "3" ]; then
    exit 1
fi

if [ "${cont}" == "1" ]; then
    git branch -r --merged | grep -Ev 'HEAD|master|develop' | xargs -r git branch -rd
elif [ "${cont}" == "2" ]; then
	git branch -r | grep -Ev 'HEAD|master|develop|origin' | xargs -r git branch -rd
elif [ "${cont}" == "3" ]; then
	git branch -r | grep -Ev 'HEAD|master|develop' | xargs -r git branch -rd
fi
