//
//  BDLogProtocol.cpp
//  BDALog
//
//  Created by hopo on 2018/11/22.
//

#include "BDAlogProtocol/BDAlogProtocol.h"
#include <dlfcn.h>
#include <atomic>
#include <mutex>

#if __has_include("BDALog/BDAgileLog.h")
#define BDAlogEnalbed 1
#endif

typedef void(alog_protocol_write_var_func_ptr)(const char *_filename, const char *_func_name, const char *_tag, int _level, int _line, const char * _format, va_list args);

typedef void(alog_protocol_write_func_ptr)(const char *_filename, const char *_func_name, const char *_tag, int _level, int _line, const char * _format);

typedef void (alog_protocol_write_oc_func_ptr)(const char *fileName, const char *funcName, NSString const *tag, int level, int line, NSString const *format);

alog_protocol_write_var_func_ptr *g_alog_protocol_write_var_ptr;
alog_protocol_write_func_ptr *g_alog_protocol_write_ptr;
alog_protocol_write_oc_func_ptr *g_alog_protocol_write_oc_ptr;

// alog多实例
typedef void(alog_protocol_open_default_instance_func_ptr)(const char* instance_name, const char* prefix);
typedef void(alog_protocol_open_instance_func_ptr)(const char* instance_name, const char* prefix, long long max_size, double outdate);

typedef void(alog_protocol_write_var_instance_func_ptr)(const char * _instancename, const char *_filename, const char *_func_name, const char *_tag, int _level, int _line, const char * _format, va_list args);
typedef void(alog_protocol_write_instance_func_ptr)(const char * _instancename, const char *_filename, const char *_func_name, const char *_tag, int _level, int _line, const char * _format);

typedef void(alog_protocol_set_log_mian_thread_async_write_instance_func_ptr)(const char* instance_name, bool _is_async);
typedef void(alog_protocol_set_max_heaped_log_info_count_instance_func_ptr)(const char* instance_name, int _count);

typedef void(alog_protocol_set_console_log_instance_func_ptr)(const char* instance_name, bool _is_open);
typedef void(alog_protocol_set_log_level_instance_func_ptr)(const char* instance_name, kBDLogLevel _level);

typedef void(alog_protocol_flush_instance_func_ptr)(const char* instance_name);
typedef void(alog_protocol_flush_sync_instance_func_ptr)(const char* instance_name);

typedef void(alog_protocol_remove_file_instance_func_ptr)(const char* instance_name, const char* _filepath);

typedef void(alog_protocol_set_log_callback_instance_func_ptr)(const char* instance_name, bd_log_callback log_callback);
typedef void(alog_protocol_set_log_detail_callback_instance_func_ptr)(const char* instance_name, bd_log_detail_callback log_detail_callback);

//typedef void(alog_protocol_get_all_instances_func_ptr)(std::vector<std::string>& instances);
//typedef void(alog_protocol_set_log_modify_handler_instance_func_ptr)(const char* instance_name, bd_log_modify_handler log_modify_handler);
//typedef void(alog_protocol_set_tag_blocklist_instance_func_ptr)(const char* instance_name, const std::vector<std::string> _tag_blocklist);
//typedef void(alog_protocol_set_tag_console_allowlist_instance_func_ptr)(const char* instance_name, const std::set<std::string> _tag_console_allowlist);
//typedef void(alog_protocol_getFilePaths_instance_func_ptr)(const char* instance_name, long long fromTimeInterval, long long toTimeInterval, std::vector<std::string>& _filepath_vec);
//typedef void(alog_protocol_getZipPaths_instance_func_ptr)(const char* instance_name, std::vector<std::string>& _zip_path_vec);

