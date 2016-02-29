#!/bin/bash
set -e

repo_path=$1

if [[ -a git_monkey.txt ]];
then
  cat git_monkey.txt
fi

if [[ -z "$repo_path" ]];
then
  echo "Please provide a git repository path."
  exit 1
fi

pushd $repo_path

stash_content=$(git stash)
current_branch=$(git rev-parse --abbrev-ref HEAD)

git checkout develop -q
git pull origin develop -q

git checkout master -q
git pull origin master -q

echo "Printing list of changes in master not in develop"
for sha1 in $(git log --format=format:%H --no-merges develop..master); do
  git diff $sha1 $sha1^1
done

git fetch -a --prune -q

branches=$(git branch --list --remotes | tail -n +2)
for branch in $branches; do
  if [[ $branch =~ ^origin/feature* ]];
  then
    unmerged_commits=$(git log $branch..develop)
    if [[ -z unmerged_commits ]];
    then
      echo "The feature branch "$branch" has been merged in develop and should be deleted."
    fi
  fi
done

git checkout $current_branch-q

if [ "$stash_content" != "No local changes to save" ]
then
  git stash pop -q
fi

popd
