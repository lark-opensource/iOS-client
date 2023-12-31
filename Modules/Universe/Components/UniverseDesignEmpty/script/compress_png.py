#! /usr/bin/python
# -*- coding: utf-8 -*-

# -*- author: huangjianming -*-

import os
import os.path
import glob
import json
import argparse

# 本脚本主要是调用pngquant进行图片压缩，内部会走一些缓存策略，提高整体脚本执行时间.
# .compress_record.json是缓存文件，存放了已经压缩过的文件路径和压缩后的文件大小，每次压缩会进行判断，如果没有缓存文件记录或者当前文件大小比缓存记录大的话都会进行重新压缩。
# pngquant重复调用png文件不会变化

cache_file_name = ".compress_record.json"
parent_dir = os.path.dirname(__file__)
pyPath = os.path.abspath(__file__).replace("compress_png.py","")
def __pngquantPicture(file):
    """
    使用pngquant进行图片压缩
    :param file: 文件
    :return: （文件路径，压缩后大小）
    """
    filesize_before = os.path.getsize(file)
    os.system("{}pngquant -f --ext .png --strip --skip-if-larger --quality 50-70 \"".format(pyPath+"pngquant/") + file + "\"")
    filesize_after = os.path.getsize(file)
    return (file, filesize_after)


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
    for xcassets_dir in glob.glob('{}/**/*.xcassets'.format(proj_dir), recursive=True):
        # 查找xcassets目录
        for file in glob.glob('{}/**/*.png'.format(xcassets_dir), recursive=True):
            current_size = os.path.getsize(file)
            if file in record:
                cache_size = record[file]
                # 判断本地图片大小是否比缓存记录小
                if cache_size >= current_size:
                    continue

            single_png_dict = __pngquantPicture(file)
            # 压缩后把相关信息记录到内存
            record[single_png_dict[0]] = single_png_dict[1]
    # 把缓存信息记录到磁盘
    cacheRecord(record, parent_dir)

def downloadpngquant():
    pngquantPath = pyPath + "pngquant.zip"
    if not os.path.exists(pngquantPath):
        os.system('curl {} --output {}'.format('http://tosv.byted.org/obj/lark-ios/pngquant.zip',pngquantPath))
    if os.path.exists(pngquantPath):
        os.system("rm -rf {}pngquant;tar zxvf {} -C {}".format(pyPath,pngquantPath,pyPath))

if __name__ == '__main__':
    print("--- 图片压缩 start ---")
    # 检查pngquant是否安装
    # if not os.path.exists("/usr/local/bin/pngquant"):
    #     os.system("brew install pngquant")
    downloadpngquant()

    # 参数解析
    p = argparse.ArgumentParser()
    p.add_argument('--proj_dir')
    args = p.parse_args()
    proj_dir = args.proj_dir
    project_dir = os.path.abspath(proj_dir)
    __compress(proj_dir)
    print("--- 图片压缩 end ---")

