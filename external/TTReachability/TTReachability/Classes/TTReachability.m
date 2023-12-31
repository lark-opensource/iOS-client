/*
 File: TTReachability.m
 Abstract: Basic demonstration of how to use the SystemConfiguration Reachablity APIs.
 Version: 3.5
 
 Disclaimer: IMPORTANT:  This Apple software is supplied to you by Apple
 Inc. ("Apple") in consideration of your agreement to the following
 terms, and your use, installation, modification or redistribution of
 this Apple software constitutes acceptance of these terms.  If you do
 not agree with these terms, please do not use, install, modify or
 redistribute this Apple software.
 
 In consideration of your agreement to abide by the following terms, and
 subject to these terms, Apple grants you a personal, non-exclusive
 license, under Apple's copyrights in this original Apple software (the
 "Apple Software"), to use, reproduce, modify and redistribute the Apple
 Software, with or without modifications, in source and/or binary forms;
 provided that if you redistribute the Apple Software in its entirety and
 without modifications, you must retain this notice and the following
 text and disclaimers in all such redistributions of the Apple Software.
 Neither the name, trademarks, service marks or logos of Apple Inc. may
 be used to endorse or promote products derived from the Apple Software
 without specific prior written permission from Apple.  Except as
 expressly stated in this notice, no other rights or licenses, express or
 implied, are granted by Apple herein, including but not limited to any
 patent rights that may be infringed by your derivative works or by other
 works in which the Apple Software may be incorporated.
 
 The Apple Software is provided by Apple on an "AS IS" basis.  APPLE
 MAKES NO WARRANTIES, EXPRESS OR IMPLIED, INCLUDING WITHOUT LIMITATION
 THE IMPLIED WARRANTIES OF NON-INFRINGEMENT, MERCHANTABILITY AND FITNESS
 FOR A PARTICULAR PURPOSE, REGARDING THE APPLE SOFTWARE OR ITS USE AND
 OPERATION ALONE OR IN COMBINATION WITH YOUR PRODUCTS.
 
 IN NO EVENT SHALL APPLE BE LIABLE FOR ANY SPECIAL, INDIRECT, INCIDENTAL
 OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
 SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
 INTERRUPTION) ARISING IN ANY WAY OUT OF THE USE, REPRODUCTION,
 MODIFICATION AND/OR DISTRIBUTION OF THE APPLE SOFTWARE, HOWEVER CAUSED
 AND WHETHER UNDER THEORY OF CONTRACT, TORT (INCLUDING NEGLIGENCE),
 STRICT LIABILITY OR OTHERWISE, EVEN IF APPLE HAS BEEN ADVISED OF THE
 POSSIBILITY OF SUCH DAMAGE.
 
 Copyright (C) 2014 Apple Inc. All Rights Reserved.
 
 */

#import <arpa/inet.h>
#import <ifaddrs.h>
#import <netdb.h>
#import <sys/socket.h>
#import <SystemConfiguration/SystemConfiguration.h>
#import <CoreFoundation/CoreFoundation.h>
#if TARGET_OS_IOS
#import <CoreTelephony/CTCellularData.h>
#import <UIKit/UIKit.h>
#import <CoreTelephony/CTTelephonyNetworkInfo.h>
#import <CoreTelephony/CTCarrier.h>
#endif
#import <libkern/OSAtomic.h>

#import "TTReachability.h"

typedef NS_OPTIONS(NSInteger, TTActiveIfAddrsStatus) {
    TTActiveIfAddrsStatusNone = 1,
    TTActiveIfAddrsStatusWithWWAN = TTActiveIfAddrsStatusNone << 1,
    TTActiveIfAddrsStatusWithWIFI = TTActiveIfAddrsStatusNone << 2
};

#define LOCK(lock) dispatch_semaphore_wait(lock, DISPATCH_TIME_FOREVER);
#define UNLOCK(lock) dispatch_semaphore_signal(lock);

NSNotificationName TTReachabilityChangedNotification = @"TTReachabilityChangedNotification";

#if TARGET_OS_IOS
static dispatch_semaphore_t dataServiceIdentifierLock API_AVAILABLE(ios(13.0)) = nil; // iOS 13以上用，修复可能的多线程问题
static dispatch_semaphore_t serviceCurrentRadioAccessTechnologyLock API_AVAILABLE(ios(12.0)) = nil; // iOS 12以上用，修复可能的多线程问题
static dispatch_semaphore_t serviceSubscriberCellularProvidersLock API_AVAILABLE(ios(12.0)) = nil; // iOS 12以上用，修复可能的多线程问题
static TTCellularNetworkConnectionType currentCellularNetworkConntectionType = TTCellularNetworkConnectionNone;
static NSString * latestRadioAccessTechString = nil;
// 对于主副卡的设备，单独存放两者的值，目前不需要使用字典（实际只有两种service）
static TTCellularNetworkConnectionType primaryCellularNetworkConntectionType = TTCellularNetworkConnectionNone;
static TTCellularNetworkConnectionType secondaryCellularNetworkConntectionType = TTCellularNetworkConnectionNone;
static NSString * latestPrimaryRadioAccessTechString = nil;
static NSString * latestSecondaryRadioAccessTechString = nil;
#endif


static BOOL telephoneInfoIndeterminateStatus = NO;   // 当前是否处于切换网络状态的中间态，这时候部分检测逻辑需要额外检查

static TTReachability * internetConnectionReachability = nil; // 单例

static double (^globalStatusCacheConfigBlock)(void) = nil;
static NSRunLoop * globalInternetConnectionNotifyRunLoop = nil;
static NSRunLoopMode globalInternetConnectionNotifyRunLoopMode = nil;

@interface TTReachability ()
{
    SCNetworkReachabilityRef _reachabilityRef;
    int32_t _hasCachedStatus;       // 是否缓存了当前网络状态
    NetworkStatus _cachedStatus;    // 当前缓存的网络状态
    int64_t _cacheTime;             // 当前缓存的时间戳
    bool _startedNotifier;          // 是否开启了网络状态变化监测
}
#if TARGET_OS_IOS
@property (class, readonly, nonnull) CTTelephonyNetworkInfo *telephoneInfo;
@property (class, readonly, nonnull) CTCellularData *cellularData API_AVAILABLE(ios(9.0));
#endif
@property (nonatomic, copy, readwrite, nullable) NSString *hostName;
@property (nonatomic, copy, readwrite, nullable) NSString *hostAddress;

