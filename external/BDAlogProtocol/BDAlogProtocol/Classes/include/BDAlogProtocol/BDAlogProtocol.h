//
//  BDLogProtocol.hpp
//  BDALog
//
//  Created by hopo on 2018/11/22.
//

#ifndef BDLogProtocol_hpp
#define BDLogProtocol_hpp

#include <stdio.h>
#include <sys/time.h>
#include <time.h>
#include <stdarg.h>
#include <stdint.h>
#include <stdbool.h>

//#ifdef __cplusplus
//#include <string>
//#include <vector>
//#include <set>
//#endif

#ifdef __FILE_NAME__
#define __BDALOGPROTOCOL_FILE_NAME__ __FILE_NAME__
#else
#define __BDALOGPROTOCOL_FILE_NAME__ __FILE__
#endif

#ifdef __OBJC__
#import<Foundation/Foundation.h>

#ifndef COMPILE_ASSERT_MESSAGE
#ifndef __cplusplus
#define COMPILE_ASSERT_MESSAGE(__value, __message) ((void)sizeof(char[1 - 2*!(condition)]))
#else
#define COMPILE_ASSERT_MESSAGE(__value, __message) static_assert(!!(__value), __message)
#endif
#endif

#if   __has_builtin(__is_convertible)
#define BDALOG_TYPE_OF_ASSERT_STRING(_from, _message)     COMPILE_ASSERT_MESSAGE((__is_convertible(_from, NSString *) || __is_convertible(_from, const NSString *)), _message)
#elif __has_builtin(__is_convertible_to)
#define BDALOG_TYPE_OF_ASSERT_STRING(_from, _message)     COMPILE_ASSERT_MESSAGE((__is_convertible_to(_from, NSString *) || __is_convertible_to(_from, const NSString *)), _message)
#else
#define BDALOG_TYPE_OF_ASSERT_STRING(_from, _message)
#endif

#define NSSTRING_LOG(format, ...) ([NSString stringWithFormat:format, ##__VA_ARGS__, nil])
#define NSCHAR_LOG(format, ...) ([[NSString stringWithFormat:format, ##__VA_ARGS__, nil] UTF8String])

