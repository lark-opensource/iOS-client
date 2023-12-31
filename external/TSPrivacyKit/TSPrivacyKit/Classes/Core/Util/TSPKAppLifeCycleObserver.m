//Copyright © 2021 Bytedance. All rights reserved.

#import "TSPKAppLifeCycleObserver.h"
#import "TSPKMonitor.h"
#import "TSPKLogger.h"
#import "TSPKUtils.h"
#import <PNSServiceKit/PNSServiceCenter.h>
#import <ByteDanceKit/NSDictionary+BTDAdditions.h>
#import "TSPKHostEnvProtocol.h"
#import "TSPrivacyKitConstants.h"
#import "TSPKSignalManager+public.h"
#import "TSPKConfigs.h"

static NSString *const TSPKLogUITag = @"PrivacyUIInfo";

@interface TSPKAppLifeCycleObserver ()

@property(nonatomic) BOOL isBackground;
@property(nonatomic) NSTimeInterval timeLastDidEnterBackground;
@property(nonatomic) NSTimeInterval serverTimeLastDidEnterBackground;
@property(atomic, strong, nullable) NSString *currentPage;
@property(nonatomic, strong) NSMutableDictionary *notificationDict;

@end

@implementation TSPKAppLifeCycleObserver

- (instancetype)init
{
    self = [super init];
    if (self) {
        self.isBackground = NO;
        self.timeLastDidEnterBackground = 0;
        self.serverTimeLastDidEnterBackground = 0;
        self.notificationDict = [self defaultNotification];
    }
    return self;
}

+ (instancetype)sharedObserver
{
    static TSPKAppLifeCycleObserver *utils;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        utils = [[TSPKAppLifeCycleObserver alloc] init];
    });
    return utils;
}

- (void)setup
{
    static dispatch_once_t setupToken;
    dispatch_once(&setupToken, ^{
        id<TSPKHostEnvProtocol> hostEnv = PNS_GET_INSTANCE(TSPKHostEnvProtocol);
        if ([hostEnv respondsToSelector:@selector(appLifeCycleNotificationDictionary)]) {
            [self.notificationDict addEntriesFromDictionary:[hostEnv appLifeCycleNotificationDictionary]];
        }
        [self addNotifications];
    });
}

- (void)addNotifications
{
    NSNotificationCenter *center = [NSNotificationCenter defaultCenter];
    [center addObserver:self selector:@selector(handlePageStatusChangeNotification:) name:TSPKViewDidAppear object:nil];
    [center addObserver:self selector:@selector(handlePageStatusChangeNotification:) name:TSPKViewDidDisappear object:nil];
    [center addObserver:self selector:@selector(handlePageStatusChangeNotification:) name:TSPKViewWillAppear object:nil];
    [center addObserver:self selector:@selector(handlePageStatusChangeNotification:) name:TSPKViewWillDisappear object:nil];
    [center addObserver:self selector:@selector(handlePageDeallocNotification:) name:TSPKViewDealloc object:nil];
    [center addObserver:self selector:@selector(handlePageStatusChangeNotification:) name:TSPKViewDidLoad object:nil];
    [center addObserver:self selector:@selector(applicationWillEnterForeground) name:[self getNotification:TSPKAppWillEnterForegroundNotificationKey] object:nil];
    [center addObserver:self selector:@selector(applicationDidEnterBackground) name:[self getNotification:TSPKAppDidEnterBackgroundNotificationKey] object:nil];
    [center addObserver:self selector:@selector(applicationWillResignActive) name:[self getNotification:TSPKAppWillResignActiveNotificationKey] object:nil];
    [center addObserver:self selector:@selector(applicationDidBecomeActive) name:[self getNotification:TSPKAppDidBecomeActiveNotificationKey] object:nil];
    [center addObserver:self selector:@selector(applicationDidReceiveMemoryWarning) name:[self getNotification:TSPKAppDidReceiveMemoryWarningNotificationKey] object:nil];
    [center addObserver:self selector:@selector(applicationWillTerminate) name:[self getNotification:TSPKAppWillTerminateNotificationKey] object:nil];
}

