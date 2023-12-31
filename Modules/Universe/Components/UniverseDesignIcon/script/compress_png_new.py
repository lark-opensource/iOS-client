#! /usr/bin/python
# -*- coding: utf-8 -*-

# -*- author: huangjianming -*-

import os
import os.path
import glob
import json
import argparse
import subprocess

# 本脚本主要是调用pngquant进行图片压缩，内部会走一些缓存策略，提高整体脚本执行时间.
# .compress_record.json是缓存文件，存放了已经压缩过的文件路径和压缩后的文件大小，每次压缩会进行判断，如果没有缓存文件记录或者当前文件大小比缓存记录大的话都会进行重新压缩。
# pngquant重复调用png文件不会变化

cache_file_name = ".compress_record.json"
parent_dir = os.path.dirname(__file__)
pyPath = os.path.abspath(__file__).replace("compress_png_new.py", "")


def __pngquantPicture(file_path):
    """
    使用pngquant进行图片压缩
    :param file_path: 文件
    :return: （文件路径，压缩后大小）
    """
    pngquant_path = get_pngquant_path()
    filesize_before = os.path.getsize(file_path)
    os.system("{} -f --ext .png --strip --skip-if-larger --quality 50-70 \"{}\"".format(pngquant_path, file_path))
    filesize_after = os.path.getsize(file_path)
    return (file_path, filesize_after)


def __getRecord(dir):
    """
    指定文件夹，读取缓存信息
    :param dir: 目录
    :return: 缓存信息
    """
    record_path = os.path.join(dir, cache_file_name)
    if os.path.exists(record_path):
        f = open(record_path, "r")
        content = f.read()
        record_dict = json.loads(content)
        if len(record_dict) > 0:
            return record_dict
    return {}


def cacheRecord(dict, dir):
    """
    记录缓存
    :param dict: 压缩缓存信息
    :param dir: 存储缓存信息文件夹
    :return: 无
    """
    if len(dict) == 0:
        return
    record_path = os.path.join(dir, ".compress_record.json")
    fp = open(record_path, "w")
    json_str = json.dumps(dict)
    fp.write(json_str)
    fp.close()


def __compress(proj_dir):
    record = __getRecord(parent_dir)
    num_compressed = 0
    num_skipped = 0
    total_compressed_size = 0
    for xcassets_dir in glob.glob('{}/**/*.xcassets'.format(proj_dir), recursive=True):
        # 查找xcassets目录
        for file in glob.glob('{}/**/*.png'.format(xcassets_dir), recursive=True):
            current_size = os.path.getsize(file)
            if file in record:
                cache_size = record[file]
                # 判断本地图片大小是否比缓存记录小
                if cache_size >= current_size:
                    num_skipped += 1
                    continue

            single_png_dict = __pngquantPicture(file)
            compressed_size = single_png_dict[1]
            total_compressed_size += compressed_size
            num_compressed += 1
            # 压缩后把相关信息记录到内存
            record[single_png_dict[0]] = compressed_size

    # 把缓存信息记录到磁盘
    cacheRecord(record, parent_dir)
    print(f"  - Compressed {num_compressed} files, skipped {num_skipped} files.")
    print(f"  - Total compressed size: {total_compressed_size} Bytes.")

# check if pngquant is installed via homebrew


def is_pngquant_installed():
    result = subprocess.run(['brew', 'list', 'pngquant'], stdout=subprocess.PIPE)
    return result.returncode == 0

# install pngquant via homebrew


def install_pngquant():
    print("  - Installing pngquant")
    os.system('brew install pngquant')

# get the path to pngquant executable


def get_pngquant_path():
    try:
        # Run the command "which pngquant" in a shell and capture the output
        output = subprocess.check_output("which pngquant", shell=True)
        # Decode the output to a string and strip any whitespace
        return output.decode().strip()
    except subprocess.CalledProcessError:
        return "/opt/homebrew/bin/pngquant"


if __name__ == '__main__':
    print("  - Start compressing files.")
    # 检查pngquant是否安装
    if not is_pngquant_installed():
        install_pngquant()
    # 参数解析
    p = argparse.ArgumentParser()
    p.add_argument('--proj_dir')
    args = p.parse_args()
    proj_dir = args.proj_dir
    project_dir = os.path.abspath(proj_dir)
    __compress(proj_dir)
    print("  - Finish compressing files.")
