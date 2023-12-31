//
//  TTVideoNetUtils.m
//  FLEX
//
//  Created by 江月 on 2019/4/2.
//

#import <SystemConfiguration/SystemConfiguration.h>
#import <CoreTelephony/CTTelephonyNetworkInfo.h>
#import <UIKit/UIKit.h>
#import <netinet/in.h>
#import "TTVideoEngineUtil.h"
#import "TTVideoNetUtils.h"
#import "TTVideoEngineUtilPrivate.h"
#import "TTVideoEngineEnvConfig.h"

NSString *kTTVideoEngineNetWorkReachabilityChangedNotification = @"kTTVideoEngineNetWorkReachabilityChangedNotification";
NSString *TTVideoEngineNetWorkReachabilityNotificationState = @"TTVideoEngineNetWorkReachabilityNotificationState";

static TTVideoEngineNetWorkStatus TTVideoEngineNetWorkStatusForFlags(SCNetworkReachabilityFlags flags) {
    BOOL isReachable = ((flags & kSCNetworkReachabilityFlagsReachable) != 0);
    BOOL needsConnection = ((flags & kSCNetworkReachabilityFlagsConnectionRequired) != 0);
    BOOL canConnectionAutomatically = (((flags & kSCNetworkReachabilityFlagsConnectionOnDemand ) != 0) || ((flags & kSCNetworkReachabilityFlagsConnectionOnTraffic) != 0));
    BOOL canConnectWithoutUserInteraction = (canConnectionAutomatically && (flags & kSCNetworkReachabilityFlagsInterventionRequired) == 0);
    BOOL isNetworkReachable = (isReachable && (!needsConnection || canConnectWithoutUserInteraction));
    
    TTVideoEngineNetWorkStatus status = TTVideoEngineNetWorkStatusUnknown;
    if (isNetworkReachable == NO) {
        status = TTVideoEngineNetWorkStatusNotReachable;
    }
#if  TARGET_OS_IPHONE
    else if ((flags & kSCNetworkReachabilityFlagsIsWWAN) != 0) {
        status = TTVideoEngineNetWorkStatusWWAN;
    }
#endif
    else {
        status = TTVideoEngineNetWorkStatusWiFi;
    }
    
    return status;
}

@interface TTVideoEngineNetWorkReachability () {
    dispatch_queue_t _networkQueue;
}

@property (nonatomic, assign) TTVideoEngineNetWorkStatus currentState;
@property (nonatomic, assign) TTVideoEngineNetWorkWWANStatus currentWWANState;
@property (nonatomic, assign) BOOL scheduleing;
@property (nonatomic, assign) SCNetworkReachabilityRef reachabilityRef;

@end

@implementation TTVideoEngineNetWorkReachability

- (instancetype)init {
    if (self = [super init]) {
        _scheduleing = NO;
        _currentState = TTVideoEngineNetWorkStatusUnknown;
        _currentWWANState = TTVideoEngineNetWorkWWANStatusUnknown;
        _networkQueue = dispatch_queue_create("vclould.engine.reachability.queue", DISPATCH_QUEUE_SERIAL);
        _reachabilityRef = NULL;
    }
    return self;
}

- (void)dealloc {
    [self stopNotifier];
    
    if (_reachabilityRef != NULL) {
        CFRelease(_reachabilityRef);
        _reachabilityRef = NULL;
    }
}

- (void)setReachabilityRef:(SCNetworkReachabilityRef)reachabilityRef {
    if (_reachabilityRef) {
        CFRelease(_reachabilityRef);
    }
    _reachabilityRef = CFRetain(reachabilityRef);
}

+ (instancetype)shareInstance {
    static dispatch_once_t onceToken;
    static TTVideoEngineNetWorkReachability *s_instance = nil;
    dispatch_once(&onceToken, ^{
        s_instance = [[[self class] alloc] init];
    });
    return s_instance;
}

- (void)startNotifier {
    @weakify(self)
    dispatch_async(_networkQueue, ^{
        @strongify(self)
        if (!self) {
            return;
        }
        
        if (self.scheduleing) {
            return;
        }
        
        if (self.reachabilityRef == NULL) {
            NSString *testHost = TTVideoEngineEnvConfig.testReachabilityHost;
            if (!testHost || testHost.length < 1) {
                TTVideoEngineLog(@"test reachability host is null");
                return;
            }
            SCNetworkReachabilityRef reachability = SCNetworkReachabilityCreateWithName(NULL, [testHost UTF8String]);//!OCLINT
            if (reachability != NULL) {
                self.reachabilityRef = reachability;
                CFRelease(reachability);
            }
        }
        ///
        SCNetworkReachabilityContext context = {0, (__bridge void *)(self), NULL, NULL, NULL};
        if (SCNetworkReachabilitySetCallback(self.reachabilityRef, TTVideoEngineReachabilityCallback, &context)) {
            if (SCNetworkReachabilityScheduleWithRunLoop(self.reachabilityRef, CFRunLoopGetMain(), kCFRunLoopDefaultMode)) {
                self.scheduleing = YES;
            }
        }
        //
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0),^{
            SCNetworkReachabilityFlags flags;
            if (SCNetworkReachabilityGetFlags(self.reachabilityRef, &flags)) {
                if (self) {
                    TTVideoEngineNetWorkStatus state = TTVideoEngineNetWorkStatusForFlags(flags);
                    if (TTVideoEngineNetWorkStatusWWAN == state) {
                        [self updateWWANState:state];
                    }
                    self.currentState = state;
                }
            }
        });
    });
}

