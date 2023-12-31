//
//  DVELoggerProtocol.h
//  NLEEditor
//
//  Created by bytedance on 2021/5/24.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSInteger, DVELogType) {
    DVELogTypeDebug = 0,
    DVELogTypeInfo  = 1,
    DVELogTypeWarn  = 2,
    DVELogTypeError = 3,
    DVELogTypeReport = 4,
};

@protocol DVELoggerProtocol <NSObject>

@optional

/// 打印日志
/// @param type 日志类型
/// @param tag 日志标签
/// @param file 文件
/// @param function 函数
/// @param line 行数
/// @param message 日志内容
- (void)logType:(DVELogType)type
            tag:(NSString *)tag
           file:(const char *)file
       function:(const char *)function
           line:(int)line
        message:(NSString *)message,...;

/// 埋点上报
/// @param serviceName 埋点名称
/// @param params 埋点上报数据字典
- (void)logEvent:(NSString *)serviceName
          params:(NSDictionary *)params;

@end

NS_ASSUME_NONNULL_END
