#!/bin/bash
set -e

#Libraries that should always be on the latest version.
LIBRARIES="connectors ucommon"

exit_status=0
repo_path=$1

unicode_monkey="\U0001F435 "

echo -e "$unicode_monkey Git Monkey \u2122"

if [[ -z "$repo_path" ]];
then
  echo "Please provide a git repository path."
  exit 1
fi

pushd $repo_path >> /dev/null

no_changes () {
  git diff-index --quiet --cached HEAD --ignore-submodules -- &&
  git diff-files --quiet --ignore-submodules
}

if ! no_changes;
then
  popd >> /dev/null
  echo "Please make sure your git environment is clean."
  exit 1
fi

# Make sure we have to correct, up-to-date versions
# of the main branches, and a reference to all
# the available tags.
update_branches () {

  git checkout develop -q >> /dev/null 2> /dev/null
  git pull origin develop -q >> /dev/null 2> /dev/null

  git checkout master -q >> /dev/null 2> /dev/null
  git pull origin master -q >> /dev/null 2> /dev/null

  git fetch -a --tags --prune -q >> /dev/null 2> /dev/null

}

# Verifies that master and develop don't
# have the same major and minor version.
check_major_minor () {

  git checkout develop >> /dev/null 2> /dev/null
  develop_version=$(git describe --tags)
  git checkout master >> /dev/null 2> /dev/null
  master_version=$(git describe --tags)

  develop_major_minor=$(echo $develop_version | grep -Eo "(v[0-9]+\.[0-9]+)") 
  master_major_minor=$(echo $master_version | grep -Eo "(v[0-9]+\.[0-9]+)") 

  echo ""
  echo -e "$unicode_monkey Validating master and develop versions"
  if [[ "$develop_major_minor" == "$master_major_minor" ]];
  then
    echo "master and develop are on the same major.minor version!"
    echo "master version : $master_version"
    echo "develop version : $develop_version"
    exit_status=1
  else
    echo "master and develop are not on same major.minor version."
    echo "master version : $master_version"
    echo "develop version : $develop_version"
  fi

}

# Checks if other files than package.json have been modified
# on master and not on develop.
check_master_develop_changes () {

  has_unported_changes=0

  echo ""
  echo -e "$unicode_monkey Validating changes in master not in develop"

  commits_master_not_develop=$(git log --format=format:%H --no-merges develop..master)

  for sha1 in $commits_master_not_develop; do

    files_changed=""
    for file_name in $(git show $sha1 --name-only --pretty=format:""); do
      if [[ ! $file_name =~ (^[ \n]*$|^package.json) ]];
      then
        files_changed=$files_changed$file_name"\n"
      fi
    done

    if [[ ! -z "$files_changed" ]];
    then

      has_unported_changes=1

      echo "Commit $sha1 should be merged into develop."
      echo -e $files_changed

    fi

  done

  if ! [ "$has_unported_changes" -eq "0" ];
  then
    exit_status=$has_unported_changes
  else
    echo "No changes in master not in develop."
  fi

}

# Verifies the prensence of outdated (merged)
# feature branches.
check_outdated_feature_branches () {

  has_outdated_branches=0

  echo ""
  echo -e "$unicode_monkey Verifying outdated feature branches"

  branches=$(git branch --list --remotes | tail -n +2)

  for branch in $branches; do
    if [[ $branch =~ ^origin/feature* ]];
    then
      unmerged_commits=$(git log $branch..develop)
      if [[ -z "$unmerged_commits" ]];
      then
        echo "Branch $branch has been merged into develop already."
        has_outdated_branches=1
      fi
    fi
  done

  if ! [ "$has_outdated_branches" -eq "0" ];
  then
    exit_status=$has_outdated_branches
  else
    echo "No unmerged feature branches."
  fi

}

# Make sure that the versions of the libraries
# on develop are the latest versions available.
check_libraries_versions () {

  echo ""
  echo -e "$unicode_monkey Verifying the versions of the libraries"

  git checkout develop >> /dev/null 2> /dev/null

  ncu --upgrade ucommon connectors >> /dev/null 2> /dev/null

  if ! no_changes;
  then
    echo "Libraries are not at the latest versions on develop!"
    git checkout . >> /dev/null 2> /dev/null
    exit_status=1
  else
    echo "All libraries are at the latest versions!"
  fi

}

update_branches
check_major_minor
check_master_develop_changes
check_outdated_feature_branches
check_libraries_versions

popd >> /dev/null
exit $exit_status
