#!/usr/bin/env bash 
set -ex
DIR=`pwd`
target_branch=$WORKFLOW_REPO_TARGET_BRANCH
source_branch=$WORKFLOW_REPO_BRANCH
output="compile_commands.json"

cd "$DIR"
export BUNDLE_PATH=~/.gem
bash bitsky.sh --bundle --install --build --configuration Debug --sdk simulator | tee "Logs/bazelbuild.log" && exit ${PIPESTATUS[0]}
bash bitsky.sh --c --c_output_file temp_compile_commands.json
python3 scripts/process_compile_commands.py \
-repo_dir "$DIR" \
-compile_commands_file temp_compile_commands.json \
-target_branch origin/$target_branch \
-source_branch origin/$source_branch \
-output $output \
-test_command "false"