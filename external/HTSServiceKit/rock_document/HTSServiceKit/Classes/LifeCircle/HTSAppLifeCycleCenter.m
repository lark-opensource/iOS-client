//
//  HTSAppLifeCycleCenter.m
//  HTSBootLoader
//
//  Created by Huangwenchen on 2019/11/17.
//  Copyright © 2019 bytedance. All rights reserved.
//

#import "HTSAppLifeCycleCenter.h"
#include <mach-o/getsect.h>
#import "HTSBundleLoader.h"
#import "HTSBundleLoader+Private.h"
#import "HTSMacro.h"
#import "HTSAppContext.h"
#import "HTSSignpost.h"
#import "HTSBootLogger.h"
#import "HTSAppMode.h"
#import "HTSServiceCenter.h"

#define DEFAULT_LIFE_IMP(_METHOD_NAME_) - (void)_METHOD_NAME_{\
    NSArray * modules = [self _snapshotModules];\
    for (id<HTSAppLifeCycle> module in modules) {\
        if ([module respondsToSelector:@selector(_METHOD_NAME_)]) {\
            NSString * mark = [NSString stringWithFormat:@"%@:%@",NSStringFromClass(module.class),NSStringFromSelector(_cmd)];\
            id<HTSAppEventPlugin> plugin = HTSCurrentContext().appDelegate.appEventPlugin;\
            if (plugin && [plugin respondsToSelector:@selector(applicationLifeCycleTask:pluginPosition:)]) {\
                [plugin applicationLifeCycleTask:mark pluginPosition:HTSPluginPositionBegin];\
            }\
            CFAbsoluteTime begin = CFAbsoluteTimeGetCurrent() * 1000;\
            os_signpost_id_t signpostId = hts_signpost_begin(mark.UTF8String);\
            [module _METHOD_NAME_];\
            hts_signpost_end(signpostId,mark.UTF8String);\
            CFAbsoluteTime end = CFAbsoluteTimeGetCurrent() * 1000;\
            if (plugin && [plugin respondsToSelector:@selector(applicationLifeCycleTask:pluginPosition:)]) {\
                [plugin applicationLifeCycleTask:mark pluginPosition:HTSPluginPositionEnd];\
            }\
            [[HTSBootLogger sharedLogger] logName:mark duration:end - begin];\
        }\
    }\
}\

@interface _HTSLifeCycleItem: NSObject

@property (strong, nonatomic) id<HTSAppLifeCycle> module;
@property (assign, nonatomic) HTSMachHeader * machHeader;

@end

@implementation _HTSLifeCycleItem

@end

@interface HTSAppLifeCycleCenter()<HTSBundleLoaderDelegate>

@property (strong, nonatomic) NSMutableArray<_HTSLifeCycleItem *> * lifeCycleObservers;

@end

@implementation HTSAppLifeCycleCenter

+ (instancetype)sharedCenter{
    static dispatch_once_t onceToken;
    static HTSAppLifeCycleCenter * _center;
    dispatch_once(&onceToken, ^{
        _center = [[HTSAppLifeCycleCenter alloc] initPrivate];
    });
    return _center;
}

- (instancetype)initPrivate
{
    self = [super init];
    if (self) {
        _lifeCycleObservers = [[NSMutableArray alloc] init];
        NSInteger imageCount = _dyld_image_count();
        for (uint32_t idx = 0; idx < imageCount; idx++) {
            HTSMachHeader * mh = (HTSMachHeader *)_dyld_get_image_header(idx);
            NSArray * items = [self _parseModulesInMachO:mh];
            if (items) {
                [self.lifeCycleObservers addObjectsFromArray:items];
            }
        }
        [self resortModules];
        //排序
        [HTSBundleLoader sharedLoader].delegate = self;
    }
    return self;
}

- (void)resortModules{
    [self.lifeCycleObservers sortUsingComparator:^NSComparisonResult(_HTSLifeCycleItem* item1, _HTSLifeCycleItem* item2) {
        NSInteger p1 = HTSLifeCyclePriorityDefault;
        NSInteger p2 = HTSLifeCyclePriorityDefault;
        if ([item1.class respondsToSelector:@selector(priority)]) {
            p1 = [item1.class priority];
        }
        if ([item2.class respondsToSelector:@selector(priority)]) {
            p2 = [item2.class priority];
        }
        if (p1 == p2) {
            return NSOrderedSame;
        }else if(p2 < p1){
            return NSOrderedAscending;
        }else{
            return NSOrderedDescending;
        }
    }];
}

#pragma mark - APP Life Circle

DEFAULT_LIFE_IMP(onAppWillResignActive);
DEFAULT_LIFE_IMP(onAppDidBecomeActive);
DEFAULT_LIFE_IMP(onAppWillTerminate);
DEFAULT_LIFE_IMP(onAppWillEnterForeground);
DEFAULT_LIFE_IMP(onAppDidEnterBackground);
DEFAULT_LIFE_IMP(onAppDidReceiveMemoryWarning);
DEFAULT_LIFE_IMP(onAppDidRegisterNotificationSetting);
DEFAULT_LIFE_IMP(onAppDidRegisterDeviceToken);
DEFAULT_LIFE_IMP(onAppDidFailToRegisterForRemoteNotifications);
DEFAULT_LIFE_IMP(onAppDidReceiveLocalNotification);
DEFAULT_LIFE_IMP(onAppDidReceiveRemoteNotification);
DEFAULT_LIFE_IMP(onAppHandleNotification);
DEFAULT_LIFE_IMP(onAppPerformBackgroundFetch);

