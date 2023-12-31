//
//  BDALog.h
//  BDALog
//
//  Created by kilroy on 2021/10/20.
//

#ifndef BDALog_h
#define BDALog_h

#include <stdio.h>
#include <string>
#include <thread>
#include <mutex>
#include <vector>
#include <condition_variable>
#include <unistd.h>
#include <set>
#include <future>
#include <functional>
#include <map>

#include "bdloggerbase.h"
#include "BDALogBuffer.h"
#include "BDALogEnv.h"
#include "BDFileManager.h"

namespace BDALog {

#define DEFAULTINSTANCENAME "default"

enum class BDALogMode {
    kAppenderAsync,
    kAppenderSync,
};

class BDALogInstance {
 public:
    BDALogInstance(const std::string& instance_name, const BDAlogInitParameter* param);
    
    ~BDALogInstance();
    bool CheckIsRunning();
    void Init();
    
    void Write(const BDLoggerInfo* info, const char* log);
    void WriteAsyncTell(const BDLoggerInfo* info, const char* log);
    void WriteIfAsyncInMainThreadOC(const BDLoggerInfo* info, NSString const * tag, NSString const * log);
    void FlushAsync();
    void FlushSync();
    void Close();
    
    void SetMode(BDALogMode mode) { mode_ = mode; }
    void SetLogLevel(kBDALogLevel level) { min_log_level_ = level; }
    void SetConsoleOutput(bool enable) { console_output_ = enable; }
    void SetEnableMainThreadWriteAsync(bool enable) { enable_main_thread_write_async_ = enable; }
    void SetTagBlockList(const std::vector<std::string>& tag_blocklist) { tag_blocklist_ = tag_blocklist; }
    void SetTagConsoleAllowList(const std::set<std::string>& tag_console_allowlist) { tag_console_allowlist_ = tag_console_allowlist; }
    void SetLogCallback(type_log_callback callback) {log_callback_ = callback; }
    void SetLogDetailCallback(type_log_detail_callback callback) {log_detail_callback_ = callback; }
    void SetLogModifyHandler(type_log_modify_handler handler) {log_modify_handler_ = handler; }
    
    FileErrorCode WriteLogFile(const void* data, size_t data_len);
    
    std::string& GetSuffix();
    std::string& GetPrefix();
    
  private:
    void DumpOldMMapBuffer();
    void AsyncFlushThread();
    std::string GenPrepareDir();
    std::string GenReadyDir();
    
    std::atomic_bool is_closed_{false};
    
    std::string alog_dir_;
    BDALogMode mode_;
    kBDALogLevel min_log_level_ = kLevelAll;
    std::string prefix_;
    std::string mmap_suffix_ = "mmap2"; //默认mmap2
    std::string public_key_;
    std::string suffix_ = "alog";
    bool console_output_ = false;
    bool enable_main_thread_write_async_ = false;
    
    // 出于性能考虑 不加锁
    std::vector<std::string> tag_blocklist_;
    std::set<std::string> tag_console_allowlist_;
    
    std::unique_ptr<BDALogBuffer> log_buffer_; //真正存储数据的缓冲区
    
    std::unique_ptr<BDFileManager> file_manager_;
    
    std::string instance_name_;
    type_log_callback log_callback_ = nullptr;
    type_log_detail_callback log_detail_callback_ = nullptr;
    type_log_modify_handler log_modify_handler_ = nullptr;
    
};

}//namespace BDALog

#endif /* BDALog_h */
