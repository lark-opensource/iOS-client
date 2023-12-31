//
//  OKReachability.m
//  OneKit
//
//  Created by bob on 2020/4/27.
//

#import "OKReachability.h"
#import <CoreFoundation/CoreFoundation.h>
#import <SystemConfiguration/SystemConfiguration.h>
#import <UIKit/UIKit.h>

#ifndef OK_WeakSelf
#define OK_WeakSelf __weak typeof(self) wself = self
#endif

#ifndef OK_StrongSelf
#define OK_StrongSelf __strong typeof(wself) self = wself
#endif

NSString *OKNotificationReachabilityChanged = @"OKNotificationReachabilityChanged";

@interface OKReachability ()

@property (nonatomic, assign) SCNetworkReachabilityRef  reachabilityRef;
@property (nonatomic, strong) dispatch_queue_t reachabilityQueue;
@property (nonatomic, strong) dispatch_queue_t callbackQueue;
@property (nonatomic, assign) BOOL callbackScheduled;
@property (nonatomic, assign) OKReachabilityStatus cachedStatus;
@property (nonatomic, assign) BOOL hasCachedStatus;
@property (nonatomic, assign) BOOL telephoneInfoIndeterminateStatus;

@end

static OKReachabilityStatus networkStatusForFlags(SCNetworkReachabilityFlags flags) {
    if ((flags & kSCNetworkReachabilityFlagsReachable) == 0){
        return OKReachabilityStatusNotReachable;
    }

    OKReachabilityStatus returnValue = OKReachabilityStatusNotReachable;
    if ((flags & kSCNetworkReachabilityFlagsConnectionRequired) == 0) {
        returnValue = OKReachabilityStatusReachableViaWiFi;
    }

    if ((((flags & kSCNetworkReachabilityFlagsConnectionOnDemand ) != 0)
         || (flags & kSCNetworkReachabilityFlagsConnectionOnTraffic) != 0)) {

        if ((flags & kSCNetworkReachabilityFlagsInterventionRequired) == 0) {
            returnValue = OKReachabilityStatusReachableViaWiFi;
        }
    }

    if ((flags & kSCNetworkReachabilityFlagsIsWWAN) == kSCNetworkReachabilityFlagsIsWWAN) {
        returnValue = OKReachabilityStatusReachableViaWWAN;
    }

    return returnValue;
}

static void ReachabilityCallback(SCNetworkReachabilityRef target, SCNetworkReachabilityFlags flags, void* info) {
    OKReachability *reachability = [OKReachability sharedInstance];
    OKReachabilityStatus status = networkStatusForFlags(flags);
    if (reachability.cachedStatus != status) {
        reachability.cachedStatus = status;
        reachability.hasCachedStatus = YES;
        [[NSNotificationCenter defaultCenter] postNotificationName:OKNotificationReachabilityChanged
                                                            object:nil];
    }
}

static void onNotifyCallback(CFNotificationCenterRef center, void *observer, CFStringRef name, const void *object, CFDictionaryRef userInfo) {
    if (CFStringCompare(name, CFSTR("com.apple.system.config.network_change"), 0) == kCFCompareEqualTo) {
        ///  当WiFi状态发生变化时候，认为此时处于不稳定状态，蜂窝权限检测依赖了WiFi的IP地址做快速检测
        ///  因为无法获取系统开关具体是什么），需要临时禁用
        /// 等待1秒后标记取消，这段时间内永远返回notDetermined，之后才能正常判定，如果有更好方法请联系我
        [OKReachability sharedInstance].telephoneInfoIndeterminateStatus = YES;
        // 注：目前测试，这个Darwin的通知在mainQueue触发，线程安全，以后如果有变化再说
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [OKReachability sharedInstance].telephoneInfoIndeterminateStatus = NO;
        });
    }
}

@implementation OKReachability

+ (instancetype)sharedInstance  {
    static OKReachability * sharedInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        struct sockaddr zeroAddress;
        bzero(&zeroAddress, sizeof(zeroAddress));
        zeroAddress.sa_len = sizeof(zeroAddress);
        zeroAddress.sa_family = AF_INET;

        SCNetworkReachabilityRef reachability = SCNetworkReachabilityCreateWithAddress(kCFAllocatorDefault,
                                                                                       &zeroAddress);
        sharedInstance = [[self alloc] initWithReachabilityRef:reachability];
        if (reachability != NULL) {
            CFRelease(reachability);
        }
    });

    return sharedInstance;
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [self stopNotifier];
    SCNetworkReachabilityRef reachabilityRef = self.reachabilityRef;
    if (reachabilityRef != NULL) {
        CFRelease(reachabilityRef);
        self.reachabilityRef = NULL;
    }
}