- (void)onHandleAppShortcutAction API_AVAILABLE(ios(9.0)){
    NSArray * modules = [self _snapshotModules];
    for (id<HTSAppLifeCycle> module in modules) {
        if ([module respondsToSelector:@selector(onHandleAppShortcutAction)]) {
            NSString * mark = [NSString stringWithFormat:@"%@:%@",NSStringFromClass(module.class),NSStringFromSelector(_cmd)];\
            CFAbsoluteTime begin = CFAbsoluteTimeGetCurrent() * 1000;
            os_signpost_id_t signpostId = hts_signpost_begin(mark.UTF8String);
            [module onHandleAppShortcutAction];
            hts_signpost_end(signpostId,mark.UTF8String);
            CFAbsoluteTime end = CFAbsoluteTimeGetCurrent() * 1000;
            [[HTSBootLogger sharedLogger] logName:mark duration:end - begin];
        }
    }
}

DEFAULT_LIFE_IMP(onHandleEventsForBackgroundURLSession);

- (BOOL)onHandleAppOpenUrl{
    NSArray<id<HTSAppLifeCycle>> * modules = [self _snapshotModules];
    for (id<HTSAppLifeCycle> module in modules) {
       if ([module respondsToSelector:@selector(onHandleAppOpenUrl)]) {
           BOOL res = [module onHandleAppOpenUrl];
           HTSLog(@"%@ handle openURL %@",[module class],HTSCurrentContext().openURLContext.openURL ?: @"NULL");
           if (res) {
               return YES;
           }
       }
    }
    return NO;
}

- (BOOL)onHandleAppContinueUserActivity{
    NSArray<id<HTSAppLifeCycle>> * modules = [self _snapshotModules];
    for (id<HTSAppLifeCycle> module in modules) {
       if ([module respondsToSelector:@selector(onHandleAppContinueUserActivity)]) {
           BOOL res = [module onHandleAppContinueUserActivity];
           HTSLog(@"%@ handle userActivity",[module class]);
           if (res) {
               return YES;
           }
       }
    }
    return NO;
}

#pragma mark - Bundle Loader Delegate

- (void)bundleLoader:(nonnull HTSBundleLoader *)loader didLoadBundle:(nonnull NSString *)name {
    HTSMachHeader * header = HTSGetMachHeader(name);
    @synchronized (self) {
        NSArray<id<HTSAppLifeCycle>> * modules = [self _parseModulesInMachO:header];
        if (!modules) {
            return;
        }
        [self.lifeCycleObservers addObjectsFromArray:modules];
        [self resortModules];
    }
}

- (void)bundleLoader:(nonnull HTSBundleLoader *)loader willUnLoadName:(nonnull NSString *)name {
    HTSMachHeader * header = HTSGetMachHeader(name);
    @synchronized (self) {
        NSMutableArray * toRemove = [[NSMutableArray alloc] init];
        for (_HTSLifeCycleItem * item in self.lifeCycleObservers) {
            if (item.machHeader == header) {
                [toRemove addObject:item];
            }
        }
        [self.lifeCycleObservers removeObjectsInArray:toRemove];
        [self resortModules];
    }
}

#pragma mark - private

NSArray<id<HTSAppLifeCycle>> *internalParseModulesInMachO(HTSMachHeader * mh,const char * segment_name) __attribute__((no_sanitize("address")))
{
    unsigned long size = 0;
    const char ** data = (const char **)getsectiondata(mh,segment_name, _HTS_LIFE_CIRCLE_SECTION, &size);
    if (size == 0) {
        return nil;
    }
    unsigned long moduleCount = size / sizeof(const char *);
    NSMutableArray<id<HTSAppLifeCycle>> * modules = [[NSMutableArray alloc] init];
    for (NSInteger idx = 0; idx < moduleCount; idx++) {
        const char * clsName = data[idx];
#if __has_feature(address_sanitizer)
        if (clsName == 0) {
            // correct
            continue;
        }
        Class cls = NSClassFromString([NSString stringWithUTF8String:clsName]);
        if (cls == nil) {
            // correct
            continue;
        }
#else
        if (clsName == 0) {
            // should not be nil
            NSLog(@"class name should not be nil");
            assert(0);
        }
        Class cls = NSClassFromString([NSString stringWithUTF8String:clsName]);
        if (cls == nil) {
            // should not be nil
            NSLog(@"Fail to get module class : %@",clsName);
            assert(0);
        }
#endif
        id<HTSAppLifeCycle> module = module = [[cls alloc] init];
        _HTSLifeCycleItem * item = [[_HTSLifeCycleItem alloc] init];
        item.machHeader = mh;
        item.module = module;
        [modules addObject:module];
    }
    return modules;
}

- (NSArray<id<HTSAppLifeCycle>> *)_parseModulesInMachO:(HTSMachHeader *)mh{
    const char *segmentName = HTSSegmentNameForCurrentMode();
    //LifeCycle is always exclusive, so we only need to parse current mode
    return internalParseModulesInMachO(mh,segmentName);
}

- (NSArray<id<HTSAppLifeCycle>> *)_snapshotModules{
    NSArray * modules;
    @synchronized (self) {
        modules = [self.lifeCycleObservers copy];
    }
    return modules;
}

@end

FOUNDATION_EXPORT id HTSGetAppLifeCycle(Class cls){
    if (!cls) {
        return nil;
    }
    id res = nil;
    NSArray<id<HTSAppLifeCycle>> * modules = [[HTSAppLifeCycleCenter sharedCenter] _snapshotModules];
    for (id<HTSAppLifeCycle> module in modules) {
        if ([module isMemberOfClass:cls]) {
            res = module;
        }
    }
    return res;
}