alog_protocol_open_default_instance_func_ptr *g_alog_protocol_open_default_instance_ptr;
alog_protocol_open_instance_func_ptr *g_alog_protocol_open_instance_ptr;
alog_protocol_write_var_instance_func_ptr *g_alog_protocol_write_var_instance_ptr;
alog_protocol_write_instance_func_ptr *g_alog_protocol_write_instance_ptr;
alog_protocol_set_log_mian_thread_async_write_instance_func_ptr *g_alog_protocol_set_log_main_thread_async_write_instance_ptr;
alog_protocol_set_max_heaped_log_info_count_instance_func_ptr *g_alog_protocol_set_max_heaped_log_info_count_instance_ptr;
alog_protocol_set_console_log_instance_func_ptr *g_alog_protocol_set_console_log_instance_ptr;
alog_protocol_set_log_level_instance_func_ptr *g_alog_protocol_set_log_level_instance_ptr;
alog_protocol_flush_instance_func_ptr *g_alog_protocol_flush_instance_ptr;
alog_protocol_flush_sync_instance_func_ptr *g_alog_protocol_flush_sync_instance_ptr;
alog_protocol_remove_file_instance_func_ptr *g_alog_protocol_remove_file_instance_ptr;
alog_protocol_set_log_callback_instance_func_ptr *g_alog_protocol_set_log_callback_instance_ptr;
alog_protocol_set_log_detail_callback_instance_func_ptr *g_alog_protocol_set_log_detail_callback_instance_ptr;
//alog_protocol_get_all_instances_func_ptr *g_alog_protocol_get_all_instances_ptr;
//alog_protocol_set_log_modify_handler_instance_func_ptr *g_alog_protocol_set_log_modify_handler_instance_ptr;
//alog_protocol_set_tag_blocklist_instance_func_ptr *g_alog_protocol_set_tag_blocklist_instance_ptr;
//alog_protocol_set_tag_console_allowlist_instance_func_ptr *g_alog_protocol_set_tag_console_allowlist_instance_ptr;
//alog_protocol_getFilePaths_instance_func_ptr *g_alog_protocol_getFilePaths_instance_ptr;
//alog_protocol_getZipPaths_instance_func_ptr *g_alog_protocol_getZipPaths_instance_ptr;


static std::mutex& GetFuncMutex() {
    static std::mutex func_mutex;
    return func_mutex;
}

static std::atomic<bool>& GetHasGotAlogFuncPtr() {
    static std::atomic<bool> has_got_alog_protocol_func_ptr(false);
    return has_got_alog_protocol_func_ptr;
}

static std::atomic<bool>& GetEnableBDALog() {
    static std::atomic<bool> enable_bdalog(false);
    return enable_bdalog;
}

static std::atomic<bool>& GetEnableBDALogMultipleInstance() {
    static std::atomic<bool> enable_bdalog_multiple_instance(false);
    return enable_bdalog_multiple_instance;
}

