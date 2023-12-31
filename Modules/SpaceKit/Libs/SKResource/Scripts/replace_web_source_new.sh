# /bin/sh
# author: xurunkang

channel='docs_channel'
local_web_source_path=''
web_source_version=''

bundlepkg_format=3 #内置前端包格式：1: zip,   2: 7z,   3: txz

bin7z_path=$(cd "$(dirname "$0")";cd ../../../bin/bin7z/;pwd)  #7z压缩命令目录
binxz_path=$(cd "$(dirname "$0")";cd ../../../bin/binxz/;pwd)  #xz压缩命令目录

extension='' #压缩包后缀名
if [ $bundlepkg_format -eq 1 ]
then
    extension='.zip'
elif [ $bundlepkg_format -eq 2 ]
then
    extension='.7z'
elif [ $bundlepkg_format -eq 3 ]
then
    extension='.txz'
else
    echo "压缩包格式指定有误，使用默认zip"
    extension='.zip'
fi

while getopts "v:c:h" arg
do
        case $arg in
            v)
                echo "输入资源包号: $OPTARG"
                web_source_version=$OPTARG
                ;;
            c)
                echo "channel: $OPTARG"
                channel=$OPTARG
                ;;
            h)
                echo "1、拉取文件内指定的资源包版本号"
                echo "2、-v: 输入前端发的资源包"
                exit
                ;;
            ?)
                echo "不要输入我不懂的"
                exit
                ;;
        esac
done

# support_files 路径
support_files_path=$(cd "$(dirname "$0")";cd ../Resources;pwd)
# 缓存路径
tmp="/tmp"
# 缓存文件名字
temp_file="docs_temp_file"

# 缓存路径中的缓存文件
tmp_temp_file=$tmp/$temp_file

download_replace_resource(){

    if [[ "${web_source_version}" =~ .*\..* ]]
    then
        file_name=${web_source_version//\./\_}
    else
        file_name="${web_source_version}"
    fi

    cd $tmp; #echo "进入 `pwd`"

    # 假设文件不存在就创建一个新的
    if [ ! -d $temp_file ]
    then
        mkdir $temp_file
        # echo "创建新文件: $temp_file"
    fi

    cd $temp_file; # echo "进入 `pwd`"
    rm -rf `ls | grep -v ".tar.gz$"`

    # 判断是否已经存在同名文件
    if [ ! -f $file_name ]
    then
        web_source_url="http://tosv.byted.org/obj/bytedance-oss-bear-web-test/scm_zip/${file_name}/ios/${channel}.zip"
        echo "开始从 $web_source_url 下载前端离线资源包"
        res_code=`curl $web_source_url -o "${file_name}" -w %{http_code}`
        if [ $res_code = '200' ]
        then
            echo "结束下载啦"
        else
            rm -rf $file_name
            echo "下载错误，错误码:$res_code"
            exit 1
        fi
    fi

    # 解压文件名
    tar_dir="ee.bear-web_${web_source_version}"

    if [ ! -d $tar_dir ]
    then
        mkdir $tar_dir
        #echo "在 `pwd` 创建 $tar_dir 这个新目录"
    fi

    #echo "开始解压啦"
    tar zxf $file_name -C $tar_dir
    #echo "结束解压啦"

    cd $tar_dir/$channel; #echo "进入 `pwd`"

    ee_dir=eesz/
    ee_version_dir=eesz/current_revision

    #echo "复制版本文件开始"
    cp $ee_version_dir ./
    #echo "复制版本文件开始"

    #echo "压缩eesz目录开始"
    if [ $bundlepkg_format -eq 1 ]
    then
        zip -rq eesz.zip $ee_dir
    elif [ $bundlepkg_format -eq 2 ]
    then
        $bin7z_path/7zz a eesz.7z $ee_dir -mx5 # -mx?  压缩级别 https://linux.cn/thread-16334-1-1.html
        if [ $? -ne 0 ];then
            echo "7z压缩失败! (若提示权限问题, 请手动信任: spacekit-ios/bin/bin7z/7zz)"
            exit 1
        fi
    elif [ $bundlepkg_format -eq 3 ]
    then
        echo "开始压缩: " $ee_dir " -> eesz.txz"
        # # tar -Jcvf eesz.txz $ee_dir # 原先的压缩方式，默认压缩level为6
        # tar cvf eesz_raw.tar $ee_dir # 仅打包，把目录打包为文件不压缩
        # $binxz_path/xz -z -9e -v ./eesz_raw.tar # 用最大压缩等级(level为9)压缩为xz格式
        # mv ./eesz_raw.tar.xz ./eesz.txz # 重命名
        tar -Jcvf eesz.txz --options xz:compression-level=9 $ee_dir
        if [ $? -ne 0 ];then
            echo "tar.xz压缩失败, 请检查log中的失败原因"
            exit 1
        fi
    else
        echo "压缩包格式指定有误，使用默认zip"
        zip -rq eesz.zip $ee_dir
    fi
    #echo "压缩eesz目录结束"


    tmp_tmp_file_tar_dir=$tmp_temp_file/$tar_dir

    #echo "开始迁移啦"
    cd $support_files_path;# echo "进入 `pwd`"

    #echo "删除 DocsSDK/Resource/eesz-zip 中的文件"
    rm -rf eesz-zip/
    mkdir eesz-zip

    #echo "复制 $tmp_tmp_file_tar_dir/eesz.后缀名 和 current_revision 到 eesz 目录下"
    cp -rf $tmp_tmp_file_tar_dir/$channel/current_revision eesz-zip
    cp -rf $tmp_tmp_file_tar_dir/$channel/eesz$extension eesz-zip

    cd $tmp_temp_file;# echo "进入 `pwd`"
    #echo "删除缓存目录下除了压缩包以外所有临时文件"
    rm -rf `ls | grep -v "{$extension}$"`

    #echo "结束迁移啦"
}

record_web_version(){
    record_file_path="${support_files_path}/eesz-versions.txt"
    case $channel in
        docs_channel)
            sed -i "" "s%lark_version:.*%lark_version:${web_source_version}%" $record_file_path
            ;;
        docs_app)
            sed -i "" "s%larkdocs_version:.*%larkdocs_version:${web_source_version}%" $record_file_path
            ;;
    esac
}

download_replace_resource
record_web_version
echo "大功告成"
