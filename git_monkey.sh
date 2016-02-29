#!/bin/bash
set -e

# Result variables.
master_to_develop_files_changed=""
merged_feature_branches=""

repo_path=$1

git_monkey_ascii_art=$(dirname "$0")"/git_monkey.txt"
if [[ -a $git_monkey_ascii_art ]];
then
  cat $git_monkey_ascii_art
fi

if [[ -z "$repo_path" ]];
then
  echo "Please provide a git repository path."
  exit 1
fi

pushd $repo_path >> /dev/null

stash_content=$(git stash)
current_branch=$(git rev-parse --abbrev-ref HEAD)

git checkout develop -q
git pull origin develop -q >> /dev/null

git checkout master -q
git pull origin master -q >> /dev/null

# Looking for changes in master but not in develop.
for sha1 in $(git log --format=format:%H --no-merges develop..master); do
  for file_name in $(git show $sha1 --name-only --pretty=format:""); do
    master_to_develop_files_changed=$master_to_develop_files_changed$file_name"\n"
  done
done
master_to_develop_files_changed=$(echo -e $master_to_develop_files_changed | grep -vE "^[ \n]*$|^\.npmrc")


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

echo -e $master_to_develop_files_changed

popd >> /dev/null