- (NetworkStatus)networkStatusForFlags:(SCNetworkReachabilityFlags)flags;
// 更新网络状态缓存
- (void)setCachedStatus:(NetworkStatus)status;
// 是否需要更新网络状态缓存
- (BOOL)shouldUpdateCachedStatus:(NetworkStatus)newStatus;

@end

#if TARGET_OS_IOS
#pragma mark - Xcode Hack
// 苹果存在Bug：这两个符号，在iOS 14.1真机上才存在，但是SDK的头文件标注的available是iOS 14.0+，会导致运行时Crash，参考FB8879347
// 暂时也不直接取符号了，直接Hardcode字符串即可。
#define CTRadioAccessTechnologyNR @"CTRadioAccessTechnologyNR"
#define CTRadioAccessTechnologyNRNSA @"CTRadioAccessTechnologyNRNSA"

#pragma mark - Compatible Hack
// 兼容Hack，仅仅在iOS 12.0.0 Beta版本，不包含双卡API，单独Hack处理，待iOS 12普及率上来后删除
// 最新发现，单卡iPhone在iOS 12.0版本上，serviceSubscriberCellularProviders方法返回nil，因此也需要过滤，指定到iOS 12.1+
static inline BOOL UsingCellularServiceAPI(void) {
    if (@available(iOS 12.1, *)) {
        return YES;
    } else {
        return NO;
    }
}
#endif

#pragma mark - Supporting functions

#define kShouldPrintReachabilityFlags 0

static void PrintReachabilityFlags(SCNetworkReachabilityFlags flags, const char* comment)
{
#if kShouldPrintReachabilityFlags
    
    NSLog(@"TTReachability Flag Status: %c%c %c%c%c%c%c%c%c %s\n",
          (flags & kSCNetworkReachabilityFlagsIsWWAN)                ? 'W' : '-',
          (flags & kSCNetworkReachabilityFlagsReachable)            ? 'R' : '-',
          
          (flags & kSCNetworkReachabilityFlagsTransientConnection)  ? 't' : '-',
          (flags & kSCNetworkReachabilityFlagsConnectionRequired)   ? 'c' : '-',
          (flags & kSCNetworkReachabilityFlagsConnectionOnTraffic)  ? 'C' : '-',
          (flags & kSCNetworkReachabilityFlagsInterventionRequired) ? 'i' : '-',
          (flags & kSCNetworkReachabilityFlagsConnectionOnDemand)   ? 'D' : '-',
          (flags & kSCNetworkReachabilityFlagsIsLocalAddress)       ? 'l' : '-',
          (flags & kSCNetworkReachabilityFlagsIsDirect)             ? 'd' : '-',
          comment
          );
#endif
}


static void ReachabilityCallback(SCNetworkReachabilityRef target, SCNetworkReachabilityFlags flags, void* info)
{
#pragma unused (target, flags)
    NSCAssert(info != NULL, @"info was NULL in ReachabilityCallback");
    NSCAssert([(__bridge NSObject*) info isKindOfClass: [TTReachability class]], @"info was wrong class in ReachabilityCallback");
    
    TTReachability* noteObject = (__bridge TTReachability *)info;
    NetworkStatus status = [noteObject networkStatusForFlags:flags];
    
    // workaround:
    // 对于使用 HostName 初始化的 reachability 实例，网络状态变化时会多次回调，且传入 flags 值不相同
    // 经实验，最后一次回调的 flags 是准确的，因此借用缓存做一个滤重策略，避免多次向上层发通知
    // case: 10.3.2 真机，使用 toutiao.com 或者 apple.com 初始化，
    //      4G -> WIFI 时，可能回调 3 次, flags 依次为
    //          262147
    //          kSCNetworkReachabilityFlagsReachable
    //          kSCNetworkReachabilityFlagsReachable
    // 注：对于使用 Address 初始化的实例，网络变化时只会回调一次
    if ([noteObject shouldUpdateCachedStatus:status])
    {
        [noteObject setCachedStatus:status];
        // Post a notification to notify the client that the network reachability changed.
        [[NSNotificationCenter defaultCenter] postNotificationName: TTReachabilityChangedNotification object: noteObject];
    }
}

static void onNotifyCallback(CFNotificationCenterRef center, void *observer, CFStringRef name, const void *object, CFDictionaryRef userInfo) {
    if (CFStringCompare(name, CFSTR("com.apple.system.config.network_change"), 0) == kCFCompareEqualTo) {
        // 当WiFi状态发生变化时候，认为此时处于不稳定状态，蜂窝权限检测依赖了WiFi的IP地址做快速检测（因为无法获取系统开关具体是什么），需要临时禁用
        // 等待1秒后标记取消，这段时间内永远返回notDetermined，之后才能正常判定，如果有更好方法请联系我
        telephoneInfoIndeterminateStatus = YES;
        // 注：目前测试，这个Darwin的通知在mainQueue触发，线程安全，以后如果有变化再说
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            telephoneInfoIndeterminateStatus = NO;
        });
    }
}

#if TARGET_OS_IOS
static TTCellularNetworkConnectionType ParseRadioAccessTechnology(NSString * tech)
{
    if (!tech.length) return TTCellularNetworkConnectionNone;
    
    if (@available(iOS 14.1, *)) {
        if ([tech isEqualToString:CTRadioAccessTechnologyNR]
            || [tech isEqualToString:CTRadioAccessTechnologyNRNSA])
        {
            return TTCellularNetworkConnection5G;
        }
    }
    if ([tech isEqualToString:CTRadioAccessTechnologyLTE])
        return TTCellularNetworkConnection4G;
    if ([tech isEqualToString:CTRadioAccessTechnologyWCDMA]
             || [tech isEqualToString:CTRadioAccessTechnologyHSDPA]
             || [tech isEqualToString:CTRadioAccessTechnologyHSUPA]
             || [tech isEqualToString:CTRadioAccessTechnologyCDMA1x]
             || [tech isEqualToString:CTRadioAccessTechnologyCDMAEVDORev0]
             || [tech isEqualToString:CTRadioAccessTechnologyCDMAEVDORevA]
             || [tech isEqualToString:CTRadioAccessTechnologyCDMAEVDORevB]
             || [tech isEqualToString:CTRadioAccessTechnologyeHRPD])
    {
        return TTCellularNetworkConnection3G;
    }
    if ([tech isEqualToString:CTRadioAccessTechnologyGPRS]
             || [tech isEqualToString:CTRadioAccessTechnologyEdge])
    {
        return TTCellularNetworkConnection2G;
    }
    
    // Maybe 6G? :)
    return TTCellularNetworkConnectionUnknown;
}

