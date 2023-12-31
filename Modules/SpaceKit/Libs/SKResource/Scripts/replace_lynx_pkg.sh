lynx_pkg_version=''
pkg_save_path=$(cd "$(dirname "$0")";cd ../Resources/Lynx;pwd)
bin7z_path=$(cd "$(dirname "$0")";cd ../../../bin/bin7z/;pwd)  #7z压缩工具目录

while getopts 'v:' arg
do
		case $arg in
			v)
				lynx_pkg_version=$OPTARG
				;;
			?)  
				echo "不要输入我不懂的"
				exit
				;;
		esac
done

temp_zip_file='lark.lynx.docs.tar.gz'
if [ ! -f $temp_zip_file ]
then
	url="http://d.scm.byted.org/api/download/ceph:lark.lynx.docs_${lynx_pkg_version}.tar.gz"#"http://luban-source.byted.org/repository/scm/lark.lynx.docs_${lynx_pkg_version}.tar.gz"
	res_code=`curl -f --location --request GET "${url}" -o "${temp_zip_file}" -w %{http_code}`
	if [ $res_code = '200' ]
	then
		echo "下载成功"
	else
		rm -rf $temp_zip_file
		echo "下载错误，错误码：$res_code"
		exit 1
	fi
fi

tar_dir="lark.lynx.docs_${lynx_pkg_version}"
if [ ! -d $tar_dir ]
then
	mkdir $tar_dir
fi
tar zxf $temp_zip_file -C $tar_dir
rm -rf $temp_zip_file

cd $tar_dir
branch_file="branch_revision"
version_file="current_revision"
channel_dir="docs_lynx_channel"
# 写入分支信息
cat $branch_file >> $version_file
rm $branch_file
cp $version_file ./$channel_dir
$bin7z_path/7zz a docs_lynx_channel.7z $channel_dir -mx5

cp -rf docs_lynx_channel.7z $pkg_save_path
cp -rf current_revision $pkg_save_path
echo $pkg_save_path

cd ..
rm -rf $tar_dir

echo "大功告成"


