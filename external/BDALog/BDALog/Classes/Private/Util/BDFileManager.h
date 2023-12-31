//
//  BDFileManager.h
//  BDALog
//
//  Created by kilroy on 2021/10/26.
//

#ifndef BDFileManager_h
#define BDFileManager_h

#include <stdio.h>

#include <string>
#include <mutex>
#include <vector>

#include "BDAlogFilesManager.h"

namespace BDALog {

enum class FileErrorCode {
    ERROR_INPUT,
    ERROR_OPEN,
    ERROR_FILE,
    ERROR_WRITE,
    NO_ERROR,
    NONE,
};



class BDFileManager final {
public:
    BDFileManager(const std::string& log_dir, const std::string& prefix, const std::string& suffix);
    ~BDFileManager();
    
    FileErrorCode WriteDataToFile(const void* data, size_t data_len);
    FileErrorCode WriteDataToFile(const void* data, size_t data_len, const std::string& suffix);//lock
    void CloseFile(); //lock
    
    void MoveOldDefaultInstanceFiles(std::string& out_old_mmap_path,
                                     bool& out_mmap_cache,
                                     std::string& out_aid);

    /* 用于判断是否存在旧的mmap2文件，用来做旧mmap2数据迁移 */
    void CheckOldMMap2File(const std::string& mmap_path,
                           std::string& out_old_mmap_path,
                           bool& out_mmap_cache,
                           std::string& out_aid, bool is_default);//lock
    
    void RemoveFile(const std::string & file_path);

private:
    bool OpenLogFile(const std::string& log_date, const std::string& suffix);
    int WriteLogFile(const void* data, size_t data_len);
    void InternalCloseLogFile();
    /* 生成Alog文件路径 */
    std::string GenerateALogFilePath(const std::string& suffix,
                                     const std::string& log_date,
                                     bool need_create_new_file);
    std::vector<std::string> GetAlogFileNamesByPrefix(const std::string& prefix, const std::string& suffix);
    std::string GetFirstPartOfALogFileName(const std::string& log_date);
    std::string GetSecondPartALogFileName(const std::string& suffix,
                                          const std::string& log_date,
                                          bool need_create_new_file);
    std::string GenPrepareDir();
    std::string GenReadyDir();
    void MovePrepareToReady(const std::string& file_path);
    void MoveRootToPrepareOrReady(const std::string& file_path, bool is_ready);
    
    std::string alog_dir_;
    std::string prefix_;
    std::string suffix_ = "alog"; // 默认.alog
    
    FILE* log_file_ = nullptr; //指向写入文件的指针

    std::string file_path_;
    bool need_create_new_file_ = true;
    std::mutex mutex_;
    
    std::string last_file_time_info_;
};

}//namespace BDALog

#endif /* BDFileManager_h */