/**
 转换自定义的主副卡枚举值到Core Telephoy用到的Service Identifier，以具体去查询某一张SIM卡的当前蜂窝状态
 @warning 目前的实现并没有官方API可以使用，依赖于反编译结果，随着固件版本更新，可能有变……到时候需要更新下
 
 @param service service
 @return service identifier
 */
static NSString * ServiceIdentifierForCelluarService(TTCellularServiceType service) API_AVAILABLE(ios(12.0))
{
    int domain = 0x1; // 目前是写死的值
    int slotID = (int)service;
    // 目前生成规则，根据前8位为固定的domain，后8位为对应的slotID（slotID = 1表示主卡，2表示副卡），不足补全8位
    return [NSString stringWithFormat:@"%08d%08d", domain, slotID];
}

static void UpdateCellularConnectionType(void)
{
    NSString *currentRadioAccessTechnology = TTReachability.telephoneInfo.currentRadioAccessTechnology;
    if ([latestRadioAccessTechString isEqualToString:currentRadioAccessTechnology])
    {
        return;
    }
    latestRadioAccessTechString = currentRadioAccessTechnology;
    TTCellularNetworkConnectionType oldType = currentCellularNetworkConntectionType;
    TTCellularNetworkConnectionType newType = ParseRadioAccessTechnology(latestRadioAccessTechString);
    OSAtomicCompareAndSwap32Barrier(oldType,
                                    newType,
                                    &currentCellularNetworkConntectionType);
}

/**
 用于iOS 12+的蜂窝状态检测
 */
static void UpdateServiceCellularConnectionType(void) API_AVAILABLE(ios(12.0))
{
    NSString * primaryServiceIdentifier = ServiceIdentifierForCelluarService(TTCellularServiceTypePrimary);
    NSString * seconaryServiceIdentifier = ServiceIdentifierForCelluarService(TTCellularServiceTypeSecondary);
    
    LOCK(serviceCurrentRadioAccessTechnologyLock);
    NSDictionary *serviceCurrentRadioAccessTechnology = [TTReachability.telephoneInfo.serviceCurrentRadioAccessTechnology copy];
    UNLOCK(serviceCurrentRadioAccessTechnologyLock);
    
    if (![latestPrimaryRadioAccessTechString isEqualToString:serviceCurrentRadioAccessTechnology[primaryServiceIdentifier]])
    {
        latestPrimaryRadioAccessTechString = serviceCurrentRadioAccessTechnology[primaryServiceIdentifier];
        TTCellularNetworkConnectionType oldType = primaryCellularNetworkConntectionType;
        TTCellularNetworkConnectionType newType = ParseRadioAccessTechnology(latestPrimaryRadioAccessTechString);
        OSAtomicCompareAndSwap32Barrier(oldType,
                                        newType,
                                        &primaryCellularNetworkConntectionType);
    }
    if (![latestSecondaryRadioAccessTechString isEqualToString:serviceCurrentRadioAccessTechnology[seconaryServiceIdentifier]])
    {
        latestSecondaryRadioAccessTechString = serviceCurrentRadioAccessTechnology[seconaryServiceIdentifier];
        TTCellularNetworkConnectionType oldType = secondaryCellularNetworkConntectionType;
        TTCellularNetworkConnectionType newType = ParseRadioAccessTechnology(latestSecondaryRadioAccessTechString);
        OSAtomicCompareAndSwap32Barrier(oldType,
                                        newType,
                                        &secondaryCellularNetworkConntectionType);
    }
}

static NSString *GetDataServiceIdentifier(void)
{
    NSString *serviceIndentifier;
    if (@available (iOS 13, *)) {
        // 这里需要加锁，iOS 15+出现了大量访问属性的多线程Crash：https://slardar.bytedance.net/node/app_detail/?aid=1128&os=iOS#/abnormal/detail/crash/1128_0b280056e5c3c472b3bb21e2a12db164
        if ([CTTelephonyNetworkInfo instancesRespondToSelector:@selector(dataServiceIdentifier)]) {
            LOCK(dataServiceIdentifierLock);
            serviceIndentifier = [TTReachability.telephoneInfo dataServiceIdentifier];
            UNLOCK(dataServiceIdentifierLock);
        }
    } else {
        // iOS 12上暂时没有办法
        // 花了一些时间进行反编译研究，CoreTelephony是一个XPC架构，苹果在iOS 13上为了支持dataService流量卡接口，重构了很多代码，在iOS 12上本身XPC的Server进程就未提供接口，尝试直接私有API调用更为底层的状态（SIM卡数据模块）也会被XPC的权限拦截掉，无法实现
        // 之前有人采取了通过UIStatusBar的私有API获取，但是只能拿到运营商名称，和这里的返回CTCarrier是不等价的（如果存在两个“中国联通”，无法判定是哪一种卡），待后续考虑
        
    }
    return serviceIndentifier;
}
#endif

#pragma mark - TTReachability implementation

