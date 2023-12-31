BRANCH_REGEX="^(develop$|release//*)"
git fetch
if [[ $WORKFLOW_REPO_TARGET_BRANCH =~ $BRANCH_REGEX ]]; then
    echo "******** 检查前端资源包是否为完整包 *************"
    export current_eesz_is_slim_str=`cat Modules/SpaceKit/Libs/SKResource/Resources/eesz-zip/current_revision | grep is_slim`
    echo $current_eesz_is_slim_str
    if [[ ${current_eesz_is_slim_str: -1} -ne 0 ]]; then
        echo "******** 需要内置完整包 *************"
        echo "******** 在群里警告出现精简包 *************"
        python3 Modules/SpaceKit/Scripts/alert_resource_not_slim_lark_notification.py
        exit -1
    fi

    echo "******** 检查前端资源包对应的完整包是否已发布 *************"
    pip3 install GitPython
#    python3 Modules/SpaceKit/Scripts/check_full_pkg_release.py
#    script_result_code=$?
#    if [ $script_result_code -ne 0 ]; then
#        exit $script_result_code
#    fi

    echo "******** 检查 Lynx 资源包分支和客户端分支是否一样 *************"
    python3 Modules/SpaceKit/Scripts/check_lynx_release_version.py
    script_result_code=$?
    if [ $script_result_code -ne 0 ]; then
        exit $script_result_code
    fi
fi

echo "******** 检查前端资源包分支和客户端分支是否一样 *************"
python3 Modules/SpaceKit/Scripts/check_offline_resources_release_version.py
script_result_code=$?
if [ $script_result_code -ne 0 ]; then
    exit $script_result_code
fi