- (void)handlePageStatusChangeNotification:(NSNotification *)notification
{
    NSObject *pageName = notification.userInfo[TSPKPageNameKey];
    NSString *notificationName = notification.name;
    NSString *message;
    if (notification.userInfo && [pageName isKindOfClass: [NSString class]]) {
        
        if ([notificationName isEqualToString:TSPKViewDidAppear]) {
            message = [NSString stringWithFormat:@"%@ viewDidAppear", pageName];
            if ([[TSPKConfigs sharedConfig] enableUseAppLifeCycleCurrentTopView]) {
                NSString *currentTopVC = [TSPKUtils topVCName];
                if (![_currentPage isEqualToString:currentTopVC]) {
                    _currentPage = currentTopVC;
                }
            } else {
                _currentPage = (NSString *)pageName;
            }
        } else if ([notificationName isEqualToString:TSPKViewDidDisappear]) {
            message = [NSString stringWithFormat:@"%@ viewDidDisappear", pageName];
        } else if ([notificationName isEqualToString:TSPKViewWillAppear]) {
            message = [NSString stringWithFormat:@"%@ viewWillAppear", pageName];
        } else if ([notificationName isEqualToString:TSPKViewWillDisappear]) {
            message = [NSString stringWithFormat:@"%@ viewWillDisappear", pageName];
        } else if ([notificationName isEqualToString:TSPKViewDidLoad]) {
            message = [NSString stringWithFormat:@"%@ viewDidLoad", pageName];
        }
    }
    
    if (message.length > 0) {
        [TSPKLogger logWithTag:TSPKLogUITag message:message];
        [TSPKSignalManager addCommonSignalWithType:TSPKCommonSignalTypePage content:message];
    }
}

- (void)handlePageDeallocNotification:(NSNotification *)notification {
    NSObject *pageName = notification.userInfo[TSPKPageNameKey];
    
    if ([pageName isKindOfClass: [NSString class]]) {
        NSString *message = [NSString stringWithFormat:@"%@ dealloc", pageName];
        [TSPKLogger logWithTag:TSPKLogUITag message:message];
        [TSPKSignalManager addCommonSignalWithType:TSPKCommonSignalTypePage content:message];
    }
}

- (void)applicationWillEnterForeground {
    self.isBackground = NO;
    [TSPKLogger logWithTag:TSPKLogUITag message:@"UIApplicationWillEnterForegroundNotification"];
    [TSPKSignalManager addCommonSignalWithType:TSPKCommonSignalTypeApp content:@"appWillEnterForeground"];
}

- (void)applicationDidEnterBackground {
    //ALog info
    self.isBackground = YES;
    self.timeLastDidEnterBackground = [TSPKUtils getUnixTime];
    self.serverTimeLastDidEnterBackground = [TSPKUtils getServerTime];
    [TSPKLogger logWithTag:TSPKLogUITag message:@"UIApplicationDidEnterBackgroundNotification"];
    [TSPKSignalManager addCommonSignalWithType:TSPKCommonSignalTypeApp content:@"appDidEnterBackground"];
}

- (void)applicationWillResignActive {
    [TSPKLogger logWithTag:TSPKLogUITag message:@"UIApplicationWillResignActiveNotification"];
    [TSPKSignalManager addCommonSignalWithType:TSPKCommonSignalTypeApp content:@"appWillResignActive"];
}

- (void)applicationDidBecomeActive {
    [TSPKLogger logWithTag:TSPKLogUITag message:@"UIApplicationDidBecomeActiveNotification"];
    [TSPKSignalManager addCommonSignalWithType:TSPKCommonSignalTypeApp content:@"appDidBecomeActive"];
}

- (void)applicationDidReceiveMemoryWarning {
    [TSPKLogger logWithTag:TSPKLogUITag message:@"UIApplicationDidReceiveMemoryWarningNotification"];
    [TSPKSignalManager addCommonSignalWithType:TSPKCommonSignalTypeApp content:@"appDidReceiveMemoryWarning"];
}

- (void)applicationWillTerminate {
    [TSPKLogger logWithTag:TSPKLogUITag message:@"UIApplicationWillTerminateNotification"];
    [TSPKSignalManager addCommonSignalWithType:TSPKCommonSignalTypeApp content:@"appWillTerminate"];
}

- (BOOL)isAppBackground {
    return self.isBackground;
}

- (NSTimeInterval)getTimeLastDidEnterBackground {
    if (self.isBackground) {
        return self.timeLastDidEnterBackground;
    }
    return 0;
}

- (NSTimeInterval)getServerTimeLastDidEnterBackground {
    if (self.isBackground) {
        return self.serverTimeLastDidEnterBackground;
    }
    return 0;
}

- (NSString *)getCurrentPage {
    return self.currentPage ?: @"";
}

- (nullable NSMutableDictionary *)defaultNotification
{
    return @{
        TSPKAppWillEnterForegroundNotificationKey : UIApplicationWillEnterForegroundNotification,
        TSPKAppDidEnterBackgroundNotificationKey : UIApplicationDidEnterBackgroundNotification,
        TSPKAppWillResignActiveNotificationKey : UIApplicationWillResignActiveNotification,
        TSPKAppDidBecomeActiveNotificationKey : UIApplicationDidBecomeActiveNotification,
        TSPKAppDidReceiveMemoryWarningNotificationKey : UIApplicationDidReceiveMemoryWarningNotification,
        TSPKAppWillTerminateNotificationKey : UIApplicationWillTerminateNotification
    }.mutableCopy;
}

- (NSString *)getNotification:(NSString *)key {
    return [self.notificationDict btd_stringValueForKey:key];
}

@end