@implementation TTReachability

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wunguarded-availability"
+ (void)initialize
{
    // 只需要执行一次，防止外界继承 TTReachability 时，子类未实现自己的 initialize，和 TTReachability 共用本方法的情况。
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{

#if TARGET_OS_IOS
        // 截止至iOS 12，currentRadioAccessTechnology(包括serviceCurrentRadioAccessTechnology)的实现内部是一个可变字典，但是苹果没有加锁，访问的时候手动加锁处理
        // Radar Bug Report: https://openradar.appspot.com/46873673 等苹果修iOS 13修复后就可以不用这个锁了
        // iOS 11以前，currentRadioAccessTechnology的内部实现没有字典，所以是多线程安全的
        // 同理对于serviceSubscriberCellularProviders属性，也是可变字典
        if (UsingCellularServiceAPI()) {
            serviceCurrentRadioAccessTechnologyLock = dispatch_semaphore_create(1);
            serviceSubscriberCellularProvidersLock = dispatch_semaphore_create(1);
        }
        
        if (@available (iOS 13, *)) {
            // iOS 13.0.x机型上可能不存在此符号，兼容性判断一下
            if ([CTTelephonyNetworkInfo instancesRespondToSelector:@selector(dataServiceIdentifier)]) {
                dataServiceIdentifierLock = dispatch_semaphore_create(1);
            }
        }
        
        if (UsingCellularServiceAPI()) {
            UpdateServiceCellularConnectionType();
            [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(serviceRadioAccessTechnologyDidChange:) name:CTServiceRadioAccessTechnologyDidChangeNotification object:nil];
        } else {
            UpdateCellularConnectionType();
            [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(radioAccessTechnologyDidChange:) name:CTRadioAccessTechnologyDidChangeNotification object:nil];
        }
#endif
        
        // 监听WiFi硬件开关变化的Darwin通知，这个按照Apple的论坛说法是Public API
        CFNotificationCenterAddObserver(CFNotificationCenterGetDarwinNotifyCenter(), //center
                                        NULL, // observer
                                        onNotifyCallback, // callback
                                        CFSTR("com.apple.system.config.network_change"), // event name
                                        NULL, // object
                                        CFNotificationSuspensionBehaviorDeliverImmediately);
    });
}

#if TARGET_OS_IOS
+ (CTTelephonyNetworkInfo *)telephoneInfo {
    static dispatch_once_t onceToken;
    static CTTelephonyNetworkInfo *telephoneInfo;
    dispatch_once(&onceToken, ^{
        telephoneInfo = [[CTTelephonyNetworkInfo alloc] init];
    });
    return telephoneInfo;
}

+ (CTCellularData *)cellularData {
    static dispatch_once_t onceToken;
    static CTCellularData *cellularData;
    dispatch_once(&onceToken, ^{
        cellularData = [[CTCellularData alloc] init];
    });
    return cellularData;
}
#endif

#if TARGET_OS_IOS
+ (void)serviceRadioAccessTechnologyDidChange:(NSNotification *)notification {
    // CTTelephonyNetworkInfo 的 init 方法中，会同步发送此通知（从iOS 12+以后不再触发）
    // 因此每当外界创建一个 CTTelephonyNetworkInfo 实例，这里都会触发回调
    // 发现在iOS 12/iOS 13上，存在苹果SDK的Bug会导致如果就地使用当前Queue去访问，后续访问CTTelephonyNetworkInfo属性有小概率的Crash问题，因此统一Dispatch到主线程
    dispatch_async(dispatch_get_main_queue(), ^{
        UpdateServiceCellularConnectionType();
    });
}

+ (void)radioAccessTechnologyDidChange:(NSNotification *)notification {
    // CTTelephonyNetworkInfo 的 init 方法中，会同步发送此通知（从iOS 12+以后不再触发）
    // 因此每当外界创建一个 CTTelephonyNetworkInfo 实例，这里都会触发回调
    // 发现在iOS 12/iOS 13上，存在苹果SDK的Bug会导致如果就地使用当前Queue去访问，后续访问CTTelephonyNetworkInfo属性有小概率的Crash问题，因此统一Dispatch到主线程
    dispatch_async(dispatch_get_main_queue(), ^{
        UpdateCellularConnectionType();
    });
}
#endif

#pragma clang diagnostic pop

+ (instancetype)reachabilityWithHostName:(NSString *)hostName
{
    TTReachability* returnValue = NULL;
    SCNetworkReachabilityRef reachability = SCNetworkReachabilityCreateWithName(NULL, [hostName UTF8String]);
    if (reachability != NULL)
    {
        returnValue= [[self alloc] initWithReachabilityRef:reachability];
        CFRelease(reachability);
        returnValue.hostName = hostName;
    } else {
#if DEBUG
        NSException *e = [NSException exceptionWithName:NSInvalidArgumentException reason:@"TTReachability failed to create with hostname" userInfo:nil];
        @throw e;
#else
        printf("NSInvalidArgumentException: TTReachability failed to create with hostname\n");
#endif
        return [TTReachability new];
    }
    return returnValue;
}

+ (instancetype)reachabilityWithAddress:(const struct sockaddr_in *)hostAddress
{
    SCNetworkReachabilityRef reachability = SCNetworkReachabilityCreateWithAddress(kCFAllocatorDefault, (const struct sockaddr *)hostAddress);
    TTReachability* returnValue = NULL;
    if (reachability != NULL)
    {
        returnValue = [[self alloc] initWithReachabilityRef:reachability];
        CFRelease(reachability);
        const char *address = inet_ntoa(hostAddress->sin_addr);
        returnValue.hostAddress = [NSString stringWithUTF8String:address];
    } else {
#if DEBUG
        NSException *e = [NSException exceptionWithName:NSInvalidArgumentException reason:@"TTReachability failed to create with address" userInfo:nil];
        @throw e;
#else
        printf("NSInvalidArgumentException: TTReachability failed to create with address\n");
#endif
        return [TTReachability new];
    }
    return returnValue;
}

+ (instancetype)reachabilityForInternetConnection
{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        struct sockaddr_in zeroAddress;
        bzero(&zeroAddress, sizeof(zeroAddress));
        zeroAddress.sin_len = sizeof(zeroAddress);
        zeroAddress.sin_family = AF_INET;
        
        internetConnectionReachability = [self reachabilityWithAddress:&zeroAddress];
        // forInternetConnection由于不响应外部的start/stop，在第一次构建后自动启动，runloop配置是类方法
        SCNetworkReachabilityRef reachabilityRef = internetConnectionReachability->_reachabilityRef;
        SCNetworkReachabilityContext context = {0, (__bridge void *)(internetConnectionReachability), NULL, NULL, NULL};
        
        CFRunLoopRef runloop = globalInternetConnectionNotifyRunLoop ? globalInternetConnectionNotifyRunLoop.getCFRunLoop : CFRunLoopGetMain();
        CFStringRef runloopMode = globalInternetConnectionNotifyRunLoopMode.length > 0 ? (__bridge CFStringRef)globalInternetConnectionNotifyRunLoopMode : kCFRunLoopDefaultMode;
        if (SCNetworkReachabilitySetCallback(reachabilityRef, ReachabilityCallback, &context)) {
            if (SCNetworkReachabilityScheduleWithRunLoop(reachabilityRef, runloop, runloopMode)) {
                internetConnectionReachability->_startedNotifier = YES;
            } else {
                NSCAssert(NO, @"internetConnectionReachability create failed");
            }
        } else {
            NSCAssert(NO, @"internetConnectionReachability create failed");
        }
    });
    
    return internetConnectionReachability;
}

