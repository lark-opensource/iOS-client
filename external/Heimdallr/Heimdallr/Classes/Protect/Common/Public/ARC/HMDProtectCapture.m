//
//  HMDProtectCapture.m
//  HMDProtectCapture
//
//  Created by fengyadong on 2018/4/8.
//

#import <Foundation/Foundation.h>
#import "HMDProtectCapture.h"
#import "HMDAppleBacktracesLog.h"

@interface HMDProtectCapture ()

- (instancetype _Nullable)initWithException:(NSString *)exception
                                     reason:(NSString *)reason
                                   crashKey:(NSString *)crashKey NS_DESIGNATED_INITIALIZER;

@end

@implementation HMDProtectCapture

#pragma mark - Initialization

- (instancetype _Nullable)initWithException:(NSString *)exception
                                     reason:(NSString *)reason
                                   crashKey:(NSString *)crashKey {
    if(self = [super init]) {
//        self.filterWithTopStack = NO;
        self.exception = exception;
        self.reason = reason ?: @"";
        self.crashKey = crashKey;
    }
    return self;
}

+ (instancetype _Nullable)captureException:(NSString *)exception
                                    reason:(NSString *)reason
                                  crashKey:(NSString *)crashKey {
    return [[HMDProtectCapture alloc] initWithException:exception reason:reason crashKey:crashKey];
}

+ (instancetype)captureException:(NSString *)exception
                          reason:(NSString *)reason {
    return [HMDProtectCapture captureException:exception reason:reason crashKey:nil];
}

+ (instancetype _Nullable)captureWithNSException:(__kindof NSException *)exception
                                        crashKey:(NSString *)crashKey {
    return [[HMDProtectCapture alloc] initWithException:exception.name
                                                 reason:[NSString stringWithFormat:@"[NSException] %@", exception.reason?:@""]
                                               crashKey:crashKey];;
}

+ (instancetype)captureWithNSException:(__kindof NSException *)exception {
    return [self captureWithNSException:exception crashKey:nil];
}

#pragma mark - Overload

- (void)setReason:(NSString *)reason {
    if(reason != nil) {
        reason = [reason stringByReplacingOccurrencesOfString:@"\n" withString:@" "];
    }
    _reason = reason;
}

@end