void get_bdalog_write_func_ptr() {
    std::lock_guard<std::mutex> lock(GetFuncMutex());
    if (!GetHasGotAlogFuncPtr().load()) {
        Class alogClass = NSClassFromString(@"BDALogProtocolHelper");
        if (alogClass) {
            SEL alogSel = NSSelectorFromString(@"getBDALogProtocolWriteVarPtr:");
            if ([alogClass respondsToSelector:alogSel]) {
                #pragma clang diagnostic push
                #pragma clang diagnostic ignored "-Warc-performSelector-leaks"
                [alogClass performSelector:alogSel withObject:^(alog_protocol_write_var_func_ptr * funPtr) {
                    g_alog_protocol_write_var_ptr = funPtr;
                    if (g_alog_protocol_write_var_ptr) {
                        GetEnableBDALog().store(true);
                    }
                }];
                #pragma clang diagnostic pop
            }
            
            alogSel = NSSelectorFromString(@"getBDALogProtocolWritePtr:");
            if ([alogClass respondsToSelector:alogSel]) {
                #pragma clang diagnostic push
                #pragma clang diagnostic ignored "-Warc-performSelector-leaks"
                [alogClass performSelector:alogSel withObject:^(alog_protocol_write_func_ptr * funPtr) {
                    g_alog_protocol_write_ptr = funPtr;
                }];
                #pragma clang diagnostic pop
            }
                    
            // 多实例
            alogSel = NSSelectorFromString(@"getBDALogProtocolOpenDefaultInstancePtr:");
            if ([alogClass respondsToSelector:alogSel]) {
                #pragma clang diagnostic push
                #pragma clang diagnostic ignored "-Warc-performSelector-leaks"
                [alogClass performSelector:alogSel withObject:^(alog_protocol_open_default_instance_func_ptr * funPtr) {
                    g_alog_protocol_open_default_instance_ptr = funPtr;
                    if (g_alog_protocol_open_default_instance_ptr) {
                        GetEnableBDALogMultipleInstance().store(true);
                    }
                }];
                #pragma clang diagnostic pop
            }
            
            alogSel = NSSelectorFromString(@"getBDALogProtocolOpenInstancePtr:");
            if ([alogClass respondsToSelector:alogSel]) {
                #pragma clang diagnostic push
                #pragma clang diagnostic ignored "-Warc-performSelector-leaks"
                [alogClass performSelector:alogSel withObject:^(alog_protocol_open_instance_func_ptr * funPtr) {
                    g_alog_protocol_open_instance_ptr = funPtr;
                }];
                #pragma clang diagnostic pop
            }
            
            alogSel = NSSelectorFromString(@"getBDALogProtocolWriteVarInstancePtr:");
            if ([alogClass respondsToSelector:alogSel]) {
                #pragma clang diagnostic push
                #pragma clang diagnostic ignored "-Warc-performSelector-leaks"
                [alogClass performSelector:alogSel withObject:^(alog_protocol_write_var_instance_func_ptr * funPtr) {
                    g_alog_protocol_write_var_instance_ptr = funPtr;
                }];
                #pragma clang diagnostic pop
            }
            
            alogSel = NSSelectorFromString(@"getBDALogProtocolWriteInstancePtr:");
            if ([alogClass respondsToSelector:alogSel]) {
                #pragma clang diagnostic push
                #pragma clang diagnostic ignored "-Warc-performSelector-leaks"
                [alogClass performSelector:alogSel withObject:^(alog_protocol_write_instance_func_ptr * funPtr) {
                    g_alog_protocol_write_instance_ptr = funPtr;
                }];
                #pragma clang diagnostic pop
            }
            
            alogSel = NSSelectorFromString(@"getBDALogProtocolSetLogMainThreadAsyncWriteInstancePtr:");
            if ([alogClass respondsToSelector:alogSel]) {
                #pragma clang diagnostic push
                #pragma clang diagnostic ignored "-Warc-performSelector-leaks"
                [alogClass performSelector:alogSel withObject:^(alog_protocol_set_log_mian_thread_async_write_instance_func_ptr * funPtr) {
                    g_alog_protocol_set_log_main_thread_async_write_instance_ptr = funPtr;
                }];
                #pragma clang diagnostic pop
            }
            
            alogSel = NSSelectorFromString(@"getBDALogProtocolSetMaxHeapedLogInfoCountInstancePtr:");
            if ([alogClass respondsToSelector:alogSel]) {
                #pragma clang diagnostic push
                #pragma clang diagnostic ignored "-Warc-performSelector-leaks"
                [alogClass performSelector:alogSel withObject:^(alog_protocol_set_max_heaped_log_info_count_instance_func_ptr * funPtr) {
                    g_alog_protocol_set_max_heaped_log_info_count_instance_ptr = funPtr;
                }];
                #pragma clang diagnostic pop
            }
            
            alogSel = NSSelectorFromString(@"getBDALogProtocolSetConsoleLogInstancePtr:");
            if ([alogClass respondsToSelector:alogSel]) {
                #pragma clang diagnostic push
                #pragma clang diagnostic ignored "-Warc-performSelector-leaks"
                [alogClass performSelector:alogSel withObject:^(alog_protocol_set_console_log_instance_func_ptr * funPtr) {
                    g_alog_protocol_set_console_log_instance_ptr = funPtr;
                }];
                #pragma clang diagnostic pop
            }
            
            alogSel = NSSelectorFromString(@"getBDALogProtocolSetLevelInstancePtr:");
            if ([alogClass respondsToSelector:alogSel]) {
                #pragma clang diagnostic push
                #pragma clang diagnostic ignored "-Warc-performSelector-leaks"
                [alogClass performSelector:alogSel withObject:^(alog_protocol_set_log_level_instance_func_ptr * funPtr) {
                    g_alog_protocol_set_log_level_instance_ptr = funPtr;
                }];
                #pragma clang diagnostic pop
            }
            
            alogSel = NSSelectorFromString(@"getBDALogProtocolFlushInstancePtr:");
            if ([alogClass respondsToSelector:alogSel]) {
                #pragma clang diagnostic push
                #pragma clang diagnostic ignored "-Warc-performSelector-leaks"
                [alogClass performSelector:alogSel withObject:^(alog_protocol_flush_instance_func_ptr * funPtr) {
                    g_alog_protocol_flush_instance_ptr = funPtr;
                }];
                #pragma clang diagnostic pop
            }
            
            alogSel = NSSelectorFromString(@"getBDALogProtocolFlushSyncInstancePtr:");
            if ([alogClass respondsToSelector:alogSel]) {
                #pragma clang diagnostic push
                #pragma clang diagnostic ignored "-Warc-performSelector-leaks"
                [alogClass performSelector:alogSel withObject:^(alog_protocol_flush_sync_instance_func_ptr * funPtr) {
                    g_alog_protocol_flush_sync_instance_ptr = funPtr;
                }];
                #pragma clang diagnostic pop
            }
            
            alogSel = NSSelectorFromString(@"getBDALogProtocolRemoveFileInstancePtr:");
            if ([alogClass respondsToSelector:alogSel]) {
                #pragma clang diagnostic push
                #pragma clang diagnostic ignored "-Warc-performSelector-leaks"
                [alogClass performSelector:alogSel withObject:^(alog_protocol_remove_file_instance_func_ptr * funPtr) {
                    g_alog_protocol_remove_file_instance_ptr = funPtr;
                }];
                #pragma clang diagnostic pop
            }
            
            alogSel = NSSelectorFromString(@"getBDALogProtocolSetLogCallbackInstancePtr:");
            if ([alogClass respondsToSelector:alogSel]) {
                #pragma clang diagnostic push
                #pragma clang diagnostic ignored "-Warc-performSelector-leaks"
                [alogClass performSelector:alogSel withObject:^(alog_protocol_set_log_callback_instance_func_ptr * funPtr) {
                    g_alog_protocol_set_log_callback_instance_ptr = funPtr;
                }];
                #pragma clang diagnostic pop
            }
            
            alogSel = NSSelectorFromString(@"getBDALogProtocolSetLogDetailCallbackInstancePtr:");
            if ([alogClass respondsToSelector:alogSel]) {
                #pragma clang diagnostic push
                #pragma clang diagnostic ignored "-Warc-performSelector-leaks"
                [alogClass performSelector:alogSel withObject:^(alog_protocol_set_log_detail_callback_instance_func_ptr * funPtr) {
                    g_alog_protocol_set_log_detail_callback_instance_ptr = funPtr;
                }];
                #pragma clang diagnostic pop
            }
            
//            alogSel = NSSelectorFromString(@"getBDALogProtocolGetAllInstancePtr:");
//            if ([alogClass respondsToSelector:alogSel]) {
//                #pragma clang diagnostic push
//                #pragma clang diagnostic ignored "-Warc-performSelector-leaks"
//                [alogClass performSelector:alogSel withObject:^(alog_protocol_get_all_instances_func_ptr * funPtr) {
//                    g_alog_protocol_get_all_instances_ptr = funPtr;
//                }];
//                #pragma clang diagnostic pop
//            }
            
//            alogSel = NSSelectorFromString(@"getBDALogProtocolSetLogModifyhandlerInstancePtr:");
//            if ([alogClass respondsToSelector:alogSel]) {
//                #pragma clang diagnostic push
//                #pragma clang diagnostic ignored "-Warc-performSelector-leaks"
//                [alogClass performSelector:alogSel withObject:^(alog_protocol_set_log_modify_handler_instance_func_ptr * funPtr) {
//                    g_alog_protocol_set_log_modify_handler_instance_ptr = funPtr;
//                }];
//                #pragma clang diagnostic pop
//            }
            
//            alogSel = NSSelectorFromString(@"getBDALogProtocolSetTagBlockListInstancePtr:");
//            if ([alogClass respondsToSelector:alogSel]) {
//                #pragma clang diagnostic push
//                #pragma clang diagnostic ignored "-Warc-performSelector-leaks"
//                [alogClass performSelector:alogSel withObject:^(alog_protocol_set_tag_blocklist_instance_func_ptr * funPtr) {
//                    g_alog_protocol_set_tag_blocklist_instance_ptr = funPtr;
//                }];
//                #pragma clang diagnostic pop
//            }
            
//            alogSel = NSSelectorFromString(@"getBDALogProtocolSetTagConsoleAllowlistInstancePtr:");
//            if ([alogClass respondsToSelector:alogSel]) {
//                #pragma clang diagnostic push
//                #pragma clang diagnostic ignored "-Warc-performSelector-leaks"
//                [alogClass performSelector:alogSel withObject:^(alog_protocol_set_tag_console_allowlist_instance_func_ptr * funPtr) {
//                    g_alog_protocol_set_tag_console_allowlist_instance_ptr = funPtr;
//                }];
//                #pragma clang diagnostic pop
//            }
//
//            alogSel = NSSelectorFromString(@"getBDALogProtocolGetFilePathsInstancePtr:");
//            if ([alogClass respondsToSelector:alogSel]) {
//                #pragma clang diagnostic push
//                #pragma clang diagnostic ignored "-Warc-performSelector-leaks"
//                [alogClass performSelector:alogSel withObject:^(alog_protocol_getFilePaths_instance_func_ptr * funPtr) {
//                    g_alog_protocol_getFilePaths_instance_ptr = funPtr;
//                }];
//                #pragma clang diagnostic pop
//            }
            
//            alogSel = NSSelectorFromString(@"getBDALogProtocolGetZipPathsInstancePtr:");
//            if ([alogClass respondsToSelector:alogSel]) {
//                #pragma clang diagnostic push
//                #pragma clang diagnostic ignored "-Warc-performSelector-leaks"
//                [alogClass performSelector:alogSel withObject:^(alog_protocol_getZipPaths_instance_func_ptr * funPtr) {
//                    g_alog_protocol_getZipPaths_instance_ptr = funPtr;
//                }];
//                #pragma clang diagnostic pop
//            }

            SEL alogWriteOCSel = NSSelectorFromString(@"getBDALogProtocolWriteOCPtr:");
            if ([alogClass respondsToSelector:alogWriteOCSel]) {
                #pragma clang diagnostic push
                #pragma clang diagnostic ignored "-Warc-performSelector-leaks"
                [alogClass performSelector:alogWriteOCSel withObject:^(alog_protocol_write_oc_func_ptr * funPtr) {
                    g_alog_protocol_write_oc_ptr = funPtr;
                }];
                #pragma clang diagnostic pop
            }
        }
        GetHasGotAlogFuncPtr().store(true);
    }
}