- (instancetype)initWithReachabilityRef:(SCNetworkReachabilityRef)reachabilityRef
{
    self = [super init];
    if (self)
    {
        if (reachabilityRef != NULL) {
            CFRetain(reachabilityRef);
            _reachabilityRef = reachabilityRef;
        }
        _hasCachedStatus = 0;
        _cachedStatus = NotReachable;
        
#if TARGET_OS_IOS
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(applicationDidEnterBackground:) name:UIApplicationDidEnterBackgroundNotification object:nil];
#endif
    }
    return self;
}

#pragma mark - Host Information

- (BOOL)isInternetConnection {
    return [self.hostAddress isEqualToString:@"0.0.0.0"];
}

#pragma mark - Start and stop notifier

- (BOOL)startNotifier
{
    // 全局的Internet Connection单例不响应
    if (self == internetConnectionReachability) {
        return YES;
    }
    [self stopNotifier];
    
    if (!_reachabilityRef) return NO;
    
    BOOL returnValue = NO;
    SCNetworkReachabilityContext context = {0, (__bridge void *)(self), NULL, NULL, NULL};
    if (SCNetworkReachabilitySetCallback(_reachabilityRef, ReachabilityCallback, &context))
    {
        if (SCNetworkReachabilityScheduleWithRunLoop(_reachabilityRef, CFRunLoopGetCurrent(), kCFRunLoopDefaultMode))
        {
            returnValue = YES;
            _startedNotifier = YES;
        }
    }
    
    return returnValue;
}


- (void)stopNotifier
{
    // 全局的Internet Connection单例不响应
    if (self == internetConnectionReachability) {
        return;
    }
    if (_reachabilityRef != NULL)
    {
        SCNetworkReachabilityUnscheduleFromRunLoop(_reachabilityRef, CFRunLoopGetCurrent(), kCFRunLoopDefaultMode);
        _startedNotifier = NO;
        [self invalidateCachedStatus];
    }
}


- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [self stopNotifier];
    if (_reachabilityRef != NULL)
    {
        CFRelease(_reachabilityRef);
        _reachabilityRef = NULL;
    }
}

#if TARGET_OS_IOS
- (void)applicationDidEnterBackground:(NSNotification *)nofication
{
    // App 进入后台后如果网络发生变化，再切入前台时不一定能确保收到 callback。
    // 安全起见，将缓存状态置为无效
    [self invalidateCachedStatus];
}
#endif

#pragma mark - Network Flag Handling

- (NetworkStatus)networkStatusForFlags:(SCNetworkReachabilityFlags)flags
{
    PrintReachabilityFlags(flags, "networkStatusForFlags");
    if ((flags & kSCNetworkReachabilityFlagsReachable) == 0)
    {
        // The target host is not reachable.
        return NotReachable;
    }
    
    NetworkStatus returnValue = NotReachable;
    
    if ((flags & kSCNetworkReachabilityFlagsConnectionRequired) == 0)
    {
        /*
         If the target host is reachable and no connection is required then we'll assume (for now) that you're on Wi-Fi...
         */
        returnValue = ReachableViaWiFi;
    }
    
    if ((((flags & kSCNetworkReachabilityFlagsConnectionOnDemand ) != 0) ||
         (flags & kSCNetworkReachabilityFlagsConnectionOnTraffic) != 0))
    {
        /*
         ... and the connection is on-demand (or on-traffic) if the calling application is using the CFSocketStream or higher APIs...
         */
        
        if ((flags & kSCNetworkReachabilityFlagsInterventionRequired) == 0)
        {
            /*
             ... and no [user] intervention is needed...
             */
            returnValue = ReachableViaWiFi;
        }
    }

#if TARGET_OS_IOS
    if ((flags & kSCNetworkReachabilityFlagsIsWWAN) == kSCNetworkReachabilityFlagsIsWWAN)
    {
        /*
         ... but WWAN connections are OK if the calling application is using the CFNetwork APIs.
         */
        returnValue = ReachableViaWWAN;
    }
#endif
    
    return returnValue;
}


- (BOOL)connectionRequired
{
    NSAssert(_reachabilityRef != NULL, @"connectionRequired called with NULL reachabilityRef");
    SCNetworkReachabilityFlags flags;
    
    if (SCNetworkReachabilityGetFlags(_reachabilityRef, &flags))
    {
        return (flags & kSCNetworkReachabilityFlagsConnectionRequired);
    }
    
    return NO;
}

- (NetworkStatus)currentReachabilityStatus
{
    NSAssert(_reachabilityRef != NULL, @"currentNetworkStatus called with NULL SCNetworkReachabilityRef");
    
    if (![self shouldUpdateNetworkStatus] && _hasCachedStatus) {
        return _cachedStatus;
    }
    
    NetworkStatus returnValue = NotReachable;
    SCNetworkReachabilityFlags flags;
    if (SCNetworkReachabilityGetFlags(_reachabilityRef, &flags))
    {
        returnValue = [self networkStatusForFlags:flags];
    }
    
    if ([self shouldUpdateCachedStatus:returnValue]) {
        [self setCachedStatus:returnValue];
    }
    return returnValue;
}

