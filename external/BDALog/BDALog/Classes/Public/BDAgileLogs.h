//
//  BDAgileLogs.hpp
//  BDALog
//
//  Created by liuhan on 2023/2/21.
//

#ifndef BDAgileLogs_h
#define BDAgileLogs_h

#include <stdio.h>

#ifdef __cplusplus
#include <map>
#endif

#include "BDAgileLog.h"
#include "bdloggerbase.h"

#ifdef __cplusplus
extern "C" {
#endif

#ifdef __OBJC__
#import<Foundation/Foundation.h>

#define NSCHARINSTANCE(format, ...) ([[NSString stringWithFormat:format, ##__VA_ARGS__, nil] UTF8String])

#pragma mark -  OC Method and its usage is same as 'NSLog'
//自定义level
#define BDALOG_INSTANCE(instance_name, level, format, ...)\
@autoreleasepool {ALOG_INSTANCE([instance_name UTF8String], level, "", NSCHARINSTANCE(format, ##__VA_ARGS__))};

//自定义level和tag
#define BDALOG_TAG_INSTANCE(instance_name, level, tag, format, ...)\
@autoreleasepool {ALOG_INSTANCE([instance_name UTF8String], level, [tag UTF8String], NSCHARINSTANCE(format, ##__VA_ARGS__))};


//debug log
#define BDALOG_DEBUG_INSTANCE(instance_name, format, ...)\
@autoreleasepool {ALOG_INSTANCE([instance_name UTF8String], kLevelDebug, "", NSCHARINSTANCE(format, ##__VA_ARGS__))};

//info log
#define BDALOG_INFO_INSTANCE(instance_name, format, ...)\
@autoreleasepool {ALOG_INSTANCE([instance_name UTF8String], kLevelInfo, "", NSCHARINSTANCE(format, ##__VA_ARGS__))};

//warn log
#define BDALOG_WARN_INSTANCE(instance_name, format, ...)\
@autoreleasepool {ALOG_INSTANCE([instance_name UTF8String], kLevelWarn, "", NSCHARINSTANCE(format, ##__VA_ARGS__))};

//error log
#define BDALOG_ERROR_INSTANCE(instance_name, format, ...)\
@autoreleasepool {ALOG_INSTANCE([instance_name UTF8String], kLevelError, "", NSCHARINSTANCE(format, ##__VA_ARGS__))};

//fatal log
#define BDALOG_FATAL_INSTANCE(instance_name, format, ...)\
@autoreleasepool {ALOG_INSTANCE([instance_name UTF8String], kLevelFatal, "", NSCHARINSTANCE(format, ##__VA_ARGS__))};




/** TAG*/
//debug log
#define BDALOG_DEBUG_TAG_INSTANCE(instance_name, tag, format, ...)\
@autoreleasepool {ALOG_INSTANCE([instance_name UTF8String], kLevelDebug, [tag UTF8String], NSCHARINSTANCE(format, ##__VA_ARGS__))};

//info log
#define BDALOG_INFO_TAG_INSTANCE(instance_name, tag, format, ...)\
@autoreleasepool {ALOG_INSTANCE([instance_name UTF8String], kLevelInfo, [tag UTF8String], NSCHARINSTANCE(format, ##__VA_ARGS__))};

//warn log
#define BDALOG_WARN_TAG_INSTANCE(instance_name, tag, format, ...)\
@autoreleasepool {ALOG_INSTANCE([instance_name UTF8String], kLevelWarn, [tag UTF8String], NSCHARINSTANCE(format, ##__VA_ARGS__))};

//error log
#define BDALOG_ERROR_TAG_INSTANCE(instance_name, tag, format, ...)\
@autoreleasepool {ALOG_INSTANCE([instance_name UTF8String], kLevelError, [tag UTF8String], NSCHARINSTANCE(format, ##__VA_ARGS__))};

//fatal log
#define BDALOG_FATAL_TAG_INSTANCE(instance_name, tag, format, ...)\
@autoreleasepool {ALOG_INSTANCE([instance_name UTF8String], kLevelFatal, [tag UTF8String], NSCHARINSTANCE(format, ##__VA_ARGS__))};

#endif

#pragma mark - C and C++
//C and C++
#define ALOG_DEBUG_INSTANCE(instance_name, format, ...) ALOG_C_INSTANCE(instance_name, kLevelDebug, "", format, ##__VA_ARGS__);
#define ALOG_INFO_INSTANCE(instance_name, format, ...) ALOG_C_INSTANCE(instance_name, kLevelInfo, "", format, ##__VA_ARGS__);
#define ALOG_WARN_INSTANCE(instance_name, format, ...) ALOG_C_INSTANCE(instance_name, kLevelWarn, "", format, ##__VA_ARGS__);
#define ALOG_ERROR_INSTANCE(instance_name, format, ...) ALOG_C_INSTANCE(instance_name, kLevelError, "", format, ##__VA_ARGS__);
#define ALOG_FATAL_INSTANCE(instance_name, format, ...) ALOG_C_INSTANCE(instance_name, kLevelFatal, "", format, ##__VA_ARGS__);

/*_format必须是"%s","format"格式d否则字符串中带%可能会crash
正确示例：BDALOG_CUSTOM(kLevelInfo, "tag", 300, "file", "function", "%s", "mess%nas%sge--------");
错误示例：BDALOG_CUSTOM(kLevelInfo, "tag", 300, "file", "function", "mess%nas%sge--------");
*/
#define BDALOG_CUSTOM_INSTANCE(_instance_name, _level, _tag, _line, _file, _function, _format, ...)\
do{\
struct timeval tv;\
gettimeofday(&tv, NULL);\
BDLoggerInfo _info;\
_info.filename = _file?:__BDALOG_FILE_NAME__;\
_info.tag = _tag?:"";\
_info.level = _level;\
_info.func_name = _function?:__FUNCTION__;\
_info.line = _line;\
_info.timeval = tv;\
alog_write_instance(_instance_name, &_info, _format, ##__VA_ARGS__);\
}while(0);\

#define ALOG_INSTANCE(_instance_name, _level, _tag, _format, ...)\
do{\
struct timeval tv;\
gettimeofday(&tv, NULL);\
BDLoggerInfo _info;\
_info.filename = __BDALOG_FILE_NAME__;\
_info.tag = _tag;\
_info.level = _level;\
_info.line = __LINE__;\
_info.func_name = __FUNCTION__;\
_info.timeval = tv;\
alog_write_macro_instance(_instance_name, &_info, _format, ##__VA_ARGS__);\
}while(0);\

#define ALOG_C_INSTANCE(_instance_name, _level, _tag, _format, ...)\
do{\
struct timeval tv;\
gettimeofday(&tv, NULL);\
BDLoggerInfo _info;\
_info.filename = __BDALOG_FILE_NAME__;\
_info.tag = _tag;\
_info.level = _level;\
_info.line = __LINE__;\
_info.func_name = __FUNCTION__;\
_info.timeval = tv;\
alog_write_instance(_instance_name, &_info, _format, ##__VA_ARGS__);\
}while(0);\


/**
 * 默认方式初始化alog，默认加密+压缩，log最大缓存50M，log有效期7天
 *
 * @param instance_name 实例名
 * @param prefix log文件文件名前缀
 */

void alog_open_default_instance(const char* instance_name, const char* prefix);

/**
 * 默认方式初始化alog，默认加密+压缩，log最大缓存50M，log有效期7天
 *
 * @param instance_name 实例名
 * @param prefix log文件文件名前缀
 * @param max_size 文件缓存最大值 e.g 50M = 50 *1024 *1024（byte），默认10M
 * @param outdate 文件有效期 e.g.七天 = 7 *24 *60 *60(s)，默认7天
 */
void alog_open_instance(const char* instance_name, const char* prefix, long long max_size, double outdate);

#ifdef __cplusplus
/**
 * 获取所有实例名
 * instances:实例名列表
 */
void alog_get_all_instances(std::vector<std::string>& instances);
#endif


/**
 * 写入log
 * @param instance_name 实例名称
 * @param info log信息
 * @param format log内容
 */
void alog_write_instance(const char* instance_name, const BDLoggerInfo* info, const char* format, ...);

/**
 * 使用宏定义时必须调用此方法，否则可能会由于格式问题导致crash
 * @param instance_name 实例名称
 * @param info log信息
 * @param format log 内容
 * @param ... 可变参数
 */
void alog_write_macro_instance(const char* instance_name, const BDLoggerInfo* info, const char* format, ...);
/**
 * 主线程调用写日志时，是否异步写入日志
 * @param instance_name 实例名称
 * @param _is_async true: 主线程中调用写alog接口写日志，会在子线程异步执行；false: 在哪个线程调用写alog接口，便会在哪个线程执行
 */
void alog_set_log_mian_thread_async_write_instance(const char* instance_name, bool _is_async);

/**
 * 主线程异步写入开关打开时，使用的默认内存池大小，，必须在alog_open之前调用
 * @param _count 默认为3
 */
void alog_set_max_heaped_log_info_count_instance(const char* instance_name, int _count);

/**
 * 是否在console打印
 * @param _is_open true:打印 false:不打印 默认debug模式为true，release为false
 */
void alog_set_console_log_instance(const char* instance_name, bool _is_open);

/**
 * 设置log level，低于该level的log不写入文件
 * @param _level log level
 */
void alog_set_log_level_instance(const char* instance_name, kBDALogLevel _level);

/* 异步将log flush到目标文件*/
void alog_flush_instance(const char* instance_name);

/* 同步将log flush到目标文件*/
void alog_flush_sync_instance(const char* instance_name);

/* 关闭alog，一般在-applicationWillTerminate调用 */
void alog_close_instance(const char* instance_name);

/**
 * ⚠️删除某个log文件，为确保线程安全删除log文件必须用此方法
 * @param _filepath 文件路径
 */
void alog_remove_file_instance(const char* instance_name, const char* _filepath);

/* 设置log回调，在实例初始化后设置 */
void alog_set_log_callback_instance(const char* instance_name, type_log_callback log_callback);

void alog_set_log_detail_callback_instance(const char* instance_name, type_log_detail_callback log_detail_callback);
    
#ifdef __cplusplus
/* 设置log回调，处理log内容，在实例初始化后设置*/
void alog_set_log_modify_handler_instance(const char* instance_name, type_log_modify_handler log_modify_handler);

/**
 * 设置tag黑名单，带黑名单中的tag的log不会写入文件
 * @param  _tag_blocklist 黑名单列表
 */
void alog_set_tag_blocklist_instance(const char* instance_name, const std::vector<std::string> _tag_blocklist);

/**
 * 设置仅用于控制台输出的tag白名单，打开alog控制台输出，设置此白名单后，带白名单中的tag的log才会输出在控制台
 * 注意此接口，与写入无关！仅用于控制台输出
 * @param  _tag_console_allowlist 控制台输出的白名单列表
 */
void alog_set_tag_console_allowlist_instance(const char* instance_name, const std::set<std::string> _tag_console_allowlist);

/**
 * 获取某个时间段文件，time interval必须是UTC时间
 * fromTimeInterval = 0 & toTimeInterval > 0时返回toTimeInterval这个时间点之前的所有文件（0表示无边界）
 * toTimeInterval = 0 & fromTimeInterval > 0时返回从fromTimeInterval这个时间点之后的所有文件（0表示无边界）
 * toTimeInterval = 0 & fromTimeInterval = 0时返回所有文件（0表示无边界）
 * @param fromTimeInterval 起始时间 e.g.三天前[NSDate dateWithTimeIntervalSince1970:[NSDate date].timeIntervalSince1970 - 3 *24 *60 * 60].timeIntervalSince1970
 * @param toTimeInterval 结束时间
 * @param _filepath_vec 文件列表，返回文件列表是根据文件创建时间排好序列表，列表第一个即为所传时间段内最近生成文件
 */
void alog_getFilePaths_instance(const char* instance_name, long long fromTimeInterval, long long toTimeInterval, std::vector<std::string>& _filepath_vec);

void alog_getFilePaths_all_instance(long long fromTimeInterval, long long toTimeInterval, std::vector<std::string>& _filepath_vec);

/**
 * 获取Alog目录下zip文件，zip文件预期都是alog上报时产生的临时文件
 * @param _zip_path_vec zip文件列表，可通过该数组获取zip文件列表
 */
void alog_getZipPaths_instance(const char* instance_name, std::vector<std::string>& _zip_path_vec);

} // extern "C"
#endif

#endif /* BDAgileLogs_h */
