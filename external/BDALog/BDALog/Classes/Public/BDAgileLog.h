//
//  BDALog
//
//  Created by hopo on 2018/9/5.
//

#ifndef BDAGILELOG_H_
#define BDAGILELOG_H_

#include <TargetConditionals.h>
#include <stdio.h>
#include <stdbool.h>

#include "bdloggerbase.h"

#ifdef __cplusplus
#include <string>
#include <vector>
#include <set>
#endif

#ifdef __FILE_NAME__
#define __BDALOG_FILE_NAME__ __FILE_NAME__
#else
#define __BDALOG_FILE_NAME__ __FILE__
#endif

#if !defined(BD_NO_TAIL_CALL)
#if __has_attribute(not_tail_called)
#define BD_NO_TAIL_CALL __attribute__((not_tail_called))
#else
#define BD_NO_TAIL_CALL
#endif
#endif

#if !defined(BD_FORMAT_FUNCTION)
#if (__GNUC__*10+__GNUC_MINOR__ >= 42) && (TARGET_OS_MAC || TARGET_OS_IPHONE || TARGET_OS_SIMULATOR)
#define BD_FORMAT_FUNCTION(F,A) __attribute__((format(printf, F, A)))
#else
#define BD_FORMAT_FUNCTION(F,A)
#endif
#endif

#ifdef __OBJC__
#import<Foundation/Foundation.h>

//设置tag黑名单,这个宏只能在.mm文件或者cpp文件中使用
#define BDALOG_SET_TAG_BLOCKLIST(tagBlocklist)\
do{\
std::vector<std::string> tag_blocklist_vec;\
for (NSString *tag in tagBlocklist) {\
    std::string str([tag UTF8String]);\
    tag_blocklist_vec.push_back(str);\
}\
alog_set_tag_blocklist(tag_blocklist_vec);\
}while(0);\


#define NSCHAR(format, ...) ([NSString stringWithFormat:format, ##__VA_ARGS__, nil])

