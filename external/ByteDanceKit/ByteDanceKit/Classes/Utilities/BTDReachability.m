// AFNetworkReachabilityManager.m
// Copyright (c) 2011–2015 Alamofire Software Foundation (http://alamofire.org/)
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in
// all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
// THE SOFTWARE.

#import "BTDReachability.h"

#import <netinet/in.h>
#import <netinet6/in6.h>
#import <arpa/inet.h>
#import <ifaddrs.h>
#import <netdb.h>

NSString * const BTDNetworkingReachabilityDidChangeNotification = @"com.btyedancekit.networking.reachability.change";
NSString * const BTDNetworkingReachabilityNotificationStatusItem = @"BTDNetworkingReachabilityNotificationStatusItem";

typedef void (^BTDNetworkReachabilityStatusBlock)(BTDNetworkReachabilityStatus status);

typedef NS_ENUM(NSUInteger, BTDNetworkReachabilityAssociation) {
    BTDNetworkReachabilityForAddress = 1,
    BTDNetworkReachabilityForAddressPair = 2,
    BTDNetworkReachabilityForName = 3,
};

NSString * BTDStringFromNetworkReachabilityStatus(BTDNetworkReachabilityStatus status) {
    switch (status) {
        case BTDNetworkReachabilityStatusNotReachable:
            return @"Not Reachable";
        case BTDNetworkReachabilityStatusReachableViaWWAN:
            return @"Reachable via WWAN";
        case BTDNetworkReachabilityStatusReachableViaWiFi:
            return @"Reachable via WiFi";
        case BTDNetworkReachabilityStatusUnknown:
        default:
            return @"Unknown";
    }
}

static BTDNetworkReachabilityStatus BTDNetworkReachabilityStatusForFlags(SCNetworkReachabilityFlags flags) {
    BOOL isReachable = ((flags & kSCNetworkReachabilityFlagsReachable) != 0);
    BOOL needsConnection = ((flags & kSCNetworkReachabilityFlagsConnectionRequired) != 0);
    BOOL canConnectionAutomatically = (((flags & kSCNetworkReachabilityFlagsConnectionOnDemand ) != 0) || ((flags & kSCNetworkReachabilityFlagsConnectionOnTraffic) != 0));
    BOOL canConnectWithoutUserInteraction = (canConnectionAutomatically && (flags & kSCNetworkReachabilityFlagsInterventionRequired) == 0);
    BOOL isNetworkReachable = (isReachable && (!needsConnection || canConnectWithoutUserInteraction));

    BTDNetworkReachabilityStatus status = BTDNetworkReachabilityStatusUnknown;
    if (isNetworkReachable == NO) {
        status = BTDNetworkReachabilityStatusNotReachable;
    }
#if	TARGET_OS_IPHONE
    else if ((flags & kSCNetworkReachabilityFlagsIsWWAN) != 0) {
        status = BTDNetworkReachabilityStatusReachableViaWWAN;
    }
#endif
    else {
        status = BTDNetworkReachabilityStatusReachableViaWiFi;
    }

    return status;
}

static void BTDNetworkReachabilityCallback(SCNetworkReachabilityRef __unused target, SCNetworkReachabilityFlags flags, void *info) {
    BTDNetworkReachabilityStatus status = BTDNetworkReachabilityStatusForFlags(flags);
    BTDNetworkReachabilityStatusBlock block = (__bridge BTDNetworkReachabilityStatusBlock)info;
    if (block) {
        block(status);
    }


    dispatch_async(dispatch_get_main_queue(), ^{
        NSNotificationCenter *notificationCenter = [NSNotificationCenter defaultCenter];
        NSDictionary *userInfo = @{ BTDNetworkingReachabilityNotificationStatusItem: @(status) };
        [notificationCenter postNotificationName:BTDNetworkingReachabilityDidChangeNotification object:nil userInfo:userInfo];
    });

}

static const void * BTDNetworkReachabilityRetainCallback(const void *info) {
    return Block_copy(info);
}

static void BTDNetworkReachabilityReleaseCallback(const void *info) {
    if (info) {
        Block_release(info);
    }
}

@interface BTDReachabilityManager ()
@property (readwrite, nonatomic, assign) SCNetworkReachabilityRef networkReachability;
@property (readwrite, nonatomic, assign) BTDNetworkReachabilityAssociation networkReachabilityAssociation;
@property (readwrite, nonatomic, assign) BTDNetworkReachabilityStatus networkReachabilityStatus;
@property (readwrite, nonatomic, copy) BTDNetworkReachabilityStatusBlock networkReachabilityStatusBlock;
@end

@implementation BTDReachabilityManager

+ (instancetype)sharedManager {
    static BTDReachabilityManager *_sharedInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        struct sockaddr_in address;
        bzero(&address, sizeof(address));
        address.sin_len = sizeof(address);
        address.sin_family = AF_INET;

        _sharedInstance = [self managerForAddress:&address];
    });

    return _sharedInstance;
}

