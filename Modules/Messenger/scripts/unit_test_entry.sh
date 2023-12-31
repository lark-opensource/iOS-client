#!/bin/bash
PROG_DIR="$(cd -- "$(dirname "$0")" && pwd -P)"
PROG_NAME=$(basename "$0")

export LANG=en_US.UTF-8
export LANGUAGE=en_US.UTF-8
export LC_ALL=en_US.UTF-8

# Disable the pager of 'git log'
export PAGER=cat

# To prevent editing `.bashrc`
export CI_SOURCE=1

print_usage() {
    echo "Usage: $PROG_NAME [options]"
    echo "Run unit test"
    echo "  -h, --help           Display this usage and then exit"
    echo "  -m, --mock_ci        Mock CI environment"
    echo "  -g, --code_coverage  Enable code coverage"
    echo "  --enable_baymax      Run baymax procedure"
}

mock_ci="false"
code_coverage="false"
enable_baymax="false"
while [ $# -gt 0 ]; do
    case "$1" in
        -h | --help)
            print_usage
            exit 0
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

project_dir="$(cd -- "$PROG_DIR/.." && pwd -P)"

export TARGETCODEPATH="$project_dir"
export HOST_APP_XCWORKSPACE="Lark.xcworkspace"
export HOST_APP_SCHEME="LarkMessengerDemo"
export HOST_APP_PRODUCT="Messenger.app"
export XCODE_UNIT_TEST_CONFIGURATION="Debug"
export XCODE_UNIT_TEST_SDK="iphonesimulator"

run_unit_test_prog="$PROG_DIR/unit_test.sh"

run_unit_test_cmd="bash $run_unit_test_prog -c -b"
if [ "$mock_ci" = "true" ]; then
    run_unit_test_cmd="$run_unit_test_cmd -m"
fi
if [ "$code_coverage" = "true" ]; then
    run_unit_test_cmd="$run_unit_test_cmd -g"
fi
if [ "$enable_baymax" = "true" ]; then
    run_unit_test_cmd="$run_unit_test_cmd --enable_baymax"
fi

echo "$run_unit_test_cmd"
eval "$run_unit_test_cmd"
