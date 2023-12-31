//
//  DAVFile.h
//  PixelPlatform
//
//  Created by bytedance on 2021/3/8.
//

#ifndef DAVFile_h
#define DAVFile_h

#include <string>
#include <memory>
#include <vector>
#include "DAVFileExport.h"

namespace davinci {
    namespace file {
        class DAV_FILE_EXPORT DAVFile {

        public:
            /** 删除一个文件夹
             * @param dir [in] 文件目录
             * @return 返回true false
             */
            static bool removeDir(const std::string &dir);

            /** 删除一个文件
             * @param filename [in] 文件
             * @return 返回true false
             */
            static bool removeFile(const std::string &filename);

            /** 拷贝一个文件
             * @param srcFilePath [in] 源文件
             * @param dstFilePath [in] 目的文件
             * @return 返回true false
             */
            static int copy(const std::string &srcFilePath, const std::string &dstFilePath);

            /** 判断是否目录
             * @param path [in] 源文件
             * @return 返回true false
             */
            static bool isDir(const std::string &path);

            static bool isDirExist(const std::string &path);

            /** 判断是否文件
             * @param path [in] 源文件
             * @return 返回true false
             */
            static bool isFile(const std::string &path);

            static bool isFileExist(const std::string &path);

            /** 写数据
             * @param data [in] 数据地址
             * @param len  [in] 数据长度
             * @return 返回实际写的长度
             */
            static int write(const std::string &path, const void *data, size_t len);

            /** 读数据
             * @param path [in] 源文件
             * @param res  [in] 数据地址
             * @return 返回实际读的长度,文件字节数(文件大小)
             */
            static int read(const std::string &path, std::string &res);

            /** 获取目录下的所有item
             * @param dirent    [in] 目录
             * @param fileList  [out] 文件list
             * @return 返回true false
             */
            static int getFileList(const std::string &dirent, std::vector<std::string> &fileList);

            /** 以mode方式创建一个以参数pathname命名的目录，mode定义新创建目录的权限
             * @param path 文件夹绝对路径
             * @param mode @see _s_ifmt.h#File mode
             * */
            static int mkdir(const std::string &path, int mode);

            /** 解压文件
              * @param zipname 待解压文件的路径.
              * @param dir 输出文件路径.
              * @param 解压回调.
              * @param arg opaque pointer.
             * */
            static bool unZip(const char *zipName, const char *dir,
                              int (*on_extract)(const char *filename, void *arg), void *arg);

            static bool unZipSafely(const char *zipPath, const char *unZipPath, bool deleteZipAfterUnZip = true);

            /** 修改文件名
              * @param oldName 原文件名.
              * @param newName 新文件名.
             * */
            static bool renameFile(const char *oldName, const char *newName);

            /** 压缩文件
             * @param 目标压缩文件路径.
             * @param 需要压缩的文件路径.
             * @param 需要压缩的文件数量.
             * */
            static bool zip(const char *zipname, const char *filenames[], size_t len);
        };
    }
}

#endif /* DAVFile_h */
