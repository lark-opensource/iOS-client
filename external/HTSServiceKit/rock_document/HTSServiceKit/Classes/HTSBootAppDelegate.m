//
//  HTSBootAppDelegate.m
//  HTSBootLoader
//
//  Created by Huangwenchen on 2019/11/14.
//  Copyright © 2019 bytedance. All rights reserved.
//

#import "HTSBootAppDelegate.h"
#import "HTSAppContext.h"
#import "HTSBootLoader.h"
#import "HTSAppLifeCycleCenter.h"
#import "HTSBootLoader+Private.h"
#import "HTSBundleLoader+Private.h"
#import <objc/runtime.h>
#import "HTSMessageCenter.h"

#define HTSLifeCyclePluginBegin(_SELNAME_) if ([self.appEventPlugin respondsToSelector:@selector(_SELNAME_:pluginPosition:)]) {\
       [self.appEventPlugin _SELNAME_:application pluginPosition:HTSPluginPositionBegin];\
   }\

#define HTSLifeCyclePluginEnd(_SELNAME_) if ([self.appEventPlugin respondsToSelector:@selector(_SELNAME_:pluginPosition:)]) {\
    [self.appEventPlugin _SELNAME_:application pluginPosition:HTSPluginPositionEnd];\
}\

@interface HTSAppContext()

@property (strong, nonatomic, readwrite) NSDictionary * launchOptions;
@property (strong, nonatomic, readwrite) UIApplication * application;
@property (assign, nonatomic, readwrite) BOOL backgroundLaunch;
@property (strong, nonatomic, readwrite) HTSBootAppDelegate * appDelegate;
@property (strong, nonatomic, readwrite) HTSOpenURLContext * openURLContext;
@property (strong, nonatomic, readwrite) HTSNotificationContext * notificationContext;
@property (strong, nonatomic, readwrite) HTSUserActivityContext * userActivityContext;
@property (strong, nonatomic, readwrite) HTSBackgroundFetchContext * backgroundFetchContext;
@property (strong, nonatomic, readwrite) HTSShortcutContext * shortcutContext API_AVAILABLE(ios(9.0));
@property (strong, nonatomic, readwrite) HTSBgURLSessionContext * bgURLSessionContext;
@property (strong, nonatomic, readwrite) HTSHandleNotificationContext * handleNotificationContext;

@end

@implementation HTSAppContext

+ (instancetype)sharedContext{
    static HTSAppContext * _context;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _context = [[HTSAppContext alloc] init];
    });
    return _context;
}

- (BOOL)isSystemBackgroundLaunch
{
    return [self.appDelegate isSystemBackgroundLaunch];
}

@end

@interface HTSOpenURLContext()

@property (nonatomic, strong, readwrite) NSURL *openURL;
@property (nonatomic, strong, readwrite) NSDictionary *options API_AVAILABLE(ios(9.0));
@property (nonatomic, strong, readwrite) NSString *sourceApplication;
@property (nonatomic, strong, readwrite) id annotation;

@end

@implementation HTSOpenURLContext

@end

@interface HTSNotificationContext()

@property (nonatomic, strong, readwrite) NSError *registerError;
@property (nonatomic, strong, readwrite) NSData *deviceToken;
@property (nonatomic, strong, readwrite) NSDictionary *remoteUserInfo;
@property (nonatomic, copy  , readwrite) HTSBackgroundFetchResultHandler notificationResultHander;
@property (nonatomic, strong, readwrite) UILocalNotification *localNotification API_DEPRECATED("Use UserNotifications Framework", ios(4.0, 10.0));
@property (nonatomic, strong, readwrite) UIUserNotificationSettings *settings API_DEPRECATED("Use UserNotifications Framework", ios(8.0, 10.0));

@end

@implementation HTSNotificationContext

@end

@interface HTSUserActivityContext()

@property (nonatomic, strong, readwrite) NSString *activityType;
@property (nonatomic, strong, readwrite) NSUserActivity *userActivity;
@property (nonatomic, strong, readwrite) NSError *userActivityError;
@property (nonatomic, copy  , readwrite) HTSUserActivityRestoreHandler restoreHandler;