#pragma mark -  OC Method and its usage is same as 'NSLog'
//自定义level
#define BDALOG(level, format, ...)\
@autoreleasepool {ALOG_OC(level, @"", NSCHAR(format, ##__VA_ARGS__))};

//自定义level和tag
#define BDALOG_TAG(level, tag, format, ...)\
@autoreleasepool {ALOG_OC(level, tag, NSCHAR(format, ##__VA_ARGS__))};


//debug log
#define BDALOG_DEBUG(format, ...)\
@autoreleasepool {ALOG_OC(kLevelDebug, @"", NSCHAR(format, ##__VA_ARGS__))};

//info log
#define BDALOG_INFO(format, ...)\
@autoreleasepool {ALOG_OC(kLevelInfo, @"", NSCHAR(format, ##__VA_ARGS__))};

//warn log
#define BDALOG_WARN(format, ...)\
@autoreleasepool {ALOG_OC(kLevelWarn, @"", NSCHAR(format, ##__VA_ARGS__))};

//error log
#define BDALOG_ERROR(format, ...)\
@autoreleasepool {ALOG_OC(kLevelError, @"", NSCHAR(format, ##__VA_ARGS__))};

//fatal log
#define BDALOG_FATAL(format, ...)\
@autoreleasepool {ALOG_OC(kLevelFatal, @"", NSCHAR(format, ##__VA_ARGS__))};




/** TAG*/
//debug log
#define BDALOG_DEBUG_TAG(tag, format, ...)\
@autoreleasepool {ALOG_OC(kLevelDebug, tag, NSCHAR(format, ##__VA_ARGS__))};

//info log
#define BDALOG_INFO_TAG(tag, format, ...)\
@autoreleasepool {ALOG_OC(kLevelInfo, tag, NSCHAR(format, ##__VA_ARGS__))};

//warn log
#define BDALOG_WARN_TAG(tag, format, ...)\
@autoreleasepool {ALOG_OC(kLevelWarn, tag, NSCHAR(format, ##__VA_ARGS__))};

//error log
#define BDALOG_ERROR_TAG(tag, format, ...)\
@autoreleasepool {ALOG_OC(kLevelError, tag, NSCHAR(format, ##__VA_ARGS__))};

//fatal log
#define BDALOG_FATAL_TAG(tag, format, ...)\
@autoreleasepool {ALOG_OC(kLevelFatal, tag, NSCHAR(format, ##__VA_ARGS__))};

#define ALOG_OC(_level, _tag, _format, ...)\
do{\
struct timeval tv;\
gettimeofday(&tv, NULL);\
BDLoggerInfo _info;\
_info.filename = __BDALOG_FILE_NAME__;\
_info.tag = [_tag UTF8String];\
_info.level = _level;\
_info.line = __LINE__;\
_info.func_name = __FUNCTION__;\
_info.timeval = tv;\
_alog_write_macro_OC(&_info, _tag, _format);\
}while(0);\

#endif


#ifdef __cplusplus
extern "C" {
#endif
    
#pragma mark - C and C++
//C and C++
#define ALOG_DEBUG(format, ...) ALOG_C(kLevelDebug, "", format, ##__VA_ARGS__);
#define ALOG_INFO(format, ...) ALOG_C(kLevelInfo, "", format, ##__VA_ARGS__);
#define ALOG_WARN(format, ...) ALOG_C(kLevelWarn, "", format, ##__VA_ARGS__);
#define ALOG_ERROR(format, ...) ALOG_C(kLevelError, "", format, ##__VA_ARGS__);
#define ALOG_FATAL(format, ...) ALOG_C(kLevelFatal, "", format, ##__VA_ARGS__);

/*_format必须是"%s","format"格式d否则字符串中带%可能会crash
 正确示例：BDALOG_CUSTOM(kLevelInfo, "tag", 300, "file", "function", "%s", "mess%nas%sge--------");
 错误示例：BDALOG_CUSTOM(kLevelInfo, "tag", 300, "file", "function", "mess%nas%sge--------");
 */
#define BDALOG_CUSTOM(_level, _tag, _line, _file, _function, _format, ...)\
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
alog_write(&_info, _format, ##__VA_ARGS__);\
}while(0);\

#define ALOG(_level, _tag, _format, ...)\
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
_alog_write_macro(&_info, _format, ##__VA_ARGS__);\
}while(0);\

#define ALOG_C(_level, _tag, _format, ...)\
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
alog_write(&_info, _format, ##__VA_ARGS__);\
}while(0);\

/* ---------------------------------------Old ALog----------------------------------------*/
/**
 * 默认方式初始化alog，默认加密+压缩，log最大缓存50M，log有效期7天
 * @param _dir log文件存储路径
 * @param _name_prefix log文件文件名前缀
 */
void alog_open_default(const char* _Nonnull _dir, const char* _Nonnull _name_prefix);
    
/**
 * 自定义初始化alog，如加密使用默认key pair加密
 * @param _dir log文件存储路径
 * @param _name_prefix log文件文件名前缀
 * @param _max_size 文件缓存最大值 e.g 50M = 50 *1024 *1024（byte）
 * @param _out_date 文件有效期 e.g.七天 = 7 *24 *60 *60(s)
 * @param _is_crypt 是否加密，true：加密 false不加密
 */
void alog_open(const char* _Nonnull _dir, const char* _Nonnull _name_prefix, long long _max_size, double _out_date, bool _is_crypt);
    
/**
 * 自定义初始化alog，设置App独立密钥加密alog文件，此方法自动获取沙盒内appID
 * @param _dir log文件存储路径
 * @param _name_prefix log文件文件名前缀
 * @param _max_size 文件缓存最大值 e.g 50M = 50 *1024 *1024（byte）
 * @param _out_date 文件有效期 e.g.七天 = 7 *24 *60 *60(s)
 * @param _pubkey App自定义密钥，密钥由服务端生成，请勿随意指定，详情请见 https://bytedance.feishu.cn/docs/doccnerTgSVSdBcWnNCWfNoP4Oc
 */
void alog_open_custom_key(const char* _Nonnull _dir, const char* _Nonnull _name_prefix, long long _max_size, double _out_date, const char* _Nullable _pubkey);

/**
 * 自定义初始化alog，设置App独立密钥和AppID加密alog文件
 * @param _dir log文件存储路径
 * @param _name_prefix log文件文件名前缀
 * @param _max_size 文件缓存最大值 e.g 50M = 50 *1024 *1024（byte）
 * @param _out_date 文件有效期 e.g.七天 = 7 *24 *60 *60(s)
 * @param _pubkey App自定义密钥，密钥由服务端生成，请勿随意指定，详情请见 https://bytedance.feishu.cn/docs/doccnerTgSVSdBcWnNCWfNoP4Oc
 * @param _appid App ID
 */
void alog_open_custom_key_aid(const char* _Nonnull _dir, const char* _Nonnull _name_prefix, long long _max_size, double _out_date, const char* _Nullable _pubkey, const char* _Nullable _appid);

/**
 * 写入log
 * @param _info log信息
 * @param _format log内容
 */
void alog_write(const BDLoggerInfo*  _Nonnull _info, const char* _Nonnull _format, ...) BD_FORMAT_FUNCTION(2,3) BD_NO_TAIL_CALL;

/**
 * 使用宏定义时必须调用此方法，否则可能会由于格式问题导致crash
 * @param _info log信息
 * @param _format log 内容
 * @param ... 可变参数
 */
void _alog_write_macro(const BDLoggerInfo*  _Nonnull _info,const char* _Nonnull _format, ...);

/**
 * 主线程调用写日志时，是否异步写入日志
 * @param _is_async true: 主线程中调用写alog接口写日志，会在子线程异步执行；false: 在哪个线程调用写alog接口，便会在哪个线程执行
 */
void alog_set_log_mian_thread_async_write(bool _is_async);

/**
 * 主线程异步写入开关打开时，使用的默认内存池大小，，必须在alog_open之前调用
 * @param _count 默认为3
 */
void alog_set_max_headed_log_info_count(int _count);

/**
 * 主线程异步写入开关打开时，内存池最大尺寸，超过该count后将直接丢弃Alog，必须在alog_open之前调用
 * @param _count 默认为3000
 */
void alog_set_max_heaped_log_info_count_abandon(int _count);

/**
 * 是否在console打印
 * @param _is_open true:打印 false:不打印 默认debug模式为true，release为false
 */
void alog_set_console_log(bool _is_open);

/**
 * 设置log level，低于该level的log不写入文件
 * @param _level log level
 */
void alog_set_log_level(kBDALogLevel _level);

/* 异步将log flush到目标文件*/
void alog_flush(void);

/* 同步将log flush到目标文件*/
void alog_flush_sync(void);

/* 关闭alog，一般在-applicationWillTerminate调用 */
void alog_close(void);

/**
 * ⚠️删除某个log文件，为确保线程安全删除log文件必须用此方法
 * @param _filepath 文件路径
 */
void alog_remove_file(const char* _Nonnull _filepath);

/**
 * ⚠️删除所有实例所有的log文件
 */
void alog_flush_and_remove_all_files_all_instance();

/**
 * ⚠️删除所有实例所有的log文件
 * @param max_remain_seconds 文件最大保留时间, e.g.七天 = 7 * 24 * 60 * 60(s)
 */
void alog_flush_and_remove_all_files_all_instance_before_time(double max_remain_seconds);

/* 设置log回调，必须在alog_open之前调用，且只调用一次 */
void alog_set_log_callback(type_log_callback _Nullable log_callback);
void alog_set_log_detail_callback(type_log_detail_callback _Nullable log_detail_callback);

/* 设置日志清理回调，必须在alog_open之前调用 */
void alog_set_files_remove_callback(type_files_remove_callback _Nullable callback);

#ifdef __OBJC__

/**
 * 主线程提交日志到子线程时，不走OC层异步
 * @param enable 是否通过oc层走异步，默认为true。
 */
void alog_write_async_in_oc(bool enable);

/**
 * ⚠️ 注意：使用宏定义时必须调用此方法，否则可能会由于格式问题导致crash
 * ⚠️ 注意：使用此接口写alog，请确保info中的funname、filename只能传递c常量字符串，否则开启主线程异步写入会有多线程风险
 * @param _info log信息
 * @param _tag tag信息
 * @param _format log 内容
 */
void _alog_write_macro_OC(const BDLoggerInfo*  _Nonnull _info, NSString const * _Nonnull _tag, NSString const * _Nonnull _format);
#endif
    
#ifdef __cplusplus
/* 设置log回调，处理log内容，为保证所有日志都能被处理，必须在alog_open之前调用*/
void alog_set_log_modify_handler(type_log_modify_handler _Nullable log_modify_handler);

void alog_set_log_detail_modify_handler(type_log_detail_modify_handler _Nullable log_detail_handler);
/**
 * 设置tag黑名单，带黑名单中的tag的log不会写入文件
 * @param  _tag_blocklist 黑名单列表
 */
void alog_set_tag_blocklist(const std::vector<std::string> _tag_blocklist);

/**
 * 设置仅用于控制台输出的tag白名单，打开alog控制台输出，设置此白名单后，带白名单中的tag的log才会输出在控制台
 * 注意此接口，与写入无关！仅用于控制台输出
 * @param  _tag_console_allowlist 控制台输出的白名单列表
 */
void alog_set_tag_console_allowlist(const std::set<std::string> _tag_console_allowlist);

/**
 * 获取某个时间段文件，time interval必须是UTC时间
 * fromTimeInterval = 0 & toTimeInterval > 0时返回toTimeInterval这个时间点之前的所有文件（0表示无边界）
 * toTimeInterval = 0 & fromTimeInterval > 0时返回从fromTimeInterval这个时间点之后的所有文件（0表示无边界）
 * toTimeInterval = 0 & fromTimeInterval = 0时返回所有文件（0表示无边界）
 * @param fromTimeInterval 起始时间 e.g.三天前[NSDate dateWithTimeIntervalSince1970:[NSDate date].timeIntervalSince1970 - 3 *24 *60 * 60].timeIntervalSince1970
 * @param toTimeInterval 结束时间
 * @param _filepath_vec 文件列表，返回文件列表是根据文件创建时间排好序列表，列表第一个即为所传时间段内最近生成文件
 */
void alog_getFilePaths(long long fromTimeInterval, long long toTimeInterval, std::vector<std::string>& _filepath_vec);

/**
 * 获取Alog目录下zip文件，zip文件预期都是alog上报时产生的临时文件
 * @param _zip_path_vec zip文件列表，可通过该数组获取zip文件列表
 */
void alog_getZipPaths(std::vector<std::string>& _zip_path_vec);

} // extern "C"
#endif

#endif /* BDAGILELOG_H_ */
