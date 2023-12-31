# appcenter 切分支的hook脚本
if  [ ! -n "$LARK_AUTO_CHECKOUT" ] ;then
	echo '封板操作使用bits，nest已废弃'
	exit 0
fi

root_dir="$(dirname $0)"/..
cd "$root_dir"

# ensure current head is based on master
function ensure_on_master () {
    local origin_develop HEAD
    read -r origin_develop HEAD <<< $(git rev-parse origin/develop HEAD)
    if [[ $HEAD != $origin_develop ]]; then
        git checkout $origin_develop
    fi
}

ensure_on_master
bash bin/increase_version.bash
