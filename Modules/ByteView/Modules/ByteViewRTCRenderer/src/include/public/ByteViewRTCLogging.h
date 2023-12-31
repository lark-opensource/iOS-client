//
//  ByteViewRTCLogging.h
//  ByteViewRTCRenderer
//
//  Created by liujianlong on 2021/3/17.
//

#import <Foundation/Foundation.h>


#define ByteViewRTCLogLevel(LEVEL, format, ...)                                                    \
do {                                                                                               \
    [ByteViewRTCLogging.sharedInstance log:LEVEL                                                   \
                                  filename:@__FILE__                                               \
                                       tag:@"Render"                                               \
                                      line:__LINE__                                                \
                                  funcName:__FUNCTION__                                                \
                                   content:[NSString stringWithFormat: format, ##__VA_ARGS__]];    \
} while (0)


typedef NS_ENUM(NSInteger, ByteViewVideoRenderLogLevel) {
    ByteViewVideoRenderLogLevelInfo,
    ByteViewVideoRenderLogLevelWarn,
    ByteViewVideoRenderLogLevelError,
};

#define ByteViewRTCLog(format, ...)  ByteViewRTCLogLevel(ByteViewVideoRenderLogLevelInfo, format, ##__VA_ARGS__)
#define ByteViewRTCLogInfo(format, ...)  ByteViewRTCLogLevel(ByteViewVideoRenderLogLevelInfo, format, ##__VA_ARGS__)
#define ByteViewRTCLogError(format, ...)  ByteViewRTCLogLevel(ByteViewVideoRenderLogLevelError, format, ##__VA_ARGS__)


NS_ASSUME_NONNULL_BEGIN

typedef void (^ByteViewRTCLogCallback)(ByteViewVideoRenderLogLevel level, NSString * filename, NSString * tag, int line, NSString * funcName, NSString * format);


@interface ByteViewRTCLogging : NSObject

@property(copy, atomic) ByteViewRTCLogCallback logCallback;

+ (instancetype)sharedInstance;

- (void)log:(ByteViewVideoRenderLogLevel)level
   filename:(NSString *)filename
        tag:(NSString *)tag
       line:(int)line
   funcName:(const char *)funcName
    content:(NSString *)content;

@end

NS_ASSUME_NONNULL_END
