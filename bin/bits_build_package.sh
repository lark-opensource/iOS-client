#!/bin/bash
cd ${WORKSPACE}
echo "开始执行打包"
git branch -D ${CUSTOM_CI_COMMIT_TARGET_REF_NAME} || echo "${CUSTOM_CI_COMMIT_TARGET_REF_NAME}本地分支不存在"
git checkout ${CUSTOM_CI_COMMIT_TARGET_REF_NAME}
git merge --no-ff ${WORKFLOW_REPO_COMMIT} -m "temp merge"
git log -n 2 --first-parent
export DEVELOPER_DIR=/Applications/Xcode-12.app/Contents/Developer
export RUNNING_BITS=true
export USE_SWIFT_BINARY=false
export TMPDIR=`pwd`
pip3 install virtualenv --user
source venv/bin/activate
pip3 install -r ./.bits/verify_dependency/requirements.txt
[ -d "./.bits/verify_dependency/verify_dependency.py"] && python3 ./.bits/verify_dependency/verify_dependency.py --main_repod_dir $MAIN_CODE_REPO_DIR --project_id $CUSTOM_CI_PROJECT_ID --mr_id $CUSTOM_CI_MR_IID #集成MR情况下，修改podfile来验证
bundle exec fastlane ios Lark build_channel:'inhouse' configuration:'Release' build_number:$TASK_ID output_directory:${WORKSPACE}/product