@end

@implementation HTSUserActivityContext

@end

@interface HTSShortcutContext()

@property (nonatomic, strong, readwrite) UIApplicationShortcutItem *item API_AVAILABLE(ios(9.0));
@property (nonatomic, copy  , readwrite) HTSShortcutCompletionHandler completionHandler;

@end

@implementation HTSShortcutContext

@end

@interface HTSBackgroundFetchContext()

@property (nonatomic, copy, readwrite) HTSBackgroundFetchResultHandler bgFetchResultHandler;

@end

@implementation HTSBackgroundFetchContext

@end

@interface HTSBgURLSessionContext()

@property (nonatomic, copy, readwrite) NSString * identifier;
@property (nonatomic ,copy, readwrite) void (^completionHandler)(void);

@end

@implementation HTSBgURLSessionContext


@end

@implementation HTSHandleNotificationContext

- (instancetype)initWithUserInfo:(NSDictionary *)userInfo
              categoryIdentifier:(NSString *)categoryIdentifier
                actionIdentifier:(NSString *)actionIdentifier
                        userText:(NSString *)userText
                      identifier:(NSString *)identifier
                    isColdLaunch:(BOOL)isColdLaunch {
    self = [super init];
    if (self) {
        _userInfo = userInfo;
        _categoryIdentifier = categoryIdentifier;
        _actionIdentifier = actionIdentifier;
        _userText = userText;
        _identifier = identifier;
        _isColdLaunch = isColdLaunch;
    }
    return self;
}

@end

extern inline HTSAppContext * HTSCurrentContext(void){
    return [HTSAppContext sharedContext];
}

@implementation HTSBootAppDelegate

- (BOOL)delayLaunchCompletionTaskUntilFeedReady
{
    return NO;
}

- (BOOL)autoMarkLuanchCompletion
{
    return YES;
}

- (BOOL)runOneBootTaskPerRunloop{
    return NO;
}

- (void)onAppHandleNotificationWithContext:(HTSHandleNotificationContext *)context {
    HTSCurrentContext().handleNotificationContext = context;
    [[HTSAppLifeCycleCenter sharedCenter] onAppHandleNotification];
}

- (BOOL)isSystemBackgroundLaunch
{
    return NO;
}

- (NSDictionary *)currentBootConfig{
    return nil;
}

- (id<HTSAppEventPlugin>)appEventPlugin{
    return nil;
}

FOUNDATION_EXPORT void HTSLoadCompileTimeNotificationData(void);
- (BOOL)application:(UIApplication *)application willFinishLaunchingWithOptions:(NSDictionary<UIApplicationLaunchOptionsKey,id> *)launchOptions
{
    // 初始化LifeCycleCenter单例
    [HTSAppLifeCycleCenter sharedCenter];
    HTSLoadCompileTimeNotificationData();
    return YES;
}

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary<UIApplicationLaunchOptionsKey,id> *)launchOptions
{
    HTSCurrentContext().application = application;
    HTSCurrentContext().appDelegate = self;
    HTSCurrentContext().launchOptions = launchOptions;
    HTSCurrentContext().backgroundLaunch = ([UIApplication sharedApplication].applicationState == UIApplicationStateBackground);
    [[HTSBootLoader sharedLoader] bootWithConfig:[self currentBootConfig]];
    if (!HTSCurrentContext().backgroundLaunch) {
        _HTSBootNotifyFirstEnterFourground();
    }
    //iOS 12-, rvc viewDidAppear is invoked within runloop block
    if ([self useRunloopBlockAsLaunchEnd] && HTSIsLaunchCompletionAutoMarked()) {
        CFRunLoopPerformBlock(CFRunLoopGetMain(), kCFRunLoopCommonModes, ^{
            HTSBootMarkLaunchCompletion();
        });
    }
    return YES;
}

- (BOOL)useRunloopBlockAsLaunchEnd
{
    return [UIDevice currentDevice].systemVersion.floatValue < 13.0;
}

