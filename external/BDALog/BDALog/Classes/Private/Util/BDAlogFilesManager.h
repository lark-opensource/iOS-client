//
//  BDAlogFilesManager.hpp
//  BDALog
//
//  Created by liuhan on 2023/3/1.
//

#ifndef BDAlogFilesManager_h
#define BDAlogFilesManager_h

#include <stdio.h>

#include <string>
#include <mutex>
#include <vector>
#include <map>

#include "BDALogConfigMMappedFile.h"

namespace BDALog {

#define BDALOGMAXFILESIZE (2 * 1024 * 1024)
#define BDALOGYEARLEN 8   //e.g.20211109
#define BDALOGHOURLEN 6   //e.g.173248
#define BDALOGSEPERATORLEN 1
#define BDALOGAIDLEN 4

void RealGetAlogFilePaths(long long start_timestamp,
                      long long end_timestamp,
                      const std::string& alog_dir,
                      const std::string& prefix,
                      const std::string& suffix,
                      std::vector<std::string>& filepaths);

bool StartWith(const std::string& str, const std::string& substr);

//做了兼容 是否需要去掉？
bool EndWith(const std::string& str, const std::string& substr);

/* 为指定目录下满足前后缀的文件排序 */
long long SortALogFilesByTime(const std::string& logdir,
                              const std::string& prefix,
                              const std::string& suffix,
                              bool filter_prefix,
                              std::vector<std::string>& filename_vec,
                              bool count_size);


struct InstanceConfig {
    bool is_free;
    int32_t index;
    int64_t max_size;
    int32_t expire_time;
    std::string prefix; // max length: 50
    std::string suffix; // max length: 50
};

class BDALogFilesManager final {
    
public:
    
    BDALogFilesManager(const std::string& alog_dir, int64_t max_size, int32_t expire_time, const std::string& suffix);
    ~BDALogFilesManager();
    
    /* 清除满足条件的Alog文件 */
    void CleanALogFilesIfNeedForAllInstance();//lock
    
    /* 清除满足条件的Alog文件 */
    void CleanALogFilesIfNeedManuallyForAllInstance(double expire_time);
    
    /* 清理所有Alog文件 */
    void CleanALLAlogFilesAllInstance();
    
    /* 清理特定实例所有Alog文件 */
    void CleanALLAlogFilesWithInstance(const std::string& instance_name);

    /* 删除指定名字的Alog文件 */
    void RemoveALogFiles( const std::string instance_name, const std::string file_path);
    
    /* 返回指定时间段内的Alog文件 */
    void GetALogFilePathsForAllInstance(long long start_time, long long end_time, std::vector<std::string>& filepaths);//lock
    void GetALogFilePaths(const std::string& instance_name, long long start_time, long long end_time, std::vector<std::string>& filepaths);//lock

    /* 返回alog目录内的Zip文件*/
    void GetALogZipFilePaths(const std::string& instance_name, std::vector<std::string>& zip_paths);//lock
    
    void SetMaxSizeAndExpireTime(const std::string instance_name, long long max_size, double expire_time, const std::string prefix, const std::string suffix); // asny to not stuck init
    
private:
    
    void UpdateMaxSizeAndExpireTime();
    void CleanALogFilesIfNeed(const std::string& instance_name, size_t max_size, double expire_time, const std::string& suffix);//lock
    std::string GenConfigFilePath();
    void WriteConfigToMMap(const std::string instance_name, const InstanceConfig *config);
    
    std::string GenInstanceAlogDir(const std::string& instance_name);
    
    std::string GetInstanceSuffix(const std::string& instance_name);
    std::string GetInstancePrefix(const std::string& instance_name);
    
    std::string GenPrepareDir(const std::string& instance_name);
    std::string GenReadyDir(const std::string& instance_name);
    
    std::string alog_root_dir;
    std::string default_instance_alog_dir_; // alog dir for defatlt instance
    int64_t default_instance_max_size_ = 50 *1024 *1024; // max disk size of default alog instance
    int32_t default_instance_expire_time_ = 7 * 24 * 60 * 60; // expire time for files of default alog instance
    std::string default_instance_suffix_ = "alog";
    
    std::atomic_bool is_config_update_{false};
    std::map<std::string, InstanceConfig> instances_config;
    std::unique_ptr<BDALogConfigMMappedFile> config_mmap_file_;
    
    std::mutex mutex_;
    
    
};

}

#endif /* BDAlogFilesManager_h */
