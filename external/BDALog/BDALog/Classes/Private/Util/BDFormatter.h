//
//  BDFormatter.h
//  BDALog
//
//  Created by kilroy on 2021/11/10.
//

#ifndef BDFormatter_h
#define BDFormatter_h

#include <stdio.h>
#include <set>
#include <string>

#include "bdloggerbase.h"

namespace BDALog {

    void SetLogCallback(type_log_callback callback);

    void SetLogDetailCallback(type_log_detail_callback callback);

    void SetOSLogDetailCallBack(type_oslog_detail_callback callback);

    void SetLogModifyHandler(type_log_modify_handler handler);

    void SetLogDetailModifyHandler(type_log_detail_modify_handler handler);

    void SetFilesRemoveCallback(type_files_remove_callback callback);
    
    type_log_detail_callback GetLogDetailCallback();

    type_log_callback GetLogCallback();

    type_log_modify_handler GetLogModifyHandler();

    type_files_remove_callback GetFilesRemoveCallback();

    type_oslog_detail_callback GetOSLogDetailCallBack();

    const char* ExtractFileName(const char* _path);

    void ExtractFunctionName(const char* _func, char* _func_ret, int _len);

    void FormatLog(const BDLoggerInfo* info, const char* log_body, char* final_log, size_t& final_len, type_log_detail_callback log_detail_callback);

    void ExternalCallback(const BDLoggerInfo* info, const char* log, bool enable_console, const std::set<std::string>& tag_allowlist, type_log_callback log_callback, type_log_detail_callback log_detail_callback);
    
    void ModifyLogByUserHandler(std::string& log, std::string& tag, bool& isAbandon, type_log_modify_handler log_modify_handler);
    
    void ModifyLogDetailByUserHandler(intmax_t pid, intmax_t tid, bool is_main_thread, kBDALogLevel level, const char * func_name, const char * file_name, std::string& log, std::string& tag, bool& isAbandon);

    bool HasSetModifyHandler();
}


#endif /* BDFormatter_h */