bool checkAndGotBDAlogFuncPtr() {
    if (!GetHasGotAlogFuncPtr().load()) {
        get_bdalog_write_func_ptr();
    }
    return true;
}

void check_g_alog_protocol_write_var_ptr(const char *_filename, const char *_func_name, const char *_tag, int _level, int _line, const char * _format, va_list args) {
    get_bdalog_write_func_ptr();
    
    if (GetHasGotAlogFuncPtr().load() && g_alog_protocol_write_var_ptr != NULL) {
        g_alog_protocol_write_var_ptr(_filename, _func_name, _tag, _level, _line, _format, args);
    }
    
}

void check_g_alog_protocol_write_ptr(const char *_filename, const char *_func_name, const char *_tag, int _level, int _line, const char * _format) {
    get_bdalog_write_func_ptr();
    
    if (GetHasGotAlogFuncPtr().load() && g_alog_protocol_write_ptr != NULL) {
        g_alog_protocol_write_ptr(_filename, _func_name, _tag, _level, _line, _format);
    }
}

void bd_log_write_var(const char *_filename, const char *_func_name, const char *_tag, kBDLogLevel _level, int _line, const char * _format, ...) {
    if (_format == nullptr) {
        return;
    }
    va_list args;
    va_start(args, _format);
    check_g_alog_protocol_write_var_ptr(_filename, _func_name, _tag, _level, _line, _format, args);
    va_end(args);
}