- (TTNetworkAuthorizationStatus)currentNetworkAuthorizationStatus
{
    NetworkStatus networkStatus = [self currentReachabilityStatus];
    // Case1: 当前 App 可联网
    //    返回 CantDetermined，无法判断 App 的网络权限设置
    if (networkStatus != NotReachable)
        return TTNetworkAuthorizationStatusNotDetermined;
    
    // Case2: 当前 App 不可联网
    //    如果系统有 WIFI 连接，则判断为 未开启无线局域网与蜂窝移动网络权限
    //    如果系统有 WWAN 连接，则判断为 未开启蜂窝移动网络权限
    //    判断顺序为先 WIFI 后 WWAN，不能反，否则会在国行 iPhone 上造成误判，将 “全部未开” 误判成 “未开蜂窝”
    TTActiveIfAddrsStatus activeIfAddrs = [TTReachability fastDetectActiveIfAddrsStatus];// 手机实际网络状态
    BOOL dataRestricted = YES; // iOS 9以下假设永远受限，走复杂判定逻辑
#if TARGET_OS_IOS
    if (@available(iOS 9.0, *)) {
        // CTCellularData对象需要创建之后等待一会才能获取到正确的状态，苹果的Bug。建立一个共享的单例来访问
        CTCellularDataRestrictedState cellState = TTReachability.cellularData.restrictedState; // 蜂窝授权状态
        dataRestricted = (cellState != kCTCellularDataNotRestricted);
    }
#endif
    if (dataRestricted && (activeIfAddrs & TTActiveIfAddrsStatusNone) == 0) {// 蜂窝未授权，且手机实际已联网
        // 由于发现苹果WiFi状态变化有时候会滞后，这里加一个额外的判定逻辑
        // 如果经过一次App活跃状态切换，并且上一次“可用的检测”还没别覆盖，直接返回NotDetermined
        if (telephoneInfoIndeterminateStatus) {
            return TTNetworkAuthorizationStatusNotDetermined;
        }
        
        if (activeIfAddrs & TTActiveIfAddrsStatusWithWIFI) {
            return TTNetworkAuthorizationStatusWLANAndCellularNotPermitted;
        } else if (activeIfAddrs & TTActiveIfAddrsStatusWithWWAN) {
            return TTNetworkAuthorizationStatusCellularNotPermitted;
        }
    }
    
    return TTNetworkAuthorizationStatusNotDetermined;
}

- (void)invalidateCachedStatus
{
    OSAtomicCompareAndSwap32(1, 0, &_hasCachedStatus);
}

- (void)setCachedStatus:(NetworkStatus)status
{
    NetworkStatus old = _cachedStatus;
#if __LP64__
    OSAtomicCompareAndSwapLongBarrier(old, status, &_cachedStatus);
#else
    OSAtomicCompareAndSwapIntBarrier(old, status, &_cachedStatus);
#endif
    OSAtomicCompareAndSwap32(0, 1, &_hasCachedStatus);
}

- (BOOL)shouldUpdateCachedStatus:(NetworkStatus)newStatus
{
    // 如果没有缓存过，或者已经缓存过，但缓存的值和新值不同，则需要更新缓存
    return (!_hasCachedStatus || _cachedStatus != newStatus);
}



# pragma mark - util

+ (TTActiveIfAddrsStatus)fastDetectActiveIfAddrsStatus
{
    // 执行速度 < 1ms (iPhone 6s, 10.3.2)
    TTActiveIfAddrsStatus status = TTActiveIfAddrsStatusNone;
    @try
    {
        struct ifaddrs *interfaces, *i;
        if (!getifaddrs(&interfaces))
        {
            i = interfaces;
            while(i != NULL)
            {
                if(i->ifa_addr->sa_family == AF_INET
                   ||i->ifa_addr->sa_family == AF_INET6)
                {
                    const char *name = i->ifa_name;
                    const char *address = inet_ntoa(((struct sockaddr_in *)i->ifa_addr)->sin_addr);
                    /**
                     iOS的WiFi切换，在从关闭到打开的状态下，约有2秒的延迟后，SCNetworkReachabilityRef才会触发callback
                     但是在切换的瞬间，WiFi intertface（en0）就立即能够获取，这2秒内，对应的IP地址会先变成0.0.0.0，或者127.0.0.1，最后才是正确的IP
                     因此，这里判断需要过滤一次，否则网络权限检测会误判定这2秒内属于WLANAndCellularNotPermitted
                     */
                    if (strcmp(address, "0.0.0.0") != 0 && strcmp(address, "127.0.0.1") != 0)
                    {
                        if (strcmp(name, "en0") == 0)
                        {
                            status |= TTActiveIfAddrsStatusWithWIFI;
                        }
                        else if (strcmp(name, "pdp_ip0") == 0)
                        {
                            // 卡1
                            status |= TTActiveIfAddrsStatusWithWWAN;
                        }
                        else if (strcmp(name, "pdp_ip1") == 0)
                        {
                            // 卡2
                            status |= TTActiveIfAddrsStatusWithWWAN;
                        }
                    }
                }
                // 如果两个都有了，不用再继续判断了
                if ((status & TTActiveIfAddrsStatusWithWIFI)
                    && (status & TTActiveIfAddrsStatusWithWWAN))
                {
                    break;
                }
                i = i->ifa_next;
            }
        }
        
        freeifaddrs(interfaces);
        interfaces = NULL;
    }
    @catch (NSException *exception)
    {
        
    }
    
    // 如果 status != None，说明已经找到 WWAN 或者 WIFI，将 None 去除
    if (status != TTActiveIfAddrsStatusNone)
    {
        status ^= TTActiveIfAddrsStatusNone;
    }
    
    return status;
}

#pragma mark - Optimise Reachability Status
- (BOOL)shouldUpdateNetworkStatus {
    double updateTime = 0;
    if (globalStatusCacheConfigBlock) {
        updateTime = globalStatusCacheConfigBlock();
    }
    if (updateTime - 0 < 0.000001) {// 开关为关直接返回
        return YES;
    }
    
    int64_t nowTime = (int64_t)[[NSDate date] timeIntervalSince1970];
    int64_t cacheTime = _cacheTime;
    if (nowTime - cacheTime  < updateTime) { // 检测缓存是否超时
        return NO;
    }
    OSAtomicCompareAndSwap64Barrier(cacheTime, nowTime, &_cacheTime); // 更新时间
    return YES;
}

@end

#if TARGET_OS_IOS
@implementation TTReachability (Cellular)

