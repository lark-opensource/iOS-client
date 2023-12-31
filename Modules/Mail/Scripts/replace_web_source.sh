# /bin/sh
# author: xurunkang

#######################     注意: 请配置下面的信息    #############################
web_source_version=9286
################################################################################


############################   神奇的分割线   ####################################

## 输出环境
pwd
tar --version

local_web_source_path=''
while getopts "p:h" arg
do
        case $arg in
            p)
                echo "输入路径: $OPTARG"
                local_web_source_path=$OPTARG
                ;;
            h)
                echo "1、直接执行默认去 SCM 拉资源包"
                echo "2、-p: 输入前端发的资源包"
                exit
                ;;
            ?)
                echo "不要输入我不懂的"
                exit
                ;;
        esac
done

# support_files 路径
support_files_path=$(cd "$(dirname "$0")";cd ../Resources/SupportFiles;pwd)
# 缓存路径
tmp="/tmp"
# 缓存文件名字
temp_file="docs_temp_file"

# 缓存路径中的缓存文件
tmp_temp_file=$tmp/$temp_file

use_local_web_source(){
    echo "解压本地数据: $local_web_source_path"

    cd $tmp/$temp_file

    echo "开始解压啦"
    rm -rf output
    mkdir output
    tar zxf $local_web_source_path -C output
    echo "结束解压啦"

    echo "开始迁移啦"
    cd $support_files_path
    cp -rf $tmp/output/resource $tmp/output/template eesz
    echo "$tmp -> eesz"
    echo "结束迁移啦"
}

use_online_web_source(){

    echo "启动 SCM 下载"

    file_name="ee.bear-web_1.0.0."${web_source_version}".tar.gz"

    cd $tmp; echo "移动到: `pwd`"

    # 假设文件不存在就创建一个新的
    if [ ! -d $temp_file ]
    then
        mkdir $temp_file
        echo "创建新文件: $temp_file"
    fi

    cd $temp_file; echo "移动到: `pwd`"
    rm -rf `ls | grep -v ".tar.gz$"`

    # 判断是否已经存在同名文件
    if [ ! -f $file_name ]
    then
        web_source_url="http://d.scm.byted.org/api/versions/401214/download/"${file_name}
        echo "下载地址: $web_source_url"
        echo "开始下载啦"
        res_code=`curl $web_source_url -o $file_name -w %{http_code}`
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
    tar_dir="ee.bear-web_1.0.0."${web_source_version}""

    if [ ! -d $tar_dir ]
    then
        mkdir $tar_dir
        echo "创建新文件"
    fi

    echo "开始解压啦"
    tar zxf $file_name -C $tar_dir
    cd $tar_dir; echo "移动到: `pwd`"
    unzip docs_channel.zip
    echo "结束解压啦"

    tmp_tmp_file_tar_dir=$tmp_temp_file/$tar_dir

    echo "开始迁移啦"
    cd $support_files_path; echo "移动到: `pwd`"

    echo "删除 DocsSDK 中 eesz/"
    rm -rf eesz/current_revision
    rm -rf eesz/resource
    rm -rf eesz/template

    echo "休眠一下吧脚本太快了"
    sleep 0.5

    echo "复制 tmp 中的相关文件到 eesz 目录下"
    cp $tmp_tmp_file_tar_dir/current_revision eesz
    cp -rf $tmp_tmp_file_tar_dir/docs_channel/eesz/resource eesz
    cp -rf $tmp_tmp_file_tar_dir/docs_channel/eesz/template eesz

    echo "休眠一下吧脚本太快了"
    sleep 0.5

    cd eesz; echo "移动到: `pwd`"
    echo "检查迁移是否成功"
    echo "检查 current_revision"
    if [ ! -f "current_revision" ]
    then
      echo "current_revision 不存在"
      exit 1
    fi

    echo "检查 resource"
    if [ ! -d "resource" ]
    then
      echo "resource 不存在"
      exit 1
    fi

    echo "检查 template"
    if [ ! -d "template" ]
    then
      echo "template 不存在"
      exit 1
    fi

    cd $tmp_temp_file; echo "移动到: `pwd`"
    echo "删除缓存目录下除了压缩包以外所有临时文件"
    rm -rf `ls | grep -v ".tar.gz$"`

    echo "结束迁移啦"
}

if [[ $local_web_source_path != '' ]]
then
    use_local_web_source
else
    use_online_web_source
fi

echo "大功告成"