void bd_log_write(const char *_filename, const char *_func_name, const char *_tag, kBDLogLevel _level, int _line, const char * _format) {
    if (_format == nullptr) {
        return;
    }
    check_g_alog_protocol_write_ptr(_filename, _func_name, _tag, _level, _line, _format);
}

bool bd_log_enable(void) {
    get_bdalog_write_func_ptr();
    return GetEnableBDALog().load();
}


// Alog多实例相关
bool bd_log_multiple_instance_enable(void) {
    get_bdalog_write_func_ptr();
    return GetEnableBDALogMultipleInstance().load();
}

void bd_log_open_default_instance(const char* instance_name, const char* prefix) {
    if (instance_name == nullptr) {
        return;
    }
    if (checkAndGotBDAlogFuncPtr() && g_alog_protocol_open_default_instance_ptr) {
        g_alog_protocol_open_default_instance_ptr(instance_name, prefix);
    }
}

void bd_log_open_instance(const char* instance_name, const char* prefix, long long max_size, double outdate) {
    if (instance_name == nullptr) {
        return;
    }
    if (checkAndGotBDAlogFuncPtr() && g_alog_protocol_open_instance_ptr) {
        g_alog_protocol_open_instance_ptr(instance_name, prefix, max_size, outdate);
    }
}

