#!/bin/bash
set -e

# Result variables.
master_to_develop_files_changed=""
merged_feature_branches=""

exit_status=0
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

git fetch -a --prune -q


# Looking for changes in master but not in develop.
for sha1 in $(git log --format=format:%H --no-merges develop..master); do
  for file_name in $(git show $sha1 --name-only --pretty=format:""); do
    master_to_develop_files_changed=$master_to_develop_files_changed$file_name"\n"
  done
done
master_to_develop_files_changed=$(echo -e $master_to_develop_files_changed | grep -vE "^[ \n]*$|^\.npmrc")


# Looking for merged feature branches.
branches=$(git branch --list --remotes | tail -n +2)
for branch in $branches; do
  if [[ $branch =~ ^origin/feature* ]];
  then
    unmerged_commits=$(git log $branch..develop)
    if [[ -z "$unmerged_commits" ]];
    then
      merged_feature_branches=$merged_feature_branches$branch"\n"
    fi
  fi
done


git checkout $current_branch -q
if [ "$stash_content" != "No local changes to save" ]
then
  git stash pop -q
fi


if [[ ! -z "$master_to_develop_files_changed" ]];
then
  echo "The following files were changed in master but not in develop:"
  echo -e $master_to_develop_files_changed
  echo ""
  exit_status=1
else
  echo "No changes in master that are not in develop."
fi

if [[ ! -z "$merged_feature_branches" ]];
then
  echo "The following feature branches are no longer needed:"
  echo -e $merged_feature_branches
  echo ""
  exit_status=1
else
  echo "No merged feature branches remaining."
fi

popd >> /dev/null
exit $exit_status
