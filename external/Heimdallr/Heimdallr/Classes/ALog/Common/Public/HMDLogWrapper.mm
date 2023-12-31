//
//  HMDLogWrapper.mm
//  Heimdallr
//
//  Created by 柳钰柯 on 2020/6/11.
//

#import "HMDLogWrapper.h"
#import "HMDMacro.h"

CLANG_DIAGNOSTIC_PUSH
CLANG_DIAGNOSTIC_IGNORE_DOCUMENTATION
#import <BDALog/BDAgileLog.h>
CLANG_DIAGNOSTIC_POP
#import <BDAlogProtocol/BDAlogProtocol.h>

@implementation HMDLogWrapper

#pragma mark -  Method for Operating BDALog

+ (NSString *)defaultPath {
    NSString *directory = [NSSearchPathForDirectoriesInDomains(NSLibraryDirectory, NSUserDomainMask, YES) firstObject];
    NSString *path = [directory stringByAppendingPathComponent:@"alog"];
    return path;
}

+ (void)setALogEnabled {
    //初始化alog
    alog_open_default([[self defaultPath] UTF8String], "BDALog");
    
    //设置log等级
    alog_set_log_level(kLevelAll);
    
    //是否在console输出
    #ifdef DEBUG
    alog_set_console_log(true);
    #endif
}

+ (void)alogOpenDefault:(NSString *)path namePrefix:(NSString *)prefix {
    alog_open_default([path UTF8String], [prefix UTF8String]);
}

+ (void)alogOpenWithDir:(NSString *)path namePrefix:(NSString *)prefix maxSize:(NSNumber *)size outdate:(NSNumber *)date isCrypt:(BOOL)crypt  {
    alog_open([path UTF8String], [prefix UTF8String], [size longLongValue], [date doubleValue], crypt);
}

+ (void)alogSetConsoleLogOpen:(BOOL)isOpen {
    alog_set_console_log(isOpen);
}

+ (void)setAlogSetLogLevel:(AlogAdaptorLogLevel)level {
    kBDALogLevel bdLevel = kLevelAll;
    switch (level) {
        case AlogAdaptorLogAll:
            bdLevel = kLevelAll;
            break;
        case AlogAdaptorLogDebug:
            bdLevel = kLevelDebug;
            break;
        case AlogAdaptorLogInfo:
            bdLevel = kLevelInfo;
            break;
        case AlogAdaptorLogWarn:
            bdLevel = kLevelWarn;
            break;
        case AlogAdaptorLogError:
            bdLevel = kLevelError;
            break;
        case AlogAdaptorLogFatal:
            bdLevel = kLevelFatal;
            break;
        case AlogAdaptorLogNone:
            bdLevel = kLevelNone;
            break;
    }
    alog_set_log_level(bdLevel);
}

+ (void)alogFlush {
    alog_flush();
}

+ (void)alogFlushSync {
    alog_flush_sync();
}

+ (void)alogClose {
    alog_close();
}

+ (void)alogRemoveFileAt:(NSString *)path {
    alog_remove_file([path UTF8String]);
}

+ (void)alogSetTagBlocklist:(NSArray *)list {
    BDALOG_SET_TAG_BLOCKLIST(list)
}

+ (NSArray *)alogGetFilPathsFrom:(NSNumber *)fromTimeInterval to:(NSNumber *)toTimeInterval {
    std::vector<std::string> paths;
    alog_getFilePaths([fromTimeInterval longLongValue], [toTimeInterval longLongValue], paths);
    NSMutableArray *filePaths = [NSMutableArray array];
    for (auto cPath : paths) {
        NSString *filePath = [NSString stringWithCString:cPath.c_str()
                                            encoding:[NSString defaultCStringEncoding]];
        if (filePath) {
            [filePaths addObject:filePath];
        }
    }
    return filePaths;
}

#pragma mark -  Method for writing logs to ALog files

+ (void)setALogWithFileName:(NSString *)fileName
                   funcName:(NSString *)funcName
                        tag:(NSString *)tag
                       line:(int)line
                      level:(int)level
                     format:(NSString *)format {
    [BDALogProtocol setALogWithFileName:fileName funcName:funcName tag:tag?:@"unknown" line:line level:level format:format];
}
+ (void)debugALog:(NSString *)format
              tag:(NSString *)tag
         fileName:(NSString *)fileName
         funcName:(NSString *)funcName
             line:(int)line {
    [BDALogProtocol setALogWithFileName:fileName funcName:funcName tag:tag?:@"unknown" line:line level:kLevelDebug format:format];
}

+ (void)infoALog:(NSString *)format
             tag:(NSString *)tag
        fileName:(NSString *)fileName
        funcName:(NSString *)funcName
            line:(int)line {
    [BDALogProtocol setALogWithFileName:fileName funcName:funcName tag:tag?:@"unknown" line:line level:kLevelInfo format:format];
}

+ (void)warnALog:(NSString *)format
             tag:(NSString *)tag
        fileName:(NSString *)fileName
        funcName:(NSString *)funcName
            line:(int)line {
    [BDALogProtocol setALogWithFileName:fileName funcName:funcName tag:tag?:@"unknown" line:line level:kLevelWarn format:format];
}

+ (void)errorALog:(NSString *)format
              tag:(NSString *)tag
         fileName:(NSString *)fileName
         funcName:(NSString *)funcName
             line:(int)line {
    [BDALogProtocol setALogWithFileName:fileName funcName:funcName tag:tag?:@"unknown" line:line level:kLevelError format:format];
}

+ (void)fatalALog:(NSString *)format
              tag:(NSString *)tag
         fileName:(NSString *)fileName
         funcName:(NSString *)funcName
             line:(int)line {
    [BDALogProtocol setALogWithFileName:fileName funcName:funcName tag:tag?:@"unknown" line:line level:kLevelFatal format:format];
}
@end