void bd_log_write_var_instance(const char *_instancename, const char *_filename, const char *_func_name, const char *_tag, kBDLogLevel _level, int _line, const char * _format, ...) {
    if (_format == nullptr || _instancename == nullptr) {
        return;
    }
    if (checkAndGotBDAlogFuncPtr() && g_alog_protocol_write_var_instance_ptr) {
        
        va_list args;
        va_start(args, _format);
        g_alog_protocol_write_var_instance_ptr(_instancename, _filename, _func_name, _tag, _level, _line, _format, args);
        va_end(args);
    }
}

void bd_log_write_instance(const char *_instancename, const char *_filename, const char *_func_name, const char *_tag, kBDLogLevel _level, int _line, const char * _format) {
    if (_format == nullptr || _instancename == nullptr) {
        return;
    }
    if (checkAndGotBDAlogFuncPtr() && g_alog_protocol_write_instance_ptr) {
        g_alog_protocol_write_instance_ptr(_instancename, _filename, _func_name, _tag, _level, _line, _format);
    }
}

void bd_log_set_log_mian_thread_async_write_instance(const char* instance_name, bool is_async) {
    if (instance_name == nullptr) {
        return;
    }
    if (checkAndGotBDAlogFuncPtr() && g_alog_protocol_set_log_main_thread_async_write_instance_ptr) {
        g_alog_protocol_set_log_main_thread_async_write_instance_ptr(instance_name, is_async);
    }
}