- (void)stopNotifier {
    @weakify(self)
    dispatch_async(_networkQueue, ^{
        @strongify(self)
        if (!self) {
            return;
        }
        if (self.scheduleing == NO) {
            return;
        }
        //
        if (self.reachabilityRef != NULL) {
            if (SCNetworkReachabilityUnscheduleFromRunLoop(self.reachabilityRef, CFRunLoopGetMain(), kCFRunLoopDefaultMode)) {
                self.scheduleing = NO;
            }
        }
    });
}

- (TTVideoEngineNetWorkStatus)currentReachabilityStatus {
    return _currentState;
}

- (TTVideoEngineNetWorkWWANStatus)getMobileNetType {
    CTTelephonyNetworkInfo *info = [[CTTelephonyNetworkInfo alloc] init];
    NSString *currentStatus = nil;
    TTVideoEngineNetWorkWWANStatus state = TTVideoEngineNetWorkWWANStatusUnknown;
    if (@available(iOS 12.0, *)) {
        if ([info respondsToSelector:@selector(serviceCurrentRadioAccessTechnology)]) {
            NSDictionary *radioDic = [info serviceCurrentRadioAccessTechnology];
            if (radioDic.allKeys.count) {
                currentStatus = [radioDic objectForKey:radioDic.allKeys[0]];
            }
        }
    } else {
        currentStatus = info.currentRadioAccessTechnology;
    }
    
    if ([currentStatus isEqualToString:CTRadioAccessTechnologyGPRS]) {
        state = TTVideoEngineNetWorkWWANStatus2G;
    } else if ([currentStatus isEqualToString:CTRadioAccessTechnologyEdge]) {
        state = TTVideoEngineNetWorkWWANStatus2G;
    } else if ([currentStatus isEqualToString:CTRadioAccessTechnologyWCDMA]) {
        state = TTVideoEngineNetWorkWWANStatus3G;
    } else if ([currentStatus isEqualToString:CTRadioAccessTechnologyHSDPA]) {
        state = TTVideoEngineNetWorkWWANStatus3G;
    } else if ([currentStatus isEqualToString:CTRadioAccessTechnologyHSUPA]) {
        state = TTVideoEngineNetWorkWWANStatus3G;
    } else if ([currentStatus isEqualToString:CTRadioAccessTechnologyCDMA1x]) {
        state = TTVideoEngineNetWorkWWANStatus2G;
    } else if ([currentStatus isEqualToString:CTRadioAccessTechnologyCDMAEVDORev0]) {
        state = TTVideoEngineNetWorkWWANStatus3G;
    } else if ([currentStatus isEqualToString:CTRadioAccessTechnologyCDMAEVDORevA]) {
        state = TTVideoEngineNetWorkWWANStatus3G;
    } else if ([currentStatus isEqualToString:CTRadioAccessTechnologyCDMAEVDORevB]) {
        state = TTVideoEngineNetWorkWWANStatus3G;
    } else if ([currentStatus isEqualToString:CTRadioAccessTechnologyeHRPD]) {
        state = TTVideoEngineNetWorkWWANStatus3G;
    } else if ([currentStatus isEqualToString:CTRadioAccessTechnologyLTE]) {
        state = TTVideoEngineNetWorkWWANStatus4G;
    } else if (@available(iOS 14.1, *)) {
        if ([currentStatus isEqualToString:CTRadioAccessTechnologyNRNSA]) {
            state = TTVideoEngineNetWorkWWANStatus5G;
        } else if ([currentStatus isEqualToString:CTRadioAccessTechnologyNR]) {
            state = TTVideoEngineNetWorkWWANStatus5G;
        }
    }
    
    return state;
}

- (void)updateWWANState:(TTVideoEngineNetWorkStatus)state {
    if (state == _currentState) {
        return;
    }
    
    if (_currentWWANState != TTVideoEngineNetWorkWWANStatusUnknown) {
        return;
    }
    
    @weakify(self)
    dispatch_async(_networkQueue, ^{
        @strongify(self)
        if (!self) {
            return;
        }
        self.currentWWANState = [self getMobileNetType];
    });
}

static void TTVideoEngineReachabilityCallback(SCNetworkReachabilityRef target, SCNetworkReachabilityFlags flags, void* info) {
    TTVideoEngineNetWorkReachability *networkObject = (__bridge TTVideoEngineNetWorkReachability *)info;
    if (networkObject == NULL) {
        return;
    }
    
    TTVideoEngineNetWorkStatus state = TTVideoEngineNetWorkStatusForFlags(flags);
    if (TTVideoEngineNetWorkStatusWWAN == state) {
        [networkObject updateWWANState:state];
    }
    networkObject.currentState = state;
    NSDictionary *userInfo = @{ TTVideoEngineNetWorkReachabilityNotificationState: @(state) };
    [[NSNotificationCenter defaultCenter] postNotificationName:kTTVideoEngineNetWorkReachabilityChangedNotification
                                                        object:nil
                                                      userInfo:userInfo];
}

@end
