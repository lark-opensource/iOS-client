//
//  HMDDebugLogger.m
//  Pods
//
//  Created by Nickyo on 2023/7/6.
//

#import "HMDDebugLogger.h"
#if RANGERSAPM
#import "RangersAPMDebugLogger.h"
#endif

@implementation HMDDebugLogger

+ (void)enableDebugLogUsingLogger:(HMDDebugLoggerBlock)logger {
    [[self service] enableDebugLogUsingLogger:logger];
}

+ (void)printLog:(NSString *)log {
    [[self service] printLog:log];
}

+ (void)printError:(NSString *)error {
    [[self service] printError:error];
}

+ (Class<HMDDebugLoggerProtocol>)service {
#if RANGERSAPM
    return [RangersAPMDebugLogger class];
#else
    return nil;
#endif
}

@end