void bd_log_set_max_heaped_log_info_count_instance(const char* instance_name, int count) {
    if (instance_name == nullptr) {
        return;
    }
    if (checkAndGotBDAlogFuncPtr() && g_alog_protocol_set_max_heaped_log_info_count_instance_ptr) {
        g_alog_protocol_set_max_heaped_log_info_count_instance_ptr(instance_name, count);
    }
}

void bd_log_set_console_log_instance(const char* instance_name, bool is_open) {
    if (instance_name == nullptr) {
        return;
    }
    if (checkAndGotBDAlogFuncPtr() && g_alog_protocol_set_console_log_instance_ptr) {
        g_alog_protocol_set_console_log_instance_ptr(instance_name, is_open);
    }
}

void bd_log_set_log_level_instance(const char* instance_name, kBDLogLevel level) {
    if (instance_name == nullptr) {
        return;
    }
    if (checkAndGotBDAlogFuncPtr() && g_alog_protocol_set_log_level_instance_ptr) {
        g_alog_protocol_set_log_level_instance_ptr(instance_name, level);
    }
}

void bd_log_flush_instance(const char* instance_name) {
    if (instance_name == nullptr) {
        return;
    }
    if (checkAndGotBDAlogFuncPtr() && g_alog_protocol_flush_instance_ptr) {
        g_alog_protocol_flush_instance_ptr(instance_name);
    }
}

void bd_log_flush_sync_instance(const char* instance_name) {
    if (instance_name == nullptr) {
        return;
    }
    if (checkAndGotBDAlogFuncPtr() && g_alog_protocol_flush_sync_instance_ptr) {
        g_alog_protocol_flush_sync_instance_ptr(instance_name);
    }
}

void bd_log_remove_file_instance(const char* instance_name, const char* filepath) {
    if (instance_name == nullptr || filepath == nullptr) {
        return;
    }
    if (checkAndGotBDAlogFuncPtr() && g_alog_protocol_remove_file_instance_ptr) {
        g_alog_protocol_remove_file_instance_ptr(instance_name, filepath);
    }
}

void bd_log_set_log_callback_instance(const char* instance_name, bd_log_callback log_callback) {
    if (instance_name == nullptr) {
        return;
    }
    if (checkAndGotBDAlogFuncPtr() && g_alog_protocol_set_log_callback_instance_ptr) {
        g_alog_protocol_set_log_callback_instance_ptr(instance_name, log_callback);
    }
}

void bd_log_set_log_detail_callback_instance(const char* instance_name, bd_log_detail_callback log_detail_callback) {
    if (instance_name == nullptr) {
        return;
    }
    if (checkAndGotBDAlogFuncPtr() && g_alog_protocol_set_log_detail_callback_instance_ptr) {
        g_alog_protocol_set_log_detail_callback_instance_ptr(instance_name, log_detail_callback);
    }
}
    
//void bd_log_set_log_modify_handler_instance(const char* instance_name, bd_log_modify_handler log_modify_handler) {
//    if (instance_name == nullptr) {
//        return;
//    }
//    if (checkAndGotBDAlogFuncPtr() && g_alog_protocol_set_log_modify_handler_instance_ptr) {
//        g_alog_protocol_set_log_modify_handler_instance_ptr(instance_name, log_modify_handler);
//    }
//}
//
//void bd_log_set_tag_blocklist_instance(const char* instance_name, const std::vector<std::string> tag_blocklist) {
//    if (instance_name == nullptr) {
//        return;
//    }
//    if (checkAndGotBDAlogFuncPtr() && g_alog_protocol_set_tag_blocklist_instance_ptr) {
//        g_alog_protocol_set_tag_blocklist_instance_ptr(instance_name, tag_blocklist);
//    }
//}
//
//void bd_log_set_tag_console_allowlist_instance(const char* instance_name, const std::set<std::string> tag_console_allowlist) {
//    if (instance_name == nullptr) {
//        return;
//    }
//    if (checkAndGotBDAlogFuncPtr() && g_alog_protocol_set_tag_console_allowlist_instance_ptr) {
//        g_alog_protocol_set_tag_console_allowlist_instance_ptr(instance_name, tag_console_allowlist);
//    }
//}