#pragma mark -  OC method and its usage is same as 'NSLog'
//自定义level
#define BDALOG_PROTOCOL(level, format, ...)\
@autoreleasepool {ALOG_PROTOCOL_OC(level, @"", NSSTRING_LOG(format, ##__VA_ARGS__))};

#define BDALOG_PROTOCOL_INSTANCE(instance_name, level, format, ...)\
@autoreleasepool {ALOG_PROTOCOL_INSTANCE([instance_name UTF8String], level, "", NSCHAR_LOG(format, ##__VA_ARGS__))};

//自定义level和tag
#define BDALOG_PROTOCOL_TAG(level, tag, format, ...)\
@autoreleasepool {ALOG_PROTOCOL_OC(level, tag, NSSTRING_LOG(format, ##__VA_ARGS__))};

#define BDALOG_PROTOCOL_TAG_INSTANCE(instance_name, level, tag, format, ...)\
@autoreleasepool {ALOG_PROTOCOL_INSTANCE([instance_name UTF8String], level, [tag UTF8String], NSCHAR_LOG(format, ##__VA_ARGS__))};


//debug log
#define BDALOG_PROTOCOL_DEBUG(format, ...)\
@autoreleasepool {ALOG_PROTOCOL_OC(kLogLevelDebug, @"", NSSTRING_LOG(format, ##__VA_ARGS__))};

#define BDALOG_PROTOCOL_DEBUG_INSTANCE(instance_name, format, ...)\
@autoreleasepool {ALOG_PROTOCOL_INSTANCE([instance_name UTF8String], kLogLevelDebug, "", NSCHAR_LOG(format, ##__VA_ARGS__))};

//info log
#define BDALOG_PROTOCOL_INFO(format, ...)\
@autoreleasepool {ALOG_PROTOCOL_OC(kLogLevelInfo, @"", NSSTRING_LOG(format, ##__VA_ARGS__))};

#define BDALOG_PROTOCOL_INFO_INSTANCE(instance_name, format, ...)\
@autoreleasepool {ALOG_PROTOCOL_INSTANCE([instance_name UTF8String], kLogLevelInfo, "", NSCHAR_LOG(format, ##__VA_ARGS__))};

//warn log
#define BDALOG_PROTOCOL_WARN(format, ...)\
@autoreleasepool {ALOG_PROTOCOL_OC(kLogLevelWarn, @"", NSSTRING_LOG(format, ##__VA_ARGS__))};

#define BDALOG_PROTOCOL_WARN_INSTANCE(instance_name, format, ...)\
@autoreleasepool {ALOG_PROTOCOL_INSTANCE([instance_name UTF8String], kLogLevelWarn, "", NSCHAR_LOG(format, ##__VA_ARGS__))};

//error log
#define BDALOG_PROTOCOL_ERROR(format, ...)\
@autoreleasepool {ALOG_PROTOCOL_OC(kLogLevelError, @"", NSSTRING_LOG(format, ##__VA_ARGS__))};

#define BDALOG_PROTOCOL_ERROR_INSTANCE(instance_name, format, ...)\
@autoreleasepool {ALOG_PROTOCOL_INSTANCE([instance_name UTF8String], kLogLevelError, "", NSCHAR_LOG(format, ##__VA_ARGS__))};

//fatal log
#define BDALOG_PROTOCOL_FATAL(format, ...)\
@autoreleasepool {ALOG_PROTOCOL_OC(kLogLevelFatal, @"", NSSTRING_LOG(format, ##__VA_ARGS__))};

#define BDALOG_PROTOCOL_FATAL_INSTANCE(instance_name, format, ...)\
@autoreleasepool {ALOG_PROTOCOL_INSTANCE([instance_name UTF8String], kLogLevelFatal, "", NSCHAR_LOG(format, ##__VA_ARGS__))};


/** TAG*/
//debug log
#define BDALOG_PROTOCOL_DEBUG_TAG(tag, format, ...)\
@autoreleasepool {ALOG_PROTOCOL_OC(kLogLevelDebug, tag, NSSTRING_LOG(format, ##__VA_ARGS__))};

#define BDALOG_PROTOCOL_DEBUG_TAG_INSTANCE(instance_name, tag, format, ...)\
@autoreleasepool {ALOG_PROTOCOL_INSTANCE([instance_name UTF8String], kLogLevelDebug, [tag UTF8String], NSCHAR_LOG(format, ##__VA_ARGS__))};

//info log
#define BDALOG_PROTOCOL_INFO_TAG(tag, format, ...)\
@autoreleasepool {ALOG_PROTOCOL_OC(kLogLevelInfo, tag, NSSTRING_LOG(format, ##__VA_ARGS__))};

#define BDALOG_PROTOCOL_INFO_TAG_INSTANCE(instance_name, tag, format, ...)\
@autoreleasepool {ALOG_PROTOCOL_INSTANCE([instance_name UTF8String], kLogLevelInfo, [tag UTF8String], NSCHAR_LOG(format, ##__VA_ARGS__))};

//warn log
#define BDALOG_PROTOCOL_WARN_TAG(tag, format, ...)\
@autoreleasepool {ALOG_PROTOCOL_OC(kLogLevelWarn, tag, NSSTRING_LOG(format, ##__VA_ARGS__))};

#define BDALOG_PROTOCOL_WARN_TAG_INSTANCE(instance_name, tag, format, ...)\
@autoreleasepool {ALOG_PROTOCOL_INSTANCE([instance_name UTF8String], kLogLevelWarn, [tag UTF8String], NSCHAR_LOG(format, ##__VA_ARGS__))};

//error log
#define BDALOG_PROTOCOL_ERROR_TAG(tag, format, ...)\
@autoreleasepool {ALOG_PROTOCOL_OC(kLogLevelError, tag, NSSTRING_LOG(format, ##__VA_ARGS__))};

#define BDALOG_PROTOCOL_ERROR_TAG_INSTANCE(instance_name, tag, format, ...)\
@autoreleasepool {ALOG_PROTOCOL_INSTANCE([instance_name UTF8String], kLogLevelError, [tag UTF8String], NSCHAR_LOG(format, ##__VA_ARGS__))};

//fatal log
#define BDALOG_PROTOCOL_FATAL_TAG(tag, format, ...)\
@autoreleasepool {ALOG_PROTOCOL_OC(kLogLevelFatal, tag, NSSTRING_LOG(format, ##__VA_ARGS__))};

#define BDALOG_PROTOCOL_FATAL_TAG_INSTANCE(instance_name, tag, format, ...)\
@autoreleasepool {ALOG_PROTOCOL_INSTANCE([instance_name UTF8String], kLogLevelFatal, [tag UTF8String], NSCHAR_LOG(format, ##__VA_ARGS__))};


#ifdef __cplusplus
    #define ALOG_PROTOCOL_OC(_level, _tag, _string) \
    do{ \
        BDALOG_TYPE_OF_ASSERT_STRING(__typeof__(_tag), "_tag must be convertible to NSString"); \
        BDALOG_TYPE_OF_ASSERT_STRING(__typeof__(_string), "_string must be convertible to NSString"); \
        bd_log_write_OC(__BDALOGPROTOCOL_FILE_NAME__, __FUNCTION__, (NSString *)(_tag), (_level), __LINE__, (NSString *)(_string)); \
    } while(0);
#else
    #define ALOG_PROTOCOL_OC(_level, _tag, _string) \
    do{ \
        bd_log_write_OC(__BDALOGPROTOCOL_FILE_NAME__, __FUNCTION__, (_tag), (_level), __LINE__, (_string)); \
    } while(0);
#endif

#endif

#ifdef __cplusplus
extern "C" {
#endif
    
#pragma mark - C and C++
//C and C++
#define ALOG_PROTOCOL_DEBUG(format, ...) ALOG_PROTOCOL_C(kLogLevelDebug, "", format, ##__VA_ARGS__);
#define ALOG_PROTOCOL_DEBUG_INSTANCE(instance_name, format, ...) ALOG_PROTOCOL_C_INSTANCE(instance_name, kLogLevelDebug, "", format, ##__VA_ARGS__);

#define ALOG_PROTOCOL_INFO(format, ...) ALOG_PROTOCOL_C(kLogLevelInfo, "", format, ##__VA_ARGS__);
#define ALOG_PROTOCOL_INFO_INSTANCE(instance_name, format, ...) ALOG_PROTOCOL_C_INSTANCE(instance_name, kLogLevelInfo, "", format, ##__VA_ARGS__);

#define ALOG_PROTOCOL_WARN(format, ...) ALOG_PROTOCOL_C(kLogLevelWarn, "", format, ##__VA_ARGS__);
#define ALOG_PROTOCOL_WARN_INSTANCE(instance_name, format, ...) ALOG_PROTOCOL_C_INSTANCE(instance_name, kLogLevelWarn, "", format, ##__VA_ARGS__);

#define ALOG_PROTOCOL_ERROR(format, ...) ALOG_PROTOCOL_C(kLogLevelError, "", format, ##__VA_ARGS__);
#define ALOG_PROTOCOL_ERROR_INSTANCE(instance_name, format, ...) ALOG_PROTOCOL_C_INSTANCE(instance_name, kLogLevelError, "", format, ##__VA_ARGS__);

#define ALOG_PROTOCOL_FATAL(format, ...) ALOG_PROTOCOL_C(kLogLevelFatal, "", format, ##__VA_ARGS__);
#define ALOG_PROTOCOL_FATAL_INSTANCE(instance_name, format, ...) ALOG_PROTOCOL_C_INSTANCE(instance_name, kLogLevelFatal, "", format, ##__VA_ARGS__);
    
#define ALOG_PROTOCOL_DEBUG_TAG(tag,format, ...) ALOG_PROTOCOL_C(kLogLevelDebug, tag, format, ##__VA_ARGS__);
#define ALOG_PROTOCOL_DEBUG_TAG_INSTANCE(instance_name, tag,format, ...) ALOG_PROTOCOL_C_INSTANCE(instance_name, kLogLevelDebug, tag, format, ##__VA_ARGS__);

#define ALOG_PROTOCOL_INFO_TAG(tag,format, ...) ALOG_PROTOCOL_C(kLogLevelInfo, tag, format, ##__VA_ARGS__);
#define ALOG_PROTOCOL_INFO_TAG_INSTANCE(instance_name, tag,format, ...) ALOG_PROTOCOL_C_INSTANCE(instance_name, kLogLevelInfo, tag, format, ##__VA_ARGS__);

#define ALOG_PROTOCOL_WARN_TAG(tag,format, ...) ALOG_PROTOCOL_C(kLogLevelWarn, tag, format, ##__VA_ARGS__);
#define ALOG_PROTOCOL_WARN_TAG_INSTANCE(instance_name, tag,format, ...) ALOG_PROTOCOL_C_INSTANCE(instance_name, kLogLevelWarn, tag, format, ##__VA_ARGS__);

#define ALOG_PROTOCOL_ERROR_TAG(tag,format, ...) ALOG_PROTOCOL_C(kLogLevelError, tag, format, ##__VA_ARGS__);
#define ALOG_PROTOCOL_ERROR_TAG_INSTANCE(instance_name, tag,format, ...) ALOG_PROTOCOL_C_INSTANCE(instance_name, kLogLevelError, tag, format, ##__VA_ARGS__);

#define ALOG_PROTOCOL_FATAL_TAG(tag,format, ...) ALOG_PROTOCOL_C(kLogLevelFatal, tag, format, ##__VA_ARGS__);
#define ALOG_PROTOCOL_FATAL_TAG_INSTANCE(instance_name, tag,format, ...) ALOG_PROTOCOL_C_INSTANCE(instance_name, kLogLevelFatal, tag, format, ##__VA_ARGS__);

#define ALOG_PROTOCOL(_level, _tag, _format, ...)\
do{\
bd_log_write(__BDALOGPROTOCOL_FILE_NAME__, __FUNCTION__, _tag, _level, __LINE__, _format);\
}while(0);\

#define ALOG_PROTOCOL_INSTANCE(_instance_name, _level, _tag, _format, ...)\
do{\
bd_log_write_instance(_instance_name, __BDALOGPROTOCOL_FILE_NAME__, __FUNCTION__, _tag, _level, __LINE__, _format);\
}while(0);\

#define ALOG_PROTOCOL_C(_level, _tag, _format, ...)\
do{\
bd_log_write_var(__BDALOGPROTOCOL_FILE_NAME__, __FUNCTION__, _tag, _level, __LINE__, _format, ##__VA_ARGS__);\
}while(0);\

#define ALOG_PROTOCOL_C_INSTANCE(_instance_name, _level, _tag, _format, ...)\
do{\
bd_log_write_var_instance(_instance_name, __BDALOGPROTOCOL_FILE_NAME__, __FUNCTION__, _tag, _level, __LINE__, _format, ##__VA_ARGS__);\
}while(0);\

    typedef enum {
        kLogLevelAll = 0,
        kLogLevelVerbose = 0,
        kLogLevelDebug = 1,    // Detailed information on the flow through the system.
        kLogLevelInfo = 2,     // Interesting runtime events (startup/shutdown), should be cautious and keep to a minimum.
        kLogLevelWarn = 3,     // Other runtime situations that are undesirable or unexpected, but not necessarily "wrong".
        kLogLevelError = 4,    // Other runtime errors or unexpected conditions.
        kLogLevelFatal = 5,    // Severe errors that cause premature termination.
        kLogLevelNone = 10000,     // Special level used to disable all log messages.
    } kBDLogLevel;

    typedef void (*bd_log_write_var_func_ptr) (const char * _Nonnull _filename, const char * _Nonnull _func_name, const char * _Nonnull _tag, kBDLogLevel _level, int _line, const char * _Nonnull _format, ...);
    typedef void (*bd_log_write_func_ptr) (const char * _Nonnull _filename, const char * _Nonnull _func_name, const char * _Nonnull _tag, kBDLogLevel _level, int _line, const char * _Nonnull _format);

    //C和C++写入log的宏定义调用方法
    void bd_log_write_var(const char * _Nonnull _filename, const char * _Nonnull _func_name, const char * _Nonnull _tag, kBDLogLevel _level, int _line, const char * _Nonnull _format, ...);

    //OC写入log的宏定义调用方法
    void bd_log_write(const char * _Nonnull _filename, const char * _Nonnull _func_name, const char * _Nonnull _tag, kBDLogLevel _level, int _line, const char * _Nonnull _format);

    //返回指向 bd_log_write_var 方法的函数指针
    bd_log_write_var_func_ptr _Nullable funcAddr_bd_log_write_var(void);

    //返回指向 bd_log_write 方法的函数指针
    bd_log_write_func_ptr _Nullable funcAddr_bd_log_write(void);

    //是否包含BDALog
    bool bd_log_enable(void);

    
    /******* alog多实例相关接口 *******/

    // log callback define
    typedef void (*bd_log_callback)(const char * _Nonnull log);
    typedef void (*bd_log_detail_callback)(const char * _Nullable time, intmax_t pid, intmax_t tid, int is_main_thread,  const char * _Nullable level,  const char * _Nullable tag,  const char * _Nullable func_name,  const char * _Nullable file_name, int line,  const char * _Nullable log);

//#ifdef __cplusplus
//    typedef void (*bd_log_modify_handler)(std::string& log, std::string& tag, bool& isAbandon);
//
//    typedef void (*bd_log_detail_modify_handler)(intmax_t pid, intmax_t tid, bool is_main_thread,  const char * _Nullable level,  const char * _Nullable func_name,  const char * _Nullable file_name, std::string& log, std::string& tag, bool& isAbandon);
//#endif

    //BDALog版本是否支持多实例
    bool bd_log_multiple_instance_enable(void);

    void bd_log_open_default_instance(const char* _Nonnull instance_name,  const char* _Nonnull prefix);
    void bd_log_open_instance(const char* _Nonnull instance_name,  const char* _Nonnull prefix, long long max_size, double out_date);

    void bd_log_write_var_instance(const char * _Nonnull _instance_name, const char * _Nonnull _filename, const char * _Nonnull _func_name, const char * _Nonnull _tag, kBDLogLevel _level, int _line,  const char * _Nonnull _format, ...);

    void bd_log_write_instance(const char * _Nonnull _instance_name, const char * _Nonnull _filename, const char * _Nonnull _func_name, const char * _Nonnull _tag, kBDLogLevel _level, int _line,  const char * _Nonnull _format);
    
    void bd_log_set_log_mian_thread_async_write_instance(const char* _Nonnull instance_name, bool _is_async);

    void bd_log_set_max_heaped_log_info_count_instance(const char* _Nonnull instance_name, int _count);

    void bd_log_set_console_log_instance(const char* _Nonnull instance_name, bool _is_open);

    void bd_log_set_log_level_instance(const char* _Nonnull instance_name, kBDLogLevel _level);

    void bd_log_flush_instance(const char* _Nonnull instance_name);

    void bd_log_flush_sync_instance(const char* _Nonnull instance_name);

    void bd_log_remove_file_instance(const char* _Nonnull instance_name,  const char* _Nonnull _filepath);

    void bd_log_set_log_callback_instance(const char* _Nonnull instance_name, bd_log_callback _Nullable log_callback);

    void bd_log_set_log_detail_callback_instance(const char* _Nonnull instance_name, bd_log_detail_callback _Nullable log_detail_callback);

//#ifdef __cplusplus
//    void bd_log_set_log_modify_handler_instance(const char* _Nullable instance_name, bd_log_modify_handler log_modify_handler);
//
//    void bd_log_set_tag_blocklist_instance(const char* _Nullable instance_name, const std::vector<std::string> _tag_blocklist);
//
//    void bd_log_set_tag_console_allowlist_instance(const char* _Nullable instance_name, const std::set<std::string> _tag_console_allowlist);
//
//    void bd_log_getFilePaths_instance(const char* _Nullable instance_name, long long fromTimeInterval, long long toTimeInterval, std::vector<std::string>& _filepath_vec);
//
//    void bd_log_getZipPaths_instance(const char* _Nullable instance_name, std::vector<std::string>& _zip_path_vec);
//#endif

/******* TTNet的安卓端保留接口，参数列表顺序不一致，其它组件请勿使用  *********/

    typedef void (*android_bd_log_write_var_func_ptr) (const char * _Nonnull _filename, const char * _Nonnull _func_name, int _line, const char * _Nonnull _tag, kBDLogLevel _level,  const char * _Nonnull _format, ...);
    typedef void (*android_bd_log_write_func_ptr) (const char * _Nonnull _filename, const char * _Nonnull _func_name, int _line, const char * _Nonnull _tag, kBDLogLevel _level,  const char * _Nonnull _format);

    void android_bd_log_write_var(const char * _Nonnull _filename, const char * _Nonnull _func_name, int _line, const char * _Nonnull _tag, kBDLogLevel _level,  const char * _Nonnull _format, ...);
    void android_bd_log_write(const char * _Nonnull _filename, const char * _Nonnull _func_name, int _line, const char * _Nonnull _tag, kBDLogLevel _level,  const char * _Nonnull _format);
    android_bd_log_write_var_func_ptr _Nullable android_funcAddr_bd_log_write_var(void);
    android_bd_log_write_func_ptr _Nullable android_funcAddr_bd_log_write(void);
        
//////////////////////////////////////////////////////////////////////////////////////
    



#ifdef __cplusplus
} // extern "C"
#endif

#endif /* BDLogProtocol_hpp */

//////////////////////////////////////////////////////////////////////////////////////
#ifdef __OBJC__
#import<Foundation/Foundation.h>

#ifdef __cplusplus
extern "C" {
#endif
void bd_log_write_OC(const char* _Nonnull fileName, const char* _Nonnull funcName, NSString const * _Nonnull tag, kBDLogLevel _level, int _line, NSString const * _Nonnull format);
#ifdef __cplusplus
} // extern "C"
#endif

@interface BDALogProtocol : NSObject
+ (void)setALogWithFileName:(NSString * _Nonnull)fileName
                   funcName:(NSString * _Nonnull)funcName
                        tag:(NSString * _Nonnull)tag
                       line:(int)line
                      level:(int)level
                     format:(NSString * _Nonnull)format;

@end
#endif
