//
//  HMDOTBridge.m
//  Heimdallr
//
//  Created by fengyadong on 2020/11/25.
//

#import "HMDOTBridge.h"
#import "HMDOTTrace.h"
#import "NSDictionary+HMDSafe.h"
#import "HMDOTManager.h"
#import "HMDOTSpan.h"
#import "HMDMacro.h"


#import "HMDOTManager2.h"

@interface HMDOTBridge()

@property (atomic, assign) BOOL enableBinding;
@property (nonatomic, strong) NSMutableDictionary *cachedTraces;
@property (nonatomic, strong) dispatch_queue_t callbackQeueue;

@end

@implementation HMDOTBridge

- (instancetype)init {
    if (self = [super init]) {
        _cachedTraces = [NSMutableDictionary dictionary];
        _callbackQeueue = dispatch_queue_create("heimdallr.opentracingbridge.callback", DISPATCH_QUEUE_CONCURRENT);
    }
    
    return self;
}

+ (instancetype)sharedInstance {
    static HMDOTBridge *shared;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        shared = [[self alloc] init];
    });
    return shared;
}

- (void)enableTraceBinding:(BOOL)enabled {
    self.enableBinding = enabled;
}

- (void)registerTrace:(HMDOTTrace *)trace forTraceID:(NSString *)traceID {
    if(!trace || HMDIsEmptyString(traceID) || !self.enableBinding) return;
    dispatch_barrier_async(self.callbackQeueue, ^{
        [self.cachedTraces hmd_setObject:trace forKey:trace.traceID];
    });
}

- (void)removeTraceID:(NSString *)traceID {
    if(HMDIsEmptyString(traceID) || !self.enableBinding) return;
    dispatch_barrier_async(self.callbackQeueue, ^{
        [self.cachedTraces removeObjectForKey:traceID];
    });
}

- (HMDOTTrace *)traceByTraceID:(NSString *)traceID; {
    if (HMDIsEmptyString(traceID)) return nil;
    __block HMDOTTrace *trace;
    dispatch_sync(self.callbackQeueue, ^{
        trace = [self.cachedTraces hmd_objectForKey:traceID class:[HMDOTTrace class]];
    });
    
    return trace;
}

@end