//void bd_log_getFilePaths_instance(const char* instance_name, long long fromTimeInterval, long long toTimeInterval, std::vector<std::string>& filepath_vec) {
//    if (instance_name == nullptr) {
//        return;
//    }
//    if (checkAndGotBDAlogFuncPtr() && g_alog_protocol_getFilePaths_instance_ptr) {
//        g_alog_protocol_getFilePaths_instance_ptr(instance_name, fromTimeInterval, toTimeInterval, filepath_vec);
//    }
//}
//
//void bd_log_getZipPaths_instance(const char* instance_name, std::vector<std::string>& zip_path_vec) {
//    if (instance_name == nullptr) {
//        return;
//    }
//    if (checkAndGotBDAlogFuncPtr() && g_alog_protocol_getZipPaths_instance_ptr) {
//        g_alog_protocol_getZipPaths_instance_ptr(instance_name, zip_path_vec);
//    }
//}

//历史遗留问题，TTNet的安卓端保留接口
void android_bd_log_write_var(const char *_filename, const char *_func_name, int _line, const char *_tag, kBDLogLevel _level, const char * _format, ...) {
    if (_format == nullptr) {
        return;
    }
    va_list args;
    va_start(args, _format);
    check_g_alog_protocol_write_var_ptr(_filename, _func_name, _tag, _level, _line, _format, args);
    va_end(args);
}

void android_bd_log_write(const char *_filename, const char *_func_name, int _line, const char *_tag, kBDLogLevel _level, const char * _format) {
    bd_log_write(_filename, _func_name, _tag, _level, _line, _format);
}

bd_log_write_var_func_ptr funcAddr_bd_log_write_var(void){
    return bd_log_write_var_func_ptr(&bd_log_write_var);
}

bd_log_write_func_ptr funcAddr_bd_log_write(void){
    return bd_log_write_func_ptr(&bd_log_write);
}

android_bd_log_write_var_func_ptr android_funcAddr_bd_log_write_var(void){
    return android_bd_log_write_var_func_ptr(&android_bd_log_write_var);
}

android_bd_log_write_func_ptr android_funcAddr_bd_log_write(void){
    return android_bd_log_write_func_ptr(&android_bd_log_write);
}


////////////////////////////////////////////////////////////////////////////////////////////////////////////
#ifdef __OBJC__
#import "BDAlogProtocol/BDAlogProtocol.h"


void bd_log_write_OC(const char* fileName, const char* funcName, NSString const * tag, kBDLogLevel level, int line, NSString const * format) {
    get_bdalog_write_func_ptr();
    
    if (GetHasGotAlogFuncPtr().load() && g_alog_protocol_write_oc_ptr != NULL) {
        g_alog_protocol_write_oc_ptr(fileName, funcName, tag, level, line, format);
    }
}

@implementation BDALogProtocol

+ (void)setALogWithFileName:(NSString *)fileName funcName:(NSString *)funcName tag:(NSString *)tag line:(int)line level:(int)level format:(NSString *)format {
    bd_log_write([fileName UTF8String], [funcName UTF8String], [tag UTF8String], [BDALogProtocol levelMap:level], line, [format UTF8String]);
}

+ (kBDLogLevel)levelMap:(int)level {
    kBDLogLevel mapLevel = kLogLevelNone;
    switch (level) {
        case 0:
            mapLevel = kLogLevelVerbose;
            break;
        case 1:
            mapLevel = kLogLevelDebug;
            break;
        case 2:
            mapLevel = kLogLevelInfo;
            break;
        case 3:
            mapLevel = kLogLevelWarn;
            break;
        case 4:
            mapLevel = kLogLevelError;
            break;
        case 5:
            mapLevel = kLogLevelFatal;
            break;
            
        default:
            break;
    }
    return mapLevel;
}

@end
#endif
