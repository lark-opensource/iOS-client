//
//  PNSLoggerProtocol.h
//  PNSServiceKit
//
//  Created by chirenhua on 2022/6/15.
//

#import <Foundation/Foundation.h>
#import "PNSServiceCenter.h"

#ifndef PNSLoggerProtocol_h
#define PNSLoggerProtocol_h

typedef NS_ENUM(NSUInteger, PNSLogLevel) {
    PNSLogLevelAll = 0,
    PNSLogLevelDebug = 1,
    PNSLogLevelInfo = 2,
    PNSLogLevelWarn = 3,
    PNSLogLevelError = 4,
    PNSLogLevelFatal = 5,
    PNSLogLevelNone = 100
};

#define PNSLog(_level, _tag, _format, ...) \
[PNS_GET_CLASS(PNSLoggerProtocol) setLogWithFileName:[NSString stringWithUTF8String:__FILE_NAME__] \
                                            funcName:[NSString stringWithUTF8String:__FUNCTION__] \
                                                 tag:_tag \
                                                line:__LINE__ \
                                               level:_level \
                                              format:[NSString stringWithFormat:_format, ##__VA_ARGS__, nil]]; \

#define PNSLogE(tag, frmt, ...) PNSLog(PNSLogLevelError, tag, frmt, ##__VA_ARGS__)
#define PNSLogW(tag, frmt, ...) PNSLog(PNSLogLevelWarn, tag, frmt, ##__VA_ARGS__)
#define PNSLogI(tag, frmt, ...) PNSLog(PNSLogLevelInfo, tag, frmt, ##__VA_ARGS__)
#define PNSLogD(tag, frmt, ...) PNSLog(PNSLogLevelDebug, tag, frmt, ##__VA_ARGS__)
#define PNSLogF(tag, frmt, ...) PNSLog(PNSLogLevelFatal, tag, frmt, ##__VA_ARGS__)

@protocol PNSLoggerProtocol <NSObject>

+ (void)setLogWithFileName:(NSString * _Nonnull)fileName
                  funcName:(NSString * _Nonnull)funcName
                       tag:(NSString * _Nonnull)tag
                      line:(int)line
                     level:(PNSLogLevel)level
                    format:(NSString * _Nullable)format;

@end

#endif /* PNSLoggerProtocol_h */