+ (BOOL)isNetworkConnected;
{
    // 创建零地址，0.0.0.0的地址表示查询本机的网络连接状态
    struct sockaddr_in zeroAddress;
    bzero(&zeroAddress, sizeof(zeroAddress));
    zeroAddress.sin_len = sizeof(zeroAddress);
    zeroAddress.sin_family = AF_INET;
    
    /**
     *  SCNetworkReachabilityRef: 用来保存创建测试连接返回的引用
     *
     *  SCNetworkReachabilityCreateWithAddress: 根据传入的地址测试连接.
     *  第一个参数可以为NULL或kCFAllocatorDefault
     *  第二个参数为需要测试连接的IP地址,当为0.0.0.0时则可以查询本机的网络连接状态.
     *  同时返回一个引用必须在用完后释放.
     *  PS: SCNetworkReachabilityCreateWithName: 这个是根据传入的网址测试连接,
     *  第二个参数比如为"www.2cto.com",其他和上一个一样.
     *
     *  SCNetworkReachabilityGetFlags: 这个函数用来获得测试连接的状态,
     *  第一个参数为之前建立的测试连接的引用,
     *  第二个参数用来保存获得的状态,
     *  如果能获得状态则返回TRUE，否则返回FALSE
     *
     */
    SCNetworkReachabilityRef defaultRouteReachability = SCNetworkReachabilityCreateWithAddress(NULL, (struct sockaddr *)&zeroAddress);
    SCNetworkReachabilityFlags flags;
    
    BOOL didRetrieveFlags = SCNetworkReachabilityGetFlags(defaultRouteReachability, &flags);
    CFRelease(defaultRouteReachability);
    
    if (!didRetrieveFlags)
    {
#ifdef DEBUG
        NSLog(@"Error. Could not recover network reachability flagsn");
#endif
        return NO;
    }
    
    /**
     *  kSCNetworkReachabilityFlagsReachable: 能够连接网络
     *  kSCNetworkReachabilityFlagsConnectionRequired: 能够连接网络,但是首先得建立连接过程
     *  kSCNetworkReachabilityFlagsIsWWAN: 判断是否通过蜂窝网覆盖的连接,
     *  比如EDGE,GPRS或者目前的3G.主要是区别通过WiFi的连接.
     *
     */
    BOOL isReachable = ((flags & kSCNetworkFlagsReachable) != 0);
    BOOL needsConnection = ((flags & kSCNetworkFlagsConnectionRequired) != 0);
    return (isReachable && !needsConnection) ? YES : NO;
}

+ (BOOL)is2GConnected
{
    return [self is2GConnectedForService:TTCellularServiceTypePrimary];
}

+ (BOOL)is3GConnected
{
    return [self is3GConnectedForService:TTCellularServiceTypePrimary];
}

+ (BOOL)is4GConnected
{
    return [self is4GConnectedForService:TTCellularServiceTypePrimary];
}

+ (BOOL)is5GConnected
{
    return [self is5GConnectedForService:TTCellularServiceTypePrimary];
}

+ (BOOL)is2GConnectedForService:(TTCellularServiceType)service {
    if (UsingCellularServiceAPI()) {
        switch (service) {
            case TTCellularServiceTypePrimary:
                return primaryCellularNetworkConntectionType == TTCellularNetworkConnection2G;
            case TTCellularServiceTypeSecondary:
                return secondaryCellularNetworkConntectionType == TTCellularNetworkConnection2G;
            default:
                return NO;
        }
    } else {
        return currentCellularNetworkConntectionType == TTCellularNetworkConnection2G;
    }
}

+ (BOOL)is3GConnectedForService:(TTCellularServiceType)service {
    if (UsingCellularServiceAPI()) {
        switch (service) {
            case TTCellularServiceTypePrimary:
                return primaryCellularNetworkConntectionType == TTCellularNetworkConnection3G;
            case TTCellularServiceTypeSecondary:
                return secondaryCellularNetworkConntectionType == TTCellularNetworkConnection3G;
            default:
                return NO;
        }
    } else {
        return currentCellularNetworkConntectionType == TTCellularNetworkConnection3G;
    }
}

+ (BOOL)is4GConnectedForService:(TTCellularServiceType)service {
    if (UsingCellularServiceAPI()) {
        switch (service) {
            case TTCellularServiceTypePrimary:
                return primaryCellularNetworkConntectionType == TTCellularNetworkConnection4G;
            case TTCellularServiceTypeSecondary:
                return secondaryCellularNetworkConntectionType == TTCellularNetworkConnection4G;
            default:
                return NO;
        }
    } else {
        return currentCellularNetworkConntectionType == TTCellularNetworkConnection4G;
    }
}

+ (BOOL)is5GConnectedForService:(TTCellularServiceType)service {
    if (UsingCellularServiceAPI()) {
        switch (service) {
            case TTCellularServiceTypePrimary:
                return primaryCellularNetworkConntectionType == TTCellularNetworkConnection5G;
            case TTCellularServiceTypeSecondary:
                return secondaryCellularNetworkConntectionType == TTCellularNetworkConnection5G;
            default:
                return NO;
        }
    } else {
        return currentCellularNetworkConntectionType == TTCellularNetworkConnection5G;
    }
}

+ (TTCellularNetworkConnectionType)currentCellularConnectionForService:(TTCellularServiceType)service {
    if (UsingCellularServiceAPI()) {
        switch (service) {
            case TTCellularServiceTypePrimary:
                return primaryCellularNetworkConntectionType;
            case TTCellularServiceTypeSecondary:
                return secondaryCellularNetworkConntectionType;
            default:
                return TTCellularNetworkConnectionNone;
        }
    } else {
        return currentCellularNetworkConntectionType;
    }
}

