//
//  AWEStickerPickerLogger.m
//  CameraClient
//
//  Created by Chipengliu on 2020/10/19.
//

#import "AWEStickerPickerLogger.h"

@implementation AWEStickerPickerLogger

static AWEStickerPickerLogger *_defaultLogger = nil;
+ (instancetype)sharedInstance {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _defaultLogger = [[AWEStickerPickerLogger alloc] init];
    });
    return _defaultLogger;
}

- (void)logLevel:(AWEStickerPickerLogLevel)level format:(NSString *)format, ... {
    va_list args;
    if (format == nil) {
        return;
    }
    
    va_start(args, format);

    NSString *logMessage = [[NSString alloc] initWithFormat:format arguments:args];

    va_end(args);
    
    if ([self.delegate respondsToSelector:@selector(stickerPickerLogger:logMessage:level:)]) {
        [self.delegate stickerPickerLogger:self logMessage:logMessage level:level];
    }
}

@end