- (void)_observerRunloopFree:(void(^)(void))block
{
    CFRunLoopRef runLoop = CFRunLoopGetCurrent();
    CFStringRef runLoopMode = kCFRunLoopDefaultMode;
    __block CFRunLoopObserverRef observer;
    observer = CFRunLoopObserverCreateWithHandler
    (kCFAllocatorDefault, kCFRunLoopBeforeWaiting, true, 0, ^(CFRunLoopObserverRef ob, CFRunLoopActivity _) {
        block();
        CFRunLoopRemoveObserver(runLoop, ob, runLoopMode);
        CFRelease(observer);
    });
    CFRunLoopAddObserver(runLoop, observer, runLoopMode);
}

/// Method is invoked with runloop source 0
- (void)applicationDidBecomeActive:(UIApplication *)application
{
    [[HTSAppLifeCycleCenter sharedCenter] onAppDidBecomeActive];
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        if (![self useRunloopBlockAsLaunchEnd] && HTSIsLaunchCompletionAutoMarked()) {
            //RootVC didAppear is invoked with before waiting, wait next runloop to invoke post luanch task
            [self _observerRunloopFree:^{
                //Wake up runloop, run post luanch task
                dispatch_async(dispatch_get_main_queue(), ^{
                    HTSBootMarkLaunchCompletion();
                });
            }];
        }
    });
}

- (void)applicationWillTerminate:(UIApplication *)application{
    [[HTSAppLifeCycleCenter sharedCenter] onAppWillTerminate];
}

- (void)applicationWillResignActive:(UIApplication *)application
{   
    [[HTSAppLifeCycleCenter sharedCenter] onAppWillResignActive];
}

- (void)applicationWillEnterForeground:(UIApplication *)application
{
    if (HTSCurrentContext().backgroundLaunch) {
        static dispatch_once_t onceToken;
        dispatch_once(&onceToken, ^{
            _HTSBootNotifyFirstEnterFourground();
        });
    }
    [[HTSAppLifeCycleCenter sharedCenter] onAppWillEnterForeground];
}

- (void)applicationDidEnterBackground:(UIApplication *)application
{
    [[HTSAppLifeCycleCenter sharedCenter] onAppDidEnterBackground];
}

- (void)applicationDidReceiveMemoryWarning:(UIApplication *)application
{
    [[HTSAppLifeCycleCenter sharedCenter] onAppDidReceiveMemoryWarning];
}

#pragma mark - Schemes

- (BOOL)application:(UIApplication *)app openURL:(NSURL *)url options:(NSDictionary<UIApplicationOpenURLOptionsKey,id> *)options
{
    HTSOpenURLContext *context =  [[HTSOpenURLContext alloc] init];
    context.openURL = url;
    if (@available(iOS 9.0, *)) {
        context.options = options;
        context.annotation = options[UIApplicationOpenURLOptionsAnnotationKey];
        context.sourceApplication = options[UIApplicationOpenURLOptionsSourceApplicationKey];
    }
    HTSCurrentContext().openURLContext = context;
    return [[HTSAppLifeCycleCenter sharedCenter] onHandleAppOpenUrl];
}

- (BOOL)application:(UIApplication *)app openURL:(NSURL *)url sourceApplication:(nullable NSString *)sourceApplication annotation:(nonnull id)annotation
{
    HTSOpenURLContext *context = [[HTSOpenURLContext alloc] init];
    context.openURL = url;
    context.sourceApplication = sourceApplication;
    context.annotation = annotation;
    HTSCurrentContext().openURLContext = context;
    return [[HTSAppLifeCycleCenter sharedCenter] onHandleAppOpenUrl];
}


- (BOOL)application:(UIApplication *)application continueUserActivity:(NSUserActivity *)userActivity restorationHandler:(void (^)(NSArray<id<UIUserActivityRestoring>> * _Nullable))restorationHandler
{
    HTSUserActivityContext *context = [[HTSUserActivityContext alloc] init];
    context.userActivity = userActivity;
    context.restoreHandler = restorationHandler;
    HTSCurrentContext().userActivityContext = context;
    return [[HTSAppLifeCycleCenter sharedCenter] onHandleAppContinueUserActivity];
}

