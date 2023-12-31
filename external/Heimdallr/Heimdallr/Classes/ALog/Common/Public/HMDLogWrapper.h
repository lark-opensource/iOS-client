//
//  HMDLogWrapper.h
//  Heimdallr
//
//  Created by 柳钰柯 on 2020/6/11.
//

#import <Foundation/Foundation.h>


/**
 * HMDLogWrapper is a Swift wrapper for BDALog
 */
@interface HMDLogWrapper : NSObject

typedef NS_ENUM(NSInteger,AlogAdaptorLogLevel) {
    AlogAdaptorLogAll = 0,
    AlogAdaptorLogVerbose = 0,
    AlogAdaptorLogDebug = 1,    // Detailed information on the flow through the system.
    AlogAdaptorLogInfo = 2,     // Interesting runtime events (startup/shutdown), should be conservative and keep to a minimum.
    AlogAdaptorLogWarn = 3,     // Other runtime situations that are undesirable or unexpected, but not necessarily "wrong".
    AlogAdaptorLogError = 4,    // Other runtime errors or unexpected conditions.
    AlogAdaptorLogFatal = 5,    // Severe errors that cause premature termination.
    AlogAdaptorLogNone = 10000,     // Special level used to disable all log messages.
};

#pragma mark -  Method for Operating BDALog

/**
 * 可作为alog初始化方法的存储路径的值
 */
+ (NSString * _Nonnull)defaultPath;

/**
 * 使用默认设置开启ALog功能
 * 默认文件加密且前缀名为BDALog
 * 默认ALog文件最大缓存50M，有效期7天
 * Debug环境下默认在控制台输出
 * 默认所有Level都写入Alog文件
 */
+ (void)setALogEnabled;

/**
 * 使用自定义设置开启ALog功能
 * @param path ALog文件的存储路径
 * @param prefix ALog文件的前缀名
 */
+ (void)alogOpenDefault:(NSString * _Nonnull)path namePrefix:(NSString * _Nonnull)prefix;

/**
 * 使用自定义设置开启ALog功能
 * @param path Alog文件的存储路径
 * @param prefix Alog文件的前缀名
 * @param size 文件缓存最大值
 * @param date 文件有效期
 * @param crypt 是否加密
 */
+ (void)alogOpenWithDir:(NSString * _Nonnull)path namePrefix:(NSString * _Nonnull)prefix maxSize:(NSNumber * _Nonnull)size outdate:(NSNumber * _Nonnull)date isCrypt:(BOOL)crypt;

/**
 * 是否在console打印log信息
 * @param isOpen true为打印，false不打印
 */
+ (void)alogSetConsoleLogOpen:(BOOL)isOpen;

/**
 * 设置log level，低于该level的log不写入文件
 * @param level log level
 */
+ (void)setAlogSetLogLevel:(AlogAdaptorLogLevel)level;

/**
 * 异步将log flush到目标文件
 */
+ (void)alogFlush;

/**
 * 同步将log flush到目标文件
 */
+ (void)alogFlushSync;

/**
 * 关闭ALog功能
 */
+ (void)alogClose;

/**
 * 删除某个ALog文件，⚠️为确保线程安全删除ALog文件必须用此方法
 * @param path ALog文件的存储路径
 */
+ (void)alogRemoveFileAt:(NSString * _Nonnull)path;

/**
 * 设置tag黑名单，带黑名单中的tag的log不会写入文件
 * @param list 黑名单tag数组
 */
+ (void)alogSetTagBlocklist:(NSArray * _Nonnull)list;

/**
 * 返回某个时间段ALog文件列表，此列表根据文件创建时间排序，列表第一个即为所传时间段内最近生成文件，time interval必须是UTC时间
 * fromTimeInterval = 0 & toTimeInterval > 0时返回toTimeInterval这个时间点之前的所有文件（0表示无边界）
 * toTimeInterval = 0 & fromTimeInterval > 0时返回从fromTimeInterval这个时间点之后的所有文件（0表示无边界）
 * toTimeInterval = 0 & fromTimeInterval = 0时返回所有文件（0表示无边界）
 * @param fromTimeInterval 起始时间 e.g.三天前[NSDate dateWithTimeIntervalSince1970:[NSDate date].timeIntervalSince1970 - 3 *24 *60 * 60].timeIntervalSince1970
 * @param toTimeInterval 结束时间
 */
+(NSArray * _Nonnull)alogGetFilPathsFrom:(NSNumber * _Nonnull)fromTimeInterval to:(NSNumber * _Nonnull)toTimeInterval;

#pragma mark -  Method for writing logs to ALog files

/**
 * 写入纯自定义log
 * @param fileName 文件名信息
 * @param funcName 函数名信息
 * @param tag log的tag
 * @param line log的行号
 * @param level log的level
 * @param format log内容
 */
+ (void)setALogWithFileName:(NSString * _Nonnull)fileName
                   funcName:(NSString * _Nonnull)funcName
                        tag:(NSString * _Nonnull)tag
                       line:(int)line
                      level:(int)level
                     format:(NSString * _Nonnull)format;

/**
 * 写入Debug Log
 * Recommended Usage：HMDLogWrapper.debugALog("alogtest", tag: "hmd", fileName: #file, funcName: #function, line: #line)
 */
+ (void)debugALog:(NSString * _Nonnull)format
              tag:(NSString * _Nonnull)tag
         fileName:(NSString * _Nonnull)fileName
         funcName:(NSString * _Nonnull)funcName
             line:(int)line;

/**
 * 写入Info Log
 * Recommended Usage：HMDLogWrapper.infoALog("alogtest", tag: "hmd", fileName: #file, funcName: #function, line: #line)
 */
+ (void)infoALog:(NSString * _Nonnull)format
             tag:(NSString * _Nonnull)tag
        fileName:(NSString * _Nonnull)fileName
        funcName:(NSString * _Nonnull)funcName
            line:(int)line;

/**
 * 写入Warn Log
 * Recommended Usage：HMDLogWrapper.warnALog("alogtest", tag: "hmd", fileName: #file, funcName: #function, line: #line)
 */
+ (void)warnALog:(NSString * _Nonnull)format
             tag:(NSString * _Nonnull)tag
        fileName:(NSString * _Nonnull)fileName
        funcName:(NSString * _Nonnull)funcName
            line:(int)line;

/**
 * 写入Error Log
 * Recommended Usage：HMDLogWrapper.errorALog("alogtest", tag: "hmd", fileName: #file, funcName: #function, line: #line)
 */
+ (void)errorALog:(NSString * _Nonnull)format
              tag:(NSString * _Nonnull)tag
         fileName:(NSString * _Nonnull)fileName
         funcName:(NSString * _Nonnull)funcName
             line:(int)line;

/**
 * 写入Fatal Log
 * Recommended Usage：HMDLogWrapper.fatalALog("alogtest", tag: "hmd", fileName: #file, funcName: #function, line: #line)
 */
+ (void)fatalALog:(NSString * _Nonnull)format
              tag:(NSString * _Nonnull)tag
         fileName:(NSString * _Nonnull)fileName
         funcName:(NSString * _Nonnull)funcName
             line:(int)line;
@end