+ (TTCellularNetworkConnectionType)currentCellularConnectionForDataService {
    NSString *techonology = [self currentRadioAccessTechnologyForDataService];
    if (!techonology) {
        return TTCellularNetworkConnectionNone;
    }
    return ParseRadioAccessTechnology(techonology);
}

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wunguarded-availability"
+ (CTCarrier *)currentCellularProviderForDataService {
    if (!UsingCellularServiceAPI()) {
        return nil;
    }
    NSString *serviceIndentifier = GetDataServiceIdentifier();
    if (!serviceIndentifier) {
        return nil;
    }
    LOCK(serviceSubscriberCellularProvidersLock);
    NSDictionary *serviceSubscriberCellularProviders = self.telephoneInfo.serviceSubscriberCellularProviders;
    UNLOCK(serviceSubscriberCellularProvidersLock);
    
    return serviceSubscriberCellularProviders[serviceIndentifier];
}
#pragma clang diagnotic pop

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wunguarded-availability"
+ (CTCarrier *)currentCellularProviderForService:(TTCellularServiceType)service {
    if (UsingCellularServiceAPI()) {
        NSString * serviceIndentifier = ServiceIdentifierForCelluarService(service);
        LOCK(serviceSubscriberCellularProvidersLock);
        NSDictionary *serviceSubscriberCellularProviders = self.telephoneInfo.serviceSubscriberCellularProviders;
        UNLOCK(serviceSubscriberCellularProvidersLock);
        if (serviceSubscriberCellularProviders[serviceIndentifier]) {
            return serviceSubscriberCellularProviders[serviceIndentifier];
        } else {
            return nil;
        }
    } else {
        return self.telephoneInfo.subscriberCellularProvider;
    }
}
#pragma clang diagnotic pop

+ (NSString *)currentRadioAccessTechnologyForService:(TTCellularServiceType)service {
    if (UsingCellularServiceAPI()) {
        switch (service) {
            case TTCellularServiceTypePrimary:
                return latestPrimaryRadioAccessTechString;
                break;
            case TTCellularServiceTypeSecondary:
                return latestSecondaryRadioAccessTechString;
                break;
        }
    } else {
        return latestRadioAccessTechString;
    }
}

+ (NSString *)currentRadioAccessTechnologyForDataService {
    if (!UsingCellularServiceAPI()) {
        return nil;
    }
    NSString *serviceIndentifier = GetDataServiceIdentifier();
    LOCK(serviceCurrentRadioAccessTechnologyLock);
    NSDictionary *serviceCurrentRadioAccessTechnology = self.telephoneInfo.serviceCurrentRadioAccessTechnology;
    UNLOCK(serviceCurrentRadioAccessTechnologyLock);
    
    return serviceCurrentRadioAccessTechnology[serviceIndentifier];
}

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wunguarded-availability"
+ (NSArray<NSNumber *> *)currentAvailableCellularServices {
    if (UsingCellularServiceAPI()) {
        NSMutableArray *services = [NSMutableArray arrayWithCapacity:2];
        NSString * primaryServiceIdentifier = ServiceIdentifierForCelluarService(TTCellularServiceTypePrimary);
        NSString * seconaryServiceIdentifier = ServiceIdentifierForCelluarService(TTCellularServiceTypeSecondary);
        LOCK(serviceCurrentRadioAccessTechnologyLock);
        NSDictionary *serviceCurrentRadioAccessTechnology = [self.telephoneInfo.serviceCurrentRadioAccessTechnology copy];
        UNLOCK(serviceCurrentRadioAccessTechnologyLock);
        if (serviceCurrentRadioAccessTechnology[primaryServiceIdentifier]) {
            [services addObject:@(TTCellularServiceTypePrimary)];
        }
        if (serviceCurrentRadioAccessTechnology[seconaryServiceIdentifier]) {
            [services addObject:@(TTCellularServiceTypeSecondary)];
        }
        return [services copy];
    } else {
        NSString *currentRadioAccessTechnology = self.telephoneInfo.currentRadioAccessTechnology;
        if (currentRadioAccessTechnology) {
            return @[@(TTCellularServiceTypePrimary)];
        } else {
            return @[];
        }
    }
}
#pragma clang diagnotic pop

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wunguarded-availability"
+ (NSArray<CTCarrier *> *)currentAvailableCellularProviders {
    if (UsingCellularServiceAPI()) {
        NSMutableArray *cellularProviders = [NSMutableArray arrayWithCapacity:2];
        LOCK(serviceSubscriberCellularProvidersLock);
        NSDictionary *serviceSubscriberCellularProviders = self.telephoneInfo.serviceSubscriberCellularProviders;
        UNLOCK(serviceSubscriberCellularProvidersLock);
        NSString *primaryServiceIdentifier = ServiceIdentifierForCelluarService(TTCellularServiceTypePrimary);
        CTCarrier *primaryCellularProvider = serviceSubscriberCellularProviders[primaryServiceIdentifier];
        if (primaryCellularProvider) {
            [cellularProviders addObject:primaryCellularProvider];
        }
        NSString *seconaryServiceIdentifier = ServiceIdentifierForCelluarService(TTCellularServiceTypeSecondary);
        CTCarrier *seconaryCellularProvider = serviceSubscriberCellularProviders[seconaryServiceIdentifier];
        if (seconaryCellularProvider) {
            [cellularProviders addObject:seconaryCellularProvider];
        }
        return [cellularProviders copy];
    } else {
        CTCarrier *cellularProvider = self.telephoneInfo.subscriberCellularProvider;
        if (cellularProvider) {
            return @[cellularProvider];
        } else {
            return @[];
        }
    }
}
#pragma clang diagnotic pop

@end
#endif

@implementation TTReachability (Config)

+ (void)setStatusCacheConfigBlock:(double (^)(void))statusCacheConfigBlock {
    globalStatusCacheConfigBlock = statusCacheConfigBlock;
}

+ (double (^)(void))statusCacheConfigBlock {
    return globalStatusCacheConfigBlock;
}

+ (void)setInternetConnectionNotifyRunLoop:(NSRunLoop *)internetConnectionNotifyRunLoop {
    globalInternetConnectionNotifyRunLoop = internetConnectionNotifyRunLoop;
}

+ (NSRunLoop *)internetConnectionNotifyRunLoop {
    return globalInternetConnectionNotifyRunLoop;
}

+ (void)setInternetConnectionNotifyRunLoopMode:(NSRunLoopMode)internetConnectionNotifyRunLoopMode {
    globalInternetConnectionNotifyRunLoopMode = [internetConnectionNotifyRunLoopMode copy];
}

+ (NSRunLoopMode)internetConnectionNotifyRunLoopMode {
    return globalInternetConnectionNotifyRunLoopMode;
}

@end
