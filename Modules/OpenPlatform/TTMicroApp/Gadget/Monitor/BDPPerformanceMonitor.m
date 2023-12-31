//
//  BDPPerformanceMonitor.m
//  Timor
//
//  Created by muhuai on 2018/3/11.
//

#import "BDPPerformanceMonitor.h"

static NSString * const timing_prefix = @"timing_";

@interface BDPPerformanceMonitor ()

@property (nonatomic, strong) NSMutableDictionary *timingDictionary;
@property (nonatomic, strong) NSMutableDictionary *performanceDictionary;

@end

@implementation BDPPerformanceMonitor

- (instancetype)init {
    if (self = [super init]) {
        _timingDictionary = [NSMutableDictionary dictionary];
        _performanceDictionary = [NSMutableDictionary dictionary];
    }
    return self;
}

- (void)setPerformance:(NSString *)name value:(NSObject *)value {
    if (!name) {
        return;
    }
    if (!value) {
        [self.performanceDictionary removeObjectForKey:name];
        return;
    }
    self.performanceDictionary[name] = value;
}

- (NSDictionary *)performanceData {
    return [self.performanceDictionary copy];
}

#pragma mark - BDPTiming
- (void)timing:(NSString *)name {
    [self timing:name value:NSDate.date.timeIntervalSince1970];
}

- (void)timing:(NSString *)name value:(NSTimeInterval)time {
    if (!name) {
        return;
    }
    self.timingDictionary[name] = @((long)(time*1000)); //采用毫秒时间戳
}

- (NSDictionary *)timingData {
    return [self.timingDictionary copy];
}

#pragma mark - methodSignatureForSelector
- (void)timingNameValue:(NSTimeInterval)time {}

- (NSMethodSignature *)methodSignatureForSelector:(SEL)aSelector {
    NSMethodSignature *sig = [super methodSignatureForSelector:aSelector];
    if(sig) return sig;
    return [self methodSignatureForSelector:@selector(timingNameValue:)];
}

// 统一处理timing接口
- (void)forwardInvocation:(NSInvocation *)anInvocation {
    NSString *selStr = NSStringFromSelector(anInvocation.selector);
    if ([selStr hasPrefix:timing_prefix]) {
        if (![selStr hasSuffix:@":"]) {
            NSString *functionName = [selStr substringFromIndex:timing_prefix.length];
            [self timing:functionName];
        }else {
            NSString *functionName = [selStr substringWithRange:NSMakeRange(timing_prefix.length, selStr.length-timing_prefix.length-1)];
            NSTimeInterval time = 0;
            [anInvocation getArgument:&time atIndex:2];
            [self timing:functionName value:time];
        }
    }
}

@end