- (instancetype)initWithReachabilityRef:(SCNetworkReachabilityRef)reachabilityRef {
    self = [super init];
    if (self) {
        if (reachabilityRef != NULL) {
            self.reachabilityRef = CFRetain(reachabilityRef);
        } else {
            self.reachabilityRef = NULL;
        }
        self.cachedStatus = OKReachabilityStatusNotReachable;
        self.hasCachedStatus = NO;
        self.reachabilityQueue = dispatch_queue_create("com.ok.reachability", DISPATCH_QUEUE_SERIAL);
        self.callbackQueue = dispatch_queue_create("com.ok.callback", DISPATCH_QUEUE_SERIAL);
        self.callbackScheduled = NO;
        self.telephoneInfoIndeterminateStatus = NO;
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(onDidEnterBackground) name:UIApplicationDidEnterBackgroundNotification
                                                   object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(onWillEnterForeground) name:UIApplicationWillEnterForegroundNotification
                                                   object:nil];
        // 监听WiFi硬件开关变化的Darwin通知，这个按照Apple的论坛说法是Public API
        CFNotificationCenterAddObserver(CFNotificationCenterGetDarwinNotifyCenter(), //center
                                        NULL, // observer
                                        onNotifyCallback, // callback
                                        CFSTR("com.apple.system.config.network_change"), // event name
                                        NULL, // object
                                        CFNotificationSuspensionBehaviorDeliverImmediately);
    }

    return self;
}

#pragma mark - Start and stop notifier

- (void)startNotifier {
    OK_WeakSelf;
    dispatch_async(self.reachabilityQueue, ^{
        OK_StrongSelf;
        if (self.callbackScheduled) {
            return;
        }
        SCNetworkReachabilityRef reachabilityRef = self.reachabilityRef;
        if (reachabilityRef == NULL) {
            return;
        };
        [self readReachabilityStatus];
        /// 耗时方法
        if (SCNetworkReachabilitySetCallback(reachabilityRef, ReachabilityCallback, NULL)) {
            if(SCNetworkReachabilitySetDispatchQueue(reachabilityRef, self.callbackQueue)) {
                self.callbackScheduled = YES;
            } else {
                SCNetworkReachabilitySetCallback(reachabilityRef, NULL,NULL);
            }
        }
    });
}

- (void)stopNotifier {
    SCNetworkReachabilityRef reachabilityRef = self.reachabilityRef;
    if (reachabilityRef == NULL) {
        return;
    }
    dispatch_sync(self.reachabilityQueue, ^{
        if (self.callbackScheduled) {
            SCNetworkReachabilitySetCallback(reachabilityRef, NULL, NULL);
            SCNetworkReachabilitySetDispatchQueue(reachabilityRef, NULL);
            self.callbackScheduled = NO;
        }
    });
    self.hasCachedStatus = NO;
}

- (void)onDidEnterBackground {
    [self stopNotifier];
    
}

- (void)onWillEnterForeground {
    [self startNotifier];
}

- (void)readReachabilityStatus {
    if (self.cachedStatus != OKReachabilityStatusNotReachable) {
        return;
    }
    
    SCNetworkReachabilityFlags flags;
    /// 弱网情况下很耗时
    if (SCNetworkReachabilityGetFlags(self.reachabilityRef, &flags)) {
        self.cachedStatus = networkStatusForFlags(flags);
        self.hasCachedStatus = YES;
    }
}

- (BOOL)shouldUpdateCachedStatus {
    return !self.hasCachedStatus || self.cachedStatus == OKReachabilityStatusNotReachable;
}

/// only fist time
/// 后面都依赖callback回调更新
- (OKReachabilityStatus)currentReachabilityStatus {
    if (![self shouldUpdateCachedStatus]) {
        return self.cachedStatus;
    }
    
    [self readReachabilityStatus];
    
    return self.cachedStatus;
}

@end
