#/bin/bash

base_path=$(
  cd $(dirname $0)
  pwd
)
source "$base_path/common.sh"
log "BasePath: ${base_path}" $RES

function clean_dir() {
    if [[ -e $1 ]]; then
        rm -r $1
    fi

    mkdir -p $1
}

# ios-client根目录
repo_dir="$base_path/../.."

# eesz.zip 文件父目录
eesz_dir="$repo_dir/Modules/SpaceKit/Libs/SKResource/Resources/eesz-zip"

# bundle内前端精简包，也可能是txz或7z格式
eesz_source_file="$eesz_dir/eesz.zip"

# 临时路径
tmp_path="$repo_dir/tmp"

# 解压缓存文件目录
file_tmp_dir="$tmp_path/feishu_ccm_eesz_tmp"
clean_dir $file_tmp_dir

file_tmp_path="$file_tmp_dir/new_eesz.zip"

# 7z 可执行文件存放位置
executable_7z_dir="$tmp_path/fs_ccm_7z"
clean_dir $executable_7z_dir
executable_7z_path="$executable_7z_dir/7zz"

function download_7z_executable() {
    curl http://tosv.byted.org/obj/ee-infra-ios/7zz -o $executable_7z_path
    chmod +x $executable_7z_path
    codesign --force --deep --sign - $executable_7z_path
}

function read_download_url() {
    # URL prefix
    download_url_prefix="full_pkg_url_home:"
    # 完整包版本前缀
    download_fullpkg_version_prefix="full_pkg_scm_version:"
    # 当前包版本前缀
    current_pkg_version_prefix="version:"

    if [ ! -e "$eesz_source_file" ]; then
        eesz_source_file="$eesz_dir/eesz.txz" # 先判断txz是否存在
        if [ ! -e $eesz_source_file ]; then
            eesz_source_file="$eesz_dir/eesz.7z" # 没有txz, 再判断7z是否存在
            if [ ! -e $eesz_source_file ]; then
                log "路径${{eesz_dir}}不存在" $RED
                exit 10002; # miss eesz file path.
            fi
        fi
    fi

    for line in $(cat "$eesz_dir/current_revision")
    do
        # if [[ $line == $download_url_prefix* ]]; then
        #     eesz_download_url=${line#"$download_url_prefix"} # remove prefix
        #     log "找到 eesz 完整包 download url: $eesz_download_url"
        # fi
        if [[ $line == $download_fullpkg_version_prefix* ]]; then
            full_pkg_version=${line#"$download_fullpkg_version_prefix"} # 示例1.0.3.7787
            full_pkg_version=$(echo ${full_pkg_version//./_}) # 示例1_0_3_7787
            eesz_download_url="http://tosv.byted.org/obj/bytedance-oss-bear-web-test/scm_zip/${full_pkg_version}/ios/docs_channel.zip"
            log "找到 eesz 完整包 download url: $eesz_download_url"
        fi
    
        if [[ $line == $current_pkg_version_prefix* ]]; then
            current_pkg_version=${line#"$current_pkg_version_prefix"} # 示例1.0.3.7787
        fi
    done

    version_desc_all=$(cat "$eesz_dir/current_revision")
    full_pkg_tag="is_slim:0" # 已经是完整包了
    if [[ $version_desc_all == *$full_pkg_tag* ]]
    then
        log "当前包是完整包: $current_pkg_version"
        exit 0 # 直接退出
    else
        log "当前包是精简包: $current_pkg_version"
    fi

    if [ -n "$eesz_download_url" ]; then
        log "New eesz download url: $eesz_download_url" $GREEN
    else
        log "Read eesz download URL failed." $RED
        exit 10004
    fi

    clean_dir $file_tmp_dir
}

function download_new_resource() {
    curl $eesz_download_url -o $file_tmp_path

    if [ -e $file_tmp_path ]; then
        log "New eesz download success." $GREEN
        log "New eesz download path: $file_tmp_path." $GREEN
    else
        log "New eesz download failed." $RED
        exit 10005
    fi
}

function reformat_and_repalce() {
    unzip -qo $file_tmp_path -d $file_tmp_dir > /dev/null

    pushd $file_tmp_dir/docs_channel
    if [[ $eesz_source_file == *zip ]]; then
        zip -r ../eesz.zip eesz > /dev/null
        mv $file_tmp_dir/eesz.zip $eesz_source_file
    elif [[ $eesz_source_file == *txz ]]; then
        # tar -Jcvf ../eesz.txz eesz # 默认压缩等级6
        tar -Jcvf ../eesz.txz --options xz:compression-level=9 eesz # 压缩等级9, 与CCM工程一致
        if [ $? -ne 0 ];then
            echo "tar.xz压缩失败, 请检查log中的失败原因"
            exit 1
        fi
        mv $file_tmp_dir/eesz.txz $eesz_source_file
    else
        $executable_7z_path a ../eesz.7z eesz -mx5
        mv $file_tmp_dir/eesz.7z $eesz_source_file
    fi

    mv $file_tmp_dir/docs_channel/eesz/current_revision $eesz_dir/
    popd
    touch "$tmp_path/success"
}

if [ -e "$tmp_path/success" ]; then
    log "已经替换过资源，不再执行"
else
    clean_dir $file_tmp_dir
    read_download_url
    download_new_resource
    reformat_and_repalce
fi