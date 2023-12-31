#!/bin/bash --login
git branch -D ${CUSTOM_CI_COMMIT_TARGET_REF_NAME}
git checkout ${CUSTOM_CI_COMMIT_TARGET_REF_NAME}
git merge --no-ff ${CI_COMMIT_SHA} -m "temp merge"
git log -n 2 --first-parent
export GIT_PREVIOUS_COMMIT=`git log --first-parent -n 1 --skip 1 --pretty=format:"%H"` #获取首父节点倒数第二个commit
export GIT_COMMIT=`git rev-parse HEAD`
echo "target_last_commit:${GIT_COMMIT}"
echo "current_commit:${CI_COMMIT_SHA}"
export DEVELOPER_DIR="$(path_for_version_string 12.x)"
bundle exec brickwork ci "."
