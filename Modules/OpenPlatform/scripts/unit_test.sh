#!/bin/bash
PROG_DIR="$(cd -- "$(dirname "$0")" && pwd -P)"
PROG_NAME=$(basename "$0")

ERROR_INVALID_PARAMS=31
ERROR_INVALID_BRANCH=32
ERROR_GIT_MERGE=33
ERROR_BUNDLE_INSTALL=34

print_usage() {
    echo "Usage: $PROG_NAME [options]"
    echo "Run unit test"
    echo "  -h, --help           Display this usage and then exit"
    echo "  -b, --always_build   Unconditionally build scheme"
    echo "  -c, --clean          Clean project before testing"
    echo "  -s, --skip_bundle    Skip procedure of 'bundle'"
    echo "  -m, --mock_ci        Mock CI environment"
    echo "  -g, --code_coverage  Enable code coverage"
    echo "  --enable_baymax      Run baymax procedure"
}

always_build="false"
clean_project="false"
skip_bundle="false"
mock_ci="false"
code_coverage="false"
enable_baymax="false"
while [ $# -gt 0 ]; do
    case "$1" in
        -h | --help)
            print_usage
            exit 0
            ;;
        -b | --always_build)
            always_build="true"
            ;;
        -c | --clean)
            clean_project="true"
            ;;
        -s | --skip_bundle)
            skip_bundle="true"
            ;;
        -m | --mock_ci)
            mock_ci="true"
            ;;
        -g | --code_coverage)
            code_coverage="true"
            ;;
        --enable_baymax)
            enable_baymax="true"
            ;;
    esac
    shift
done

running_in_pipeline="false"
if [ -n "$WORKFLOW_PIPELINE_URL" ]; then
    echo "Running in CI pipeline ..."
    running_in_pipeline="true"
fi

unit_test_prog="$PROG_DIR/unit_test.py"

project_dir="$TARGETCODEPATH"
host_app_xcworkspace="$project_dir/$HOST_APP_XCWORKSPACE"
host_app_scheme="$HOST_APP_SCHEME"
host_app_product="$HOST_APP_PRODUCT"
xcode_unit_test_configuration="$XCODE_UNIT_TEST_CONFIGURATION"
xcode_unit_test_sdk="$XCODE_UNIT_TEST_SDK"

if [ ! -d "$project_dir" ]; then
    echo "Error: invalid project dir('$project_dir')"
    exit "$ERROR_INVALID_PARAMS"
fi

if [ ! -d "$host_app_xcworkspace" ]; then
    echo "Error: invalid xcworkspace('$host_app_xcworkspace')"
    exit "$ERROR_INVALID_PARAMS"
fi

host_app_project_dir="$(cd -- "$(dirname "$host_app_xcworkspace")" && pwd -P)"
xcode_derived_data_path="$host_app_project_dir/DerivedData"
output_path="$TARGETCODEPATH/output"

cd "$project_dir"
rm -rf "$xcode_derived_data_path/Logs/Test"
rm -rf "$output_path"

force_checkout_to_branch() {
    local target_branch="$1"
    if [ -z "$target_branch" ]; then
        echo "Error: invalid branch('$target_branch')"
        exit "$ERROR_INVALID_BRANCH"
    fi

    echo "Checkout to branch '$target_branch'"
    git reset --hard
    git fetch origin --prune
    git branch -D "$target_branch" &>/dev/null || true
    git checkout "$target_branch"
    git reset --hard "origin/$target_branch"
}

if [ "$running_in_pipeline" = "true" ]; then
    if [ -f "$PROG_DIR/../Common/ci_prepare.sh" ]; then
        echo "Prepare MR env ..."
        python_index_url="$PROG_DIR/../python_requirements"
        requirements_txt="$PROG_DIR/requirements.txt"

        source "$PROG_DIR/../Common/ci_prepare.sh"

        if [ -n "$XCODE_VERSION" ]; then
            source "$PROG_DIR/../Common/select_xcode_version.sh"
        fi

        source "$PROG_DIR/../Common/ci_prepare_ruby.sh"
        source "$PROG_DIR/../Common/ci_activate_venv.sh" "$requirements_txt"
        source "$PROG_DIR/../Common/ci_prepare_target_repo.sh"
        bash "$PROG_DIR/../Common/ci_fix_pod_repo.sh"
    fi

    if [ -z "$RUNNING_BITS" ]; then
        export RUNNING_BITS="true"
    fi

    if [ -n "$WORKFLOW_REPO_TARGET_BRANCH" ] &&
        [ "$MERGE_TO_TARGET_BRANCH" = "true" ]; then
        force_checkout_to_branch "$WORKFLOW_REPO_TARGET_BRANCH"

        echo "Trying to merge source branch into target branch"
        error_status=0
        git merge --no-ff "origin/$WORKFLOW_REPO_BRANCH" \
            -m "temp" || error_status="$?"
        if [ "$error_status" -ne 0 ]; then
            echo "Error: failed to merge source branch into target branch"
            exit "$ERROR_GIT_MERGE"
        fi
    else
        force_checkout_to_branch "$WORKFLOW_REPO_BRANCH"
    fi

    git --no-pager log -n2 --first-parent

    mr_id="$CUSTOM_CI_MR_ID"
    [ -n "$CUSTOM_CI_HOST_MR_ID" ] && mr_id="$CUSTOM_CI_HOST_MR_ID"
    if [ -n "$mr_id" ]; then
        echo "Trying to sync dependencies from main repo ..."
        python3 -m pylib.verify_dependency_template \
            --main_repo_dir "$host_app_project_dir" \
            --project_id "$CUSTOM_CI_PROJECT_ID" \
            --mr_id "$mr_id" \
            --mr_iid "$CUSTOM_CI_MR_IID" \
            --repo_url "$WORKFLOW_REPO_URL"
    fi
