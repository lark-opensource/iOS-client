//
//  BDALogManager.h
//  BDALog
//
//  Created by kilroy on 2021/11/22.
//

#ifndef BDALogManager_hpp
#define BDALogManager_hpp

#include <stdio.h>
#include <string.h>
#include <map>
#include <set>
#include <shared_mutex>

#include "BDALogInstance.h"
#include "BDAlogFilesManager.h"

namespace BDALog {

class BDALogManager {
public:
    static BDALogManager& GetManager() {
        static BDALogManager manager;
        return manager;
    }
    BDALogManager();
    ~BDALogManager() = default;
    BDALogManager(const BDALogManager&) = delete;
    
    void InitInstance(const BDAlogInitParameter* param);
    void InitInstance(const std::string instance_name, const BDAlogInitParameter* param);
    
    void CloseInstance();
    void CloseInstance(const std::string instance_name);
    
    void GetAllInstances(std::vector<std::string>& instances);
    
    void WriteLog(const BDLoggerInfo* info, const char* log);
    void WriteLog(const std::string instance_name, const BDLoggerInfo* info, const char* log);
    void WriteLogOC(const BDLoggerInfo* info, NSString const * tag, NSString const * log);
    void WriteLogOC(const std::string instance_name, const BDLoggerInfo* info, NSString *tag, NSString *log);
    
    void FlushSync();
    void FlushSync(const std::string instance_name);
    void FlushAsync();
    void FlushAsync(const std::string instance_name);
    void GetFilePaths(long long begin_time, long long end_timestamp, std::vector<std::string>& out_file_paths);
    void GetFilePaths(const std::string instance_name, long long begin_time, long long end_timestamp,
                      std::vector<std::string>& out_file_paths);
    void GetFilePathsAllInstance(long long begin_time, long long end_timestamp, std::vector<std::string>& out_filepaths);
    void GetZipPaths(std::vector<std::string>& zip_paths);
    void GetZipPaths(const std::string instance_name, std::vector<std::string>& zip_paths);
    void RemoveFile(const std::string filepath);
    void RemoveFile(const std::string instance_name, const std::string filepath);
    void FlushAndClearAllInstance();
    void FlushAndClearAllInstance(double max_remain_seconds);
    
    void SetConsoleOutput(bool enable);
    void SetConsoleOutput(const std::string instance_name, bool enable);
    void SetLogLevel(kBDALogLevel level);
    void SetLogLevel(const std::string instance_name, kBDALogLevel level);
    void SetTagBlockList(const std::vector<std::string>& tag_blocklist);
    void SetTagBlockList(const std::string instance_name, const std::vector<std::string>& tag_blocklist);
    void SetTagConsoleAllowlist(const std::set<std::string>& console_allowlist);
    void SetTagConsoleAllowlist(const std::string instance_name, const std::set<std::string>& console_allowlist);
    void SetEnableMainThreadWriteAsync(bool enable);
    void SetEnableMainThreadWriteAsync(const std::string instance_name, bool enable);
    void SetLogCallback(const type_log_callback callback);
    void SetLogCallback(const std::string instance_name, const type_log_callback callback);
    void SetLogDetailCallback(const type_log_detail_callback callback);
    void SetLogDetailCallback(const std::string instance_name, const type_log_detail_callback callback);
    void SetLogModifyHandler(const type_log_modify_handler handler);
    void SetLogModifyHandler(const std::string instance_name, const type_log_modify_handler handler);

private:
    bool create_default_ = false;
    std::unique_ptr<BDALogInstance> default_;
    std::map<std::string, std::shared_ptr<BDALogInstance>> instances_;
    std::string default_path_;
    std::unique_ptr<BDALogFilesManager> files_manager_;
    
};

}


#endif /* BDALogManager_hpp */
