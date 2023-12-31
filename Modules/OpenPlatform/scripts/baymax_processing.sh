#!/bin/bash
# Do not run this script independently.
# You MUST `source` this file in `unit_test.sh`.

baymax_script_url="https://tosv.byted.org/obj/thubservice-public/bd_ut/lhw/online/unit-test.py"
baymax_upload_method="uploadv2"
baymax_ut_script="baymax_unit_test.py"

if [ -n "$BAYMAX_SCRIPT_URL" ]; then
    baymax_script_url="$BAYMAX_SCRIPT_URL"
fi
if [ -n "$BAYMAX_UPLOAD_METHOD" ]; then
    baymax_upload_method="$BAYMAX_UPLOAD_METHOD"
fi

[ -r "$baymax_ut_script" ] && rm -rf "$baymax_ut_script"

echo ""
echo "Run baymax ..."
export CI_PROJECT_DIR="$project_dir"
export BAYMAX_PRODUCT_PATH="$xcode_derived_data_path/Build/Products/${xcode_unit_test_configuration}-${xcode_unit_test_sdk}/$host_app_product"
export BAYMAX_XCRESULT="$xcode_derived_data_path/Logs/Test"

baymax_cmd="curl -s $baymax_script_url -o $baymax_ut_script"
echo "$baymax_cmd"
eval "$baymax_cmd"
if [ ! -s "$baymax_ut_script" ]; then
    echo "Error: getting baymax script failed."
    exit "$unit_test_status"
fi

baymax_cmd="python3 $baymax_ut_script ios $baymax_upload_method"
baymax_status=0
echo "$baymax_cmd"
eval "$baymax_cmd" || baymax_status="$?"
if [ "$baymax_status" -ne 0 ]; then
    echo "Run baymax failed."
else
    echo "Run baymax succeeded."
fi