else
    if [ "$mock_ci" = "true" ]; then
        # Mocking CI environment can only be enabled when running
        # in local environment
        export JOB_NAME="local"
        export USE_SWIFT_BINARY="true"
        export IS_SWIFT_BINARY_CACHE_ENABLE="true"
        export ASSERT_PATCH=1
    fi

    if [ "$enable_baymax" = "true" ]; then
        # `version.json` is needed by Baymax which depends on
        # environment variable `WORKSPACE`
        export WORKSPACE="$project_dir"

        # To prevent editing `.bashrc`
        export CI_SOURCE=1
    fi
fi

echo "PATH: $PATH"
cd "$host_app_project_dir"

if [ "$code_coverage" = "true" ]; then
    # To enable code coverage
    export NEED_ENABLE_XCTEST_CODE_COVERAGE="true"
fi

# Baymax needs `version.json` which is generated by running `pod install`
if [ "$enable_baymax" = "true" ] || [ "$skip_bundle" != "true" ]; then
    if [ "$running_in_pipeline" = "true" ]; then
        export BUNDLE_PATH="$HOME/.gem"
    else
        expected_bundle_path="$project_dir/.bundle"
        bundle config set --local path "$expected_bundle_path"
    fi

    macos_sdk="/Library/Developer/CommandLineTools/SDKs/MacOSX.sdk"
    if [ -e "$macos_sdk" ]; then
        bundle_cmd="SDKROOT=\"$macos_sdk\" bundle install"
    else
        bundle_cmd="DEVELOPER_DIR=\"\" bundle install"
    fi
    echo "$bundle_cmd"
    eval "$bundle_cmd"
    if [ $? -ne 0 ]; then
        echo "Error: bundle install failed"
        exit "$ERROR_BUNDLE_INSTALL"
    fi

    echo ""
    bundle_cmd="bundle exec pod install"
    if [ "$running_in_pipeline" = "true" ] ||
        [ "$clean_project" = "true" ]; then
        bundle_cmd="$bundle_cmd --clean-install"
    fi
    if [ "$running_in_pipeline" = "true" ]; then
        bundle_cmd="$bundle_cmd --verbose"
    fi
    bundle_cmd="$bundle_cmd || bundle exec pod update LarkSQLCipher"
    echo "$bundle_cmd"
    eval "$bundle_cmd"
    if [ $? -ne 0 ]; then
        echo "Error: bundle exec pod install failed"
        exit "$ERROR_BUNDLE_INSTALL"
    fi
    echo ""
fi

unit_test_cmd="python3 $unit_test_prog --verbose \
-w \"$host_app_xcworkspace\" \
-s \"$host_app_scheme\" \
-C \"$xcode_unit_test_configuration\" \
-S \"$xcode_unit_test_sdk\" \
-D \"$xcode_derived_data_path\" \
-o \"$output_path\""

if [ "$clean_project" = "true" ]; then
    unit_test_cmd="$unit_test_cmd -c"
fi

if [ "$always_build" = "true" ]; then
    unit_test_cmd="$unit_test_cmd -b"
fi

if [ -x "$(command \which xcpretty)" ]; then
    unit_test_cmd="$unit_test_cmd -p"
fi

unit_test_status=0
echo "$unit_test_cmd"
eval "$unit_test_cmd" || unit_test_status="$?"
if [ "$unit_test_status" -ne 0 ]; then
    echo "Unit Test failed(code: $unit_test_status)."
else
    echo "Unit Test succeeded."
fi

if [ "$enable_baymax" = "true" ]; then
    source "$PROG_DIR/baymax_processing.sh"
fi

exit "$unit_test_status"
