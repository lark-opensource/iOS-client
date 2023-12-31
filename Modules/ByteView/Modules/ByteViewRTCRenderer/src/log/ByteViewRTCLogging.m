//
//  ByteViewRTCLogging.m
//  ByteViewRTCRenderer
//
//  Created by liujianlong on 2021/3/17.
//

#import "ByteViewRTCLogging.h"

@implementation ByteViewRTCLogging

+ (instancetype)sharedInstance {
    static ByteViewRTCLogging *inst;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        inst = [[self alloc] init];
    });
    return inst;
}


- (instancetype)init {
    self = [super init];
    if (self) {
        _logCallback = ^(ByteViewVideoRenderLogLevel level, NSString * filename, NSString * tag, int line, NSString * funcName, NSString * format) {
            // NOP
        };
    }
    return self;
}

- (void)log:(ByteViewVideoRenderLogLevel)level
   filename:(NSString *)filename
        tag:(NSString *)tag
       line:(int)line
   funcName:(const char *)funcName
    content:(NSString *)content {
    self.logCallback(level,
                     [filename lastPathComponent],
                     tag,
                     line,
                     [NSString stringWithCString:funcName encoding:NSUTF8StringEncoding],
                     content);
}

@end
