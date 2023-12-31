//
//  IESEffectLogger.m
//  EffectPlatformSDK
//
//  Created by zhangchengtao on 2020/3/16.
//

#import "IESEffectLogger.h"

@implementation IESEffectLogger

+ (instancetype)logger {
    static IESEffectLogger *logger = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        logger = [[self alloc] init];
    });
    return logger;
}

- (void)logType:(IESEffectPlatformLogType)type withMessage:(NSString *)format, ... {
    va_list args;
    va_start(args, format);
    NSString *logMessage = [[NSString alloc] initWithFormat:format arguments:args];
    va_end(args);
    logMessage = [NSString stringWithFormat:@"[IESEffectManager Log]: %@", logMessage];
    if ([self.loggerProxy respondsToSelector:@selector(log:type:)]) {
        [self.loggerProxy log:logMessage type:type];
    }
}

- (void)logEvent:(NSString *)event params:(nullable NSDictionary *)params {
    if (self.loggerProxy && [self.loggerProxy respondsToSelector:@selector(logEvent:params:)]) {
        [self.loggerProxy logEvent:event params:params];
    }
}

- (void)trackService:(NSString *)serviceName status:(NSInteger)status extra:(NSDictionary *)extraValue {
    if (!serviceName) {
        return;
    }
    
    if (self.loggerProxy && [self.loggerProxy respondsToSelector:@selector(trackService:status:extra:)]) {
        [self.loggerProxy trackService:serviceName status:status extra:extraValue];
    }
}

@end
