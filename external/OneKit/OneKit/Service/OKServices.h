//
//  OKServices.h
//  OneKit
//
//  Created by bob on 2021/1/13.
//

#import <OneKit/OKService.h>
#import <OneKit/OKServiceCenter.h>

NS_ASSUME_NONNULL_BEGIN

@protocol OKDeviceService <OKService>

- (nullable NSString *)deviceID;
- (nullable NSString *)installID;
- (nullable NSString *)ssID;

@end

@protocol OKAnalyticsService <OKService>

- (void)eventV3:(NSString *)event params:(nullable NSDictionary *)param;
- (nullable NSString *)sessionID;

@end

@protocol OKIDFAService <OKService>

- (nullable NSString *)IDFA;

@end

@protocol OKLogService <OKService>

- (void)verbose:(NSString *)log;
- (void)debug:(NSString *)log;
- (void)info:(NSString *)log;
- (void)warn:(NSString *)log;
- (void)error:(NSString *)log;

@end


@protocol OKCellularService <OKService>

- (NSInteger)cellularConnectionTypeForService:(NSInteger)service;
- (id)carrierForService:(NSInteger)service;
- (NSInteger)currentDataServiceType;/// 返回当前流量卡类型

@end


#ifdef __FILE_NAME__
#define __OKALOG_FILE_NAME__ __FILE_NAME__
#else
#define __OKALOG_FILE_NAME__ __FILE__
#endif

#define NSSTRING_LOG(tag, format, ...) ( [NSString stringWithFormat:@"[%@][%@:%d] %@", tag, [[NSString stringWithUTF8String:__OKALOG_FILE_NAME__] lastPathComponent], __LINE__, [NSString stringWithFormat:format, ##__VA_ARGS__, nil]])


#define OKLOG_PROTOCOL_VERBOSE_TAG(tag, format, ...)\
@autoreleasepool {do{[OK_CENTER_OBJECT(OKLogService) verbose:NSSTRING_LOG(tag, format, ##__VA_ARGS__)];\
}while(0);};

#define OKLOG_PROTOCOL_DEBUG_TAG(tag, format, ...)\
@autoreleasepool {do{[OK_CENTER_OBJECT(OKLogService) debug:NSSTRING_LOG(tag, format, ##__VA_ARGS__)];\
}while(0);};

#define OKLOG_PROTOCOL_INFO_TAG(tag, format, ...)\
@autoreleasepool {do{[OK_CENTER_OBJECT(OKLogService) info:NSSTRING_LOG(tag, format, ##__VA_ARGS__)];\
}while(0);};

#define OKLOG_PROTOCOL_WARN_TAG(tag, format, ...)\
@autoreleasepool {do{[OK_CENTER_OBJECT(OKLogService) warn:NSSTRING_LOG(tag, format, ##__VA_ARGS__)];\
}while(0);};

#define OKLOG_PROTOCOL_ERROR_TAG(tag, format, ...)\
@autoreleasepool {do{[OK_CENTER_OBJECT(OKLogService) error:NSSTRING_LOG(tag, format, ##__VA_ARGS__)];\
}while(0);};



NS_ASSUME_NONNULL_END