+ (instancetype)managerForDomain:(NSString *)domain {
    SCNetworkReachabilityRef reachability = SCNetworkReachabilityCreateWithName(kCFAllocatorDefault, [domain UTF8String]);

    BTDReachabilityManager *manager = [[self alloc] initWithReachability:reachability];
    manager.networkReachabilityAssociation = BTDNetworkReachabilityForName;

    return manager;
}

+ (instancetype)managerForAddress:(const void *)address {
    SCNetworkReachabilityRef reachability = SCNetworkReachabilityCreateWithAddress(kCFAllocatorDefault, (const struct sockaddr *)address);

    BTDReachabilityManager *manager = [[self alloc] initWithReachability:reachability];
    manager.networkReachabilityAssociation = BTDNetworkReachabilityForAddress;

    return manager;
}

- (instancetype)initWithReachability:(SCNetworkReachabilityRef)reachability {
    self = [super init];
    if (!self) {
        return nil;
    }

    self.networkReachability = reachability;
    self.networkReachabilityStatus = BTDNetworkReachabilityStatusUnknown;

    return self;
}

- (void)dealloc {
    [self stopMonitoring];

    if (_networkReachability) {
        CFRelease(_networkReachability);
        _networkReachability = NULL;
    }
}

#pragma mark -

- (BOOL)isReachable {
    return self.networkReachabilityStatus != BTDNetworkReachabilityStatusNotReachable;
}

- (BOOL)isReachableViaWWAN {
    return self.networkReachabilityStatus == BTDNetworkReachabilityStatusReachableViaWWAN;
}

- (BOOL)isReachableViaWiFi {
    return self.networkReachabilityStatus == BTDNetworkReachabilityStatusReachableViaWiFi;
}

#pragma mark -

- (void)startMonitoring {
    [self stopMonitoring];

    if (!self.networkReachability) {
        return;
    }

    __weak __typeof(self)weakSelf = self;
    BTDNetworkReachabilityStatusBlock callback = ^(BTDNetworkReachabilityStatus status) {
        __strong __typeof(weakSelf)strongSelf = weakSelf;

        strongSelf.networkReachabilityStatus = status;
        if (strongSelf.networkReachabilityStatusBlock) {
            strongSelf.networkReachabilityStatusBlock(status);
        }

    };

    SCNetworkReachabilityContext context = {0, (__bridge void *)callback, BTDNetworkReachabilityRetainCallback, BTDNetworkReachabilityReleaseCallback, NULL};
    SCNetworkReachabilitySetCallback(self.networkReachability, BTDNetworkReachabilityCallback, &context);
    SCNetworkReachabilityScheduleWithRunLoop(self.networkReachability, CFRunLoopGetMain(), kCFRunLoopCommonModes);

    switch (self.networkReachabilityAssociation) {
        case BTDNetworkReachabilityForName:
            break;
        case BTDNetworkReachabilityForAddress:
        case BTDNetworkReachabilityForAddressPair:
        default: {
            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0),^{
                SCNetworkReachabilityFlags flags;
                SCNetworkReachabilityGetFlags(self.networkReachability, &flags);
                BTDNetworkReachabilityStatus status = BTDNetworkReachabilityStatusForFlags(flags);
                dispatch_async(dispatch_get_main_queue(), ^{
                    callback(status);

                    NSNotificationCenter *notificationCenter = [NSNotificationCenter defaultCenter];
                    [notificationCenter postNotificationName:BTDNetworkingReachabilityDidChangeNotification object:nil userInfo:@{ BTDNetworkingReachabilityNotificationStatusItem: @(status) }];


                });
            });
        }
            break;
    }
}

- (void)stopMonitoring {
    if (!self.networkReachability) {
        return;
    }

    SCNetworkReachabilityUnscheduleFromRunLoop(self.networkReachability, CFRunLoopGetMain(), kCFRunLoopCommonModes);
}

#pragma mark -

- (NSString *)localizedNetworkReachabilityStatusString {
    return BTDStringFromNetworkReachabilityStatus(self.networkReachabilityStatus);
}

#pragma mark -

- (void)setReachabilityStatusChangeBlock:(void (^)(BTDNetworkReachabilityStatus status))block {
    self.networkReachabilityStatusBlock = block;
}

#pragma mark - NSKeyValueObserving

+ (NSSet *)keyPathsForValuesAffectingValueForKey:(NSString *)key {
    if ([key isEqualToString:@"reachable"] || [key isEqualToString:@"reachableViaWWAN"] || [key isEqualToString:@"reachableViaWiFi"]) {
        return [NSSet setWithObject:@"networkReachabilityStatus"];
    }
    
    return [super keyPathsForValuesAffectingValueForKey:key];
}

@end