- (void)application:(UIApplication *)application performActionForShortcutItem:(UIApplicationShortcutItem *)shortcutItem completionHandler:(void(^)(BOOL succeeded))completionHandler
API_AVAILABLE(ios(9.0)){
    if (@available(iOS 9.0, *)) {
        HTSShortcutContext *context = [[HTSShortcutContext alloc] init];
        context.item = shortcutItem;
        context.completionHandler = completionHandler;
        HTSCurrentContext().shortcutContext = context;
        [[HTSAppLifeCycleCenter sharedCenter] onHandleAppShortcutAction];
    }
}

- (void)application:(UIApplication *)application handleEventsForBackgroundURLSession:(NSString *)identifier completionHandler:(void (^)(void))completionHandler{
    HTSBgURLSessionContext * context = [[HTSBgURLSessionContext alloc] init];
    context.identifier = identifier;
    context.completionHandler = completionHandler;
    HTSCurrentContext().bgURLSessionContext = context;
    [[HTSAppLifeCycleCenter sharedCenter] onHandleEventsForBackgroundURLSession];
}
#pragma mark - Push Notification

- (void)application:(UIApplication *)application didRegisterUserNotificationSettings:(UIUserNotificationSettings *)notificationSettings{
    HTSNotificationContext * context = [[HTSNotificationContext alloc] init];
    context.settings = notificationSettings;
    HTSCurrentContext().notificationContext = context;
    [[HTSAppLifeCycleCenter sharedCenter] onAppDidRegisterNotificationSetting];
}

- (void)application:(UIApplication *)application didRegisterForRemoteNotificationsWithDeviceToken:(NSData *)deviceToken
{
    HTSNotificationContext * context = [[HTSNotificationContext alloc] init];
    context.deviceToken = deviceToken;
    HTSCurrentContext().notificationContext = context;
    [[HTSAppLifeCycleCenter sharedCenter] onAppDidRegisterDeviceToken];
}

- (void)application:(UIApplication *)application didFailToRegisterForRemoteNotificationsWithError:(NSError *)error
{
    HTSNotificationContext * context = [[HTSNotificationContext alloc] init];
    context.registerError = error;
    HTSCurrentContext().notificationContext = context;
    [[HTSAppLifeCycleCenter sharedCenter] onAppDidFailToRegisterForRemoteNotifications];
}

- (void)application:(UIApplication *)application didReceiveLocalNotification:(nonnull UILocalNotification *)notification
{
    HTSNotificationContext * context = [[HTSNotificationContext alloc] init];
    context.localNotification = notification;
    HTSCurrentContext().notificationContext = context;
    [[HTSAppLifeCycleCenter sharedCenter] onAppDidReceiveLocalNotification];
}

#pragma mark - Background fetch

- (void)application:(UIApplication *)application didReceiveRemoteNotification:(NSDictionary *)userInfo fetchCompletionHandler:(void (^)(UIBackgroundFetchResult))completionHandler
{
    HTSNotificationContext * context = [[HTSNotificationContext alloc] init];
    context.notificationResultHander = completionHandler;
    context.remoteUserInfo = userInfo;
    HTSCurrentContext().notificationContext = context;
    [[HTSAppLifeCycleCenter sharedCenter] onAppDidReceiveRemoteNotification];
}

#pragma mark - Screen Rotate

- (UIInterfaceOrientationMask)application:(UIApplication *)application supportedInterfaceOrientationsForWindow:(nullable UIWindow *)window {
    return self.supportOrientation;
}

#pragma mark - Property

- (UIInterfaceOrientationMask)supportOrientation{
    NSNumber * num = objc_getAssociatedObject(self, @selector(supportOrientation));
    if (num) {
        return num.unsignedIntegerValue;
    }else{
        return UIInterfaceOrientationMaskPortrait;
    }
}

- (void)setSupportOrientation:(UIInterfaceOrientationMask)supportOrientation{
    objc_setAssociatedObject(self, @selector(supportOrientation), @(supportOrientation), OBJC_ASSOCIATION_RETAIN);
}

@end

FOUNDATION_EXPORT BOOL HTSIsLaunchCompletionAutoMarked(void)
{
    return [HTSCurrentContext().appDelegate autoMarkLuanchCompletion];
}
